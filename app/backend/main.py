# app/backend/main.py

import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from starlette.responses import HTMLResponse
from starlette.routing import Mount, Route

from .database import create_tables
from .routes import router as api_router, print_banner_on_startup # Import the router and the banner function

# --- CORE APPLICATION SETUP ---

app = FastAPI(
    title="Helix🐘️App API",
    version="v1",
    description="FastAPI backend 🐘️ for file upload to MinIO and webhook trigger"
)

# --- 1. MOUNT STATIC FILES ---
# Note: You should check the path 'backend/static' works relative to where you run uvicorn
app.mount("/static", StaticFiles(directory="backend/static"), name="static")

# --- 2. INCLUDE ALL API ROUTES ---
# The routes.py file will define all API endpoints under the /api prefix
app.include_router(api_router, prefix="/api")

# --- 3. SERVE HTML FORM ROUTE (Separate from /api router) ---
@app.get("/upload-form", response_class=HTMLResponse)
async def get_upload_form():
    """Serves the main HTML upload form."""
    # Note: Using a path relative to the project root might be safer
    try:
        with open("backend/static/helix-form.html", "r") as f:
            return f.read()
    except FileNotFoundError:
        return HTMLResponse("<h1>Error: helix-form.html not found.</h1>", status_code=500)

# --- 4. LIFECYCLE EVENTS (Startup/Shutdown) ---

@app.on_event("startup")
async def startup_event():
    # 🐘️ Database initialization: Call this once on startup
    print("🐘️ Initializing database tables...")
    create_tables() 
    
    # Print the cool banner!
    print_banner_on_startup() 

# No need for the other code (upload_files_and_log) here! It moves to routes.py.