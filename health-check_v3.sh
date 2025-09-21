#!/usr/bin/env bash
# health-check-dynamic.sh
# Dynamic Docker Compose health checker with enhanced features

set -euo pipefail

# Colors and formatting
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# Define service URLs and descriptions in an associative array
declare -A SERVICES_INFO
SERVICES_INFO["n8n"]="http://localhost:5678"
SERVICES_INFO["prometheus"]="http://localhost:9090"
SERVICES_INFO["grafana"]="http://localhost:3000"
SERVICES_INFO["portainer"]="http://localhost:9000"
SERVICES_INFO["pgadmin"]="http://localhost:5050"
SERVICES_INFO["filebrowser"]="http://localhost:8082"
SERVICES_INFO["keycloak"]="http://localhost:8084"
SERVICES_INFO["vault"]="http://localhost:8200"
SERVICES_INFO["mailhog"]="http://localhost:8025"
SERVICES_INFO["minio"]="http://localhost:9001"
SERVICES_INFO["rabbitmq"]="http://localhost:15672"
SERVICES_INFO["kafka"]="http://localhost:9092"
SERVICES_INFO["zookeeper"]="http://localhost:2181"
SERVICES_INFO["sftp"]="http://localhost:2222"
SERVICES_INFO["redis"]="http://localhost:6379"
SERVICES_INFO["postgres"]="http://localhost:5432"

echo -e "\n${BOLD}${CYAN}📊 InfraLite Health Check Dashboard${RESET}"
echo -e "${CYAN}============================================${RESET}"

# Step 1: Capture Docker container status
container_output=$(docker ps --format "{{.Names}} {{.Status}} {{.Ports}}")

# Step 2: Read into an array
IFS=$'\n' read -d '' -r -a containers <<< "$container_output"

# Step 3: Process each container
for line in "${containers[@]}"; do
    read -r name status ports <<< "$line"

    # Extract service name without the project prefix
    service_name=${name#*helix-lite-alpha-}

    echo -e "\n${BLUE}✨ Checking: ${BOLD}${service_name^}${RESET}"
    echo "  ${MAGENTA}Status:${RESET} $status"

    url=${SERVICES_INFO["${service_name}"]:-""}
    desc="No description available."

    # Check for a valid service description
    if [[ -n "$url" ]]; then
        desc="${SERVICES_INFO["${service_name}"]}_desc"
    fi

    echo -e "  ${MAGENTA}Description:${RESET} $desc"

    # Health check
    if [[ -n "$url" ]]; then
        echo -e "  ${MAGENTA}URL:${RESET} ${BOLD}${url}${RESET}"
        echo -e "  ${CYAN}Testing connectivity...${RESET}"
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -qE "200|302|401|403|503"; then
            echo -e "  ${GREEN}✅ Healthy: Responding with a valid HTTP status code.${RESET}"
        else
            echo -e "  ${RED}❌ Unhealthy: Not responding at ${url}${RESET}"
        fi
    else
        echo "  ${MAGENTA}URLs:${RESET} Not a web UI service or URL not defined."
    fi
done

echo -e "${BOLD}${CYAN}✅ Health check complete.${RESET}"
echo -e "${CYAN}============================================${RESET}\n"