# app/backend/models.py
import uuid
from typing import Optional

from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from .database import Base


class HelixN8NTable(Base):
    """
    Represents the database table for tracking documents and their workflow status.
    """
    __tablename__ = 'helix_n8n_table'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    job_id = Column(String, nullable=True)
    user_email = Column(String, nullable=True)
    profile_url = Column(String, nullable=True)
    brief_url = Column(String, nullable=True)
    status = Column(String, default="10_initial_upload")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    webhook_triggered = Column(Boolean, default=False)
    offer_status = Column(String, nullable=True)
    booking_link = Column(String, nullable=True)
    notes = Column(String, nullable=True)


class UploadResponse(BaseModel):
    """
    Pydantic model for the API response after a successful upload.
    We have removed 'webhook_triggered' as the API no longer performs this action directly.
    """
    uuid: uuid.UUID
    profile_url: str
    brief_url: str
    status: str
    model_config = ConfigDict(from_attributes=True)


class WebhookPayload(BaseModel):
    """
    Pydantic model for the webhook payload.
    """
    uuid: str
    profile_url: str
    brief_url: str
    params: dict
    webhook_triggered: bool
