#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# InfraLite setup script (Option B - Pro)
# Creates folder scaffold, sample files, .gitignore, .env.example, banner,
# initializes git (if none), and provides a whiptail TUI for common operations.
#
# Usage:
#   ./setup.sh           -> runs interactive TUI (requires whiptail)
#   ./setup.sh --init    -> just create structure & git init (no TUI)
#   ./setup.sh --help    -> show help
# =============================================================================

# ---------- Configuration ----------
BASE_DIR="infra-lite"
BANNER_FILE="banner.asc"
GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-Angel}"
GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-angel@example.com}"
COMPOSE_FILE="docker-compose.yml"   # placeholder created
LOGFILE="./setup.log"

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
BOLD="\e[1m"
RESET="\e[0m"

# Profiles list (can be extended)
PROFILES=(core lms integration ai ecommerce minecraft analytics)

# Services for initial folders
SERVICES=(traefik authelia vault postgres moodle minio mailhog grafana prometheus)

# Addons and their main config filenames
declare -A ADDONS=(
  [n8n]="config.json"
  [medusa]="config.js"
  [minecraft]="server.properties"
  [ai-assistant]="ollama-config.yml"
  [analytics]="matomo-config.php"
)

# ---------- Helper Functions ----------
log() {
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOGFILE"
}

info()  { echo -e "${BLUE}${BOLD}➜${RESET} ${BLUE}$*${RESET}"; log "[INFO] $*"; }
ok()    { echo -e "${GREEN}${BOLD}✔${RESET} ${GREEN}$*${RESET}"; log "[OK] $*"; }
warn()  { echo -e "${YELLOW}${BOLD}⚠${RESET} ${YELLOW}$*${RESET}"; log "[WARN] $*"; }
err()   { echo -e "${RED}${BOLD}✖${RESET} ${RED}$*${RESET}" >&2; log "[ERR] $*"; }

# check if command exists
require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Required command '$cmd' not found. Please install it and re-run."
    return 1
  fi
  return 0
}

# Create ascii banner file if missing
create_banner() {
  if [[ -f "$BANNER_FILE" ]]; then
    info "Banner file $BANNER_FILE already exists — leaving intact."
    return
  fi
  cat > "$BANNER_FILE" <<'EOF'
  ___  _ _   _ _______
 |_ _|| (_) | |_   _(_)
  | | | | | | | | |  _
  | | | | | |_| | | || |
 |___||_|_|\___/  |_|(_)
        I L I T E
EOF
  ok "Created banner file: $BANNER_FILE"
}

# Safe create directory
safe_mkdir() {
  local d="$1"
  if [[ -d "$d" ]]; then
    info "Directory exists: $d"
  else
    mkdir -p "$d"
    ok "Created directory: $d"
  fi
}

