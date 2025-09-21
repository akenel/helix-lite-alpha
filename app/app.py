# 🐍 Minimal Flask Presign/Rename Service
# 🐍 Minimal Flask Presign/Rename Service
import uuid
import requests
from minio import Minio
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask import send_from_directory

CORS(app)
app = Flask(__name__)

# Connect to MinIO (use service name from docker-compose)
client = Minio(
    "minio:9000", 
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False,
)

@app.route("/")
def index():
    return send_from_directory(".", "index.html")  # serve your form

@app.route("/process", methods=["POST"])
def process():
    data = request.json
    bucket = data["bucket"]
    tmp_key = data["tmp_key"]
    file_type = data["file_type"]  # "profile" or "brief"

    # Generate UUID
    guid = str(uuid.uuid4())

    # New object key
    new_key = f"contacts/{file_type}s/{guid}__{tmp_key.split('/')[-1]}"

    # Copy (rename) object
    client.copy_object(bucket, new_key, f"/{bucket}/{tmp_key}")
    client.remove_object(bucket, tmp_key)

    # Presigned URL (1 hour)
    url = client.presigned_get_object(bucket, new_key, expires=3600)

    return jsonify({"uuid": guid, "new_key": new_key, "url": url})

##########

@app.route("/upload", methods=["POST"])
def upload():
    # Get the files from the form-data request
    profile_file = request.files.get("profile_file")
    brief_letter = request.files.get("brief_letter")
    
    # Generate UUID for the database entry
    guid = str(uuid.uuid4())
    
    # Upload profile to MinIO
    profile_object_name = f"contacts/{guid}-profile.txt"
    client.put_object(
        "helix-lite-alpha", profile_object_name, profile_file.stream, length=-1, part_size=10*1024*1024
    )
    
    # Upload brief to MinIO
    brief_object_name = f"contacts/{guid}-brief.txt"
    client.put_object(
        "helix-lite-alpha", brief_object_name, brief_letter.stream, length=-1, part_size=10*1024*1024
    )

    # Return the data to n8n
    return jsonify({
        "uuid": guid,
        "profile_url": f"/helix-lite-alpha/{profile_object_name}",
        "brief_url": f"/helix-lite-alpha/{brief_object_name}",
    })

@app.route("/ngrok-url", methods=["GET"])
def get_ngrok_url():
    """
    This function makes an internal, server-side call to the Ngrok API
    and returns the public HTTPS URL. This bypasses the CORS issue.
    """
    try:
        # Make the request to the Ngrok API
        ngrok_res = requests.get('http://127.0.0.1:4040/api/tunnels', timeout=5)
        
        # Raise an exception for bad status codes (4xx or 5xx)
        ngrok_res.raise_for_status()

        data = ngrok_res.json()
        
        # Find the public HTTPS tunnel
        https_tunnel = next((t for t in data.get('tunnels', []) if t.get('proto') == 'https'), None)

        if https_tunnel:
            ngrok_url = https_tunnel.get('public_url')
            # Return the URL in a JSON response
            return jsonify({"ngrokUrl": ngrok_url})
        else:
            return jsonify({"error": "HTTPS tunnel not found."}), 404
            
    except requests.exceptions.RequestException as e:
        print(f"Error fetching Ngrok URL: {e}")
        return jsonify({"error": "Failed to retrieve Ngrok URL."}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)