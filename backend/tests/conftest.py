"""
Test configuration for Wine Emulator Backend API
"""
import pytest
import os
from fastapi.testclient import TestClient

# Test environment variables
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost:5432/test_db")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379")
os.environ.setdefault("WINE_SERVICE_URL", "http://localhost:8080")
os.environ.setdefault("SECRET_KEY", "test-secret-key")

@pytest.fixture
def client():
    """Create test client fixture"""
    from main import app
    return TestClient(app)