# Create scaffold structure
create_structure() {
  info "Creating infra structure in: ${BASE_DIR}"
  if [[ -e "$BASE_DIR" && ! -d "$BASE_DIR" ]]; then
    err "$BASE_DIR exists and is not a directory. Aborting."
    exit 1
  fi

  safe_mkdir "$BASE_DIR"
  pushd "$BASE_DIR" >/dev/null

  # Top-level
  touch "$COMPOSE_FILE" ".env" "README.md"
  ok "Top-level placeholders created."

  # Profiles
  safe_mkdir "profiles"
  for p in "${PROFILES[@]}"; do
    local pf="profiles/${p}.yml"
    if [[ -f "$pf" ]]; then
      info "Profile exists: $pf"
    else
      cat > "$pf" <<EOF
# Profile: ${p}
# Add Compose service entries here for the '${p}' profile.
# Example:
# services:
#   myservice:
#     image: busybox
#     profiles: ["${p}"]
EOF
      ok "Created profile: $pf"
    fi
  done

  # Core service folders
  for s in "${SERVICES[@]}"; do
    safe_mkdir "$s"
    touch "$s/README.md"
  done

  # Traefik specifics
  safe_mkdir "traefik/certs"
  touch "traefik/traefik.yml" "traefik/dynamic.yml"

  # Authelia
  touch "authelia/configuration.yml" "authelia/users_database.yml"

  # Vault
  safe_mkdir "vault/policies" "vault/secrets"
  touch "vault/vault-config.hcl"

  # Postgres
  touch "postgres/init.sql"

  # Moodle
  safe_mkdir "moodle/moodledata"
  touch "moodle/config.php"

  # Grafana
  safe_mkdir "grafana/dashboards"
  touch "grafana/grafana.ini"

  # Prometheus
  touch "prometheus/prometheus.yml"

  # Addons
  for addon in "${!ADDONS[@]}"; do
    safe_mkdir "$addon"
    touch "$addon/${ADDONS[$addon]}" "$addon/README.md"
  done

  # Create banner inside base dir for easy display
  create_banner >/dev/null 2>&1 || true
  cp -n "../$BANNER_FILE" . 2>/dev/null || true

  # .env.example
  if [[ ! -f ".env.example" ]]; then
    cat > .env.example <<'EOF'
# Example .env
COMPOSE_PROJECT_NAME=infralite
POSTGRES_PASSWORD=example
VAULT_DEV_ROOT_TOKEN_ID=example
# DO NOT commit real secrets. Use .env for local only and add .env to .gitignore
EOF
    ok "Created .env.example"
  fi

  # .gitignore
  if [[ ! -f ".gitignore" ]]; then
    cat > .gitignore <<'EOF'
# Local env & secrets
.env
vault/secrets/
moodle/moodledata/
*.log
node_modules/
dist/
.DS_Store
# Docker artifacts
docker-compose.override.yml
*.crt
*.key
EOF
    ok "Created .gitignore"
  fi

  # Minimal docker-compose placeholder (with profiles)
  if [[ ! -s "$COMPOSE_FILE" ]]; then
    cat > "$COMPOSE_FILE" <<'EOF'
# Minimal docker-compose.yml placeholder for InfraLite
version: "3.9"
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-example}
    volumes:
      - ./postgres:/docker-entrypoint-initdb.d
    profiles:
      - core

  traefik:
    image: traefik:v2.11
    command: --api.insecure=true
    volumes:
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml
    ports:
      - "80:80"
      - "443:443"
    profiles:
      - core
EOF
    ok "Seeded $COMPOSE_FILE"
  else
    info "$COMPOSE_FILE already exists and non-empty — left unchanged."
  fi

  popd >/dev/null
  ok "Scaffold creation complete."
}

# Initialize git repo if not already
init_git() {
  pushd "$BASE_DIR" >/dev/null
  if [[ -d .git ]]; then
    info "Git repo already initialized in $BASE_DIR"
  else
    if require_cmd git; then
      git init
      git -c user.name="$GIT_AUTHOR_NAME" -c user.email="$GIT_AUTHOR_EMAIL" add .
      git -c user.name="$GIT_AUTHOR_NAME" -c user.email="$GIT_AUTHOR_EMAIL" commit -m "chore: initial InfraLite scaffold"
      ok "Initialized git repository and created initial commit."
    else
      warn "git not found; skipping git init."
    fi
  fi
  popd >/dev/null
}

# Deploy core profile
deploy_core() {
  if require_cmd docker && require_cmd docker-compose; then
    info "Starting core profile (detached)..."
    pushd "$BASE_DIR" >/dev/null
    # prefer docker compose (Docker CLI plugin) if available
    if command -v docker-compose >/dev/null 2>&1; then
      docker-compose --profile core up -d --remove-orphans
    else
      docker compose --profile core up -d --remove-orphans
    fi
    popd >/dev/null
    ok "Core profile deployed."
  else
    err "Docker or docker-compose not installed. Install and re-run."
  fi
}

# Tear down (careful)
teardown_all() {
  warn "This will stop and remove containers for the project. Press ENTER to confirm or Ctrl-C to cancel."
  read -r _
  if require_cmd docker-compose || require_cmd docker; then
    pushd "$BASE_DIR" >/dev/null
    if command -v docker-compose >/dev/null 2>&1; then
      docker-compose down -v --remove-orphans
    else
      docker compose down -v --remove-orphans
    fi
    popd >/dev/null
    ok "Teardown complete."
  else
    err "docker/docker-compose missing; cannot teardown."
  fi
}

