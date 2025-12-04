from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import httpx
import os
from typing import List, Dict, Any
import asyncio
import logging

from routes import emulator, applications, sessions, lowcode
from database import engine, Base
from config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create database tables
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Wine Emulator API...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database initialized")
    yield
    # Shutdown
    logger.info("Shutting down Wine Emulator API...")

# Initialize FastAPI app
app = FastAPI(
    title="Wine Emulator API",
    description="Low-code/No-code Wine Emulator Platform API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(emulator.router, prefix="/api/emulator", tags=["Emulator"])
app.include_router(applications.router, prefix="/api/applications", tags=["Applications"])
app.include_router(sessions.router, prefix="/api/sessions", tags=["Sessions"])
app.include_router(lowcode.router, prefix="/api/lowcode", tags=["Low-Code Builder"])

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "wine-emulator-api"}

@app.get("/ready")
async def ready_check():
    try:
        # Check database connection
        async with engine.connect() as conn:
            await conn.execute("SELECT 1")
        
        # Check Wine service connection
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.WINE_SERVICE_URL}/health",
                timeout=5.0
            )
            if response.status_code != 200:
                raise HTTPException(status_code=503, detail="Wine service not ready")
        
        return {"status": "ready", "service": "wine-emulator-api"}
    except Exception as e:
        logger.error(f"Ready check failed: {e}")
        raise HTTPException(status_code=503, detail=f"Service not ready: {str(e)}")

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "Wine Emulator Low-Code Platform API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }

# WebSocket for real-time updates
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f"Message received: {data}")
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
