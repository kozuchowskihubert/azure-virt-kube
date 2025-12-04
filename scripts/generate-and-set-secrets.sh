#!/bin/bash

###############################################################################
# Generate and Set GitHub Secrets for Wine Emulator Platform
###############################################################################
# This script:
# 1. Gets Azure subscription and tenant information
# 2. Creates a Service Principal for GitHub Actions
# 3. Generates secure random secrets
# 4. Sets all secrets in the GitHub repository
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO="kozuchowskihubert/azure-virt-kube"
RESOURCE_GROUP="wine-emulator-rg"
LOCATION="eastus"
APP_NAME="wine-emulator"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔐 Generate & Set GitHub Secrets - Wine Emulator Platform  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

###############################################################################
# 1. Check Prerequisites
###############################################################################
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    exit 1
fi

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo -e "${YELLOW}Run: az login${NC}"
    exit 1
fi

# Check if logged in to GitHub
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not logged in to GitHub${NC}"
    echo -e "${YELLOW}Run: gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

###############################################################################
# 2. Get Azure Information
###############################################################################
echo -e "${YELLOW}🔍 Getting Azure subscription information...${NC}"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo -e "${GREEN}✓ Subscription: ${SUBSCRIPTION_NAME}${NC}"
echo -e "${GREEN}✓ Subscription ID: ${SUBSCRIPTION_ID}${NC}"
echo -e "${GREEN}✓ Tenant ID: ${TENANT_ID}${NC}"
echo ""

###############################################################################
# 3. Create Service Principal for GitHub Actions
###############################################################################
echo -e "${YELLOW}🔑 Creating Service Principal for GitHub Actions...${NC}"

SP_NAME="sp-${APP_NAME}-github-actions"

# Check if Service Principal already exists
SP_EXISTS=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv 2>/dev/null || echo "")

if [ -n "$SP_EXISTS" ]; then
    echo -e "${YELLOW}⚠️  Service Principal already exists. Resetting credentials...${NC}"
    SP_APP_ID="$SP_EXISTS"
    
    # Reset credentials
    SP_CREDENTIALS=$(az ad sp credential reset --id "$SP_APP_ID" --query "{clientId: appId, clientSecret: password, tenantId: tenant}" -o json)
else
    echo -e "${YELLOW}Creating new Service Principal...${NC}"
    
    # Create Service Principal with Contributor role
    SP_CREDENTIALS=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role Contributor \
        --scopes "/subscriptions/${SUBSCRIPTION_ID}" \
        --query "{clientId: appId, clientSecret: password, tenantId: tenant}" \
        -o json)
    
    SP_APP_ID=$(echo "$SP_CREDENTIALS" | jq -r '.clientId')
fi

# Add subscriptionId to credentials
AZURE_CREDENTIALS=$(echo "$SP_CREDENTIALS" | jq --arg sub "$SUBSCRIPTION_ID" '. + {subscriptionId: $sub}')

echo -e "${GREEN}✓ Service Principal created: ${SP_NAME}${NC}"
echo -e "${GREEN}✓ App ID: ${SP_APP_ID}${NC}"
echo ""

###############################################################################
# 4. Generate Random Secrets
###############################################################################
echo -e "${YELLOW}🎲 Generating secure random secrets...${NC}"

# Generate SECRET_KEY (64 characters)
SECRET_KEY=$(openssl rand -base64 48 | tr -d '\n')

# Generate JWT_SECRET (64 characters)
JWT_SECRET=$(openssl rand -base64 48 | tr -d '\n')

# Generate Database Password (32 characters with special chars)
DB_PASSWORD=$(openssl rand -base64 24 | tr -d '\n' | head -c 32)

# Generate Redis Password (if needed - Azure Redis generates its own)
REDIS_PASSWORD=$(openssl rand -base64 24 | tr -d '\n' | head -c 32)

echo -e "${GREEN}✓ Generated SECRET_KEY${NC}"
echo -e "${GREEN}✓ Generated JWT_SECRET${NC}"
echo -e "${GREEN}✓ Generated DB_PASSWORD${NC}"
echo ""

###############################################################################
# 5. Set GitHub Secrets
###############################################################################
echo -e "${YELLOW}📤 Setting GitHub secrets in ${REPO}...${NC}"

# Azure Credentials (JSON format for azure/login@v1)
echo "$AZURE_CREDENTIALS" | gh secret set AZURE_CREDENTIALS -R "$REPO"
echo -e "${GREEN}✓ Set AZURE_CREDENTIALS${NC}"

