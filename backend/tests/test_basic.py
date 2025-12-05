"""
Basic health check tests for Wine Emulator Backend API
"""

def test_health_endpoint():
    """Test basic health endpoint functionality"""
    from main import app
    from fastapi.testclient import TestClient
    
    client = TestClient(app)
    response = client.get("/health")
    
    assert response.status_code == 200
    assert "status" in response.json()
    assert response.json()["status"] == "healthy"

def test_ready_endpoint():
    """Test ready endpoint functionality"""
    from main import app
    from fastapi.testclient import TestClient
    
    client = TestClient(app)
    response = client.get("/ready")
    
    # Should return 200 or 503 depending on services availability
    assert response.status_code in [200, 503]
    assert "status" in response.json()

def test_emulator_info_endpoint():
    """Test wine emulator info endpoint"""
    from main import app
    from fastapi.testclient import TestClient
    
    client = TestClient(app)
    response = client.get("/api/emulator/info")
    
    assert response.status_code == 200
    data = response.json()
    assert "arch" in data
    assert "supported_formats" in data
    assert data["arch"] == "win64"

def test_basic_import():
    """Test that basic imports work"""
    try:
        from config import settings
        from database import Base
        assert settings is not None
        assert Base is not None
    except ImportError as e:
        assert False, f"Import failed: {e}"