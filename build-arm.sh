#!/bin/bash
# Build script for ARM64 Wine Emulator Platform
# Supports both single-arch and multi-arch builds

set -e

echo "🍷 Building ARM64-Compatible Wine Emulator Platform"
echo "====================================================="

# Parse arguments
BUILD_MODE="${1:-single}"  # single, multi, or all
PUSH_IMAGES="${2:-false}"  # Push to registry

# Check if running on ARM
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
    echo "✅ ARM64 architecture detected"
    NATIVE_ARM=true
else
    echo "⚠️  Building for ARM64 on $ARCH architecture (cross-compile)"
    NATIVE_ARM=false
fi

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo "❌ Docker buildx not found. Installing..."
    docker buildx create --use --name multi-arch-builder || true
fi

# Ensure buildx builder exists
docker buildx use multi-arch-builder 2>/dev/null || docker buildx create --use --name multi-arch-builder

echo ""
echo "Build mode: $BUILD_MODE"
echo ""

# Function to build single architecture
build_single_arch() {
    local platform=$1
    local tag_suffix=$2
    
    echo "📦 Building for platform: $platform"
    
    # Build Wine Service
    echo "Building wine-service..."
    if [[ "$platform" == "linux/arm64" ]]; then
        docker buildx build \
            --platform "$platform" \
            -f wine-service/Dockerfile.arm64 \
            -t wine-emulator-arm64:latest \
            -t wine-emulator:arm64 \
            --load \
            .
    else
        docker buildx build \
            --platform "$platform" \
            -f wine-service/Dockerfile \
            -t wine-emulator:latest \
            -t wine-emulator:amd64 \
            --load \
            .
    fi
    
    # Build Backend
    echo "Building backend..."
    docker buildx build \
        --platform "$platform" \
        -f backend/Dockerfile \
        -t wine-backend:$tag_suffix \
        --load \
        .
    
    # Build Frontend
    echo "Building frontend..."
    docker buildx build \
        --platform "$platform" \
        -f frontend/Dockerfile \
        -t wine-frontend:$tag_suffix \
        --load \
        .
}

# Function to build multi-architecture
build_multi_arch() {
    echo "📦 Building multi-architecture images (linux/amd64,linux/arm64)..."
    
    local push_flag=""
    if [[ "$PUSH_IMAGES" == "true" ]]; then
        push_flag="--push"
    else
        push_flag="--load"
    fi
    
    # Build Wine Service (multi-arch)
    echo "Building wine-service (multi-arch)..."
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -f wine-service/Dockerfile \
        -t wine-emulator:latest \
        -t wine-emulator:multi \
        $push_flag \
        .
    
    # Build Backend (multi-arch)
    echo "Building backend (multi-arch)..."
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -f backend/Dockerfile \
        -t wine-backend:latest \
        -t wine-backend:multi \
        $push_flag \
        .
    
    # Build Frontend (multi-arch)
    echo "Building frontend (multi-arch)..."
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -f frontend/Dockerfile \
        -t wine-frontend:latest \
        -t wine-frontend:multi \
        $push_flag \
        .
}

# Execute build based on mode
case $BUILD_MODE in
    single)
        if [[ "$NATIVE_ARM" == "true" ]]; then
            build_single_arch "linux/arm64" "arm64"
        else
            build_single_arch "linux/amd64" "amd64"
        fi
        ;;
    
    arm64)
        build_single_arch "linux/arm64" "arm64"
        ;;
    
    amd64)
        build_single_arch "linux/amd64" "amd64"
        ;;
    
    multi)
        build_multi_arch
        ;;
    
    all)
        echo "Building all architectures separately..."
        build_single_arch "linux/amd64" "amd64"
        build_single_arch "linux/arm64" "arm64"
        ;;
    
    *)
        echo "❌ Unknown build mode: $BUILD_MODE"
        echo "Usage: $0 [single|arm64|amd64|multi|all] [push]"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "Built images:"
    docker images | grep -E "wine-(emulator|backend|frontend)" | head -10
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Test locally with Docker Compose:"
    echo "   docker-compose up -d"
    echo ""
    echo "2. Deploy to Kubernetes:"
    echo "   kubectl apply -f k8s/deployment-arm.yaml"
    echo ""
    echo "3. Tag and push to registry:"
    echo "   docker tag wine-emulator-arm64:latest <registry>/wine-emulator:latest"
    echo "   docker push <registry>/wine-emulator:latest"
    echo ""
    echo "4. Deploy to Azure:"
    echo "   ./deploy-azure.sh"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
