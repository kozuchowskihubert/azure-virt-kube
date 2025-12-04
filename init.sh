#!/bin/bash

# Wine Emulator Platform - Initialization Script
echo "🍷 Initializing Wine Emulator Platform..."
echo "========================================="

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p backend/routes
mkdir -p frontend/src/{app,components,lib}
mkdir -p frontend/src/app/api/health
mkdir -p wine-service
mkdir -p k8s
mkdir -p helm/wine-emulator/templates
mkdir -p terraform
mkdir -p .github/workflows
mkdir -p nginx

# Create environment files
echo "📝 Creating environment configuration files..."

# Backend .env
if [ ! -f backend/.env ]; then
  cp backend/.env.example backend/.env
  echo "✅ Created backend/.env"
fi

# Frontend .env.local
if [ ! -f frontend/.env.local ]; then
  cp frontend/.env.example frontend/.env.local
  echo "✅ Created frontend/.env.local"
fi

# Initialize npm in frontend
if [ ! -f frontend/package-lock.json ]; then
  echo "📦 Installing frontend dependencies..."
  cd frontend && npm install && cd ..
  echo "✅ Frontend dependencies installed"
fi

# Create k3d cluster for local development
echo "☸️  Checking k3d cluster..."
if ! k3d cluster list | grep -q wine-emulator; then
  echo "Creating k3d cluster..."
  k3d cluster create wine-emulator \
    --api-port 6550 \
    --port 8080:80@loadbalancer \
    --port 8443:443@loadbalancer
  echo "✅ k3d cluster created"
else
  echo "✅ k3d cluster already exists"
fi

# Initialize git repository if not already initialized
if [ ! -d .git ]; then
  echo "🔧 Initializing git repository..."
  git init
  git add .
  git commit -m "Initial commit: Wine Emulator Platform"
  echo "✅ Git repository initialized"
fi

echo ""
echo "🎉 Initialization complete!"
echo ""
echo "Next steps:"
echo "1. Review and update .env files in backend/ and frontend/"
echo "2. Start local development: make dev"
echo "3. Or deploy to cloud: ./deploy.sh"
echo ""
echo "For more information, see DOCUMENTATION.md"
