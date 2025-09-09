#!/usr/bin/env bash
set -euo pipefail

echo "=== InfraLite Health Check ==="

# List containers we expect
containers=(postgres redis traefik kong vault n8n portainer demo-ui)

for c in "${containers[@]}"; do
  if ! docker ps --format '{{.Names}}' | grep -q "^$c$"; then
    echo "✖ $c not running"
    continue
  fi

  health=$(docker inspect --format='{{json .State.Health.Status}}' "$c" 2>/dev/null || echo "null")
  status=$(docker inspect --format='{{.State.Status}}' "$c")

  if [[ "$health" != "null" ]]; then
    echo "✔ $c ($status, health=$health)"
  else
    echo "✔ $c ($status)"
  fi
done
