# app/backend/routes.py
import os
import uuid
import sys
import requests 
from requests.exceptions import ConnectionError, Timeout 
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from starlette.status import HTTP_201_CREATED, HTTP_200_OK, HTTP_202_ACCEPTED 
from .minio_client import client, BUCKET_NAME
from .models import HelixN8NTable, UploadResponse
from .database import get_db
# ----------------------------------------------------
# ⚙️ CONFIGURATION CONSTANTS
# ----------------------------------------------------
# Base URL for n8n (can be an internal service name if running in Docker)
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL", "http://n8n:5678/webhook/msg_v1")
# The local API address ngrok exposes
# app/backend/routes.py
# ... other constants
# The new, correct address to reach the host machine from inside the Docker container
NGROK_API_URL = "http://ngrok:4040/api/tunnels"
# Fallback URL for n8n when ngrok is offline
FALLBACK_TEST_URL = "http://n8n:5678/webhook-test/msg_v1" 
NGROK_TIMEOUT = 2.0 
# ----------------------------------------------------
# Create an API Router instance
router = APIRouter()
# ----------------------------------------------------
# 🖼️ HELPER FUNCTIONS (Moved from main.py)
# ----------------------------------------------------
def print_banner_on_startup():
    """Function to print ASCII banner on application startup."""
    # Adjusted path logic to be relative to the file where uvicorn is run (likely the project root)
    try:
        # Assuming uvicorn is run from the project root: helix-lite-alpha/
        banner_path = os.path.join(os.getcwd(), "static", "banner.asc")
        with open(banner_path, 'r') as f:
            banner = f.read()
            print("\n" + banner + "\n")
    except FileNotFoundError:
        # Fallback if the path is wrong
        print("Banner file not found. Skipping banner display.")
    except Exception as e:
        print(f"Failed to display banner: {e}")
# ----------------------------------------------------
# ⬆️ API ENDPOINT: /upload (Moved from main.py)
# ----------------------------------------------------
@router.post("/upload", response_model=UploadResponse, status_code=HTTP_201_CREATED)
async def upload_files_and_log(
    profile_file: UploadFile = File(...),
    brief_letter: UploadFile = File(...),
    job_id: str = Form(...),
    user_email: str = Form(...),
    db: Session = Depends(get_db)
):
    """
    Handles file upload to MinIO and creates the initial database record.
    This replaces the entire 'upload_files_and_log' function from your old main.py.
    """
    guid = str(uuid.uuid4())

    try:
        # Use a database transaction to ensure atomicity
        with db.begin():
            # Step 1: Upload files to MinIO
            profile_object = f"contacts/{guid}/profile.txt"
            brief_object = f"contacts/{guid}/brief.txt"

            client.put_object(
                BUCKET_NAME, profile_object, profile_file.file, length=-1, part_size=10*1024*1024
            )
            client.put_object(
                BUCKET_NAME, brief_object, brief_letter.file, length=-1, part_size=10*1024*1024
            )

            profile_url = f"http://minio:9000/{BUCKET_NAME}/{profile_object}"
            brief_url = f"http://minio:9000/{BUCKET_NAME}/{brief_object}"

            # Step 2: Create a new record in the database
            new_record = HelixN8NTable(
                job_id=job_id,
                user_email=user_email,
                profile_url=profile_url,
                brief_url=brief_url,
                status='10_initial_upload',
            )
            db.add(new_record)

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process upload: {e}")

    # Step 3: Return the successful response
    return UploadResponse(
        uuid=guid,
        profile_url=profile_url,
        brief_url=brief_url,
        status="10_initial_upload",
    )
# ----------------------------------------------------
# 🩺 API ENDPOINT: /health
# ----------------------------------------------------
@router.get("/health")
async def health_check():
    """Checks the health of the MinIO client."""
    try:
        client.list_buckets()
        return {"status": "ok", "minio": "connected"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {e}")
# ----------------------------------------------------
# 🌐 API ENDPOINT: /ngrok_status (Your new logic)
# ----------------------------------------------------
@router.get("/ngrok_status")
async def get_ngrok_status():
    """
    Checks the local ngrok API to find the active public URL.
    Returns the URL with 'live' mode if ngrok is active (200 OK).
    Returns a fallback URL with 'test' mode if ngrok is offline (202 Accepted).
    """
    try:
        # 🎣 Try to reach the ngrok API (the correct URL: http://127.0.0.1:4040/api/tunnels)
        response = requests.get(NGROK_API_URL, timeout=NGROK_TIMEOUT)
        response.raise_for_status() 

        data = response.json()
        
        # 🔍 Look for the secure HTTPS tunnel 
        ngrok_url = None
        for tunnel in data.get('tunnels', []):
            if tunnel.get('proto') == 'https':
                ngrok_url = tunnel['public_url']
                break
        
        if ngrok_url:
            print(f"✅ Ngrok active. Returning URL: {ngrok_url}")
            return {
                "status": "ngrok_active",
                "mode": "live",
                "url": ngrok_url,
            }
        
        print("⚠️ Ngrok API active, but no HTTPS tunnel found. Falling back to test URL.")
        return {
            "status": "ngrok_no_tunnel",
            "mode": "test",
            "url": FALLBACK_TEST_URL,
        }

    except (ConnectionError, Timeout) as e:
        # ❌ ngrok is not running, API unreachable, or timed out.
        print(f"🛑 Ngrok API not reachable or timed out ({e}). Falling back to test URL.")
        return {
            "status": "ngrok_offline",
            "mode": "test",
            "url": FALLBACK_TEST_URL,
        }
    except Exception as e:
        # 💥 Catch any other errors
        print(f"🔥 An unexpected error occurred: {e}. Falling back to test URL.")
        return {
            "status": "error",
            "mode": "test",
            "url": FALLBACK_TEST_URL,
        }