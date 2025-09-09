#!/bin/bash

# 🏔️ Helix Hub Service Discovery & Access Guide - Wilhelm Tell Edition
# Dynamic service discovery based on running containers
# Author: Angel (Master of 41 Years Tunnel Engineering) & GitHub Copilot

set -e

# Colors for Swiss quality output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Service configuration - maps generic service names to service info
declare -A SERVICE_INFO=(
    # Key format: service_name (e.g., 'traefik', 'postgres')
    # Value format: display_name|description|direct_port|https_host|tips
    ["traefik"]="Traefik Reverse Proxy|Load balancer and SSL termination|8080|traefik.helix.local|Check dashboard for routing rules and SSL certs"
    ["kafka"]="Kafka|Distributed streaming platform|9092||Check container logs for more info"
    ["kong"]="Kong|API Gateway|8000-8001|kong.helix.local|Check container logs for more info"
    ["prometheus"]="Prometheus|Monitoring system and time series database|9090|prometheus.helix.local|View metrics and create dashboards"
    ["moodle"]="Moodle|Learning management system|9002|moodle.helix.local|Log in as admin / password"
    ["n8n"]="n8n Workflow Engine|Automation and workflow orchestration|5678|n8n.helix.local|Create workflows for file processing automation"
    ["pgadmin"]="pgAdmin|PostgreSQL database management web UI|5050|pgadmin.helix.local|Connect to the Postgres service"
    ["adminer"]="Adminer|Database management in a single PHP file|8083|adminer.helix.local|Connect to any database easily"
    ["keycloak"]="Keycloak Auth Engine|Identity and access management|8084|keycloak.helix.local|Admin Console: /admin/master/console/"
    ["zookeeper"]="Zookeeper|Centralized service for distributed systems|2181||Required for Kafka"
    ["sftp-demo"]="SFTP Demo Service|Secure file transfer for bank files|2222||Test: sftp bank@localhost -P 2222 (password: bankpassword)"
    ["grafana"]="Grafana|Open-source analytics and visualization web application|3000|grafana.helix.local|Visualize Prometheus metrics"
    ["minecraft"]="Minecraft|Minecraft Server|25565||Connect with your Minecraft client"
    ["redis"]="Redis|In-memory data structure store|6379||Used for caching and sessions"
    ["postgres"]="PostgreSQL Database|Primary database for banking data|5432||Connect: docker exec -it infra-lite-postgres-1 psql -U helix"
    ["filebrowser"]="FileBrowser Web UI|Web-based file manager for uploads|8082|files.helix.local|Browse and manage uploaded banking files"
    ["portainer"]="Portainer|Docker management GUI|9000|portainer.helix.local|Manage your Docker containers and services"
    ["minio"]="Minio|High performance S3-compatible object storage|9001|minio.helix.local|Used for file storage"
    ["mailhog"]="Mailhog|Testing mail server|8025|mailhog.helix.local|View sent emails in a web UI"
    ["medusa"]="Medusa|Movie and TV show manager|8081|medusa.helix.local|Organize your media library"
    ["rabbitmq"]="RabbitMQ|Message broker|5672||Connect applications with message queues"
    ["vault"]="HashiCorp Vault|Secret management and encryption|8200|vault.helix.local|Store API keys and certificates securely"
    # Placeholder for a hypothetical service that might be created later
    ["helix-core"]="Helix Core Banking|Main banking application with file processing|5000|helix.local|Upload MT940/BAI2/CSV files for processing"
    ["ollama"]="Ollama AI Service|Local AI/LLM inference engine|11434|ollama.helix.local|Try: curl /api/generate with model llama3.2"
)


# Default credentials for services
declare -A SERVICE_CREDS=(
    ["filebrowser"]="admin / admin"
    ["keycloak"]="admin / admin123"
    ["vault"]="Root Token: myroot"
    ["n8n"]="admin / admin"
    ["postgres"]="helix / helixpass"
    ["sftp-demo"]="bank / bankpassword"
    ["portainer"]="admin / password (first login)"
)

