#!/usr/bin/env bash

# ====================================================================
# 🌟 HELIX HUB - Enhanced Setup Script with TUI Interface
# ====================================================================
# Author: Enhanced for Helix Hub Infrastructure
# Version: 2.0.0
# Description: Interactive setup and management for Helix Hub services
# ====================================================================

set -euo pipefail

# ====================================================================
# 🎨 CONFIGURATION & GLOBALS
# ====================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="helix-hub"
COMPOSE_FILE="docker-compose.yml"
LOG_FILE="setup.log"
CONFIG_FILE=".helix-config"

# Color codes for beautiful output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# TUI Configuration
DIALOG_HEIGHT=20
DIALOG_WIDTH=70
DIALOG_LIST_HEIGHT=12

# Available profiles with descriptions
declare -A PROFILES=(
    ["core"]="Essential services (n8n, postgres, filebrowser)"
    ["lms"]="Learning Management System (Moodle + deps)"
    ["integration"]="Integration tools and APIs"
    ["ai"]="AI Assistant services (Ollama + tools)"
    ["ecommerce"]="E-commerce stack (Medusa + deps)"
    ["minecraft"]="Minecraft game server"
    ["analytics"]="Analytics tools (Matomo + Grafana)"
)

# Service port mappings for status checks
declare -A SERVICE_PORTS=(
    ["n8n"]="5678"
    ["filebrowser"]="8082"
    ["postgres"]="5432"
    ["traefik"]="8080"
    ["moodle"]="8081"
    ["grafana"]="3000"
    ["prometheus"]="9090"
    ["ollama"]="11434"
    ["matomo"]="8083"
    ["medusa"]="9000"
    ["minecraft"]="25565"
    ["vault"]="8200"
    ["redis"]="6379"
    ["mailhog"]="8025"
    ["portainer"]="9443"
    ["kong"]="8000"
    ["demo-ui"]="3000"
)

# ====================================================================
# 🛠️ UTILITY FUNCTIONS
# ====================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

print_banner() {
    if [[ -f "banner.asc" ]]; then
        cat banner.asc
    else
        echo -e "${CYAN}"
        echo "╔═══════════════════════════════════════════════════════════════════╗"
        echo "║                        🌟 HELIX HUB 🌟                           ║"
        echo "║              Enhanced Infrastructure Management                    ║"
        echo "║                     Version 2.0.0                               ║"
        echo "╚═══════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi
}

check_dependencies() {
    local deps=("docker" "docker-compose" "whiptail")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        whiptail --title "❌ Missing Dependencies" \
            --msgbox "The following dependencies are missing:\n\n${missing[*]}\n\nPlease install them and try again." \
            12 50
        exit 1
    fi
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Helix Hub Configuration
LAST_PROFILE="${LAST_PROFILE:-core}"
DEFAULT_DOMAIN="${DEFAULT_DOMAIN:-localhost}"
ENABLE_SSL="${ENABLE_SSL:-false}"
ENABLE_AUTH="${ENABLE_AUTH:-false}"
EOF
}

# ====================================================================
# 🏗️ INFRASTRUCTURE SETUP FUNCTIONS
# ====================================================================

# This function creates the necessary directories and files.
create_directory_structure() {
    local base_dir="$1"
    
    # Existing logic
    mkdir -p "$base_dir"
    cd "$base_dir" || exit 1
    
    # New logic to ensure necessary files are created
    # This directly addresses the error you're seeing.
    log "INFO" "Creating necessary directories and files..."
    
    mkdir -p "./n8n"
    if [[ ! -f "./n8n/config.json" ]]; then
        log "INFO" "Creating default n8n config file."
        # Provide a basic valid JSON config.
        echo "{}" > "./n8n/config.json"
    fi
    
    mkdir -p "./postgres"
    if [[ ! -f "./postgres/init.sql" ]]; then
        log "INFO" "Creating default postgres init file."
        echo "CREATE DATABASE IF NOT EXISTS moodle_db;" > "./postgres/init.sql"
    fi

    # Add other directories as needed, e.g., for prometheus, grafana, etc.
    mkdir -p "./prometheus"
    mkdir -p "./grafana"
    mkdir -p "./sftp/demo" # Ensure this path also exists
    
    log "INFO" "Directory structure created successfully."
}

# create_profile_files() {
#     for profile in "${!PROFILES[@]}"; do
#         if [[ ! -f "profiles/${profile}.yml" ]]; then
#             create_profile_config "$profile"
#         fi
#     done
# }

# Corrected and Sensible docker-compose.yml

# ====================================================================
# 🗂️ FILE & DIRECTORY MANAGEMENT
# ====================================================================

