#!/bin/bash
# caz
# Find the Vault container's IP address
VAULT_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' infra-lite-vault-1)

# Export the Vault address
export VAULT_ADDR="http://${VAULT_IP}:8200"

# Export your root token. REPLACE <YOUR_ROOT_TOKEN> WITH YOUR ACTUAL TOKEN.
export VAULT_TOKEN="Au4r8Wl3qomC9RBc6E2nwbJvqoIGLgGIB23xmWUJ4ic="

# Now, run your command. It will work because you are authenticated.
vault policy read n8n-policy

# Or to create the policy again
# vault policy write n8n-policy n8n-policy.hcl
