# app/backend/database.py
import os

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Load environment variables
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_USER="helix_user"
POSTGRES_PASSWORD="helix_pass"
POSTGRES_DB="helix_db"
# Construct the database URL
SQLALCHEMY_DATABASE_URL = (
    f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@"
    f"{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
)

# Create the engine
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# Create the base class for declarative models
Base = declarative_base()

# Create a sessionmaker
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Function to get a database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Function to create all tables
def create_tables():
    """
    Creates all tables defined by the models that inherit from Base.
    This is useful for initial setup and testing.
    """
    print("Creating all database tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created successfully!")

# You can add a call to this function in your main application startup
# to ensure tables are created on first run. For example, in main.py:
# from .database import create_tables
# create_tables()
