#!/bin/bash

# Simple Local Deployment - Works on ARM Mac
set -e

echo "🍷 Wine Emulator Platform - Simple Local Setup"
echo "=============================================="

# Check if k3d cluster exists
if ! kubectl get nodes &> /dev/null; then
    echo "❌ Kubernetes cluster not running"
    echo "Creating k3d cluster..."
    k3d cluster create wine-emulator \
        --api-port 6550 \
        --port 8080:80@loadbalancer \
        --port 8443:443@loadbalancer
    echo "✅ Cluster created"
else
    echo "✅ Kubernetes cluster is running"
fi

# Deploy demo version
echo ""
echo "📦 Deploying demo application..."
kubectl apply -f k8s/demo-deployment.yaml

# Wait for deployment
echo ""
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s \
    deployment/wine-emulator-demo -n wine-emulator

# Get service info
echo ""
echo "🌐 Service Information:"
kubectl get svc -n wine-emulator wine-emulator-demo

# Port forward
echo ""
echo "🔌 Setting up port forward..."
echo ""
echo "Access the application at: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward -n wine-emulator svc/wine-emulator-demo 8080:8080
