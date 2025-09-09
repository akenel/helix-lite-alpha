#!/bin/bash

# --- Helper Functions ---

# Find the Vault container's IP address
get_vault_ip() {
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' infra-lite-vault-1
}

# --- Main Script ---

VAULT_ADDR="http://$(get_vault_ip):8200"
export VAULT_ADDR

# Check for a valid VAULT_TOKEN environment variable. If it doesn't exist, prompt the user.
if [ -z "$VAULT_TOKEN" ]; then
    read -p "Enter your Vault Token (e.g., the root token): " VAULT_TOKEN
    export VAULT_TOKEN
fi

# Check if Vault is unsealed
vault_status=$(vault status -format=json 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ Vault is not running or not responding."
    exit 1
fi
sealed=$(echo "$vault_status" | jq -r '.sealed')
if [ "$sealed" = "true" ]; then
    echo "⚠️  Vault is sealed. Please unseal first."
    exit 1
fi

echo "✅ Vault is unsealed and ready. Address: $VAULT_ADDR"
echo "----------------------------------------------------"

# Perform a quick sanity check of the token
echo "Sanity Check: Looking up token details..."
vault token lookup || { echo "❌ Token is invalid or expired."; exit 1; }
echo "----------------------------------------------------"

show_menu() {
    echo "🎯 Vault Management Menu"
    echo "1) Get Vault Status"
    echo "2) Login (via OIDC)"
    echo "3) List Policies"
    echo "4) Read Secret"
    echo "5) Write Secret"
    echo "6) Exit"
    echo
}

process_choice() {
    case $1 in
        1)
            vault status
            ;;
        2)
            echo "Redirecting to Keycloak for OIDC Login..."
            vault login -method=oidc
            ;;
        3)
            vault policy list
            ;;
        4)
            read -p "Enter path to secret (e.g., secret/data/dev/my-app-db): " secret_path
            vault read "$secret_path"
            ;;
        5)
            read -p "Enter path to secret (e.g., secret/data/dev/my-app-db): " secret_path
            read -p "Enter key=value pair (e.g., password=mysecret): " data_to_write
            vault write "$secret_path" "$data_to_write"
            ;;
        6)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
}

# Loop the menu until the user exits
while true; do
    show_menu
    read -p "Enter your choice: " choice
    process_choice "$choice"
    echo
    read -p "Press Enter to continue..."
    clear
done