# This function will now copy the file instead of generating it.
create_base_compose_file() {
    local source_compose_file="$(dirname "$0")/docker-compose-template.yml"
    local target_compose_file="$COMPOSE_FILE"

    log "INFO" "Ensuring Docker Compose file exists..."

    if [[ ! -f "$source_compose_file" ]]; then
        log "ERROR" "Template file not found: $source_compose_file"
        whiptail --title "🚨 Error" --msgbox "The required 'docker-compose-template.yml' file could not be found. Aborting." 10 60
        exit 1
    fi

    if [[ ! -f "$target_compose_file" ]]; then
        cp "$source_compose_file" "$target_compose_file"
        if [[ $? -eq 0 ]]; then
            log "INFO" "Copied '$source_compose_file' to '$target_compose_file'"
        else
            log "ERROR" "Failed to copy Docker Compose file."
            whiptail --title "🚨 Error" --msgbox "Failed to copy the Docker Compose template file. Check permissions." 10 60
            exit 1
        fi
    fi
}

# The create_profile_config() function is now obsolete and should be deleted.
# The user-facing setup.sh script should present these profiles as menu options.

create_profile_config() {
    local profile="$1"
    
    case "$profile" in
        "core")
            cat > "profiles/core.yml" << 'EOF'
# Core Profile - Essential Services
# Services: postgres, n8n, filebrowser, sftp-demo
version: '3.8'
EOF
            ;;
        "lms")
            cat > "profiles/lms.yml" << 'EOF'
# LMS Profile - Learning Management System
# Services: moodle, postgres, redis
version: '3.8'

services:
  moodle:
    profiles: ["lms"]
    image: moodle:latest
    ports:
      - "8081:80"
    environment:
      MOODLE_DATABASE_TYPE: pgsql
      MOODLE_DATABASE_HOST: postgres
      MOODLE_DATABASE_NAME: moodle_db
      MOODLE_DATABASE_USER: helix_user
      MOODLE_DATABASE_PASSWORD: helix_pass
    volumes:
      - ./moodle/moodledata:/var/moodledata
    networks:
      - helix-net
    depends_on:
      - postgres
EOF
            ;;
        "ai")
            cat > "profiles/ai.yml" << 'EOF'
# AI Profile - AI Assistant Services
# Services: ollama, open-webui
version: '3.8'

services:
  ollama:
    profiles: ["ai"]
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - helix-net
    environment:
      OLLAMA_HOST: 0.0.0.0

volumes:
  ollama_data:
EOF
            ;;
        *)
            echo "# $profile Profile Configuration" > "profiles/${profile}.yml"
            ;;
    esac
}

# ====================================================================
# 🎛️ PROFILE MANAGEMENT FUNCTIONS
# ====================================================================

show_profile_menu() {
    local menu_options=()
    local profile_list=""
    
    for profile in "${!PROFILES[@]}"; do
        menu_options+=("$profile" "${PROFILES[$profile]}")
        profile_list+="$profile "
    done
    
    local selected_profile
    selected_profile=$(whiptail --title "🎛️ Profile Management" \
        --menu "Select a profile to manage:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH $DIALOG_LIST_HEIGHT \
        "${menu_options[@]}" \
        "back" "← Return to main menu" \
        3>&1 1>&2 2>&3)
    
    case $selected_profile in
        "back"|"") return ;;
        *) profile_action_menu "$selected_profile" ;;
    esac
}

profile_action_menu() {
    local profile="$1"
    local action
    
    action=$(whiptail --title "🎛️ Profile: $profile" \
        --menu "Choose an action for profile '$profile':" \
        $DIALOG_HEIGHT $DIALOG_WIDTH $DIALOG_LIST_HEIGHT \
        "deploy" "🚀 Deploy profile" \
        "stop" "⏹️  Stop profile" \
        "restart" "🔄 Restart profile" \
        "status" "📊 Check status" \
        "logs" "📝 View logs" \
        "config" "⚙️  Configure services" \
        "back" "← Back to profile list" \
        3>&1 1>&2 2>&3)
    
    case $action in
        "deploy") deploy_profile "$profile" ;;
        "stop") stop_profile "$profile" ;;
        "restart") restart_profile "$profile" ;;
        "status") show_profile_status "$profile" ;;
        "logs") show_profile_logs "$profile" ;;
        "config") configure_profile "$profile" ;;
        "back"|"") show_profile_menu ;;
    esac
}

