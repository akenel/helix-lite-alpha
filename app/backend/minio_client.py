#  app/backend/minio_client.py
import os
from minio import Minio

MINIO_HOST = os.environ.get("MINIO_HOST", "minio")
MINIO_PORT = os.environ.get("MINIO_PORT", "9000")
MINIO_USER = os.environ.get("MINIO_USER", "minioadmin")
MINIO_PASS = os.environ.get("MINIO_PASS", "minioadmin")

client = Minio(
    f"{MINIO_HOST}:{MINIO_PORT}",
    access_key=MINIO_USER,  
    secret_key=MINIO_PASS,  
    secure=False
)

BUCKET_NAME = "helix-lite-alpha"

# Ensure bucket exists
found = client.bucket_exists(BUCKET_NAME)
if not found:
    client.make_bucket(BUCKET_NAME)
