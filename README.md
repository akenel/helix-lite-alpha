# helix-lite-alpha
road map
🕵️‍♂️ Sherlock reporting — I *love* this energy. What you’re sketching out is ambitious (a **lean BTP rival on Docker Compose**), but it’s not crazy. In fact, running a **micro-BTP on a laptop** is one of the smartest ways to:

* ✅ Validate the architecture.
* ✅ Test the integration flows (OData, REST, IDoc, ABAP proxy).
* ✅ Harden the security model before any real deployment.

This is **totally doable today** on your laptop — as long as we **stay lean, modular, and scripted** so you don’t get lost in the service jungle.

---
# 🚁 Helix Infra-Lite

This repository contains the core infrastructure for the Helix project,
a powerful local development environment for testing and developing
webhooks, email automations, and more.

## ✨ Features

- **Docker-Compose:** Easy setup with a single command.
- **Traefik:** Reverse proxy with automatic SSL for local domains (`.local`).
- **N8N:** Workflow automation and webhook processing.
- **MailHog:** Local SMTP server for email testing and debugging.

## 🚀 Getting Started

1.  Clone this repository.
2.  Run `docker compose up -d`.
3.  Access N8N at `https://n8n.helix.local` and MailHog at `http://localhost:8025`.

## 🔒 Configuration

This project uses environment variables for sensitive information. A `.env` file should be created based on the `.env.example` file.



## 📝 Checklist: SAP BTP-like Platform on Docker Compose

### 1. **Core Infrastructure (must-have backbone)**

* [x] **Traefik** → API Gateway + Routing + TLS (your entrypoint).
* [x] **Kong** → API management (quotas, rate limiting, OData/REST exposure).
* [x] **Postgres** → DB backend for services (and Kong).
* [x] **Redis** → Cache + message state store.
* [x] **Vault** → Secrets, credentials, SAP backend keys.
* [x] **Authelia / Keycloak** → Identity & Access (SSO, JWT for services).

---

### 2. **Integration & Event Backbone**

* [x] **n8n** → Orchestrator + low-code mapper (IDoc ↔ OData ↔ REST ↔ ABAP).
* [ ] **Kafka or Redpanda (optional)** → Event streaming backbone (IDoc streams, async SAP events).
* [ ] **Schema Registry** → Keep OData/IDoc schemas aligned.
* [ ] **Connectors** → Pre-built n8n nodes for SAP OData / IDoc / RFC.

---

### 3. **Developer & Ops Tools**

* [x] **Portainer** → Container management UI (debug fast).
* [x] **Filebrowser / SFTP** → File integration (classic SAP batch jobs).
* [ ] **Grafana + Prometheus** → Monitoring stack.
* [ ] **ELK or Loki** → Logs + trace for SAP ↔ Middleware ↔ Cloud.

---

### 4. **Security / Enterprise Features**

* [ ] Vault integration with Traefik & Kong → no secrets in env files.
* [ ] Authelia → handle OAuth2/OIDC, SSO across services.
* [ ] Mutual TLS between services (docker-compose networks).
* [ ] Role-based access → separate "admin vs dev vs runtime".

---

### 5. **SAP Connectivity Layer**

* [ ] **OData connector** (via n8n node or Kong plugin).
* [ ] **REST connector** (standard).
* [ ] **IDoc listener** (via SFTP / Kafka stream / RFC connector).
* [ ] **ABAP proxy simulation** (could be proxied via Kong or exposed through an adapter microservice).

---

### 6. **Local Dev Workflow**

* ✅ `docker compose --profile core up -d` → Start backbone.
* ✅ `./setup.sh` → TUI for deployment/teardown.
* ✅ `./health-check.sh` → Dashboard status check.
* ✅ `./config.sh` → Configure secrets (Vault) + routes (Kong) + SSO (Authelia).
* 🔜 Add **profiles** (`profiles/integration.yml`, `profiles/analytics.yml`) for modular expansion.

---

### 7. **Stretch Goals (Phase 2)**

* [ ] **Multi-tenant simulation** → SAP BTP spaces/projects.
* [ ] **Custom dashboard (TUI or Web)** → Show all service URLs in one place.
* [ ] **CI/CD on Laptop** → Scripts simulate deployment pipelines.
* [ ] **Hybrid connectivity** → VPN tunnel into SAP backend sandbox.

---

## 🚦 Game Plan (Today → MVP)

1. **Stabilize Core Profile** → get Postgres, Kong, Traefik, Vault, Authelia, n8n working together.
2. **Wire Kong + n8n** → expose a mock SAP OData service via Kong, route to n8n.
3. **Secure It** → Vault manages secrets, Authelia provides login.
4. **Check with Health Script** → get ✅ on all services.
5. **Add Kafka if Needed** → only if you need async events.

---

## ⚡ Reality Check

* 💻 Your laptop *can* handle this if you stay modular (not everything at once).
* 🧠 The hardest part isn’t containers — it’s **designing the integration flows** (OData ↔ IDoc ↔ REST).
* 🚀 If we script carefully, you’ll have a **mini-SAP BTP rival in Docker Compose** — and you’ll understand it *better than SAP consultants*.

---

👉 Sherlock says: This isn’t crazy — this is *exactly* how to build enterprise middleware lean.

Do you want me to **draft the first `core.yml` Docker Compose profile** with:

* Traefik
* Kong
* Postgres
* Redis
* Vault
* Authelia
* n8n

so you can run `docker compose --profile core up -d` and bootstrap your mini-BTP backbone today?


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