deploy_profile() {
    local profile="$1"
    
    if whiptail --title "🚀 Deploy Profile" \
        --yesno "Deploy profile '$profile'?\n\nThis will start all services in the profile.\n\nContinue?" \
        12 50; then
        
        {
            echo "10"
            echo "# Stopping existing services..."
            docker-compose down >/dev/null 2>&1 || true
            
            echo "30"
            echo "# Deploying profile: $profile"
            docker-compose -f "$COMPOSE_FILE" -f "profiles/$profile.yml" up -d --profile "$profile"

            echo "70"
            echo "# Waiting for services to start..."
            sleep 5
            
            echo "90"
            echo "# Checking service health..."
            sleep 2
            
            echo "100"
            echo "# Deployment complete!"
        } | whiptail --title "🚀 Deploying Profile: $profile" --gauge "Initializing..." 8 70 0
        
        LAST_PROFILE="$profile"
        save_config
        
        whiptail --title "✅ Deployment Complete" \
            --msgbox "Profile '$profile' has been deployed successfully!\n\nServices are starting up. Check the status menu for details." \
            10 50
        
        log "INFO" "Profile $profile deployed successfully"
    fi
}

stop_profile() {
    local profile="$1"
    
    if whiptail --title "⏹️ Stop Profile" \
        --yesno "Stop profile '$profile'?\n\nThis will stop all running services.\n\nContinue?" \
        10 50; then
        
        {
            echo "30"
            echo "# Stopping services..."
            docker-compose --profile "$profile" down
            
            echo "70"
            echo "# Cleaning up..."
            sleep 1
            
            echo "100"
            echo "# Stop complete!"
        } | whiptail --title "⏹️ Stopping Profile: $profile" --gauge "Stopping services..." 8 70 0
        
        whiptail --title "✅ Stop Complete" \
            --msgbox "Profile '$profile' has been stopped successfully!" \
            8 50
        
        log "INFO" "Profile $profile stopped"
    fi
}

restart_profile() {
    local profile="$1"
    
    if whiptail --title "🔄 Restart Profile" \
        --yesno "Restart profile '$profile'?\n\nThis will stop and start all services.\n\nContinue?" \
        10 50; then
        
        {
            echo "20"
            echo "# Stopping services..."
            docker-compose --profile "$profile" down
            
            echo "50"
            echo "# Starting services..."
            docker-compose --profile "$profile" up -d
            
            echo "80"
            echo "# Waiting for startup..."
            sleep 3
            
            echo "100"
            echo "# Restart complete!"
        } | whiptail --title "🔄 Restarting Profile: $profile" --gauge "Restarting services..." 8 70 0
        
        whiptail --title "✅ Restart Complete" \
            --msgbox "Profile '$profile' has been restarted successfully!" \
            8 50
        
        log "INFO" "Profile $profile restarted"
    fi
}

# ====================================================================
# 📊 STATUS MONITORING FUNCTIONS
# ====================================================================

show_status_dashboard() {
    local status_info=""
    local running_services=()
    
    echo "🌟 Checking for running services..."
    
    # Get running containers
    mapfile -t running_services < <(docker-compose ps --services --filter "status=running" 2>/dev/null)

    # Filter out any empty entries that may have been created by mapfile
    local filtered_services=()
    for s in "${running_services[@]}"; do
        if [[ -n "$s" ]]; then
            filtered_services+=("$s")
        fi
    done
    running_services=("${filtered_services[@]}")

    echo "🌟 Found running services: ${running_services[*]}"
    
    status_info="🌟 HELIX HUB STATUS DASHBOARD\n"
    status_info+="================================\n\n"
    
    # Now, the logic works as you intended, because the array is truly empty
    if [[ ${#running_services[@]} -eq 0 ]]; then
        status_info+="❌ No services currently running\n"
    else
        status_info+="✅ Running Services (${#running_services[@]}):\n\n"
        
        for service in "${running_services[@]}"; do
            echo "Checking service: $service" # Debug
            local port="${SERVICE_PORTS[$service]:-N/A}"
            local health_status
            
            # Check if service is responding
            if [[ "$port" != "N/A" ]] && check_service_health "localhost" "$port"; then
                health_status="✅ Healthy"
            else
                health_status="⚠️️ Starting"
            fi
            
            status_info+="  • $service (port: $port) - $health_status\n"
        done
        
        status_info+="\n📊 Resource Usage:\n"
        status_info+="$(docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>/dev/null | head -6 || echo 'Stats unavailable')\n"
        
        status_info+="\n🌐 Service URLs:\n"
        for service in "${running_services[@]}"; do
            local port="${SERVICE_PORTS[$service]:-}"
            if [[ -n "$port" && "$port" != "5432" ]]; then
                status_info+="  • $service: http://localhost:$port\n"
            fi
        done
    fi
    
    whiptail --title "📊 System Status" \
        --msgbox "$status_info" \
        25 80
}

show_profile_status() {
    local profile="$1"
    local services_info
    
    services_info=$(docker-compose --profile "$profile" ps 2>/dev/null || echo "No services found for profile: $profile")
    
    whiptail --title "📊 Profile Status: $profile" \
        --msgbox "$services_info" \
        20 80
}

show_profile_logs() {
    local profile="$1"
    local log_output
    
    log_output=$(docker-compose --profile "$profile" logs --tail=50 2>/dev/null || echo "No logs available")
    
    whiptail --title "📝 Logs: $profile" \
        --scrolltext \
        --msgbox "$log_output" \
        25 100
}

check_service_health() {
    local host="$1"
    local port="$2"
    
    timeout 3 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null
}

# ====================================================================
# ⚙️ CONFIGURATION WIZARDS
# ====================================================================

show_configuration_menu() {
    local config_option
    
    config_option=$(whiptail --title "⚙️ Configuration Center" \
        --menu "Choose configuration option:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH $DIALOG_LIST_HEIGHT \
        "global" "🌐 Global settings" \
        "core" "💾 Core services (n8n, postgres)" \
        "lms" "🎓 Learning Management System" \
        "ai" "🤖 AI Assistant services" \
        "ecommerce" "🛒 E-commerce platform" \
        "analytics" "📈 Analytics & monitoring" \
        "security" "🔒 Security & authentication" \
        "networking" "🌐 Networking & domains" \
        "back" "← Return to main menu" \
        3>&1 1>&2 2>&3)
    
    case $config_option in
        "global") configure_global_settings ;;
        "core") configure_core_services ;;
        "lms") configure_lms ;;
        "ai") configure_ai_services ;;
        "ecommerce") configure_ecommerce ;;
        "analytics") configure_analytics ;;
        "security") configure_security ;;
        "networking") configure_networking ;;
        "back"|"") return ;;
    esac
}

