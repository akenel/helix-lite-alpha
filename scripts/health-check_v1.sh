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
SERVICES_INFO["n8n_desc"]="Workflow Automation: Your visual workflow tool."

SERVICES_INFO["prometheus"]="http://localhost:9090"
SERVICES_INFO["prometheus_desc"]="Monitoring System: Collects metrics from services."

SERVICES_INFO["grafana"]="http://localhost:3000"
SERVICES_INFO["grafana_desc"]="Analytics & Dashboards: Visualizes your monitoring data."

SERVICES_INFO["portainer"]="http://localhost:9000"
SERVICES_INFO["portainer_desc"]="Docker Management UI: A web interface to manage your containers."

SERVICES_INFO["pgadmin"]="http://localhost:5050"
SERVICES_INFO["pgadmin_desc"]="PostgreSQL Admin UI: Web-based tool to manage your database."

SERVICES_INFO["filebrowser"]="http://localhost:8082"
SERVICES_INFO["filebrowser_desc"]="File Manager: A simple web UI for your local files."

SERVICES_INFO["keycloak"]="http://localhost:8084"
SERVICES_INFO["keycloak_desc"]="Identity & Access Management: Centralized authentication server."

SERVICES_INFO["vault"]="http://localhost:8200"
SERVICES_INFO["vault_desc"]="Secrets Management: Securely stores and manages sensitive data."

SERVICES_INFO["mailhog"]="http://localhost:8025"
SERVICES_INFO["mailhog_desc"]="Email Testing: Catches all outgoing emails for local testing."

SERVICES_INFO["minio"]="http://localhost:9001"
SERVICES_INFO["minio_desc"]="S3 Object Storage: A local-running S3-compatible service."

SERVICES_INFO["rabbitmq"]="http://localhost:15672"
SERVICES_INFO["rabbitmq_desc"]="Message Broker Admin: RabbitMQ's management dashboard."

SERVICES_INFO["traefik"]="http://localhost:8080"
SERVICES_INFO["traefik_desc"]="Reverse Proxy & Dashboard: Manages routing for other services."

SERVICES_INFO["kafka_desc"]="Message Queue: For high-throughput, distributed messaging."
SERVICES_INFO["zookeeper_desc"]="Distributed Coordination: Required by Kafka."
SERVICES_INFO["sftp_desc"]="Secure File Transfer: Local SFTP server."
SERVICES_INFO["redis_desc"]="In-memory Data Store: Used for caching and session management."
SERVICES_INFO["postgres_desc"]="Database: Your primary PostgreSQL database."

echo -e "\n${BOLD}${CYAN}📊 InfraLite Health Check Dashboard${RESET}"
echo -e "${CYAN}============================================${RESET}"

# Capture the output of docker-compose ps into an array
IFS=$'\n' read -d '' -r -a containers <<<"$(docker ps --format "{{.Names}} {{.Status}} {{.Ports}}")"
# Loop through the array
for line in "${containers[@]}"; do
    read -r name status ports <<<"$line"

    # Extract service name without the project prefix
    service_name=${name#*helix-lite-alpha-}

    echo -e "\n${BLUE}✨ Checking: ${BOLD}${service_name^}${RESET}"
    echo "  ${MAGENTA}Status:${RESET} $status"

    url=""
    tip=""
    desc=""

    # Get info from the associative array
    desc=${SERVICES_INFO["${service_name}_desc"]:-"No description available."}
    url=${SERVICES_INFO["${service_name}"]:-""}

    echo -e "  ${MAGENTA}Description:${RESET} $desc"

    # Specific checks and tips
    case "$service_name" in
        "n8n")
            tip="Use this URL to access the n8n UI and create your workflows."
            ;;
        "prometheus")
            tip="Use this to see your metrics. For now, it might be empty."
            ;;
        "grafana")
            tip="Login with admin/admin (or as configured) to build dashboards."
            ;;
        "portainer")
            tip="First-time setup required. Create an admin user to access the UI."
            ;;
        "pgadmin")
            tip="Connect to your Postgres DB with the host 'postgres'."
            ;;
        "filebrowser")
            tip="Use this to browse files in the mounted volumes."
            ;;
        "keycloak")
            tip="Use this to configure users, roles, and clients for authentication."
            ;;
        "vault")
            url_check="http://localhost:8200/v1/sys/health"
            tip="The UI is at http://localhost:8200. Check health at: $url_check"
            ;;
        "mailhog")
            tip="This UI shows emails sent from within your Docker network."
            ;;
        "minio")
            tip="Access the UI to manage your S3 buckets and files. Access keys are in your docker-compose file."
            ;;
        "rabbitmq")
            tip="Monitor queues and messages here. The default user is 'guest'."
            ;;
        "traefik")
            tip="This dashboard shows the services Traefik has discovered and is routing traffic to."
            url_check="http://localhost:8080/dashboard/"
            ;;
        *)
            # No specific tips for these, but we can display the URLs if they exist.
            if [[ -z "$url" ]]; then
                echo "  ${MAGENTA}URLs:${RESET} Not a web UI service or URL not defined."
            fi
            ;;
    esac

    # Display URL and perform health check if a URL exists
    if [[ -n "$url" ]]; then
        echo -e "  ${MAGENTA}URL:${RESET} ${BOLD}${url}${RESET}"
        echo -e "  ${CYAN}Testing connectivity...${RESET}"
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -qE "200|302|401|403|503"; then
            echo -e "  ${GREEN}✅ Healthy: Responding with a valid HTTP status code.${RESET}"
        else
            echo -e "  ${RED}❌ Unhealthy: Not responding at ${url}${RESET}"
        fi
        if [[ -n "$tip" ]]; then
            echo -e "  ${YELLOW}💡 Tip:${RESET} $tip"
        fi
    fi
    echo "" # Add a newline for spacing
done

echo -e "${BOLD}${CYAN}✅ Health check complete.${RESET}"
echo -e "${CYAN}============================================${RESET}\n"