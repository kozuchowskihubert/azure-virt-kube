# Local Development & CI/CD Guide

## Overview
This guide covers local development setup, testing, and CI/CD pipeline optimization for the Wine Emulator Platform.

## 🏗️ Local Development Setup

### Prerequisites
- Docker Desktop installed and running
- Node.js 20+ (for frontend development)
- Python 3.11+ (for backend development)
- Git

### Quick Start

#### 1. Build and Start Services
```bash
# Build and start development environment (backend + frontend only)
docker compose -f docker-compose.dev.yml up --build -d

# Check service status
docker compose -f docker-compose.dev.yml ps

# View logs
docker compose -f docker-compose.dev.yml logs -f
```

#### 2. Access Services
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

#### 3. Stop Services
```bash
docker compose -f docker-compose.dev.yml down
```

### Development Workflow

#### Backend Development (FastAPI)
```bash
# Run backend locally (outside Docker)
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="postgresql://admin:changeme123@localhost:5432/wine_emulator"
export REDIS_URL="redis://localhost:6379"

# Run with hot reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### Frontend Development (Next.js)
```bash
# Run frontend locally (outside Docker)
cd frontend
npm install

# Set environment variables
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
echo "NEXT_PUBLIC_WINE_VNC_URL=http://localhost:8080" >> .env.local

# Run development server
npm run dev
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest
pytest --cov=. --cov-report=html
```

### Frontend Tests
```bash
cd frontend
npm test
npm run test:coverage
```

### Local Integration Tests
```bash
# Start all services
docker compose -f docker-compose.dev.yml up -d

# Run integration tests
./scripts/test-integration.sh

# Stop services
docker compose -f docker-compose.dev.yml down
```

## 🚀 CI/CD Pipeline

### GitHub Actions Workflows

#### 1. **PR Checks** (`.github/workflows/pr-check.yml`)
Runs on pull requests:
- ✅ Lint backend (Python)
- ✅ Lint frontend (TypeScript)
- ✅ Test backend
- ✅ Test frontend
- ✅ Build test
- 🔒 Security scan

#### 2. **Docker Build** (`.github/workflows/docker-build.yml`)
Tests Docker builds locally:
- Builds all services
- Tests container startup
- Validates health checks

#### 3. **Azure Deploy** (`.github/workflows/azure-deploy.yml`)
Full deployment pipeline:
- **Stage 0**: Build & push Docker images to ACR
  - Backend (linux/amd64)
  - Frontend (linux/amd64)
  - Wine Service (linux/arm64)
- **Stage 1**: Deploy to Azure Container Apps
  - Deploy wine service
  - Deploy backend
- **Stage 2**: Deploy frontend
- **Stage 3**: Deployment summary

### Optimizing CI/CD

#### Current Issues & Fixes

1. **Docker Build Context**
   - ✅ Fixed: Changed from root context to service-specific contexts
   - Before: `context: .` + `dockerfile: backend/Dockerfile`
   - After: `context: ./backend` + `dockerfile: Dockerfile`

2. **Image Caching**
   - Uses ACR build cache: `--cache-from type=registry,ref=wineemulatoracr.azurecr.io/backend:buildcache`
   - Cache mode: `max` for maximum layer caching

3. **Parallel Builds**
   - Matrix strategy builds 3 images in parallel
   - Reduces total build time from ~15min to ~5min

4. **Deployment Strategy**
   - Sequential deployment with dependencies
   - Wine service → Backend → Frontend
   - Ensures services are available when needed

### Running CI/CD Locally with `act`

```bash
# Install act (if not already installed)
brew install act

# Configure act
mkdir -p ~/Library/Application\ Support/act
cat > ~/Library/Application\ Support/act/actrc << 'EOF'
-P ubuntu-latest=catthehacker/ubuntu:full-latest
--container-daemon-socket -
EOF

# Run specific workflow
act -j build-local --container-architecture linux/amd64

# Run with secrets (for Azure deploy)
act -j build-and-push-images --secret-file .secrets
```

### Secrets Management

Required secrets in GitHub:
```
# Azure Authentication
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID

# Azure Resources
AZURE_RESOURCE_GROUP
ACR_NAME
ACR_LOGIN_SERVER
ACR_PASSWORD

# Service Endpoints
BACKEND_CONTAINER_APP
FRONTEND_CONTAINER_APP  
WINE_SERVICE_CONTAINER_APP

# Database & Cache
DATABASE_URL
REDIS_URL
REDIS_PASSWORD

# Application
SECRET_KEY
JWT_SECRET
```

## 📊 Monitoring Deployment

### Check GitHub Actions Status
```bash
# List recent runs
gh run list --limit 5

# Watch current run
gh run watch

# View logs
gh run view --log
```

### Check Azure Resources
```bash
# Container Apps status
az containerapp list --resource-group wine-emulator-rg --output table

# View logs
az containerapp logs show \
  --name wine-emulator-backend \
  --resource-group wine-emulator-rg \
  --follow

# Check revisions
az containerapp revision list \
  --name wine-emulator-backend \
  --resource-group wine-emulator-rg \
  --output table
```

## 🔄 Continuous Improvement

### Performance Optimizations
1. **Build Time**
   - ✅ Multi-stage builds
   - ✅ Layer caching
   - ✅ Parallel matrix builds
   - 🔄 BuildKit optimizations

2. **Image Size**
   - Backend: ~200MB (Python slim)
   - Frontend: ~150MB (Node alpine + multi-stage)
   - Wine Service: ~2GB (includes Wine + dependencies)

3. **Deployment Speed**
   - Pull from ACR: ~30s
   - Container startup: ~10s
   - Health check: ~5s
   - Total: ~45s per service

### Next Steps
- [ ] Add smoke tests after deployment
- [ ] Implement blue-green deployment
- [ ] Add automatic rollback on failure
- [ ] Set up monitoring with Application Insights
- [ ] Configure auto-scaling rules
- [ ] Add deployment notifications (Slack/Teams)