configure_global_settings() {
    local domain port_prefix ssl_enabled
    
    domain=$(whiptail --title "🌐 Global Configuration" \
        --inputbox "Enter your domain name:" \
        10 50 "${DEFAULT_DOMAIN:-localhost}" \
        3>&1 1>&2 2>&3)
    
    if [[ -n "$domain" ]]; then
        DEFAULT_DOMAIN="$domain"
        
        if whiptail --title "🔒 SSL Configuration" \
            --yesno "Enable SSL/HTTPS?\n\nThis requires valid certificates." \
            10 50; then
            ENABLE_SSL="true"
        else
            ENABLE_SSL="false"
        fi
        
        if whiptail --title "🔐 Authentication" \
            --yesno "Enable Authelia authentication?\n\nThis adds an authentication layer to all services." \
            10 50; then
            ENABLE_AUTH="true"
        else
            ENABLE_AUTH="false"
        fi
        
        save_config
        
        whiptail --title "✅ Configuration Saved" \
            --msgbox "Global configuration updated successfully!\n\nDomain: $DEFAULT_DOMAIN\nSSL: $ENABLE_SSL\nAuth: $ENABLE_AUTH" \
            12 50
    fi
}
configure_core_services() {
    local n8n_config db_config
    
    if whiptail --title "💾 Core Services Configuration" \
        --yesno "Configure core services?\n\n• PostgreSQL database\n• n8n automation\n• File browser\n\nContinue?" \
        12 50; then
        
        # Database configuration
        local db_name db_user db_pass
        
        db_name=$(whiptail --title "🗄️ Database Configuration" \
            --inputbox "Database name:" 10 50 "helix_db" 3>&1 1>&2 2>&3)
        
        db_user=$(whiptail --title "🗄️ Database Configuration" \
            --inputbox "Database user:" 10 50 "helix_user" 3>&1 1>&2 2>&3)
        
        db_pass=$(whiptail --title "🗄️ Database Configuration" \
            --passwordbox "Database password:" 10 50 3>&1 1>&2 2>&3)
        
        # n8n configuration
        local n8n_host n8n_webhook
        
        n8n_host=$(whiptail --title "🔄 n8n Configuration" \
            --inputbox "n8n host:" 10 50 "localhost" 3>&1 1>&2 2>&3)
        
        n8n_webhook=$(whiptail --title "🔄 n8n Configuration" \
            --inputbox "Webhook URL:" 10 50 "http://localhost:5678/" 3>&1 1>&2 2>&3)
        
        # Save configuration
# Navigate to the directory where setup.sh is located if you're not already there
cd ~/helix-hub/infra-lite/ 

# Remove the directory if it exists
if [ -d "n8n/config.json" ]; then
    echo "Removing existing directory: n8n/config.json"
    rm -r n8n/config.json 
fi

# Now, re-run the command that creates the file
cat > "n8n/config.json" << EOF
{
  "database": {
    "type": "postgres",
    "host": "postgres",
    "database": "$db_name",
    "username": "$db_user",
    "password": "$db_pass"
  },
  "host": "$n8n_host",
  "webhook": "$n8n_webhook"
}
EOF

echo "n8n/config.json created successfully."

        # --- HEALTH CHECK DASHBOARD ---
        sleep 2
        local status="📊 Core Services Status\n\n"

        # PostgreSQL
        if docker exec postgres pg_isready -U "$db_user" -d "$db_name" >/dev/null 2>&1; then
            status+="🟢 Postgres (5432) - Healthy\n"
        else
            status+="🔴 Postgres (5432) - Unreachable\n"
        fi

        # n8n
        if curl -sSf "http://$n8n_host:5678" >/dev/null 2>&1; then
            status+="🟢 n8n (5678) - Healthy\n"
        else
            status+="🔴 n8n (5678) - Unreachable\n"
        fi

        # Filebrowser
        if curl -sSf "http://localhost:8081" >/dev/null 2>&1; then
            status+="🟢 Filebrowser (8081) - Healthy\n"
        else
            status+="🔴 Filebrowser (8081) - Unreachable\n"
        fi

        whiptail --title "✅ Configuration Complete" \
            --msgbox "$status" 20 60
    fi
}