# Health check (basic)
health_check() {
  info "Performing basic healthcheck of core containers"
  if require_cmd docker; then
    # look for containers from this compose project
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -i "postgres\|traefik\|authelia" || echo "No core containers detected by name. Use 'docker ps' manually."
  else
    err "docker not available."
  fi
}

# Open README in editor (falls back to cat)
open_readme() {
  local editor="${EDITOR:-nano}"
  if command -v "$editor" >/dev/null 2>&1; then
    "$editor" "$BASE_DIR/README.md"
  else
    cat "$BASE_DIR/README.md"
  fi
}

# TUI menu using whiptail
tui_menu() {
  if ! require_cmd whiptail; then
    err "whiptail not available. Install 'whiptail' (apt install whiptail) or run with --no-tui."
    exit 1
  fi

  while true; do
    CHOICE=$(whiptail --title "InfraLite — Sherlock Setup" --menu "Choose an action" 20 70 10 \
      "1" "Create scaffold (idempotent)" \
      "2" "Initialize git (if missing)" \
      "3" "Deploy core profile (docker compose --profile core up -d)" \
      "4" "Teardown (docker compose down -v)" \
      "5" "Health check (basic docker ps filter)" \
      "6" "Open README.md" \
      "7" "Full Reset (stop & purge ALL containers, volumes, images)" \

      "Q" "Exit" 3>&1 1>&2 2>&3) || break

    case "$CHOICE" in
      "1") create_structure ;;
      "2") init_git ;;
      "3") deploy_core ;;
      "4") teardown_all ;;
      "5") health_check ;;
      "6") open_readme ;;
      "7") ./reset_docker.sh ;;
      "Q") break ;;
      *) warn "Unknown option: $CHOICE" ;;
    esac
    sleep 1
  done
  ok "Exited TUI."
}

# ---------- CLI Arg Parsing ----------
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
  cat <<EOF
Usage: $0 [--init|--no-tui|--help]

--init    : create scaffold and init git, then exit (no TUI)
--no-tui  : create scaffold, but do not prompt for TUI (same as --init)
--help    : show this help
(no args) : run TUI (requires whiptail)
EOF
  exit 0
fi
# ---------- Main Menu ----------
tui_menu() {
  while true; do
    CHOICE=$(whiptail --title "InfraLite TUI" --menu "Choose an action:" 20 60 10 \
      "1" "Deploy Core Profile" \
      "2" "Tear Down (remove all containers/volumes)" \
      "3" "Check Service Health" \
      "4" "View Logs" \
      "5" "Exit" \
      3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus != 0 ]; then
      echo "Exiting..."
      exit 1
    fi

    case $CHOICE in
      1)
        echo "Deploying core profile..."
        docker compose --profile core up -d
        whiptail --msgbox "Core profile deployed." 10 40
        ;;
      2)
        echo "Tearing down everything..."
        docker compose down -v
        whiptail --msgbox "All containers and volumes removed." 10 40
        ;;
      3)
        docker compose ps > /tmp/health.txt
        whiptail --textbox /tmp/health.txt 20 70
        ;;
      4)
        docker compose logs --tail=50 > /tmp/logs.txt
        whiptail --textbox /tmp/logs.txt 20 70
        ;;
      5)
        exit 0
        ;;
    esac
  done
}

# ---------- Main Flow ----------
main() {
  # pre-checks (non-fatal)
  for cmd in docker git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      warn "'$cmd' not found — some features will be disabled. Install it for full functionality."
    fi
  done

  # create banner locally if not present in cwd (we copy into base dir later)
  create_banner

  # Create structure & files
  create_structure

  # CLI flags
  if [[ "${1:-}" == "--init" || "${1:-}" == "--no-tui" ]]; then
    init_git || true
    ok "Init complete. Run './setup.sh' later for TUI."
    exit 0
  fi

  # default — run interactive TUI
  tui_menu
}

trap 'err "Interrupted. Exiting."; exit 1' INT TERM
main "${1:-}"
# ---------- End of Script ----------