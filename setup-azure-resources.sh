#!/bin/bash

################################################################################
# Azure Resources Setup Script
# Purpose: Create all Azure resources for Wine Emulator Platform
# Architecture: ARM64 + x86/x64 translation support
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="wine-emulator"
LOCATION="eastus"  # Change to your preferred region
RESOURCE_GROUP="${PROJECT_NAME}-rg"
ACR_NAME="${PROJECT_NAME}acr$(date +%s | tail -c 6)"  # Must be unique globally
POSTGRES_SERVER="${PROJECT_NAME}-db-$(date +%s | tail -c 6)"
REDIS_NAME="${PROJECT_NAME}-cache"
STORAGE_ACCOUNT="${PROJECT_NAME}storage$(date +%s | tail -c 6)"
VNET_NAME="${PROJECT_NAME}-vnet"
CONTAINER_ENV="${PROJECT_NAME}-env"
LOG_ANALYTICS_WORKSPACE="${PROJECT_NAME}-logs"

# GitHub repository (update this)
GITHUB_REPO="your-username/azure-virt-kube"  # Change this!

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Wine Emulator Platform - Azure Setup                 ║${NC}"
echo -e "${BLUE}║  ARM64 + x86/x64 Translation Infrastructure           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Step 1: Prerequisites Check
################################################################################

echo -e "${YELLOW}[1/9] Checking prerequisites...${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed!${NC}"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if GitHub CLI is installed (optional but recommended)
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not found. You'll need to set secrets manually.${NC}"
    GH_CLI_AVAILABLE=false
else
    GH_CLI_AVAILABLE=true
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Logging in...${NC}"
    az login
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo -e "${GREEN}✓ Azure CLI installed${NC}"
echo -e "${GREEN}✓ Logged in to subscription: ${SUBSCRIPTION_NAME}${NC}"
echo -e "${GREEN}✓ Subscription ID: ${SUBSCRIPTION_ID}${NC}"
echo ""

################################################################################
# Step 2: Create Resource Group
################################################################################

echo -e "${YELLOW}[2/9] Creating Resource Group...${NC}"

if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  Resource group already exists${NC}"
else
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --tags project="wine-emulator" environment="production" architecture="arm64-x86-translation"
    echo -e "${GREEN}✓ Resource group created: ${RESOURCE_GROUP}${NC}"
fi
echo ""

################################################################################
# Step 3: Create Azure Container Registry (ACR)
################################################################################

echo -e "${YELLOW}[3/9] Creating Azure Container Registry...${NC}"

if az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  ACR already exists${NC}"
else
    az acr create \
        --resource-group $RESOURCE_GROUP \
        --name $ACR_NAME \
        --sku Standard \
        --location $LOCATION \
        --admin-enabled true
    echo -e "${GREEN}✓ Container Registry created: ${ACR_NAME}${NC}"
fi

# Get ACR credentials
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

echo -e "${GREEN}✓ ACR Login Server: ${ACR_LOGIN_SERVER}${NC}"
echo ""

################################################################################
# Step 4: Create Virtual Network
################################################################################

echo -e "${YELLOW}[4/9] Creating Virtual Network...${NC}"

if az network vnet show --name $VNET_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  VNet already exists${NC}"
else
    az network vnet create \
        --resource-group $RESOURCE_GROUP \
        --name $VNET_NAME \
        --address-prefix 10.0.0.0/16 \
        --subnet-name default \
        --subnet-prefix 10.0.0.0/24
    echo -e "${GREEN}✓ Virtual Network created${NC}"
fi
echo ""

################################################################################
# Step 5: Create PostgreSQL Flexible Server
################################################################################

echo -e "${YELLOW}[5/9] Creating PostgreSQL Database...${NC}"

if az postgres flexible-server show --name $POSTGRES_SERVER --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL server already exists${NC}"
else
    # Generate random password
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    az postgres flexible-server create \
        --resource-group $RESOURCE_GROUP \
        --name $POSTGRES_SERVER \
        --location $LOCATION \
        --admin-user wineadmin \
        --admin-password "$POSTGRES_PASSWORD" \
        --sku-name Standard_B1ms \
        --tier Burstable \
        --version 15 \
        --storage-size 32 \
        --public-access 0.0.0.0-255.255.255.255
    
    # Create database
    az postgres flexible-server db create \
        --resource-group $RESOURCE_GROUP \
        --server-name $POSTGRES_SERVER \
        --database-name wine_emulator
    
    echo -e "${GREEN}✓ PostgreSQL created${NC}"
    echo -e "${GREEN}  Database: wine_emulator${NC}"
    echo -e "${GREEN}  Username: wineadmin${NC}"