# Azure Subscription Details
echo "$SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID -R "$REPO"
echo -e "${GREEN}✓ Set AZURE_SUBSCRIPTION_ID${NC}"

echo "$TENANT_ID" | gh secret set AZURE_TENANT_ID -R "$REPO"
echo -e "${GREEN}✓ Set AZURE_TENANT_ID${NC}"

echo "$LOCATION" | gh secret set AZURE_LOCATION -R "$REPO"
echo -e "${GREEN}✓ Set AZURE_LOCATION${NC}"

echo "$RESOURCE_GROUP" | gh secret set AZURE_RESOURCE_GROUP -R "$REPO"
echo -e "${GREEN}✓ Set AZURE_RESOURCE_GROUP${NC}"

# Application Secrets
echo "$SECRET_KEY" | gh secret set SECRET_KEY -R "$REPO"
echo -e "${GREEN}✓ Set SECRET_KEY${NC}"

echo "$JWT_SECRET" | gh secret set JWT_SECRET -R "$REPO"
echo -e "${GREEN}✓ Set JWT_SECRET${NC}"

# Database Configuration (Placeholders - will be updated by Terraform)
echo "postgresql://winadmin:${DB_PASSWORD}@wine-emulator-db.postgres.database.azure.com:5432/wine_emulator?sslmode=require" | gh secret set DATABASE_URL -R "$REPO"
echo -e "${GREEN}✓ Set DATABASE_URL${NC}"

echo "wine-emulator-db.postgres.database.azure.com" | gh secret set POSTGRES_HOST -R "$REPO"
echo -e "${GREEN}✓ Set POSTGRES_HOST${NC}"

echo "winadmin" | gh secret set POSTGRES_USER -R "$REPO"
echo -e "${GREEN}✓ Set POSTGRES_USER${NC}"

echo "$DB_PASSWORD" | gh secret set POSTGRES_PASSWORD -R "$REPO"
echo -e "${GREEN}✓ Set POSTGRES_PASSWORD${NC}"

echo "wine_emulator" | gh secret set POSTGRES_DB -R "$REPO"
echo -e "${GREEN}✓ Set POSTGRES_DB${NC}"

# Redis Configuration (Placeholder - will be updated by Terraform)
echo "wine-emulator-cache.redis.cache.windows.net" | gh secret set REDIS_HOST -R "$REPO"
echo -e "${GREEN}✓ Set REDIS_HOST${NC}"

echo "6380" | gh secret set REDIS_PORT -R "$REPO"
echo -e "${GREEN}✓ Set REDIS_PORT${NC}"

echo "$REDIS_PASSWORD" | gh secret set REDIS_PASSWORD -R "$REPO"
echo -e "${GREEN}✓ Set REDIS_PASSWORD${NC}"

echo "rediss://wine-emulator-cache.redis.cache.windows.net:6380" | gh secret set REDIS_URL -R "$REPO"
echo -e "${GREEN}✓ Set REDIS_URL${NC}"

# Azure Container Registry (Placeholder - will be updated by Terraform)
ACR_NAME="${APP_NAME//[-_]/}acr"
echo "${ACR_NAME}.azurecr.io" | gh secret set ACR_LOGIN_SERVER -R "$REPO"
echo -e "${GREEN}✓ Set ACR_LOGIN_SERVER${NC}"

echo "$ACR_NAME" | gh secret set ACR_NAME -R "$REPO"
echo -e "${GREEN}✓ Set ACR_NAME${NC}"

echo "$ACR_NAME" | gh secret set ACR_USERNAME -R "$REPO"
echo -e "${GREEN}✓ Set ACR_USERNAME (placeholder)${NC}"

echo "ACR_PASSWORD_WILL_BE_SET_BY_TERRAFORM" | gh secret set ACR_PASSWORD -R "$REPO"
echo -e "${GREEN}✓ Set ACR_PASSWORD (placeholder)${NC}"

# Storage Account (Placeholder - will be updated by Terraform)
STORAGE_ACCOUNT_NAME="${APP_NAME//[-_]/}storage"
echo "$STORAGE_ACCOUNT_NAME" | gh secret set STORAGE_ACCOUNT_NAME -R "$REPO"
echo -e "${GREEN}✓ Set STORAGE_ACCOUNT_NAME${NC}"

