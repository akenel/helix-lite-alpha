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
	@echo "🔐 Keycloak:                                               (admin / admin)            🔐 http://localhost:8084"
	@echo "🐳 Portainer:   🔀 https://portainer.helix.local/  (admin / <password>)         🔌 http://localhost:9000"
	@echo "📊 Grafana:     🔀 https://grafana.helix.local:8443/        (admin / admin)           🔌 http://localhost:3000"
	@echo "📈 Prometheus:  🔀 https://prometheus.helix.local              (N/A)                  🔌 http://localhost:9090"
	@echo "📂 Filebrowser: 🔀 https://filebrowser.helix.local          (admin / xxxx)            🔌 http://localhost:8082"
	@echo "📬 Mailhog:     🔀 https://mailhog.helix.local    (no login/SMTP: localhost:1025)     🔌 http://localhost:8025"  
	@echo "🐇 RabbitMQ:    🔀 https://rabbitmq.helix.local (guest/guest | AMQP: localhost:5672)  🔌 http://localhost:15672"
	@echo "📋 pgAdmin:     🔀 https://pgadmin.helix.local     (admin@example.com : admin )       🔌 http://localhost:5050"

	@echo "🧰 Vault:       🔀 https://vault.helix.local:8443/ui/vault (🔑 Login with root token) 🔌 http://localhost:8200"
	@echo "📦 Minio:       🔀 https://minio.helix.local            (minioadmin / minioadmin)     🔌 http://localhost:9001"
	@echo "🤖 n8n:         🔀 https://n8n.helix.local:8443/home/workflows   (create new user)    🔌 http://localhost:5678"
	@echo "🌐 Traefik:     🔀 https://traefik.helix.local/dashboard/         (if enabled)        🔌 http://localhost:8080"
	@echo ""
	@echo " Check Ports: docker ps --format 'table {{.Names}}\t{{.Ports}}'"
	@echo ""
	@echo "🗄️ PostgreSQL:  🔌 localhost:5432              (user: postgres / pw: <from .env>)" 
	@echo "🗄️   POSTGRES_DB=helix_db"
	@echo "🗄️   POSTGRES_USER=helix_user"
	@echo "🗄️   POSTGRES_PASSWORD=helix_pass"
	@echo "💡 Tip: Prefer Traefik HTTPS links when DNS + TLS are working."
	@echo "   Use localhost ports for debugging or if routing is incomplete."
