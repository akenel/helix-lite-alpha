#!/bin/bash
# 🥷 Oracle Webhook Tester – Chuck Norris style 💥
# Prompts for input but provides sensible defaults if you just smash ENTER

# --- Defaults ---
DEFAULT_EMAIL="candidate1@example.com"
DEFAULT_NAME="Larry Legend"
DEFAULT_JOB_ROLE="Data Scientist"
DEFAULT_PROMPT_TYPE="general"
DEFAULT_PROFILE="Experienced in Python, ML, AI. Strong communicator."
DEFAULT_JD="We are seeking a Data Scientist to build ML pipelines and deliver insights."
DEFAULT_URL="http://localhost:5678/webhook/oracle-podcast_v6"

# --- Prompt user ---
read -p "📧 Candidate Email [${DEFAULT_EMAIL}]: " EMAIL
EMAIL="${EMAIL:-$DEFAULT_EMAIL}"

read -p "👤 Candidate Name [${DEFAULT_NAME}]: " NAME
NAME="${NAME:-$DEFAULT_NAME}"

read -p "💼 Job Role [${DEFAULT_JOB_ROLE}]: " JOB_ROLE
JOB_ROLE="${JOB_ROLE:-$DEFAULT_JOB_ROLE}"

read -p "📜 Prompt Type [${DEFAULT_PROMPT_TYPE}]: " PROMPT_TYPE
PROMPT_TYPE="${PROMPT_TYPE:-$DEFAULT_PROMPT_TYPE}"

read -p "🧑‍💻 CV Profile Text [${DEFAULT_PROFILE}]: " PROFILE
PROFILE="${PROFILE:-$DEFAULT_PROFILE}"

read -p "📄 Job Description [${DEFAULT_JD}]: " JD
JD="${JD:-$DEFAULT_JD}"

read -p "🌐 Webhook URL [${DEFAULT_URL}]: " URL
URL="${URL:-$DEFAULT_URL}"

# --- JSON Payload ---
JSON_PAYLOAD=$(cat <<EOF
{
  "query": {
    "email": "$EMAIL",
    "guest_name": "$NAME",
    "job_role": "$JOB_ROLE",
    "prompt_type": "$PROMPT_TYPE"
  },
  "body": {
    "guest_email": "$EMAIL",
    "guest_name": "$NAME",
    "profile_text": "$PROFILE",
    "job_description": "$JD"
  }
}
EOF
)

# --- Curl Command ---
echo "🚀 Firing Chuck Norris Roundhouse Kick to $URL ..."
echo "📦 Payload:"
echo "$JSON_PAYLOAD" | jq .

curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"

echo -e "\n✅ Test Complete. Chuck Norris approves 👊"
# --- End of Script ---th curl ---th curl ---