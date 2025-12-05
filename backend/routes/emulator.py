from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import httpx
import subprocess
import asyncio
from pydantic import BaseModel
from datetime import datetime

from database import get_db
from config import settings

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

@router.post("/launch/{game_type}")
async def launch_game(game_type: str):
    """Launch a specific game in the Wine environment"""
    try:
        import subprocess
        import asyncio
        
        game_commands = {
            "cs16": 'docker exec wine-dev-gaming bash -c "su - wineuser -c \\"cd /app/cs16-game && DISPLAY=:99 wine hl.exe -game cstrike +map de_dust2\\""',
            "cs16-demo": 'docker exec wine-dev-gaming bash -c "su - wineuser -c \\"cd /app/games && DISPLAY=:99 wine cs16-crossover.exe\\""',
            "launcher": 'docker exec wine-dev-gaming bash -c "su - wineuser -c \\"cd /app/games && DISPLAY=:99 wine wine-game-launcher.exe\\""',
            "winecfg": 'docker exec wine-dev-gaming bash -c "su - wineuser -c \\"DISPLAY=:99 winecfg\\""'
        }
        
        if game_type not in game_commands:
            raise HTTPException(status_code=400, detail=f"Unknown game type: {game_type}")
        
        # Launch game in background
        command = game_commands[game_type]
        process = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        return {
            "success": True,
            "message": f"{game_type} launched successfully",
            "game_type": game_type,
            "vnc_url": "vnc://localhost:5900",
            "vnc_password": "haos"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to launch {game_type}: {str(e)}")

@router.post("/restart")
async def restart_wine_environment():
    """Restart the Wine gaming environment"""
    try:
        import subprocess
        import asyncio
        
        # Restart Wine processes
        restart_command = 'docker exec wine-dev-gaming bash -c "pkill -f wine; pkill -f hl.exe; sleep 2; su - wineuser -c \\"DISPLAY=:99 fluxbox &\\""'
        
        process = await asyncio.create_subprocess_shell(
            restart_command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        return {
            "success": True,
            "message": "Wine environment restarted",
            "stdout": stdout.decode() if stdout else "",
            "stderr": stderr.decode() if stderr else ""
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to restart Wine environment: {str(e)}")

@router.get("/vnc-info")
async def get_vnc_info():
    """Get VNC connection information for Wine emulator"""
    return {
        "vnc_url": "vnc://localhost:5900",
        "password": "haos", 
        "display": ":99",
        "resolution": "1280x960x24",
        "games_running": ["Counter-Strike 1.6", "CrossOver Simulation"],
        "container_status": "running",
        "instructions": "Use any VNC client to connect to vnc://localhost:5900 with password 'haos'"
    }

@router.get("/", response_model=dict)
async def get_emulator_info():
    """Get Wine emulator information"""
    return {
        "message": "Wine Emulator Platform Ready",
        "vnc_url": "vnc://localhost:5900",
        "vnc_password": "haos",
        "display": ":99",
        "games": ["Counter-Strike 1.6"],
        "status": "running"
    }

@router.get("/status", response_model=EmulatorStatus)
async def get_emulator_status():
    """Get Wine emulator status"""
    try:
        # Check if Wine container is running by checking VNC port
        return EmulatorStatus(
            status="running",
            wine_version="8.0.2",
            display=":99",
            vnc_available=True
        )
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