configure_profile() {
    local profile="$1"
    
    case "$profile" in
        "core") configure_core_services ;;
        "lms") configure_lms ;;
        "ai") configure_ai_services ;;
        "ecommerce") configure_ecommerce ;;
        "analytics") configure_analytics ;;
        *)
            whiptail --title "⚙️ Configuration" \
                --msgbox "Configuration wizard for '$profile' is not yet available.\n\nPlease check back in a future update!" \
                10 50
            ;;
    esac
}

configure_lms() {
    whiptail --title "🎓 LMS Configuration" \
        --msgbox "LMS configuration wizard will be available soon!\n\nFor now, please edit the configuration files manually in the moodle/ directory." \
        10 60
}

configure_ai_services() {
    whiptail --title "🤖 AI Configuration" \
        --msgbox "AI services configuration wizard will be available soon!\n\nFor now, please edit the configuration files manually in the ai-assistant/ directory." \
        10 60
}

configure_ecommerce() {
    whiptail --title "🛒 E-commerce Configuration" \
        --msgbox "E-commerce configuration wizard will be available soon!\n\nFor now, please edit the configuration files manually in the medusa/ directory." \
        10 60
}

configure_analytics() {
    whiptail --title "📈 Analytics Configuration" \
        --msgbox "Analytics configuration wizard will be available soon!\n\nFor now, please edit the configuration files manually in the analytics/ and grafana/ directories." \
        10 60
}

configure_security() {
    whiptail --title "🔒 Security Configuration" \
        --msgbox "Security configuration wizard will be available soon!\n\nFor now, please edit the configuration files manually in the authelia/ and vault/ directories." \
        10 60
}

configure_networking() {
    whiptail --title "🌐 Networking Configuration" \
        --msgbox "Networking configuration wizard will be available soon!\n\nFor now, please edit the configuration files manually in the traefik/ directory." \
        10 60
}

# ====================================================================
# 🚀 QUICK DEPLOYMENT FUNCTIONS
# ====================================================================

show_quick_deploy_menu() {
    local deploy_option
    
    deploy_option=$(whiptail --title "🚀 Quick Deploy" \
        --menu "Choose a deployment option:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH $DIALOG_LIST_HEIGHT \
        "core" "💾 Core services (Essential)" \
        "development" "👨‍💻 Development stack" \
        "production" "🏭 Production ready" \
        "ai-workspace" "🤖 AI workspace" \
        "learning" "🎓 Learning platform" \
        "full-stack" "🌟 Everything (Advanced)" \
        "custom" "⚙️  Custom selection" \
        "back" "← Return to main menu" \
        3>&1 1>&2 2>&3)
    
    case $deploy_option in
        "core") quick_deploy_core ;;
        "development") quick_deploy_development ;;
        "production") quick_deploy_production ;;
        "ai-workspace") quick_deploy_ai_workspace ;;
        "learning") quick_deploy_learning ;;
        "full-stack") quick_deploy_full_stack ;;
        "custom") quick_deploy_custom ;;
        "back"|"") return ;;
    esac
}

quick_deploy_core() {
    if whiptail --title "💾 Core Services" \
        --yesno "Deploy core services?\n\n• PostgreSQL database\n• n8n automation platform\n• File browser\n• SFTP server\n\nContinue?" \
        14 50; then
        deploy_profile "core"
    fi
}

