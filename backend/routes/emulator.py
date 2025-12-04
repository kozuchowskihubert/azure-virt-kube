from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import httpx
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db
from ..config import settings

router = APIRouter()

# Pydantic models
class EmulatorStatus(BaseModel):
    status: str
    wine_version: str
    display: str
    vnc_available: bool

class ExecuteCommand(BaseModel):
    command: str
    args: Optional[List[str]] = []
    wine_prefix: Optional[str] = None

class CommandResponse(BaseModel):
    success: bool
    output: str
    error: Optional[str] = None

@router.get("/status", response_model=EmulatorStatus)
async def get_emulator_status():
    """Get Wine emulator status"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.WINE_SERVICE_URL}/health",
                timeout=10.0
            )
            
            if response.status_code == 200:
                return EmulatorStatus(
                    status="running",
                    wine_version="8.0",
                    display=":0",
                    vnc_available=True
                )
            else:
                raise HTTPException(status_code=503, detail="Wine service unavailable")
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Connection error: {str(e)}")

@router.post("/execute", response_model=CommandResponse)
async def execute_wine_command(command: ExecuteCommand):
    """Execute a Wine command"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.WINE_SERVICE_URL}/api/execute",
                json={
                    "command": command.command,
                    "args": command.args,
                    "wine_prefix": command.wine_prefix
                },
                timeout=30.0
            )
            
            if response.status_code == 200:
                data = response.json()
                return CommandResponse(
                    success=True,
                    output=data.get("output", ""),
                    error=data.get("error")
                )
            else:
                return CommandResponse(
                    success=False,
                    output="",
                    error=f"Command failed with status {response.status_code}"
                )
    except Exception as e:
        return CommandResponse(
            success=False,
            output="",
            error=str(e)
        )

@router.get("/info")
async def get_wine_info():
    """Get Wine configuration information"""
    return {
        "arch": "win64",
        "display": ":0",
        "vnc_port": 5900,
        "web_port": 8080,
        "supported_formats": [".exe", ".msi"],
        "features": [
            "x86 to x64 translation",
            "DirectX support",
            "Windows API compatibility",
            "GUI applications",
            "VNC remote access"
        ]
    }

@router.get("/screenshot")
async def get_screenshot():
    """Get current screen screenshot"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.WINE_SERVICE_URL}/api/screenshot",
                timeout=10.0
            )
            
            if response.status_code == 200:
                return {"screenshot": response.content.decode("base64")}
            else:
                raise HTTPException(status_code=500, detail="Screenshot failed")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Screenshot error: {str(e)}")