echo "STORAGE_CONNECTION_STRING_WILL_BE_SET_BY_TERRAFORM" | gh secret set STORAGE_CONNECTION_STRING -R "$REPO"
echo -e "${GREEN}✓ Set STORAGE_CONNECTION_STRING (placeholder)${NC}"

# Container Apps Environment (Placeholder - will be updated by Terraform)
echo "wine-emulator-env" | gh secret set CONTAINER_ENV -R "$REPO"
echo -e "${GREEN}✓ Set CONTAINER_ENV${NC}"

# Wine Configuration (ARM64 Support)
echo "8.0" | gh secret set WINE_VERSION -R "$REPO"
echo -e "${GREEN}✓ Set WINE_VERSION${NC}"

echo "win64" | gh secret set WINEARCH -R "$REPO"
echo -e "${GREEN}✓ Set WINEARCH (supports x86 and x64)${NC}"

echo ":0" | gh secret set DISPLAY -R "$REPO"
echo -e "${GREEN}✓ Set DISPLAY${NC}"

# ARM64 Emulation Settings
echo "1" | gh secret set BOX86_NOBANNER -R "$REPO"
echo -e "${GREEN}✓ Set BOX86_NOBANNER${NC}"

echo "1" | gh secret set BOX64_NOBANNER -R "$REPO"
echo -e "${GREEN}✓ Set BOX64_NOBANNER${NC}"

echo "linux/arm64" | gh secret set DOCKER_DEFAULT_PLATFORM -R "$REPO"
echo -e "${GREEN}✓ Set DOCKER_DEFAULT_PLATFORM${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    ✅ Secrets Set Successfully!               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

###############################################################################
# 6. Summary
###############################################################################
echo -e "${YELLOW}📊 Summary:${NC}"
echo ""
echo -e "${GREEN}✓ Azure Credentials:${NC}"
echo -e "  • Service Principal: ${SP_NAME}"
echo -e "  • Subscription: ${SUBSCRIPTION_NAME}"
echo -e "  • Resource Group: ${RESOURCE_GROUP}"
echo -e "  • Location: ${LOCATION}"
echo ""
echo -e "${GREEN}✓ Application Secrets:${NC}"
echo -e "  • SECRET_KEY: Generated (64 chars)"
echo -e "  • JWT_SECRET: Generated (64 chars)"
echo ""
echo -e "${GREEN}✓ Database Configuration:${NC}"
echo -e "  • PostgreSQL Host: wine-emulator-db.postgres.database.azure.com"
echo -e "  • Database: wine_emulator"
echo -e "  • User: winadmin"
echo -e "  • Password: Generated (32 chars)"
echo ""
echo -e "${GREEN}✓ ARM64 Configuration:${NC}"
echo -e "  • Wine Version: 8.0"
echo -e "  • Wine Arch: win64 (x86 + x64 support)"
echo -e "  • Box86/Box64: Enabled for ARM translation"
echo -e "  • Platform: linux/arm64"
echo ""
echo -e "${YELLOW}⚠️  Note:${NC}"
echo -e "  • Some secrets are placeholders and will be updated by Terraform"
echo -e "  • Run Terraform to create actual Azure resources"
echo -e "  • ACR password, Redis keys, and Storage connection strings will be set by Terraform"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo -e "  1. Run Terraform to create Azure resources:"
echo -e "     ${GREEN}./terraform-deploy.sh${NC}"
echo ""
echo -e "  2. Terraform will update these secrets automatically:"
echo -e "     • ACR_PASSWORD"
echo -e "     • REDIS_PASSWORD"
echo -e "     • REDIS_URL"
echo -e "     • STORAGE_CONNECTION_STRING"
echo -e "     • DATABASE_URL (with actual endpoints)"
echo ""
echo -e "  3. Build and push Docker images to ACR"
echo ""
echo -e "  4. Deploy via GitHub Actions"
echo ""
echo -e "${GREEN}✨ All secrets configured successfully!${NC}"
echo ""

# Save credentials locally for reference (DO NOT COMMIT THIS FILE)
cat > /tmp/azure-credentials.json << EOF
{
  "azure_credentials": $AZURE_CREDENTIALS,
  "subscription_id": "$SUBSCRIPTION_ID",
  "tenant_id": "$TENANT_ID",
  "resource_group": "$RESOURCE_GROUP",
  "location": "$LOCATION"
}
EOF

echo -e "${YELLOW}💾 Azure credentials saved to: ${NC}/tmp/azure-credentials.json"
echo -e "${RED}⚠️  DO NOT commit this file to git!${NC}"
echo ""
