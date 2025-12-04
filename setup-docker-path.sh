#!/bin/bash

# Wine Emulator Platform - Docker Path Setup
# This script ensures Docker is in your PATH

echo "🔧 Setting up Docker environment..."

# Add Docker to PATH
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

# Verify Docker is accessible
if command -v docker &> /dev/null; then
    echo "✅ Docker is now accessible"
    docker --version
else
    echo "❌ Docker not found. Please ensure Docker Desktop is installed."
    exit 1
fi

# Verify Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose (standalone) found"
    docker-compose --version
elif docker compose version &> /dev/null; then
    echo "✅ Docker Compose (plugin) found"
    docker compose version
else
    echo "⚠️  Docker Compose not found"
fi

echo ""
echo "Docker environment is ready!"
echo ""
echo "Add this to your ~/.zshrc to make it permanent:"
echo 'export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"'