# Health check commands for each service
declare -A HEALTH_CHECKS=(
    ["traefik"]="curl -s http://localhost:8080/api/version"
    ["helix-core"]="curl -s http://localhost:5000/health || curl -s http://localhost:5000/"
    ["ollama"]="curl -s http://localhost:11434/api/tags"
    ["postgres"]="docker exec \$(docker ps -q --filter name=postgres) pg_isready -U helix"
    ["vault"]="curl -s http://localhost:8200/v1/sys/health"
    ["keycloak"]="curl -s http://localhost:8084/"
    ["n8n"]="curl -s http://localhost:5678/"
    ["filebrowser"]="curl -s http://localhost:8082/"
    ["sftp-demo"]="nc -z localhost 2222"
    ["prometheus"]="curl -s http://localhost:9090/"
    ["kong"]="curl  http://localhost:8001/"
    ["moodle"]="curl -s http://localhost:9002/"
    ["pgadmin"]="curl -s http://localhost:5050/"
    ["adminer"]="curl -s http://localhost:8083/"
    ["minio"]="curl -s http://localhost:9001/minio/login"
    ["grafana"]="curl -s http://localhost:3000/"
    ["redis"]="docker exec \$(docker ps -q --filter name=redis) redis-cli ping"
    ["rabbitmq"]="nc -z localhost 5672"
    ["mailhog"]="curl -s http://localhost:8025/"
    ["medusa"]="curl -s http://localhost:8081/"
    ["kafka"]="nc -z localhost 9092"
    ["zookeeper"]="nc -z localhost 2181"
    ["minecraft"]="nc -z localhost 25565"
    ["portainer"]="curl -s http://localhost:9000/api/status"
)

# Function definitions remain the same, but with the corrected logic
print_header() {
    echo -e "${PURPLE}🏔️========================================🏔️${NC}"
    echo -e "${PURPLE}    HELIX HUB DYNAMIC SERVICE DIRECTORY${NC}"
    echo -e "${PURPLE}🏔️========================================🏔️${NC}"
    echo
    echo -e "${BLUE}🕐 Discovered at: $(date)${NC}"
    echo
}

get_container_status() {
    local container=$1
    local status=$(docker ps -a --filter "name=$container" --format "{{.Status}}" 2>/dev/null)
    if [[ $status =~ ^Up ]]; then
        echo -e "${GREEN}🟢 Running${NC}"
    elif [[ $status =~ ^Exited ]]; then
        echo -e "${RED}🔴 Stopped${NC}"
    else
        echo -e "${YELLOW}🟡 Unknown${NC}"
    fi
}

get_container_ports() {
    local container=$1
    docker ps --filter "name=$container" --format "{{.Ports}}" 2>/dev/null | sed 's/0.0.0.0://g' | sed 's/, /\n  /g' | head -3
}

get_container_uptime() {
    local container=$1
    docker ps --filter "name=$container" --format "{{.Status}}" 2>/dev/null | sed 's/Up //' | sed 's/ ago//'
}

run_health_check() {
    local container_name=$1
    # Get the generic service name from the container name
    local service_name=$(echo "$container_name" | sed 's/infra-lite-//' | sed 's/-1$//')
    
    local cmd="${HEALTH_CHECKS[$service_name]}"
    
    if [ -z "$cmd" ]; then
        echo -e "${YELLOW}⚠️  No health check defined${NC}"
        return
    fi
    
    # Run the health check, replacing the container name if necessary
    if echo "$cmd" | grep -q '\$'; then
        # If the command uses a variable, evaluate it directly
        eval "$cmd" >/dev/null 2>&1
    else
        # Otherwise, assume it's a simple curl check and try it
        eval "$cmd" >/dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Healthy${NC}"
    else
        echo -e "${RED}❌ Unhealthy${NC}"
    fi
}

format_service_info() {
    local container_name=$1
    local service_name=$(echo "$container_name" | sed 's/infra-lite-//' | sed 's/-1$//')
    local info="${SERVICE_INFO[$service_name]}"
    
    if [ -z "$info" ]; then
        # If no predefined info, extract from container name and image
        local image=$(docker ps -a --filter "name=$container_name" --format "{{.Image}}" 2>/dev/null)
        local display_name=$(echo "$service_name" | tr '-' ' ' | sed 's/\b\w/\U&/g')
        echo "$display_name|Unknown service|Unknown|Unknown|Check container logs for more info"
        return
    fi
    
    echo "$info"
}

