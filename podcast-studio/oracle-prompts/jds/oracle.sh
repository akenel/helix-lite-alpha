#!/bin/bash
# 🤖 n8n Webhook Test Script 🚀
# Use -y for 'yes' click and -n for 'no' click.
# Example: ./test_webhook.sh -y --email "test@example.com"

# --- Constants & Defaults ---
DEFAULT_GUID="3d6df1f0b67f-default-guid"
DEFAULT_JOB_ROLE="Oracle Architect"
DEFAULT_EMAIL="candidate@example.com"
WEBHOOK_PATH="/webhook-test/accept"
ACTION=""

# --- Help Function ---
help_text() {
  echo "Usage: $0 [-y] [-n] [--guid <GUID>] [--email <EMAIL>] [--job <JOB_ROLE>] [--help]"
  echo ""
  echo "Simulates a candidate clicking 'Yes' or 'No' on an interview email."
  echo ""
  echo "Parameters:"
  echo "  -y                Simulate a 'yes' click. Sets status=yes."
  echo "  -n                Simulate a 'no' click. Sets status=no."
  echo "  --guid <GUID>     The unique tracking GUID. (Default: a simple placeholder)."
  echo "  --email <EMAIL>   The candidate's email address. (Default: ${DEFAULT_EMAIL})."
  echo "  --job <JOB_ROLE>  The job reference code. (Default: ${DEFAULT_JOB_ROLE})."
  echo "  --help            Show this help message."
  echo ""
  echo "Prerequisites:"
  echo "  1. n8n must be running locally."
  echo "  2. ngrok must be active and forwarding to n8n's port (e.g., ngrok http 5678)."
  echo ""
  echo "Example:"
  echo "  ./test_webhook.sh -y --email "jane.doe@example.com" --job "Senior Oracle Consultant""
}

# --- Parse Arguments ---
for arg in "$@"; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--guid") set -- "$@" "-g" ;;
    "--email") set -- "$@" "-e" ;;
    "--job") set -- "$@" "-j" ;;
    *) set -- "$@" "$arg"
  esac
done

while getopts "ynhg:e:j:" opt; do
  case $opt in
    y) ACTION="yes" ;;
    n) ACTION="no" ;;
    h) help_text; exit 0 ;;
    g) DEFAULT_GUID="$OPTARG" ;;
    e) DEFAULT_EMAIL="$OPTARG" ;;
    j) DEFAULT_JOB_ROLE="$OPTARG" ;;
    \?) echo "⚠️ Invalid option: -$OPTARG. See --help." >&2; exit 1 ;;
  esac
done

if [ -z "$ACTION" ]; then
  echo "⚠️ Error: You must specify either -y (yes) or -n (no). See --help." >&2; exit 1
fi

# --- Get the Ngrok URL dynamically ---
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')

if [ -z "$NGROK_URL" ]; then
  echo "❌ Error: Could not retrieve ngrok URL. Is ngrok running?" >&2
  exit 1
fi

echo "✅ Ngrok URL found: $NGROK_URL"
echo "🔧 Testing a '$ACTION' click..."

# --- Execute the Curl Command ---
curl -X POST \
  "$NGROK_URL$WEBHOOK_PATH?guid=$DEFAULT_GUID&email=$DEFAULT_EMAIL&job_role=$DEFAULT_JOB_ROLE&status=$ACTION" \
  --compressed

echo -e "\n🚀 Test complete."