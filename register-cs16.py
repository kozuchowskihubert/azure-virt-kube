#!/usr/bin/env python3
"""
Register Counter-Strike 1.6 application in the Wine Emulator Platform database
"""
import asyncio
import json
import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

from database import async_session, Application, Base, engine
from sqlalchemy import select


async def register_cs16():
    """Register Counter-Strike 1.6 in the database"""
    
    print("🎮 Registering Counter-Strike 1.6...")
    
    # Create tables if they don't exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Application configuration
    cs16_config = {
        "name": "Counter-Strike 1.6",
        "executable_path": "/app/games/cs16/hl.exe",
        "description": "Counter-Strike 1.6 (non-steam) - The legendary tactical FPS game. "
                      "Join the counter-terrorists or terrorists in classic maps like de_dust2, "
                      "de_inferno, and cs_office. Features realistic weapons, team-based gameplay, "
                      "and competitive action.",
        "icon_url": "https://upload.wikimedia.org/wikipedia/en/6/6e/Counter-Strike_box.jpg",
        "wine_config": {
            "WINEPREFIX": "/root/.wine",
            "WINEARCH": "win32",
            "WINEDEBUG": "-all",
            "DISPLAY": ":99",
            "working_directory": "/app/games/cs16",
            "arguments": [
                "-game", "cstrike",
                "-console",
                "-nojoy",
                "-noipx",
                "-nomaster",
                "+maxplayers", "32",
                "+map", "de_dust2",
                "+sv_lan", "1"
            ],
            "environment": {
                "MESA_GL_VERSION_OVERRIDE": "3.3",
                "__GL_SHADER_DISK_CACHE": "1",
                "WINE_CPU_TOPOLOGY": "4:4"
            },
            "graphics": {
                "renderer": "opengl",
                "resolution": "1280x960",
                "bpp": 32,
                "vsync": False
            },
            "audio": {
                "driver": "alsa",
                "quality": "high"
            }
        }
    }
    
    async with async_session() as session:
        # Check if CS 1.6 already exists
        result = await session.execute(
            select(Application).where(Application.name == cs16_config["name"])
        )
        existing = result.scalar_one_or_none()
        
        if existing:
            print(f"⚠️  Application '{cs16_config['name']}' already exists (ID: {existing.id})")
            print("🔄 Updating configuration...")
            
            existing.executable_path = cs16_config["executable_path"]
            existing.description = cs16_config["description"]
            existing.icon_url = cs16_config["icon_url"]
            existing.wine_config = cs16_config["wine_config"]
            existing.is_active = True
            
            await session.commit()
            print(f"✅ Updated Counter-Strike 1.6 (ID: {existing.id})")
            return existing.id
        else:
            # Create new application
            app = Application(**cs16_config)
            session.add(app)
            await session.commit()
            await session.refresh(app)
            
            print(f"✅ Registered Counter-Strike 1.6 (ID: {app.id})")
            return app.id


async def list_applications():
    """List all registered applications"""
    print("\n📋 Registered Applications:")
    print("-" * 80)
    
    async with async_session() as session:
        result = await session.execute(select(Application).where(Application.is_active == True))
        apps = result.scalars().all()
        
        if not apps:
            print("No applications registered yet.")
            return
        
        for app in apps:
            print(f"\n🎮 {app.name} (ID: {app.id})")
            print(f"   📁 Executable: {app.executable_path}")
            print(f"   📝 Description: {app.description[:100]}...")
            print(f"   🍷 Wine Prefix: {app.wine_config.get('WINEPREFIX', 'N/A')}")
            print(f"   ⏰ Created: {app.created_at}")


async def main():
    """Main function"""
    try:
        # Register CS 1.6
        app_id = await register_cs16()
        
        # List all applications
        await list_applications()
        
        print("\n" + "=" * 80)
        print("🎯 Next Steps:")
        print(f"1. Run setup script: chmod +x setup-cs16.sh && ./setup-cs16.sh")
        print(f"2. Copy CS 1.6 files to /app/games/cs16/")
        print(f"3. Launch through API: POST /api/sessions/create with application_id={app_id}")
        print(f"4. Connect via VNC to play!")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