print_service_table() {
    echo -e "${YELLOW}📋 DISCOVERED SERVICES${NC}"
    echo "=============================================="

    # Get all containers with the "infra-lite-" prefix
    local containers=$(docker ps -a --filter "name=infra-lite-" --format "{{.Names}}" | sort)

    if [ -z "$containers" ]; then
        echo -e "${RED}❌ No Infra Lite containers found${NC}"
        return
    fi
    
    for container in $containers; do
        local service_name=$(echo "$container" | sed 's/infra-lite-//' | sed 's/-1$//')
        local info=$(format_service_info "$container")
        IFS='|' read -r display_name description direct_port https_host tips <<< "$info"

        echo -e "${CYAN}🔧 $display_name${NC}"
        echo -e "   ${BOLD}Status:${NC} $(get_container_status "$container")"
        echo -e "   ${BOLD}Health:${NC} $(run_health_check "$container")"
        echo -e "   ${BOLD}Uptime:${NC} $(get_container_uptime "$container")"
        echo -e "   ${BOLD}Description:${NC} $description"

        # Show URLs
        if [ "$direct_port" != "" ] && [ "$direct_port" != "Unknown" ]; then
            echo -e "   ${BOLD}Direct URL:${NC} ${BLUE}http://localhost:$direct_port${NC}"
        fi

        if [ "$https_host" != "" ] && [ "$https_host" != "Unknown" ]; then
            echo -e "   ${BOLD}HTTPS URL:${NC} ${GREEN}https://$https_host:8443${NC}"
        fi

        # Show public DO URL for Moodle and other known services
        if [[ "$service_name" == "moodle" ]]; then
            echo -e "   🌍 ${BOLD}Public HTTP:${NC} ${YELLOW}http://206.189.30.236:8083/${NC} 🐣 Click to test Moodle!"
            echo -e "   🔒 ${BOLD}Public HTTPS:${NC} ${GREEN}https://206.189.30.236:8443/${NC} 🛡️ Secure access (if enabled)"
        fi
        # Add more public URLs for other services as needed

        # Show credentials if available
        local creds="${SERVICE_CREDS[$service_name]}"
        if [ -n "$creds" ]; then
            echo -e "   ${BOLD}Credentials:${NC} ${YELLOW}$creds${NC}"
        fi

        # Show port mappings
        local ports=$(get_container_ports "$container")
        if [ -n "$ports" ]; then
            echo -e "   ${BOLD}Port Mappings:${NC}"
            echo "   $ports" | sed 's/^/     /'
        fi

        # Show tips
        if [ "$tips" != "" ]; then
            echo -e "   ${BOLD}Tips:${NC} $tips"
        fi

        echo
    done
}

print_quick_access() {
    echo -e "${YELLOW}🚀 QUICK ACCESS COMMANDS${NC}"
    echo "=============================================="
    
    echo -e "${BOLD}Health Check All Services:${NC}"
    echo "  ./scripts/helix-health-check.sh"
    echo
    
    echo -e "${BOLD}Restart All Services:${NC}"
    echo "  docker compose restart"
    echo
    
    echo -e "${BOLD}View Logs (replace <service>):${NC}"
    echo "  docker logs infra-lite-<service>-1 --tail 50"
    echo
    
    echo -e "${BOLD}Container Management:${NC}"
    echo "  docker ps -a                          # List all containers"
    echo "  docker stats --no-stream              # Resource usage"
    echo "  docker compose down && docker compose up -d  # Full restart"
    echo
    
    echo -e "${BOLD}Database Access:${NC}"
    echo "  docker exec -it infra-lite-postgres-1 psql -U helix"
    echo "  docker exec -it infra-lite-postgres-1 psql -U helix -d keycloak_db"
    echo
    
    echo -e "${BOLD}Keycloak Management:${NC}"
    echo "  ./scripts/keycloak-manager.sh          # Interactive management"
    echo "  ./scripts/keycloak-manager.sh list-users"
    echo
}

