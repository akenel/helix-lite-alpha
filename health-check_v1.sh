#!/usr/bin/env bash
set -euo pipefail

echo "=== InfraLite Health Check ==="

# List of services + endpoints to check
declare -A services=(
  [postgres]="localhost:5432"
  [redis]="localhost:6379"
  [traefik]="http://localhost:8080/dashboard/"
  [kong]="http://localhost:8001/"
  [vault]="http://localhost:8200/v1/sys/health"
  [n8n]="http://localhost:5678/"
  [portainer]="http://localhost:9000/"
  [demo-ui]="http://localhost:3000/"
)

for service in "${!services[@]}"; do
  url="${services[$service]}"

  # If it looks like a TCP port, test with nc
  if [[ "$url" == *":"* && "$url" != http* ]]; then
    host="${url%:*}"
    port="${url#*:}"
    if nc -z "$host" "$port" >/dev/null 2>&1; then
      echo "✔ $service responding on $url"
    else
      echo "✖ $service not responding on $url"
    fi
  else
    # Otherwise test HTTP
    if curl -fsS --max-time 3 "$url" >/dev/null; then
      echo "✔ $service healthy at $url"
    else
      echo "✖ $service failed at $url"
    fi
  fi
done
