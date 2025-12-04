#!/bin/bash

################################################################################
# GitHub Secrets Setup Script
# Purpose: Automatically configure GitHub repository secrets
# Requires: GitHub CLI (gh) installed and authenticated
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  GitHub Secrets Configuration                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Prerequisites Check
################################################################################

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed!${NC}"
    echo ""
    echo "Install it with:"
    echo "  macOS:   ${GREEN}brew install gh${NC}"
    echo "  Linux:   ${GREEN}sudo apt install gh${NC}"
    echo "  Windows: ${GREEN}winget install GitHub.cli${NC}"
    echo ""
    echo "Or download from: https://cli.github.com"
    echo ""
    echo -e "${YELLOW}Alternative: Manually set secrets using github-secrets.txt${NC}"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Not authenticated with GitHub. Logging in...${NC}"
    gh auth login
fi

# Check if secrets file exists
if [ ! -f "azure-secrets.env" ]; then
    echo -e "${RED}❌ azure-secrets.env not found!${NC}"
    echo "Run ${GREEN}./setup-azure-resources.sh${NC} first to create Azure resources."
    exit 1
fi

# Source the secrets
source azure-secrets.env

################################################################################
# Get Repository Information
################################################################################

echo -e "${YELLOW}Detecting GitHub repository...${NC}"

