from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql+asyncpg://admin:changeme123@postgres:5432/wine_emulator"
    )
    
    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379")
    
    # Wine Service
    WINE_SERVICE_URL: str = os.getenv("WINE_SERVICE_URL", "http://wine-emulator:8080")
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://frontend:3000",
        "http://localhost",
    ]
    
    # Application
    APP_NAME: str = "Wine Emulator API"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