print_network_info() {
    echo -e "${YELLOW}🌐 NETWORK INFORMATION${NC}"
    echo "=============================================="
    
    echo -e "${BOLD}Docker Network:${NC} helix-hub_helix-net"
    echo -e "${BOLD}Network Driver:${NC} bridge"
    echo
    
    echo -e "${BOLD}Internal Service Communication:${NC}"
    local containers=$(docker ps --filter "name=infra-lite-" --format "{{.Names}}" | sort)
    for container in $containers; do
        local ip=$(docker inspect "$container" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
        local service_name=$(echo "$container" | sed 's/infra-lite-//' | sed 's/-1$//')
        if [ -n "$ip" ]; then
            echo "  $service_name: $ip"
        fi
    done
    echo
    
    echo -e "${BOLD}/etc/hosts entries (for HTTPS access):${NC}"
    grep "helix.local" /etc/hosts 2>/dev/null || echo "  No helix.local entries found in /etc/hosts"
    echo
}

print_troubleshooting() {
    echo -e "${YELLOW}🔧 TROUBLESHOOTING GUIDE${NC}"
    echo "=============================================="
    
    echo -e "${BOLD}Service Not Responding:${NC}"
    echo "  1. Check container status: docker ps -a | grep infra-lite-"
    echo "  2. Check logs: docker logs infra-lite-<service>-1 --tail 50"
    echo "  3. Restart service: docker restart infra-lite-<service>-1"
    echo
    
    echo -e "${BOLD}HTTPS Not Working:${NC}"
    echo "  1. Check /etc/hosts: grep helix.local /etc/hosts"
    echo "  2. Check Traefik: curl -k https://traefik.helix.local:8443"
    echo "  3. Check certificates: ls -la traefik/certs/"
    echo
    
    echo -e "${BOLD}Database Issues:${NC}"
    echo "  1. Check DB status: docker exec infra-lite-postgres-1 pg_isready -U helix"
    echo "  2. List databases: docker exec -it infra-lite-postgres-1 psql -U helix -c '\\l'"
    echo "  3. Check connections: docker logs infra-lite-postgres-1 --tail 20"
    echo
    
    echo -e "${BOLD}Performance Issues:${NC}"
    echo "  1. Check resources: docker stats --no-stream"
    "  2. Check disk space: df -h && docker system df"
    "  3. Clean up: docker system prune -f"
    echo
}

show_menu() {
    echo -e "${CYAN}🎯 SERVICE DISCOVERY OPTIONS:${NC}"
    echo "1. Show all services (default)"
    echo "2. Show quick access commands"
    echo "3. Show network information"
    echo "4. Show troubleshooting guide"
    echo "5. Run health checks"
    echo "6. Show container resources"
    echo "7. Export service info to file"
    echo "8. Watch mode (refresh every 5s)"
    echo "9. Exit"
    echo
}

show_resources() {
    echo -e "${YELLOW}💾 CONTAINER RESOURCES${NC}"
    echo "=============================================="
    
    echo -e "${BOLD}Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | grep infra-lite || echo "No infra-lite containers found"
    echo
    
    echo -e "${BOLD}System Resources:${NC}"
    echo "  Disk Usage: $(docker system df | grep -E '^Images|^Containers|^Local Volumes' | awk '{print $1": "$2}')"
    echo
}

export_info() {
    local output_file="infra-lite-services-$(date +%Y%m%d-%H%M%S).txt"
    
    echo "Exporting service information to $output_file..."
    
    {
        echo "INFRA LITE SERVICE DIRECTORY"
        echo "Generated: $(date)"
        echo "=================================="
        echo
        
        # Export service table in plain text
        print_service_table | sed 's/\x1b\[[0-9;]*m//g'  # Remove color codes
        print_quick_access | sed 's/\x1b\[[0-9;]*m//g'
        print_network_info | sed 's/\x1b\[[0-9;]*m//g'
        
    } > "$output_file"
    
    echo -e "${GREEN}✅ Service information exported to: $output_file${NC}"
    echo
}

watch_mode() {
    echo -e "${CYAN}🔄 Watch mode - refreshing every 5 seconds (Ctrl+C to exit)${NC}"
    echo
    
    while true; do
        clear
        print_header
        print_service_table
        echo -e "${BLUE}🔄 Refreshing in 5 seconds... (Ctrl+C to exit)${NC}"
        sleep 5
    done
}

# Interactive mode
interactive_mode() {
    while true; do
        print_header
        show_menu
        read -p "🏔️ Choose an option (1-9): " choice
        echo
        
        case $choice in
            1) print_service_table ;;
            2) print_quick_access ;;
            3) print_network_info ;;
            4) print_troubleshooting ;;
            5) ./scripts/helix-health-check.sh ;;
            6) show_resources ;;
            7) export_info ;;
            8) watch_mode ;;
            9)
                echo -e "${GREEN}🏔️ Exiting Service Discovery. Stay Swiss! 🇨🇭${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option. Please choose 1-9.${NC}"
                echo
                ;;
        esac
        
        if [ "$choice" != "8" ]; then
            read -p "Press Enter to continue..."
            clear
        fi
    done
}

# Command line usage
usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  services        - Show all discovered services (default)"
    echo "  quick          - Show quick access commands"
    echo "  network        - Show network information"
    echo "  troubleshoot   - Show troubleshooting guide"
    echo "  health         - Run health checks"
    echo "  resources      - Show container resources"
    echo "  export         - Export service info to file"
    echo "  watch          - Watch mode (refresh every 5s)"
    echo "  interactive    - Interactive mode"
    echo
    echo "Examples:"
    echo "  $0                    # Show all services"
    echo "  $0 services           # Show all services"
    echo "  $0 quick              # Show quick commands"
    echo "  $0 watch              # Watch mode"
}

# Parse command line arguments
case "${1:-services}" in
    services) 
        print_header
        print_service_table
        ;;
    quick) 
        print_header
        print_quick_access
        ;;
    network) 
        print_header
        print_network_info
        ;;
    troubleshoot) 
        print_header
        print_troubleshooting
        ;;
    health) 
        print_header
        ./scripts/helix-health-check.sh
        ;;
    resources) 
        print_header
        show_resources
        ;;
    export) 
        print_header
        export_info
        ;;
    watch) 
        watch_mode
        ;;
    interactive) 
        interactive_mode
        ;;
    help|--help|-h) 
        usage
        ;;
    *) 
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo
        usage
        exit 1
        ;;
esac