# Try to detect repo from git remote
if git remote get-url origin &> /dev/null; then
    REPO_URL=$(git remote get-url origin)
    # Extract owner/repo from URL (handles both HTTPS and SSH)
    if [[ $REPO_URL =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi
fi

# Ask user to confirm or enter manually
if [ -z "$REPO" ]; then
    echo -e "${YELLOW}Could not auto-detect repository.${NC}"
    echo -n "Enter your GitHub repository (format: owner/repo): "
    read REPO
else
    echo -e "Detected repository: ${GREEN}$REPO${NC}"
    echo -n "Is this correct? (y/n): "
    read CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        echo -n "Enter your GitHub repository (format: owner/repo): "
        read REPO
    fi
fi

echo -e "${GREEN}✓ Using repository: $REPO${NC}"
echo ""

################################################################################
# Set GitHub Secrets
################################################################################

echo -e "${YELLOW}Setting GitHub secrets...${NC}"
echo ""

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    
    if [ -z "$secret_value" ]; then
        echo -e "  ${YELLOW}⚠️  Skipping $secret_name (empty value)${NC}"
        return
    fi
    
    if echo "$secret_value" | gh secret set "$secret_name" -R "$REPO"; then
        echo -e "  ${GREEN}✓ Set $secret_name${NC}"
    else
        echo -e "  ${RED}✗ Failed to set $secret_name${NC}"
    fi
}

# Azure Credentials (Service Principal JSON)
echo -e "${BLUE}[1/10] Azure Credentials...${NC}"
set_secret "AZURE_CREDENTIALS" "$AZURE_CREDENTIALS"

# Container Registry
echo -e "${BLUE}[2/10] Container Registry...${NC}"
set_secret "ACR_LOGIN_SERVER" "$ACR_LOGIN_SERVER"
set_secret "ACR_USERNAME" "$ACR_USERNAME"
set_secret "ACR_PASSWORD" "$ACR_PASSWORD"
set_secret "REGISTRY_NAME" "$REGISTRY_NAME"

# Database
echo -e "${BLUE}[3/10] PostgreSQL Database...${NC}"
set_secret "DATABASE_URL" "$DATABASE_URL"
set_secret "POSTGRES_HOST" "$POSTGRES_HOST"
set_secret "POSTGRES_USER" "$POSTGRES_USER"
set_secret "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD"
set_secret "POSTGRES_DB" "$POSTGRES_DB"

# Redis
echo -e "${BLUE}[4/10] Redis Cache...${NC}"
set_secret "REDIS_URL" "$REDIS_URL"
set_secret "REDIS_HOST" "$REDIS_HOST"
set_secret "REDIS_KEY" "$REDIS_KEY"

# Storage
echo -e "${BLUE}[5/10] Storage Account...${NC}"
set_secret "STORAGE_ACCOUNT_NAME" "$STORAGE_ACCOUNT_NAME"
set_secret "STORAGE_CONNECTION_STRING" "$STORAGE_CONNECTION_STRING"

# Azure Resources
echo -e "${BLUE}[6/10] Azure Resource Info...${NC}"
set_secret "AZURE_RESOURCE_GROUP" "$AZURE_RESOURCE_GROUP"
set_secret "AZURE_SUBSCRIPTION_ID" "$AZURE_SUBSCRIPTION_ID"
set_secret "AZURE_LOCATION" "$AZURE_LOCATION"
set_secret "CONTAINER_ENV" "$CONTAINER_ENV"

# Log Analytics
echo -e "${BLUE}[7/10] Log Analytics...${NC}"
set_secret "LOG_ANALYTICS_WORKSPACE_ID" "$LOG_ANALYTICS_WORKSPACE_ID"
set_secret "LOG_ANALYTICS_KEY" "$LOG_ANALYTICS_KEY"

# Application Secrets
echo -e "${BLUE}[8/10] Application Secrets...${NC}"
SECRET_KEY=$(openssl rand -hex 32)
set_secret "SECRET_KEY" "$SECRET_KEY"

JWT_SECRET=$(openssl rand -hex 32)
set_secret "JWT_SECRET" "$JWT_SECRET"

# API URLs
echo -e "${BLUE}[9/10] API URLs...${NC}"
set_secret "NEXT_PUBLIC_API_URL" "https://${ACR_LOGIN_SERVER}"
set_secret "API_URL" "http://backend:8000"

# Wine Configuration
echo -e "${BLUE}[10/10] Wine Configuration...${NC}"
set_secret "WINE_VERSION" "8.0"
set_secret "WINEARCH" "win64"
set_secret "DISPLAY" ":0"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ GitHub Secrets Configured Successfully!            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Verify Secrets
################################################################################

echo -e "${YELLOW}Verifying secrets...${NC}"
echo ""

SECRET_COUNT=$(gh secret list -R "$REPO" | wc -l)
echo -e "Total secrets set: ${GREEN}$SECRET_COUNT${NC}"
echo ""
echo "Secrets list:"
gh secret list -R "$REPO"
echo ""

################################################################################
# Summary and Next Steps
################################################################################

echo -e "${BLUE}📋 Next Steps:${NC}"
echo ""
echo -e "1️⃣  ${GREEN}View all secrets:${NC}"
echo "   gh secret list -R $REPO"
echo ""
echo -e "2️⃣  ${GREEN}Test GitHub Actions:${NC}"
echo "   git add .github/workflows/"
echo "   git commit -m 'Add GitHub Actions workflows'"
echo "   git push"
echo ""
echo -e "3️⃣  ${GREEN}Monitor workflow:${NC}"
echo "   gh workflow list -R $REPO"
echo "   gh run watch -R $REPO"
echo ""
echo -e "4️⃣  ${GREEN}Manual deployment:${NC}"
echo "   gh workflow run deploy.yml -R $REPO"
echo ""

echo -e "${YELLOW}💡 Useful Commands:${NC}"
echo ""
echo "• View secret:      ${GREEN}gh secret list -R $REPO${NC}"
echo "• Update secret:    ${GREEN}gh secret set SECRET_NAME -R $REPO${NC}"
echo "• Delete secret:    ${GREEN}gh secret delete SECRET_NAME -R $REPO${NC}"
echo "• View workflows:   ${GREEN}gh workflow list -R $REPO${NC}"
echo "• Trigger workflow: ${GREEN}gh workflow run WORKFLOW_NAME -R $REPO${NC}"
echo ""

echo -e "${GREEN}🎉 GitHub secrets setup complete!${NC}"
