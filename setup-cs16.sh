#!/bin/bash
set -e

# Counter-Strike 1.6 Setup Script for Wine Emulator Platform
# This script sets up CS 1.6 (non-steam) in the Wine environment

echo "🎮 Counter-Strike 1.6 Wine Emulator Setup"
echo "=========================================="

# Configuration
CS16_DIR="/app/games/cs16"
WINE_PREFIX="/root/.wine"
CS16_DOWNLOAD_URL="https://archive.org/download/counter-strike-1.6-non-steam/cstrike.zip"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create directory structure
echo -e "${BLUE}📁 Creating directory structure...${NC}"
mkdir -p $CS16_DIR
mkdir -p $WINE_PREFIX

# Install required Wine components
echo -e "${BLUE}🍷 Setting up Wine environment...${NC}"
export WINEPREFIX=$WINE_PREFIX
export WINEARCH=win32
export DISPLAY=:99

# Initialize Wine prefix
echo -e "${BLUE}⚙️  Initializing Wine prefix...${NC}"
wine wineboot --init 2>/dev/null || true
sleep 5

# Install essential Windows components via winetricks
echo -e "${BLUE}📦 Installing Windows dependencies...${NC}"
if command -v winetricks &> /dev/null; then
    winetricks -q directx9 d3dx9 vcrun2019 corefonts 2>/dev/null || echo "Winetricks installation encountered issues (may be expected)"
else
    echo -e "${RED}⚠️  Winetricks not found, skipping dependency installation${NC}"
fi

# Download Counter-Strike 1.6 (using a placeholder - user should provide their own files)
echo -e "${BLUE}📥 Preparing Counter-Strike 1.6 files...${NC}"
echo "Note: You need to provide your own CS 1.6 installation files."
echo "Expected structure: $CS16_DIR/cstrike/"

# Create sample directory structure
mkdir -p $CS16_DIR/cstrike
mkdir -p $CS16_DIR/valve
mkdir -p $CS16_DIR/platform

# Create launcher script
cat > $CS16_DIR/launch-cs16.sh << 'LAUNCHER'
#!/bin/bash
export WINEPREFIX=/root/.wine
export WINEARCH=win32
export DISPLAY=:99
export WINEDEBUG=-all

# Set graphics optimizations
export MESA_GL_VERSION_OVERRIDE=3.3
export __GL_SHADER_DISK_CACHE=1

# Launch CS 1.6
cd /app/games/cs16
wine hl.exe -game cstrike -console -nojoy -noipx +maxplayers 32 +map de_dust2
LAUNCHER

chmod +x $CS16_DIR/launch-cs16.sh

# Create README with instructions
cat > $CS16_DIR/README.md << 'README'
# Counter-Strike 1.6 Setup Instructions

## Installation

1. Copy your CS 1.6 files to `/app/games/cs16/`
2. Ensure `hl.exe` is in the root directory
3. Ensure `cstrike/` folder contains game files

## Expected Structure:
```
/app/games/cs16/
├── hl.exe                 # Half-Life executable
├── cstrike/              # Counter-Strike mod
│   ├── maps/            # Game maps
│   ├── models/          # Player models
│   ├── sprites/         # Sprites
│   └── gfx/             # Graphics
├── valve/               # Half-Life base files
└── platform/            # Platform files
```

## Launch

Run: `/app/games/cs16/launch-cs16.sh`

Or manually:
```bash
cd /app/games/cs16
wine hl.exe -game cstrike -console -nojoy -noipx +maxplayers 32 +map de_dust2
```

## Common Issues

- **Black screen**: Check DirectX installation
- **No sound**: Verify PulseAudio/ALSA configuration
- **Crashes**: Try adding `-gl` for OpenGL mode
- **Performance**: Use `-noforcemparms -noforcemaccel` for better mouse control
README

# Set registry settings for better game compatibility
echo -e "${BLUE}⚙️  Configuring registry settings...${NC}"
cat > /tmp/cs16-registry.reg << 'REGISTRY'
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="opengl"
"OffScreenRenderingMode"="fbo"
"VideoMemorySize"="2048"
"Multisampling"="enabled"
"StrictDrawOrdering"="enabled"

[HKEY_CURRENT_USER\Software\Wine\DirectSound]
"HelEmulation"="Enabled"
"MaxShadowSize"="0"

[HKEY_CURRENT_USER\Software\Valve\Half-Life\Settings]
"ScreenWidth"=dword:00000500
"ScreenHeight"=dword:000003c0
"ScreenBPP"=dword:00000020
REGISTRY

wine regedit /tmp/cs16-registry.reg 2>/dev/null || true

# Create application configuration for backend
echo -e "${BLUE}📝 Creating application configuration...${NC}"
cat > $CS16_DIR/app-config.json << 'APPCONFIG'
{
  "name": "Counter-Strike 1.6",
  "executable_path": "/app/games/cs16/hl.exe",
  "description": "Classic Counter-Strike 1.6 (non-steam) - The legendary tactical FPS game",
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
      "+maxplayers", "32",
      "+map", "de_dust2"
    ],
    "environment": {
      "MESA_GL_VERSION_OVERRIDE": "3.3",
      "__GL_SHADER_DISK_CACHE": "1"
    }
  }
}
APPCONFIG

echo -e "${GREEN}✅ Counter-Strike 1.6 setup completed!${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Copy your CS 1.6 files to: $CS16_DIR"
echo "2. Register the application in the backend database"
echo "3. Launch through the Wine Emulator Platform"
echo ""
echo "🎮 To test manually:"
echo "   cd $CS16_DIR && ./launch-cs16.sh"
echo ""
echo "📁 Configuration saved to: $CS16_DIR/app-config.json"
