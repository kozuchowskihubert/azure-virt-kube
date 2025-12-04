from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, JSON
from datetime import datetime
from .config import settings

# Create async engine
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True
)

# Create async session factory
async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Base class for models
class Base(DeclarativeBase):
    pass

# Database models
class Application(Base):
    __tablename__ = "applications"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    executable_path = Column(String(500), nullable=False)
    description = Column(Text, nullable=True)
    icon_url = Column(String(500), nullable=True)
    wine_config = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)

class Session(Base):
    __tablename__ = "sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String(100), unique=True, index=True)
    application_id = Column(Integer, nullable=True)
    user_id = Column(String(100), nullable=True)
    vnc_port = Column(Integer, nullable=True)
    status = Column(String(50), default="pending")
    metadata = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)

class LowCodeComponent(Base):
    __tablename__ = "lowcode_components"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    component_type = Column(String(100), nullable=False)
    config = Column(JSON, nullable=False)
    position = Column(JSON, nullable=True)
    parent_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Dependency to get database session
async def get_db():
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