fi

POSTGRES_HOST="${POSTGRES_SERVER}.postgres.database.azure.com"
echo ""

################################################################################
# Step 6: Create Azure Cache for Redis
################################################################################

echo -e "${YELLOW}[6/9] Creating Redis Cache...${NC}"

if az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  Redis already exists${NC}"
else
    az redis create \
        --resource-group $RESOURCE_GROUP \
        --name $REDIS_NAME \
        --location $LOCATION \
        --sku Basic \
        --vm-size c0 \
        --enable-non-ssl-port false
    echo -e "${GREEN}✓ Redis Cache created${NC}"
fi

REDIS_HOST=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query hostName -o tsv)
REDIS_KEY=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query primaryKey -o tsv)
echo ""

################################################################################
# Step 7: Create Storage Account
################################################################################

echo -e "${YELLOW}[7/9] Creating Storage Account...${NC}"

if az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  Storage account already exists${NC}"
else
    az storage account create \
        --name $STORAGE_ACCOUNT \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --sku Standard_LRS \
        --kind StorageV2
    echo -e "${GREEN}✓ Storage Account created${NC}"
fi

STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --query connectionString -o tsv)
echo ""

################################################################################
# Step 8: Create Log Analytics Workspace
################################################################################

echo -e "${YELLOW}[8/9] Creating Log Analytics Workspace...${NC}"

if az monitor log-analytics workspace show --workspace-name $LOG_ANALYTICS_WORKSPACE --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  Log Analytics workspace already exists${NC}"
else
    az monitor log-analytics workspace create \
        --resource-group $RESOURCE_GROUP \
        --workspace-name $LOG_ANALYTICS_WORKSPACE \
        --location $LOCATION
    echo -e "${GREEN}✓ Log Analytics Workspace created${NC}"
fi

LOG_ANALYTICS_ID=$(az monitor log-analytics workspace show \
    --workspace-name $LOG_ANALYTICS_WORKSPACE \
    --resource-group $RESOURCE_GROUP \
    --query customerId -o tsv)

LOG_ANALYTICS_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --workspace-name $LOG_ANALYTICS_WORKSPACE \
    --resource-group $RESOURCE_GROUP \
    --query primarySharedKey -o tsv)
echo ""

################################################################################
# Step 9: Create Container Apps Environment
################################################################################

echo -e "${YELLOW}[9/9] Creating Container Apps Environment...${NC}"

# Register Microsoft.App provider if not already registered
az provider register --namespace Microsoft.App --wait

if az containerapp env show --name $CONTAINER_ENV --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  Container Apps environment already exists${NC}"
else
    az containerapp env create \
        --name $CONTAINER_ENV \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --logs-workspace-id $LOG_ANALYTICS_ID \
        --logs-workspace-key $LOG_ANALYTICS_KEY
    echo -e "${GREEN}✓ Container Apps Environment created${NC}"
fi
echo ""

################################################################################
# Step 10: Create Service Principal for GitHub Actions
################################################################################

echo -e "${YELLOW}[10/11] Creating Service Principal for GitHub Actions...${NC}"

# Create service principal for GitHub Actions
SP_NAME="${PROJECT_NAME}-github-actions"
echo "Creating service principal for GitHub Actions..."
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name $SP_NAME \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --sdk-auth)

# Note: --sdk-auth format is deprecated but still works with azure/login@v1
# Output format: {"clientId":"xxx","clientSecret":"xxx","subscriptionId":"xxx","tenantId":"xxx"}

echo -e "${GREEN}✓ Service Principal created${NC}"
echo ""

################################################################################
# Save Configuration
################################################################################

echo -e "${YELLOW}[11/11] Saving configuration...${NC}"

# Create secrets file
cat > azure-secrets.env << EOF
# Azure Resource Configuration
# Generated: $(date)
# DO NOT COMMIT THIS FILE TO VERSION CONTROL!

# Resource Group
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_LOCATION=$LOCATION
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID

# Container Registry
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD
REGISTRY_NAME=$ACR_NAME

