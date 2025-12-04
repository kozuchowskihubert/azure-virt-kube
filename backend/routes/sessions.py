from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from pydantic import BaseModel
from datetime import datetime, timedelta
import uuid

from ..database import get_db, Session

router = APIRouter()

# Pydantic models
class SessionCreate(BaseModel):
    application_id: int | None = None
    user_id: str | None = None
    duration_minutes: int = 60

class SessionResponse(BaseModel):
    id: int
    session_id: str
    application_id: int | None
    user_id: str | None
    vnc_port: int | None
    status: str
    metadata: dict | None
    created_at: datetime
    expires_at: datetime | None
    
    class Config:
        from_attributes = True

@router.post("/", response_model=SessionResponse, status_code=201)
async def create_session(
    session_data: SessionCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new emulation session"""
    session_id = str(uuid.uuid4())
    expires_at = datetime.utcnow() + timedelta(minutes=session_data.duration_minutes)
    
    db_session = Session(
        session_id=session_id,
        application_id=session_data.application_id,
        user_id=session_data.user_id,
        status="active",
        vnc_port=5900,
        expires_at=expires_at,
        metadata={"duration_minutes": session_data.duration_minutes}
    )
    
    db.add(db_session)
    await db.commit()
    await db.refresh(db_session)
    return db_session

@router.get("/", response_model=List[SessionResponse])
async def list_sessions(
    status: str | None = None,
    db: AsyncSession = Depends(get_db)
):
    """List all sessions"""
    query = select(Session)
    
    if status:
        query = query.where(Session.status == status)
    
    result = await db.execute(query)
    sessions = result.scalars().all()
    return sessions

@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get session by ID"""
    result = await db.execute(
        select(Session).where(Session.session_id == session_id)
    )
    session = result.scalar_one_or_none()
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    return session

@router.delete("/{session_id}")
async def terminate_session(
    session_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Terminate a session"""
    result = await db.execute(
        select(Session).where(Session.session_id == session_id)
    )
    session = result.scalar_one_or_none()
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    session.status = "terminated"
    await db.commit()
    return {"message": "Session terminated successfully"}
