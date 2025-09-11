#!/bin/bash

# --- Configuration & Defaults ---
DEFAULT_EMAIL="candidate@example.com"
DEFAULT_NAME="A. Tester"
DEFAULT_PROMPT_TYPE="general"
WEBHOOK_PATH="/webhook/oracle-podcast_v6" # This is the prod path
TEST_WEBHOOK_PATH="/webhook-test/oracle-podcast_v6" # This is the dev path
NGROK_URL=""
EMAIL=""
NAME=""
CV_FILE=""
JOB_FILE=""
PROMPT_TYPE=""
TEST_MODE=false
USE_TEST_PATH=false

# --- Help Function ---
help_text() {
  echo "Usage: $0 --email <EMAIL> --name <NAME> --cv <CV_PATH> --job <JOB_PATH> [OPTIONS]"
  echo ""
  echo "Submits a candidate's CV and a job description to the n8n webhook."
  echo ""
  echo "Required Flags:"
  echo "  --email <EMAIL>     Candidate's email address."
  echo "  --cv <FILE>         Path to the candidate's CV file."
  echo "  --job <FILE>        Path to the job description file."
  echo ""
  echo "Optional Flags:"
  echo "  --name <NAME>       Candidate's name. (Default: '$DEFAULT_NAME')"
  echo "  --prompt <TYPE>     Prompt type (e.g., general, technical). (Default: '$DEFAULT_PROMPT_TYPE')"
  echo "  --url <URL>         Override the default ngrok URL."
  echo "  -y, --test          Run a simple test with default values and test webhook path."
  echo "  --test-path         Use the test webhook path for a full manual run."
  echo "  --help              Show this help message."
  echo ""
  echo "Example:"
  echo "  $0 --email \"jane@example.com\" --cv \"jane_cv.txt\" --job \"senior_data_scientist.txt\""
  echo "  $0 -y               # Run test with defaults"
  exit 0
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --email) EMAIL="$2"; shift ;;
    --name) NAME="$2"; shift ;;
    --cv) CV_FILE="$2"; shift ;;
    --job) JOB_FILE="$2"; shift ;;
    --prompt) PROMPT_TYPE="$2"; shift ;;
    --url) NGROK_URL="$2"; shift ;;
    -y|--test) TEST_MODE=true ;;
    --test-path) USE_TEST_PATH=true ;;
    --help) help_text ;;
    *) echo "❌ Unknown parameter passed: $1"; help_text ;;
  esac
  shift
done

# --- Set defaults for test mode ---
if [ "$TEST_MODE" = true ]; then
  EMAIL="${EMAIL:-$DEFAULT_EMAIL}"
  NAME="${NAME:-$DEFAULT_NAME}"
  PROMPT_TYPE="${PROMPT_TYPE:-$DEFAULT_PROMPT_TYPE}"
  USE_TEST_PATH=true
  
  # Create temporary test files if not provided
  if [ -z "$CV_FILE" ]; then
    CV_FILE="/tmp/test_cv.txt"
    echo "Experienced software developer with 5 years in full-stack development." > "$CV_FILE"
  fi
  
  if [ -z "$JOB_FILE" ]; then
    JOB_FILE="/tmp/test_job.txt"
    echo "Senior Developer position requiring React, Node.js, and database experience." > "$JOB_FILE"
  fi
fi

# --- Error Handling ---
if [ -z "$EMAIL" ] || [ -z "$CV_FILE" ] || [ -z "$JOB_FILE" ]; then
  echo "❌ Error: Missing required flags." >&2
  help_text
fi

if [ ! -f "$CV_FILE" ]; then
  echo "❌ Error: CV file not found at '$CV_FILE'." >&2
  exit 1
fi
if [ ! -f "$JOB_FILE" ]; then
  echo "❌ Error: Job file not found at '$JOB_FILE'." >&2
  exit 1
fi

# --- Get Ngrok URL ---
if [ -z "$NGROK_URL" ]; then
  echo "🔍 Fetching ngrok URL..."
  NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')
  if [ -z "$NGROK_URL" ] || [ "$NGROK_URL" = "null" ]; then
    echo "❌ Error: Could not retrieve ngrok URL. Is ngrok running?" >&2
    exit 1
  fi
fi

echo "✅ Ngrok URL found: $NGROK_URL"

# --- Set default name and prompt type if not provided ---
NAME="${NAME:-$DEFAULT_NAME}"
PROMPT_TYPE="${PROMPT_TYPE:-$DEFAULT_PROMPT_TYPE}"

# --- Read File Contents and escape with jq ---
# Read the file content and use jq's @json filter to escape it.
CV_CONTENT=$(cat "$CV_FILE" | jq -Rsa '.')
JOB_CONTENT=$(cat "$JOB_FILE" | jq -Rsa '.')

if [ "$TEST_MODE" = true ]; then
  echo "🔧 Running in simple test mode..."
fi

# --- Determine Webhook URL ---
if [ "$USE_TEST_PATH" = true ]; then
  FULL_WEBHOOK_URL="$NGROK_URL$TEST_WEBHOOK_PATH"
else
  FULL_WEBHOOK_URL="$NGROK_URL$WEBHOOK_PATH"
fi

# --- JSON Payload Construction ---
JSON_PAYLOAD=$(cat <<EOF
{
  "body": {
    "guest_email": "$EMAIL",
    "guest_name": "$NAME",
    "profile_text": $CV_CONTENT,
    "job_description": $JOB_CONTENT,
    "prompt_type": "$PROMPT_TYPE"
  }
}
EOF
)

# --- The Final Curl Command ---
echo "✅ Submitting data to webhook..."
echo "📦 Payload:"
echo "$JSON_PAYLOAD" | jq .
echo ""
echo "🌐 Full URL: $FULL_WEBHOOK_URL"
echo ""

curl -X POST "$FULL_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"

# --- Cleanup temporary files if in test mode ---
if [ "$TEST_MODE" = true ]; then
  rm -f "/tmp/test_cv.txt" "/tmp/test_job.txt"
fi

echo -e "\n🚀 Test complete."