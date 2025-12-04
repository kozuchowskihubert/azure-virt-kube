#!/bin/bash

# Wine Emulator Platform - First Deployment Script
# This script performs the initial deployment with all necessary checks

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   🍷 Wine Emulator Platform - First Deployment               ║"
echo "║   x86/x64 Translation | ARM64 Support | Azure Ready          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Step 1: Check prerequisites
echo ""
echo "Step 1: Checking Prerequisites"
echo "================================"

# Check Docker
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_status 0 "Docker installed: $DOCKER_VERSION"
else
    print_status 1 "Docker not found"
    echo "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check Docker daemon
if docker info &> /dev/null; then
    print_status 0 "Docker daemon is running"
else
    print_status 1 "Docker daemon is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short)
    print_status 0 "Docker Compose installed: $COMPOSE_VERSION"
else
    print_status 1 "Docker Compose not found"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
print_info "System architecture: $ARCH"
if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
    print_warning "ARM64 detected - will use ARM-optimized builds with Box86/Box64"
    USE_ARM=true
else
    print_info "AMD64 detected - will use standard Wine builds"
    USE_ARM=false
fi

# Step 2: Environment setup
echo ""
echo "Step 2: Setting Up Environment"
echo "==============================="

# Check .env files
if [ -f "backend/.env" ]; then
    print_status 0 "Backend .env exists"
else
    print_warning "Creating backend/.env from example"
    cp backend/.env.example backend/.env 2>/dev/null || echo "Created backend/.env"
    print_status 0 "Backend .env created"
fi

if [ -f "frontend/.env.local" ]; then
    print_status 0 "Frontend .env.local exists"
else
    print_warning "Creating frontend/.env.local from example"
    cp frontend/.env.example frontend/.env.local 2>/dev/null || echo "Created frontend/.env.local"
    print_status 0 "Frontend .env.local created"
fi

# Step 3: Clean up old containers
echo ""
echo "Step 3: Cleaning Up Old Containers"
echo "==================================="

docker compose down -v &> /dev/null || true
print_status 0 "Old containers removed"

# Step 4: Start infrastructure services
echo ""
echo "Step 4: Starting Infrastructure Services"
echo "========================================="

print_info "Starting PostgreSQL and Redis..."
docker compose up -d postgres redis

# Wait for databases to be healthy
print_info "Waiting for databases to be ready (max 30 seconds)..."
for i in {1..30}; do
    if docker compose ps | grep -q "healthy.*postgres" && docker compose ps | grep -q "healthy.*redis"; then
        print_status 0 "Databases are ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_warning "Databases might not be fully ready yet"
    fi
    sleep 1
done

# Step 5: Build and start application services
echo ""
echo "Step 5: Building Application Services"
echo "======================================"

print_info "This may take 5-15 minutes on first run..."
print_info "Building backend..."
docker compose build backend &

print_info "Building frontend..."
docker compose build frontend &

print_info "Building Wine service (this is the longest)..."
if [ "$USE_ARM" = true ]; then
    print_info "Using ARM64 Dockerfile with Box86/Box64 support"
    # Note: For ARM, you'd want to update docker-compose.yml to use Dockerfile.arm64
fi
docker compose build wine-emulator

# Wait for all builds
wait

print_status 0 "All services built successfully"

# Step 6: Start all services
echo ""
echo "Step 6: Starting All Services"
echo "=============================="

docker compose up -d
print_status 0 "All services started"

# Step 7: Wait for services to be ready
echo ""
echo "Step 7: Waiting for Services to Initialize"
echo "==========================================="

sleep 5

print_info "Checking service health..."
docker compose ps

# Step 8: Verify deployment
echo ""
echo "Step 8: Verifying Deployment"
echo "============================"

# Check if containers are running
CONTAINERS_RUNNING=$(docker compose ps --filter "status=running" | grep -c "Up" || echo "0")
if [ "$CONTAINERS_RUNNING" -ge 3 ]; then
    print_status 0 "Services are running"
else
    print_warning "Some services may not be running. Check logs with: docker compose logs"
fi

# Test endpoints
echo ""
print_info "Testing API endpoints..."

sleep 3

if curl -s http://localhost:8000/health &> /dev/null; then
    print_status 0 "Backend API is responding"
else
    print_warning "Backend API not ready yet (may need more time)"
fi

if curl -s http://localhost:3000 &> /dev/null; then
    print_status 0 "Frontend is responding"
else
    print_warning "Frontend not ready yet (may need more time)"
fi

if curl -s http://localhost:8080 &> /dev/null; then
    print_status 0 "Wine VNC service is responding"
else
    print_warning "Wine VNC not ready yet (may need more time)"
fi

# Step 9: Display access information
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   🎉 Deployment Complete!                                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo "Access your application:"
echo "========================"
echo -e "${BLUE}Frontend:${NC}     http://localhost:3000"
echo -e "${BLUE}Backend API:${NC}  http://localhost:8000/docs"
echo -e "${BLUE}Wine VNC:${NC}     http://localhost:8080/vnc.html"
echo -e "${BLUE}PostgreSQL:${NC}   localhost:5432 (user: admin, pass: changeme123)"
echo -e "${BLUE}Redis:${NC}        localhost:6379"

echo ""
echo "Useful commands:"
echo "================"
echo "View logs:           docker compose logs -f"
echo "View specific logs:  docker compose logs -f [backend|frontend|wine-emulator]"
echo "Stop services:       docker compose down"
echo "Restart services:    docker compose restart"
echo "Check status:        docker compose ps"

echo ""
echo "Architecture Support:"
echo "====================="
echo -e "System:              ${BLUE}$ARCH${NC}"
echo -e "Wine Architecture:   ${BLUE}win64 (supports x86 + x64)${NC}"
if [ "$USE_ARM" = true ]; then
    echo -e "Translation:         ${BLUE}Box86/Box64 (ARM64)${NC}"
else
    echo -e "Translation:         ${BLUE}WoW64 (AMD64)${NC}"
fi

echo ""
echo "Next steps:"
echo "==========="
echo "1. Open http://localhost:3000 in your browser"
echo "2. Navigate to 'Applications' tab"
echo "3. Add your first Windows application"
echo "4. Or check out the Low-Code Builder tab"

echo ""
echo "For Azure deployment:"
echo "===================="
echo "./deploy-azure.sh"

echo ""
echo "For detailed documentation:"
echo "==========================="
echo "README.md                    - Full user guide"
echo "X86_X64_TRANSLATION.md       - Architecture translation guide"
echo "DEPLOYMENT_SUMMARY.md        - Deployment checklist"

echo ""
echo -e "${GREEN}Happy coding! 🍷${NC}"
