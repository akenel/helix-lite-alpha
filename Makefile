# Makefile for Helix-Lite-Alpha Stack 🚀
COMPOSE = docker compose
PROJECT = helix-lite-alpha

# Profiles
PROFILES = core testing integration ecommerce
.PHONY: helix-app

helix-app:
	docker compose build --no-cache helix-app
	docker compose up -d helix-app

help:
	@echo "📖 Available commands:"
	@echo "  make helix-app             # 🚀 Rebuilds and starts the Helix app"
	@echo "  make up profile=core       # 🚀 Start stack with profile"
	@echo "  make down profile=core     # 🛑 Stop stack with profile"
	@echo "  make restart profile=core  # 🔄 Restart stack with profile"
	@echo "  make ps                    # 📋 Show running containers"
	@echo "  make logs profile=core     # 📜 Show logs for profile"
	@echo "  make clean                 # 🧹 Remove all containers & volumes"
	@echo "  make creds                 # 🔑 Show dynamic credentials"
	@echo "  make links                 # 🔗 Show service URLs"
	@echo "  make vault-init            # 🧰 Get Vault root token (first time only)"

up:
	$(COMPOSE) --profile $(profile) up -d
	@echo "✅ Started profile: $(profile)"
	@$(MAKE) links

down:
	$(COMPOSE) --profile $(profile) down
	@echo "🛑 Stopped profile: $(profile)"

restart: down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) --profile $(profile) logs -f

clean:
	$(COMPOSE) down -v --remove-orphans
	docker system prune -af --volumes
	@echo "🧹 Cleaned up stack $(PROJECT)"

creds:
	@echo "🔑 Service Credentials"
	@echo "-----------------------"
	@echo "Filebrowser: (check logs on first run)"
	@docker logs filebrowser 2>/dev/null | grep -A1 "login credentials"
	@echo ""
	@echo "Portainer: (check logs on first run)"
	@docker logs portainer 2>/dev/null | grep 'Admin password'

vault-init:
	@echo "🧰 Initializing Vault and retrieving root token..."
	@echo "---------------------------------------------------"
	@echo "This command should only be run the very first time you start the Vault container."
	@echo "Storing the token in a text file is a security risk. Use a proper secret manager."
	@docker exec -it helix-lite-alpha_vault_1 vault operator init > vault-init.txt
	@echo "✅ Vault initialization complete. Root token saved to vault-init.txt"
	@echo "Please secure this token and delete the file immediately."

links:
	@echo ""
	@echo "🌐 Helix-Lite-Alpha Service Dashboard"
	@echo "-------------------------------------"
	@echo "🔐 Keycloak:     https://keycloak.helix.local/ (admin / admin)"
	@echo "🐳 Portainer:    https://portainer.helix.local/ (admin / check 'make creds')"
	@echo "📊 Grafana:      https://grafana.helix.local/ (admin / admin)"
	@echo "📈 Prometheus:   https://prometheus.helix.local/"
	@echo "📂 Filebrowser:  https://filebrowser.helix.local/ (admin / check 'make creds')"
	@echo "📬 Mailhog:      https://mailhog.helix.local/"
	@echo "📋 pgAdmin:      https://pgadmin.helix.local/ (admin@helix.com : admin)"
	@echo "🧰 Vault:        https://vault.helix.local (Login with root token)"
	@echo "📦 Minio Console: https://minio.helix.local/ (minioadmin / minioadmin)"
	@echo "🤖 n8n:          https://n8n.helix.local/ (create new user)"
	@echo "🤖 Ollama:       https://ollama.helix.local/"
	@echo "💡 OpenWebUI:    https://openwebui.helix.local/ (create new user)"
	@echo "🗃️  Adminer:      https://adminer.helix.local/ (postgres db creds)"
	@echo "🌐 Traefik:      https://traefik.helix.local/dashboard/"
	@echo ""
	@echo " Use the above HTTPS links for a secure connection."
	@echo " Run 'make creds' for dynamic credentials."