# PostgreSQL
POSTGRES_HOST=$POSTGRES_HOST
POSTGRES_USER=wineadmin
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=wine_emulator
DATABASE_URL=postgresql://wineadmin:$POSTGRES_PASSWORD@$POSTGRES_HOST:5432/wine_emulator

# Redis
REDIS_HOST=$REDIS_HOST
REDIS_KEY=$REDIS_KEY
REDIS_URL=rediss://:$REDIS_KEY@$REDIS_HOST:6380

# Storage
STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT
STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING

# Container Apps
CONTAINER_ENV=$CONTAINER_ENV

# Log Analytics
LOG_ANALYTICS_WORKSPACE_ID=$LOG_ANALYTICS_ID
LOG_ANALYTICS_KEY=$LOG_ANALYTICS_KEY

# Service Principal (for GitHub Actions)
AZURE_CREDENTIALS='$SP_OUTPUT'
EOF

# Create GitHub secrets template
cat > github-secrets.txt << EOF
# GitHub Secrets Configuration
# Set these in your GitHub repository: Settings > Secrets and variables > Actions

# Azure Service Principal (entire JSON object)
AZURE_CREDENTIALS='$SP_OUTPUT'

# Container Registry
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD

# Database
DATABASE_URL=postgresql://wineadmin:$POSTGRES_PASSWORD@$POSTGRES_HOST:5432/wine_emulator

# Redis
REDIS_URL=rediss://:$REDIS_KEY@$REDIS_HOST:6380

# Azure Resources
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
CONTAINER_ENV=$CONTAINER_ENV
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
EOF

chmod 600 azure-secrets.env github-secrets.txt

echo -e "${GREEN}✓ Configuration saved to:${NC}"
echo -e "  ${BLUE}azure-secrets.env${NC} (environment variables)"
echo -e "  ${BLUE}github-secrets.txt${NC} (GitHub secrets template)"
echo ""

################################################################################
# Summary
################################################################################

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ Azure Resources Created Successfully!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Resources Created:${NC}"
echo -e "  ✓ Resource Group: ${GREEN}$RESOURCE_GROUP${NC}"
echo -e "  ✓ Container Registry: ${GREEN}$ACR_LOGIN_SERVER${NC}"
echo -e "  ✓ PostgreSQL: ${GREEN}$POSTGRES_HOST${NC}"
echo -e "  ✓ Redis: ${GREEN}$REDIS_HOST${NC}"
echo -e "  ✓ Storage: ${GREEN}$STORAGE_ACCOUNT${NC}"
echo -e "  ✓ Container Apps Env: ${GREEN}$CONTAINER_ENV${NC}"
echo -e "  ✓ Service Principal: ${GREEN}$SP_NAME${NC}"
echo ""

echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo -e "1️⃣  ${BLUE}Set up GitHub Secrets:${NC}"
echo "   Run: ${GREEN}./setup-github-secrets.sh${NC}"
echo "   Or manually copy from: ${BLUE}github-secrets.txt${NC}"
echo ""
echo -e "2️⃣  ${BLUE}Push Docker Images to ACR:${NC}"
echo "   ${GREEN}docker login $ACR_LOGIN_SERVER -u $ACR_USERNAME${NC}"
echo "   ${GREEN}./build-arm.sh multi${NC}"
echo "   ${GREEN}docker tag wine-emulator:latest $ACR_LOGIN_SERVER/wine-emulator:latest${NC}"
echo "   ${GREEN}docker push $ACR_LOGIN_SERVER/wine-emulator:latest${NC}"
echo ""
echo -e "3️⃣  ${BLUE}Deploy to Azure Container Apps:${NC}"
echo "   ${GREEN}./deploy-azure.sh${NC}"
echo ""
echo -e "4️⃣  ${BLUE}Enable GitHub Actions:${NC}"
echo "   Commit and push to trigger automated deployment"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo -e "  • ${RED}DO NOT commit azure-secrets.env or github-secrets.txt${NC}"
echo -e "  • Files already added to .gitignore"
echo -e "  • Store passwords in a secure password manager"
echo ""

# Add to .gitignore
if ! grep -q "azure-secrets.env" .gitignore 2>/dev/null; then
    echo "azure-secrets.env" >> .gitignore
    echo "github-secrets.txt" >> .gitignore
    echo -e "${GREEN}✓ Added secrets files to .gitignore${NC}"
fi

echo -e "${GREEN}🎉 Setup complete! Ready for deployment.${NC}"
