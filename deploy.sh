#!/bin/bash

# Wine Emulator Platform - Deployment Script
set -e

echo "🍷 Wine Emulator Platform Deployment Script"
echo "==========================================="

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed.  Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed.  Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm is required but not installed.  Aborting." >&2; exit 1; }

echo "✅ All prerequisites installed"

# Ask deployment type
echo ""
echo "Select deployment type:"
echo "1) Local Docker Compose"
echo "2) Local Kubernetes (k3d)"
echo "3) Azure Cloud"
read -p "Enter choice [1-3]: " choice

case $choice in
  1)
    echo ""
    echo "🐳 Starting Docker Compose deployment..."
    docker-compose up -d
    echo ""
    echo "✅ Deployment complete!"
    echo "🌐 Frontend: http://localhost:3000"
    echo "🔌 Backend API: http://localhost:8000"
    echo "🖥️  Wine VNC: http://localhost:8080"
    ;;
  2)
    echo ""
    echo "☸️  Starting Kubernetes deployment..."
    
    # Create k3d cluster if it doesn't exist
    if ! k3d cluster list | grep -q wine-emulator; then
      echo "Creating k3d cluster..."
      k3d cluster create wine-emulator \
        --api-port 6550 \
        --port 8080:80@loadbalancer \
        --port 8443:443@loadbalancer
    fi
    
    # Apply manifests
    echo "Applying Kubernetes manifests..."
    kubectl apply -f k8s/
    
    # Wait for pods
    echo "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod \
      -l app=wine-emulator \
      -n wine-emulator \
      --timeout=300s
    
    echo ""
    echo "✅ Deployment complete!"
    kubectl get pods -n wine-emulator
    ;;
  3)
    echo ""
    echo "☁️  Starting Azure deployment..."
    
    # Check Azure CLI
    command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI is required but not installed.  Aborting." >&2; exit 1; }
    
    # Check if logged in
    if ! az account show >/dev/null 2>&1; then
      echo "Please login to Azure..."
      az login
    fi
    
    # Terraform deployment
    cd terraform
    
    echo "Initializing Terraform..."
    terraform init
    
    echo "Planning infrastructure..."
    terraform plan -out=tfplan
    
    read -p "Apply this plan? (yes/no): " apply
    if [ "$apply" = "yes" ]; then
      echo "Applying infrastructure..."
      terraform apply tfplan
      
      echo ""
      echo "✅ Deployment complete!"
      terraform output
    else
      echo "Deployment cancelled"
    fi
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

echo ""
echo "🎉 All done! Enjoy your Wine Emulator Platform!"
