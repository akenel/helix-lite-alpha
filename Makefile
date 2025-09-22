# Makefile for Helix-Lite-Alpha Stack 🚀
COMPOSE = docker compose
PROJECT = helix-lite-alpha

# Profiles
PROFILES = core testing integration ecommerce

help:
	@echo "📖 Available commands:"
	@echo "  make up profile=core       # 🚀 Start stack with profile"
	@echo "  make down profile=core     # 🛑 Stop stack with profile"
	@echo "  make restart profile=core  # 🔄 Restart stack with profile"
	@echo "  make ps                    # 📋 Show running containers"
	@echo "  make logs profile=core     # 📜 Show logs for profile"
	@echo "  make clean                 # 🧹 Remove all containers & volumes"
	@echo "  make links                 # 🔗 Show service URLs + credentials"

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

links:
	@echo ""
	@echo "🌐 Helix-Lite-Alpha Service Dashboard"
	@echo "-------------------------------------"
	@echo "🔐 Keycloak:     🔀 https://keycloak.helix.local/     (admin / admin)              🔌 http://localhost:32804"
	@echo "🐳 Portainer:    🔀 https://portainer.helix.local/    (admin / <password>)         🔌 http://localhost:9000"
	@echo "📊 Grafana:      🔀 https://grafana.helix.local/      (admin / admin)              🔌 http://localhost:3000"
	@echo "📈 Prometheus:   🔀 https://prometheus.helix.local/   (N/A)                        🔌 http://localhost:9090"
	@echo "📂 Filebrowser:  🔀 https://filebrowser.helix.local/  (admin / check logs)         🔌 http://localhost:8082"
	@echo "📬 Mailhog:      🔀 https://mailhog.helix.local/      (no login/SMTP)              🔌 http://localhost:8025"  
	@echo "📋 pgAdmin:      🔀 https://pgadmin.helix.local/      (admin@example.com : admin ) 🔌 http://localhost:5050"
	@echo "🧰 Vault:        🔀 https://vault.helix.local         (🔑 Login with root token)   🔌 http://localhost:8200"
	@echo "📦 Minio:        🔀 https://minio.helix.local         (minioadmin / minioadmin)    🔌 http://localhost:32806"
	@echo "🤖 n8n:          🔀 https://n8n.helix.local           (create new user)            🔌 http://localhost:5678"
	@echo "🤖 Ollama:       🔀 https://ollama.helix.local        (N/A)                        🔌 http://localhost:11434"
	@echo "💡 OpenWebUI:    🔀 https://openwebui.helix.local/    (create new user)            🔌 http://localhost:32807"
	@echo "🗃️  Adminer:      🔀 https://adminer.helix.local/      (psotgres db creds)          🔌 http://localhost:8083"
	@echo "🌐 Traefik:      🔀 https://traefik.helix.local/dashboard/                         🔌 http://localhost:8080"
	@echo ""
	@echo " Check Ports: docker ps --format 'table {{.Names}}\t{{.Ports}}'"
	@echo ""
	@echo "🗄️ PostgreSQL:   🔌 localhost:5432              (user: postgres / pw: <from .env>)" 
	@echo "🗄️   POSTGRES_DB=helix_db"
	@echo "🗄️   POSTGRES_USER=helix_user"
	@echo "🗄️   POSTGRES_PASSWORD=helix_pass"
	@echo "💡 Tip: Prefer Traefik HTTPS links when DNS + TLS are working."
	@echo "   Use localhost ports for debugging or if routing is incomplete."