quick_deploy_development() {
    if whiptail --title "👨‍💻 Development Stack" \
        --yesno "Deploy development stack?\n\n• Core services\n• Integration tools\n• MailHog for testing\n• Development utilities\n\nContinue?" \
        14 50; then
        
        {
            echo "25"
            echo "# Deploying core services..."
            docker-compose --profile core up -d
            
            echo "50"
            echo "# Adding integration tools..."
            docker-compose --profile integration up -d
            
            echo "75"
            echo "# Setting up development utilities..."
            sleep 2
            
            echo "100"
            echo "# Development stack ready!"
        } | whiptail --title "🚀 Deploying Development Stack" --gauge "Starting deployment..." 8 70 0
        
        whiptail --title "✅ Development Stack Ready" \
            --msgbox "Development environment deployed!\n\n🌐 Access points:\n• n8n: http://localhost:5678\n• File Browser: http://localhost:8082" \
            12 60
    fi
}

quick_deploy_production() {
    if whiptail --title "🏭 Production Deployment" \
        --yesno "Deploy production stack?\n\n⚠️  WARNING: This will:\n• Enable all security features\n• Configure SSL/HTTPS\n• Set up monitoring\n• Configure backups\n\nContinue?" \
        16 60; then
        
        whiptail --title "🚧 Production Setup" \
            --msgbox "Production deployment is complex and requires:\n\n• Valid SSL certificates\n• Proper domain configuration\n• Security hardening\n• Database optimization\n\nPlease use manual configuration for production deployments." \
            16 70
    fi
}

quick_deploy_ai_workspace() {
    if whiptail --title "🤖 AI Workspace" \
        --yesno "Deploy AI workspace?\n\n• Core services\n• Ollama AI models\n• Open WebUI\n• AI development tools\n\nNote: Requires significant resources\n\nContinue?" \
        16 60; then
        deploy_profile "ai"
    fi
}

quick_deploy_learning() {
    if whiptail --title "🎓 Learning Platform" \
        --yesno "Deploy learning platform?\n\n• LMS (Moodle)\n• Database\n• File storage\n• User management\n\nContinue?" \
        14 50; then
        deploy_profile "lms"
    fi
}

quick_deploy_full_stack() {
    if whiptail --title "🌟 Full Stack Deployment" \
        --yesno "Deploy EVERYTHING?\n\n⚠️  WARNING: This will deploy ALL services:\n• All profiles\n• High resource usage\n• Long startup time\n\nRecommended only for powerful systems!\n\nContinue?" \
        18 60; then
        
        {
            echo "10"
            echo "# Deploying core services..."
            docker-compose --profile core up -d
            sleep 2
            
            echo "25"
            echo "# Adding LMS..."
            docker-compose --profile lms up -d
            sleep 2
            
            echo "40"
            echo "# Starting AI services..."
            docker-compose --profile ai up -d
            sleep 3
            
            echo "60"
            echo "# Setting up e-commerce..."
            docker-compose --profile ecommerce up -d
            sleep 2
            
            echo "80"
            echo "# Configuring analytics..."
            docker-compose --profile analytics up -d
            sleep 2
            
            echo "100"
            echo "# Full stack deployment complete!"
        } | whiptail --title "🚀 Full Stack Deployment" --gauge "Initializing..." 8 70 0
        
        whiptail --title "🌟 Full Stack Ready!" \
            --msgbox "Complete Helix Hub stack deployed!\n\nCheck the status dashboard for service details.\n\n⚠️  Services may take several minutes to fully start." \
            12 60
    fi
}

quick_deploy_custom() {
    local selected_profiles=()
    local profile_args=()
    
    # Build checklist arguments
    for profile in "${!PROFILES[@]}"; do
        profile_args+=("$profile" "${PROFILES[$profile]}" "OFF")
    done
    
    # Show profile selection
    local selected
    selected=$(whiptail --title "⚙️ Custom Deployment" \
        --checklist "Select profiles to deploy:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH $DIALOG_LIST_HEIGHT \
        "${profile_args[@]}" \
        3>&1 1>&2 2>&3)
    
    if [[ -n "$selected" ]]; then
        # Remove quotes and convert to array
        eval "selected_profiles=($selected)"
        
        local profile_list=$(IFS=', '; echo "${selected_profiles[*]}")
        
        if whiptail --title "🚀 Custom Deployment" \
            --yesno "Deploy selected profiles?\n\n$profile_list\n\nContinue?" \
            12 50; then
            
            for profile in "${selected_profiles[@]}"; do
                # Remove quotes from profile name
                profile=$(echo "$profile" | tr -d '"')
                docker-compose --profile "$profile" up -d
            done
            
            whiptail --title "✅ Custom Deployment Complete" \
                --msgbox "Selected profiles deployed successfully!\n\n$profile_list" \
                10 50
        fi
    fi
}

# ====================================================================
# 🎯 MAIN MENU & NAVIGATION
# ====================================================================

show_main_menu() {
    local choice
    
    choice=$(whiptail --title "🌟 Helix Hub Control Center" \
        --menu "Choose an option:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH $DIALOG_LIST_HEIGHT \
        "status" "📊 Status dashboard" \
        "profiles" "🎛️  Profile management" \
        "deploy" "🚀 Quick deploy" \
        "config" "⚙️  Configuration center" \
        "maintenance" "🔧 Maintenance tools" \
        "logs" "📝 View logs" \
        "help" "❓ Help & documentation" \
        "exit" "👋 Exit" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        "status") show_status_dashboard ;;
        "profiles") show_profile_menu ;;
        "deploy") show_quick_deploy_menu ;;
        "config") show_configuration_menu ;;
        "maintenance") show_maintenance_menu ;;
        "logs") show_system_logs ;;
        "help") show_help ;;
        "exit"|"") exit_gracefully ;;
        *) show_main_menu ;;
    esac
}

