#!/usr/bin/env bash
# health-check-dynamic.sh
# Dynamic Docker Compose health checker with emojis & color

set -euo pipefail

# Colors
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
BOLD="\e[1m"
RESET="\e[0m"

echo -e "\n${BOLD}📊 InfraLite Health Check Dashboard${RESET}"
echo "============================================"

# Loop through running containers
docker ps --format "{{.Names}} {{.Status}} {{.Ports}}" | while read -r name status ports; do
    echo -e "\n${BLUE}🔍 Checking: ${BOLD}${name}${RESET}"
    echo "   Status: $status"
    echo "   Ports:  ${ports:-none}"

    # Extract first published port (if any)
    if [[ -n "$ports" ]]; then
        host_ports=$(echo "$ports" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | cut -d: -f2)
        if [[ -z "$host_ports" ]]; then
            host_ports=$(echo "$ports" | grep -oE '0.0.0.0:[0-9]+' | cut -d: -f2)
        fi
    else
        host_ports=""
    fi

    # Try curl check if HTTP port is detected
    for port in $host_ports; do
        if [[ "$port" =~ ^(80|8080|8081|8082|8088|443|8200|9000|9443|5678|3000)$ ]]; then
            url="http://localhost:${port}"
            if [[ "$port" == "443" || "$port" == "9443" || "$port" == "8443" ]]; then
                url="https://localhost:${port}"
            fi

            echo "   Testing: $url ..."
            if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -qE "200|302"; then
                echo -e "   ${GREEN}✔ Healthy: accessible at ${url}${RESET}"
            else
                echo -e "   ${RED}✖ Issue: not responding at ${url}${RESET}"
                case $name in
                    portainer)
                        echo "     🛠️ Tip: Ensure Portainer is fully started, try: docker logs portainer"
                        ;;
                    traefik)
                        echo "     🛠️ Tip: Traefik dashboard: http://localhost:8080/dashboard/"
                        echo "        Check traefik logs for certificate or config errors."
                        ;;
                    kong)
                        echo "     🛠️ Tip: Kong Admin API should be at http://localhost:8001"
                        ;;
                    demo-ui)
                        echo "     🛠️ Tip: Demo UI returned 403 – check Nginx config inside demo-ui container."
                        ;;
                    vault)
                        echo "     🛠️ Tip: Vault health: curl http://localhost:8200/v1/sys/health"
                        ;;
                    *)
                        echo "     🛠️ Tip: Run 'docker logs $name' to debug further."
                        ;;
                esac
            fi
        fi
    done
done

echo -e "\n${BOLD}✅ Health check complete.${RESET}"
echo "============================================"