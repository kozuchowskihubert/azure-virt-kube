#!/bin/bash

# Azure Deployment Script for Wine Emulator Platform
set -e

echo "☁️  Wine Emulator Platform - Azure Deployment"
echo "=============================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo ""
echo "📋 Checking prerequisites..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    echo "Install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI installed${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    echo "Install it with: brew install terraform"
    exit 1
fi
echo -e "${GREEN}✅ Terraform installed${NC}"

# Check Azure login
echo ""
echo "🔐 Checking Azure authentication..."
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure${NC}"
    echo "Logging in..."
    az login
else
    ACCOUNT=$(az account show --query name -o tsv)
    echo -e "${GREEN}✅ Logged in to Azure${NC}"
    echo "   Subscription: $ACCOUNT"
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "   Subscription ID: $SUBSCRIPTION_ID"

# Prompt for deployment confirmation
echo ""
echo "📦 Deployment Configuration:"
echo "   Resource Group: wine-emulator-rg"
echo "   Location: East US"
echo "   Services:"
echo "     - Azure Container Apps (Frontend, Backend, Wine Service)"
echo "     - PostgreSQL Flexible Server"
echo "     - Redis Cache"
echo "     - Container Registry"
echo "     - Storage Account"
echo ""
read -p "Continue with deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo ""
    echo "📝 Creating terraform.tfvars..."
    cat > terraform.tfvars <<EOF
# Azure Configuration
location            = "East US"
resource_group_name = "wine-emulator-rg"

# Application Configuration
app_name    = "wine-emulator"
app_version = "1.0.0"
replicas    = 1

# Container Image (using public images for now)
container_image = "nginx:alpine"

# Kubernetes Configuration (for AKS if needed)
namespace    = "wine-emulator"
service_type = "LoadBalancer"
service_port = 8080

# Storage
storage_size = "10Gi"

# Tags
tags = {
  Environment = "production"
  Project     = "wine-emulator"
  ManagedBy   = "terraform"
  DeployedBy  = "$(whoami)"
  DeployDate  = "$(date +%Y-%m-%d)"
}
EOF
    echo -e "${GREEN}✅ Created terraform.tfvars${NC}"
fi

# Plan
echo ""
echo "📊 Planning infrastructure..."
terraform plan -out=tfplan

# Confirm apply
echo ""
read -p "Apply this plan? (yes/no): " APPLY_CONFIRM

if [ "$APPLY_CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Apply
echo ""
echo "🚀 Deploying infrastructure to Azure..."
terraform apply tfplan

# Get outputs
echo ""
echo "📋 Deployment Complete!"
echo "======================="
echo ""
terraform output

# Save outputs to file
terraform output -json > ../deployment-outputs.json
echo ""
echo -e "${GREEN}✅ Deployment outputs saved to deployment-outputs.json${NC}"

# Display access information
echo ""
echo "🌐 Access Your Application:"
echo "============================"
FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null || echo "Not available yet")
BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null || echo "Not available yet")
WINE_URL=$(terraform output -raw wine_service_url 2>/dev/null || echo "Not available yet")

echo ""
echo "Frontend:      $FRONTEND_URL"
echo "Backend API:   $BACKEND_URL/docs"
echo "Wine Service:  $WINE_URL"

echo ""
echo -e "${GREEN}🎉 Deployment successful!${NC}"
echo ""
echo "Next steps:"
echo "1. Wait 2-3 minutes for containers to start"
echo "2. Access the frontend URL above"
echo "3. Check deployment status:"
echo "   az containerapp list -g wine-emulator-rg -o table"
echo ""
echo "To destroy the infrastructure:"
echo "   cd terraform && terraform destroy"
