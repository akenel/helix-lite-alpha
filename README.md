# helix-lite-alpha

A streamlined, local-first development stack for microservice-based applications. This setup provides essential infrastructure components including a reverse proxy, a message queue, and a PostgreSQL database, all orchestrated with Docker Compose.

## Components

- **Kong**: A declarative API gateway and reverse proxy.
- **n8n**: A workflow automation platform for integrating various services.
- **Traefik**: A modern HTTP reverse proxy and load balancer.
- **Postgres**: A robust relational database for persistent data.
- **Redis**: An in-memory data store for caching and messaging.
- **Portainer**: A management UI for your Docker environment.
- **Vault**: An essential tool for managing secrets.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Quick Start

1.  Clone this repository.
2.  Navigate into the project directory.
3.  Copy the example environment file and fill in your secrets.

    ```bash
    cp .env.example .env
    ```

4.  Start the core stack.

    ```bash
    docker compose --profile core up -d
    ```

This will spin up all the core services and their dependencies.

# InfraLite

Modular, extensible, and local-first infrastructure scaffolding for rapid development.

## Quick start

```bash
# run the setup (from the folder containing setup.sh & banner.asc)
chmod +x setup.sh
./setup.sh        # launches TUI (requires whiptail)
# Or: ./setup.sh --init  -> create scaffold + git init

🎨 Features Included:
✨ Beautiful TUI Interface

Colorful, professional whiptail dialogs
Consistent styling and branding
Progress indicators for long operations
Scrollable log viewers

🎛️ Interactive Profile Management

Visual profile selection with descriptions
Deploy, stop, restart, and monitor profiles
Real-time status checking
Individual service management

⚙️ Configuration Wizards

Global settings (domain, SSL, authentication)
Service-specific configuration
Database setup wizards
Security configuration

📊 Real-time Status Monitoring

Service health checks
Resource usage display
Port mapping and URLs
Container status dashboard

🚀 One-click Deployment Options

Core: Essential services
Development: Dev stack with tools
AI Workspace: AI services and models
Learning Platform: LMS setup
Full Stack: Everything at once
Custom: Choose your own profiles

🔧 Maintenance Tools

System cleanup and optimization
Backup and restore functionality
Service updates
Factory reset option

🎯 Usage Instructions:

Make executable: chmod +x setup.sh
Run the script: ./setup.sh
Navigate with arrow keys and Enter/Space
Follow the intuitive menus

The script automatically handles:

✅ Dependency checking
📁 Directory structure creation
🔧 Service configuration
📊 Health monitoring
💾 Configuration persistence


The issue you're experiencing is that port 8443 is still being used by something, even though netstat doesn't show it. This is a common Docker networking issue. Here's how to troubleshoot and fix it:
1. Check Docker's port usage specifically:
issue: angel@debian:~/helix-hub/infra-lite$ docker compose --profile core up -d
[+] Running 8/9
 ✔ Network infra-lite_alpinenet  Created                                                                                                                      0.0s 
 ✔ Container vault               Started                                                                                                                      0.2s 
 ✔ Container demo-ui             Started                                                                                                                      0.3s 
 ✔ Container redis               Started                                                                                                                      0.5s 
 ✔ Container portainer           Started                                                                                                                      0.4s 
 ✔ Container traefik             Started                                                                                                                      0.2s 
 ✔ Container postgres            Started                                                                                                                      0.5s 
 ✔ Container n8n                 Started                                                                                                                      0.9s 
 ⠴ Container kong                Starting                                                                                                                     0.9s 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint kong (6cb7ed78b70e4f0ba190d61bdc78abe41443aa7bc845634f3c31bd15943d2219): Bind for 0.0.0.0:8443 failed: port is already allocated
angel@debian:~/helix-hub/infra-lite$ 

docker ps -a
docker port $(docker ps -aq) 2>/dev/null | grep 8443

# Check Docker's internal networking
sudo ss -tulpn | grep :8443
sudo lsof -i :8443

sudo systemctl restart docker

# Stop all containers
docker compose --profile core down

# Clean up any orphaned containers
docker container prune -f

# Restart Docker
sudo systemctl restart docker

# Start again
docker compose --profile core up -d
