from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Dict, Any
from pydantic import BaseModel
from datetime import datetime

from database import get_db, LowCodeComponent

router = APIRouter()

# Pydantic models
class ComponentBase(BaseModel):
    name: str
    component_type: str
    config: Dict[str, Any]
    position: Dict[str, Any] | None = None
    parent_id: int | None = None

class ComponentCreate(ComponentBase):
    pass

class ComponentResponse(ComponentBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class WorkflowConfig(BaseModel):
    components: List[Dict[str, Any]]
    connections: List[Dict[str, Any]]

@router.get("/components", response_model=List[ComponentResponse])
async def list_components(
    component_type: str | None = None,
    db: AsyncSession = Depends(get_db)
):
    """List all low-code components"""
    query = select(LowCodeComponent)
    
    if component_type:
        query = query.where(LowCodeComponent.component_type == component_type)
    
    result = await db.execute(query)
    components = result.scalars().all()
    return components

@router.post("/components", response_model=ComponentResponse, status_code=201)
async def create_component(
    component: ComponentCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new low-code component"""
    db_component = LowCodeComponent(**component.model_dump())
    db.add(db_component)
    await db.commit()
    await db.refresh(db_component)
    return db_component

@router.get("/components/{component_id}", response_model=ComponentResponse)
async def get_component(
    component_id: int,
    db: AsyncSession = Depends(get_db)
):
    """Get component by ID"""
    result = await db.execute(
        select(LowCodeComponent).where(LowCodeComponent.id == component_id)
    )
    component = result.scalar_one_or_none()
    
    if not component:
        raise HTTPException(status_code=404, detail="Component not found")
    
    return component

@router.put("/components/{component_id}", response_model=ComponentResponse)
async def update_component(
    component_id: int,
    component_update: ComponentCreate,
    db: AsyncSession = Depends(get_db)
):
    """Update a component"""
    result = await db.execute(
        select(LowCodeComponent).where(LowCodeComponent.id == component_id)
    )
    db_component = result.scalar_one_or_none()
    
    if not db_component:
        raise HTTPException(status_code=404, detail="Component not found")
    
    for key, value in component_update.model_dump(exclude_unset=True).items():
        setattr(db_component, key, value)
    
    db_component.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(db_component)
    return db_component

@router.delete("/components/{component_id}")
async def delete_component(
    component_id: int,
    db: AsyncSession = Depends(get_db)
):
    """Delete a component"""
    result = await db.execute(
        select(LowCodeComponent).where(LowCodeComponent.id == component_id)
    )
    db_component = result.scalar_one_or_none()
    
    if not db_component:
        raise HTTPException(status_code=404, detail="Component not found")
    
    await db.delete(db_component)
    await db.commit()
    return {"message": "Component deleted successfully"}

@router.get("/templates")
async def get_component_templates():
    """Get available component templates"""
    return {
        "ui_components": [
            {"type": "button", "name": "Button", "icon": "🔘"},
            {"type": "input", "name": "Text Input", "icon": "📝"},
            {"type": "dropdown", "name": "Dropdown", "icon": "📋"},
            {"type": "file_upload", "name": "File Upload", "icon": "📁"},
        ],
        "logic_components": [
            {"type": "conditional", "name": "If/Else", "icon": "🔀"},
            {"type": "loop", "name": "Loop", "icon": "🔁"},
            {"type": "api_call", "name": "API Request", "icon": "🌐"},
        ],
        "wine_components": [
            {"type": "wine_execute", "name": "Execute Windows App", "icon": "🍷"},
            {"type": "wine_install", "name": "Install Application", "icon": "📦"},
            {"type": "wine_config", "name": "Configure Wine", "icon": "⚙️"},
        ]
    }

@router.post("/workflow/execute")
async def execute_workflow(workflow: WorkflowConfig):
    """Execute a low-code workflow"""
    # This would execute the workflow logic
    return {
        "status": "success",
        "message": "Workflow executed successfully",
        "components_executed": len(workflow.components)
    }