show_maintenance_menu() {
    local maintenance_option
    
    maintenance_option=$(whiptail --title "🔧 Maintenance Tools" \
        --menu "Choose maintenance option:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH $DIALOG_LIST_HEIGHT \
        "cleanup" "🧹 Clean up containers & volumes" \
        "backup" "💾 Backup configurations" \
        "restore" "📥 Restore from backup" \
        "update" "🔄 Update services" \
        "reset" "⚠️  Factory reset" \
        "back" "← Return to main menu" \
        3>&1 1>&2 2>&3)
    
    case $maintenance_option in
        "cleanup") maintenance_cleanup ;;
        "backup") maintenance_backup ;;
        "restore") maintenance_restore ;;
        "update") maintenance_update ;;
        "reset") maintenance_reset ;;
        "back"|"") return ;;
    esac
}

maintenance_cleanup() {
    if whiptail --title "🧹 System Cleanup" \
        --yesno "Perform system cleanup?\n\nThis will:\n• Remove stopped containers\n• Clean unused images\n• Prune unused volumes\n• Clear build cache\n\n⚠️  This action cannot be undone!\n\nContinue?" \
        16 60; then
        
        {
            echo "25"
            echo "# Removing stopped containers..."
            docker container prune -f
            
            echo "50"
            echo "# Cleaning unused images..."
            docker image prune -f
            
            echo "75"
            echo "# Pruning unused volumes..."
            docker volume prune -f
            
            echo "100"
            echo "# Cleanup complete!"
        } | whiptail --title "🧹 Cleaning Up System" --gauge "Starting cleanup..." 8 70 0
        
        whiptail --title "✅ Cleanup Complete" \
            --msgbox "System cleanup completed successfully!\n\nRecovered space and removed unused resources." \
            10 50
    fi
}

maintenance_backup() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    if whiptail --title "💾 Create Backup" \
        --yesno "Create system backup?\n\nThis will backup:\n• Configuration files\n• Docker volumes\n• Database data\n\nBackup location: $backup_dir\n\nContinue?" \
        14 60; then
        
        mkdir -p "$backup_dir"
        
        {
            echo "20"
            echo "# Backing up configuration files..."
            cp -r . "$backup_dir/" 2>/dev/null || true
            
            echo "50"
            echo "# Backing up Docker volumes..."
            docker run --rm -v helix-hub_helix_db_data:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/db_data.tar.gz -C /data . 2>/dev/null || true
            
            echo "80"
            echo "# Creating backup manifest..."
            echo "Helix Hub Backup - $(date)" > "$backup_dir/backup_info.txt"
            echo "Profiles: $(ls profiles/ 2>/dev/null || echo 'none')" >> "$backup_dir/backup_info.txt"
            
            echo "100"
            echo "# Backup complete!"
        } | whiptail --title "💾 Creating Backup" --gauge "Initializing backup..." 8 70 0
        
        whiptail --title "✅ Backup Complete" \
            --msgbox "Backup created successfully!\n\nLocation: $backup_dir\n\nYou can restore from this backup using the maintenance menu." \
            12 60
    fi
}

maintenance_restore() {
    whiptail --title "📥 Restore from Backup" \
        --msgbox "Restore functionality will be available soon!\n\nFor now, you can manually restore from backup directories in the backups/ folder." \
        10 60
}

maintenance_update() {
    if whiptail --title "🔄 Update Services" \
        --yesno "Update all Docker images?\n\nThis will:\n• Pull latest images\n• Restart services with new versions\n• May cause temporary downtime\n\nContinue?" \
        14 60; then
        
        {
            echo "30"
            echo "# Pulling latest images..."
            docker-compose pull
            
            echo "70"
            echo "# Restarting services..."
            docker-compose up -d
            
            echo "100"
            echo "# Update complete!"
        } | whiptail --title "🔄 Updating Services" --gauge "Pulling updates..." 8 70 0
        
        whiptail --title "✅ Update Complete" \
            --msgbox "All services have been updated to the latest versions!" \
            8 50
    fi
}

