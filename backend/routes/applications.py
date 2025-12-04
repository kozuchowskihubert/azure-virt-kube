from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db, Application

router = APIRouter()

# Pydantic models
class ApplicationBase(BaseModel):
    name: str
    executable_path: str
    description: str | None = None
    icon_url: str | None = None
    wine_config: dict | None = None

class ApplicationCreate(ApplicationBase):
    pass

class ApplicationResponse(ApplicationBase):
    id: int
    created_at: datetime
    updated_at: datetime
    is_active: bool
    
    class Config:
        from_attributes = True

@router.get("/", response_model=List[ApplicationResponse])
async def list_applications(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """List all applications"""
    result = await db.execute(
        select(Application)
        .where(Application.is_active == True)
        .offset(skip)
        .limit(limit)
    )
    applications = result.scalars().all()
    return applications

@router.post("/", response_model=ApplicationResponse, status_code=201)
async def create_application(
    app: ApplicationCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new application"""
    db_app = Application(**app.model_dump())
    db.add(db_app)
    await db.commit()
    await db.refresh(db_app)
    return db_app

@router.get("/{app_id}", response_model=ApplicationResponse)
async def get_application(
    app_id: int,
    db: AsyncSession = Depends(get_db)
):
    """Get application by ID"""
    result = await db.execute(
        select(Application).where(Application.id == app_id)
    )
    app = result.scalar_one_or_none()
    
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
    
    return app

@router.put("/{app_id}", response_model=ApplicationResponse)
async def update_application(
    app_id: int,
    app_update: ApplicationCreate,
    db: AsyncSession = Depends(get_db)
):
    """Update an application"""
    result = await db.execute(
        select(Application).where(Application.id == app_id)
    )
    db_app = result.scalar_one_or_none()
    
    if not db_app:
        raise HTTPException(status_code=404, detail="Application not found")
    
    for key, value in app_update.model_dump(exclude_unset=True).items():
        setattr(db_app, key, value)
    
    db_app.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(db_app)
    return db_app

@router.delete("/{app_id}")
async def delete_application(
    app_id: int,
    db: AsyncSession = Depends(get_db)
):
    """Delete (deactivate) an application"""
    result = await db.execute(
        select(Application).where(Application.id == app_id)
    )
    db_app = result.scalar_one_or_none()
    
    if not db_app:
        raise HTTPException(status_code=404, detail="Application not found")
    
    db_app.is_active = False
    await db.commit()
    return {"message": "Application deleted successfully"}
