# --- Step 1: Define variables for files and guest details ---

# Define the files to read
JD_FILE="my_jd.txt"
CV_FILE="my_cv.txt"
PROMPT_TYPE="general" # We'll stick with 'general' for now, but you can dynamically set this later!

# Read JD file, escape control characters and double quotes
JOB_DESC_ESCAPED=$(cat "$JD_FILE" | sed ':a;N;$!ba;s/\n/\\n/g;s/\t/\\t/g;s/"/\\"/g')

# Read CV file, escape control characters and double quotes
PROFILE_TEXT_ESCAPED=$(cat "$CV_FILE" | sed ':a;N;$!ba;s/\n/\\n/g;s/\t/\\t/g;s/"/\\"/g')

# --- Step 2: Define Guest details ---
# You can hardcode these, or if you parse them from the CV file, you can add that logic here.
GUEST_NAME="Angelo Kenel"
GUEST_EMAIL="theSAPspecialist@gmail.com"

# --- Step 3: Construct the JSON payload with all fields ---
JSON_PAYLOAD=$(printf '{
  "guest_name": "%s",
  "guest_email": "%s",
  "profile_text": "%s",
  "job_description": "%s",
  "prompt_type": "%s"
}' "$GUEST_NAME" "$GUEST_EMAIL" "$PROFILE_TEXT_ESCAPED" "$JOB_DESC_ESCAPED" "$PROMPT_TYPE")

# --- Step 4: Send the payload with curl ---
curl --location --request POST "http://localhost:5678/webhook-test/oracle-podcast_v3" \
--header 'Content-Type: application/json' \
--data-raw "$JSON_PAYLOAD"