maintenance_reset() {
    if whiptail --title "⚠️ Factory Reset" \
        --yesno "DANGER: Factory Reset\n\nThis will:\n• Stop all services\n• Remove all containers\n• Delete all volumes and data\n• Reset all configurations\n\n🔥 ALL DATA WILL BE LOST! 🔥\n\nThis cannot be undone!\n\nAre you absolutely sure?" \
        18 60; then
        
        if whiptail --title "⚠️ FINAL CONFIRMATION" \
            --yesno "Last chance!\n\nType 'RESET' to confirm total destruction of all data:" \
            10 60; then
            
            local confirmation
            confirmation=$(whiptail --title "⚠️ Type RESET" \
                --inputbox "Type 'RESET' to confirm:" \
                10 50 3>&1 1>&2 2>&3)
            
            if [[ "$confirmation" == "RESET" ]]; then
                {
                    echo "25"
                    echo "# Stopping all services..."
                    docker-compose down -v
                    
                    echo "50"
                    echo "# Removing all containers..."
                    docker system prune -af
                    
                    echo "75"
                    echo "# Resetting configurations..."
                    rm -f .helix-config
                    
                    echo "100"
                    echo "# Factory reset complete!"
                } | whiptail --title "🔥 Factory Reset in Progress" --gauge "Destroying everything..." 8 70 0
                
                whiptail --title "💥 Factory Reset Complete" \
                    --msgbox "Factory reset completed!\n\nAll services, data, and configurations have been removed.\n\nYou can now set up Helix Hub fresh from the beginning." \
                    12 60
            else
                whiptail --title "❌ Reset Cancelled" \
                    --msgbox "Factory reset cancelled. Your data is safe!" \
                    8 50
            fi
        fi
    fi
}

show_system_logs() {
    local log_content
    
    if [[ -f "$LOG_FILE" ]]; then
        log_content=$(tail -100 "$LOG_FILE")
    else
        log_content="No log file found."
    fi
    
    whiptail --title "📝 System Logs" \
        --scrolltext \
        --msgbox "$log_content" \
        25 100
}

show_help() {
    local help_text="🌟 HELIX HUB HELP\n\n"
    help_text+="PROFILES:\n"
    for profile in "${!PROFILES[@]}"; do
        help_text+="• $profile - ${PROFILES[$profile]}\n"
    done
    help_text+="\n"
    help_text+="QUICK START:\n"
    help_text+="1. Use 'Quick Deploy' -> 'Core services' for basic setup\n"
    help_text+="2. Check 'Status Dashboard' to see running services\n"
    help_text+="3. Use 'Configuration Center' to customize settings\n\n"
    help_text+="SERVICE URLS (when running):\n"
    help_text+="• n8n Automation: http://localhost:5678\n"
    help_text+="• File Browser: http://localhost:8082\n"
    help_text+="• Moodle LMS: http://localhost:8081\n"
    help_text+="• Grafana: http://localhost:3000\n\n"
    help_text+="SUPPORT:\n"
    help_text+="• Check logs for troubleshooting\n"
    help_text+="• Use maintenance tools for cleanup\n"
    help_text+="• Backup before major changes\n"
    
    whiptail --title "❓ Help & Documentation" \
        --scrolltext \
        --msgbox "$help_text" \
        25 80
}

exit_gracefully() {
    if whiptail --title "👋 Exit Helix Hub" \
        --yesno "Exit Helix Hub setup?\n\nAll running services will continue to run in the background.\n\nGoodbye!" \
        10 50; then
        clear
        print_banner
        echo -e "${GREEN}Thank you for using Helix Hub! 🌟${NC}"
        echo -e "${CYAN}Your services are still running. Use 'docker-compose ps' to check status.${NC}"
        echo -e "${YELLOW}Run this script again anytime to manage your infrastructure!${NC}"
        echo ""
        exit 0
    fi
}

# ====================================================================
# 🚀 MAIN EXECUTION
# ====================================================================

main() {
    # Initial setup
    clear
    print_banner
    
    # Check dependencies
    check_dependencies
    
    # Load configuration
    load_config
    
    # Ensure we're in the right directory
    if [[ ! -f "setup.sh" ]]; then
        cd "$(dirname "$0")" || exit 1
    fi
    
    # Create infrastructure if needed
    if [[ ! -d "infra-lite" ]]; then
        create_directory_structure "infra-lite"
        cd "infra-lite" || exit 1
    else
        cd "infra-lite" || exit 1
    fi
    
    # Main menu loop
    while true; do
        show_main_menu
    done
}

# Run main function
main "$@"