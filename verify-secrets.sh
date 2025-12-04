#!/bin/bash

################################################################################
# Verify Azure & GitHub Secrets Configuration
# Purpose: Test all secrets and Azure connection
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Azure & GitHub Secrets Verification                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

ERRORS=0
WARNINGS=0
SUCCESSES=0

################################################################################
# Helper Functions
################################################################################

check_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((SUCCESSES++))
}

check_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

check_error() {
    echo -e "${RED}✗ $1${NC}"
    ((ERRORS++))
}

################################################################################
# 1. Check Prerequisites
################################################################################

echo -e "${CYAN}[1/7] Checking prerequisites...${NC}"
echo ""

if command -v az &> /dev/null; then
    check_success "Azure CLI installed"
else
    check_error "Azure CLI not found"
fi

if command -v gh &> /dev/null; then
    check_success "GitHub CLI installed"
else
    check_warning "GitHub CLI not found (optional)"
fi

if command -v docker &> /dev/null; then
    check_success "Docker installed"
else
    check_error "Docker not found"
fi

echo ""

################################################################################
# 2. Check Azure Login
################################################################################

echo -e "${CYAN}[2/7] Checking Azure authentication...${NC}"
echo ""

if az account show &> /dev/null; then
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    check_success "Logged in to Azure"
    echo -e "  ${BLUE}Subscription: $SUBSCRIPTION_NAME${NC}"
    echo -e "  ${BLUE}ID: $SUBSCRIPTION_ID${NC}"
else
    check_error "Not logged in to Azure. Run: az login"
fi

echo ""

################################################################################
# 3. Check Local Secrets File
################################################################################

echo -e "${CYAN}[3/7] Checking local secrets file...${NC}"
echo ""

if [ -f "azure-secrets.env" ]; then
    check_success "azure-secrets.env found"
    source azure-secrets.env
    
    # Check required variables
    REQUIRED_VARS=(
        "AZURE_RESOURCE_GROUP"
        "ACR_LOGIN_SERVER"
        "ACR_USERNAME"
        "ACR_PASSWORD"
        "POSTGRES_HOST"
        "POSTGRES_USER"
        "POSTGRES_PASSWORD"
        "REDIS_HOST"
        "REDIS_KEY"
        "CONTAINER_ENV"
    )
    
    for var in "${REQUIRED_VARS[@]}"; do
        if [ ! -z "${!var}" ]; then
            check_success "$var is set"
        else
            check_error "$var is not set"
        fi
    done
else
    check_error "azure-secrets.env not found. Run: ./setup-azure-resources.sh"
fi

echo ""

################################################################################
# 4. Verify Azure Resources
################################################################################

echo -e "${CYAN}[4/7] Verifying Azure resources...${NC}"
echo ""

if [ ! -z "$AZURE_RESOURCE_GROUP" ]; then
    # Resource Group
    if az group show --name "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        check_success "Resource Group: $AZURE_RESOURCE_GROUP"
    else
        check_error "Resource Group not found: $AZURE_RESOURCE_GROUP"
    fi
    
    # Container Registry
    if [ ! -z "$REGISTRY_NAME" ]; then
        if az acr show --name "$REGISTRY_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
            check_success "Container Registry: $REGISTRY_NAME"
            
            # Test ACR login
            echo "$ACR_PASSWORD" | docker login "$ACR_LOGIN_SERVER" -u "$ACR_USERNAME" --password-stdin &> /dev/null
            if [ $? -eq 0 ]; then
                check_success "ACR login successful"
            else
                check_error "ACR login failed"
            fi
        else
            check_error "Container Registry not found: $REGISTRY_NAME"
        fi
    fi
    
    # PostgreSQL
    if [ ! -z "$POSTGRES_HOST" ]; then
        POSTGRES_SERVER=$(echo $POSTGRES_HOST | cut -d'.' -f1)
        if az postgres flexible-server show --name "$POSTGRES_SERVER" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
            check_success "PostgreSQL Server: $POSTGRES_SERVER"
            
            # Test connection
            if command -v psql &> /dev/null; then
                PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" &> /dev/null
                if [ $? -eq 0 ]; then
                    check_success "PostgreSQL connection successful"
                else
                    check_warning "PostgreSQL connection failed (may need firewall rule)"
                fi
            else
                check_warning "psql not installed, skipping database test"
            fi
        else
            check_error "PostgreSQL Server not found"
        fi
    fi
    
    # Redis
    if [ ! -z "$REDIS_NAME" ]; then
        if az redis show --name "$REDIS_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
            check_success "Redis Cache: $REDIS_NAME"
        else
            check_error "Redis Cache not found: $REDIS_NAME"
        fi
    fi
    
    # Container Apps Environment
    if [ ! -z "$CONTAINER_ENV" ]; then
        if az containerapp env show --name "$CONTAINER_ENV" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
            check_success "Container Apps Environment: $CONTAINER_ENV"
        else
            check_error "Container Apps Environment not found: $CONTAINER_ENV"
        fi
    fi
fi

echo ""

################################################################################
# 5. Check GitHub Secrets
################################################################################

echo -e "${CYAN}[5/7] Checking GitHub secrets...${NC}"
echo ""

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    # Get repo from git remote
    if git remote get-url origin &> /dev/null; then
        REPO_URL=$(git remote get-url origin)
        if [[ $REPO_URL =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
            check_success "Repository detected: $REPO"
            
            # List secrets
            GITHUB_SECRETS=$(gh secret list -R "$REPO" 2>/dev/null)
            
            REQUIRED_SECRETS=(
                "AZURE_CREDENTIALS"
                "ACR_LOGIN_SERVER"
                "ACR_USERNAME"
                "ACR_PASSWORD"
                "DATABASE_URL"
                "REDIS_URL"
                "AZURE_RESOURCE_GROUP"
                "CONTAINER_ENV"
            )
            
            for secret in "${REQUIRED_SECRETS[@]}"; do
                if echo "$GITHUB_SECRETS" | grep -q "$secret"; then
                    check_success "GitHub secret set: $secret"
                else
                    check_error "GitHub secret missing: $secret"
                fi
            done
        else
            check_warning "Could not parse GitHub repository URL"
        fi
    else
        check_warning "No git remote found"
    fi
else
    check_warning "GitHub CLI not available or not authenticated"
    echo -e "  ${YELLOW}Run: gh auth login${NC}"
fi

echo ""

################################################################################
# 6. Check Docker Images
################################################################################

echo -e "${CYAN}[6/7] Checking Docker images...${NC}"
echo ""

IMAGES=("wine-emulator" "backend" "frontend" "nginx")

for image in "${IMAGES[@]}"; do
    if docker images | grep -q "$image"; then
        VERSION=$(docker images | grep "$image" | awk 'NR==1{print $2}')
        check_success "Docker image exists: $image:$VERSION"
    else
        check_warning "Docker image not found: $image (run ./build-arm.sh)"
    fi
done

echo ""

################################################################################
# 7. Test API Endpoints
################################################################################

echo -e "${CYAN}[7/7] Testing deployed endpoints...${NC}"
echo ""

if [ ! -z "$AZURE_RESOURCE_GROUP" ]; then
    # Check if backend is deployed
    if az containerapp show --name wine-emulator-backend --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        BACKEND_FQDN=$(az containerapp show \
            --name wine-emulator-backend \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --query properties.configuration.ingress.fqdn \
            -o tsv 2>/dev/null)
        
        if [ ! -z "$BACKEND_FQDN" ]; then
            BACKEND_URL="https://$BACKEND_FQDN"
            check_success "Backend deployed: $BACKEND_URL"
            
            # Test health endpoint
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" 2>/dev/null)
            if [ "$HTTP_CODE" = "200" ]; then
                check_success "Backend health check passed (HTTP $HTTP_CODE)"
            else
                check_warning "Backend health check returned HTTP $HTTP_CODE"
            fi
        else
            check_warning "Backend FQDN not available"
        fi
    else
        check_warning "Backend not deployed yet"
    fi
    
    # Check if frontend is deployed
    if az containerapp show --name wine-emulator-frontend --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        FRONTEND_FQDN=$(az containerapp show \
            --name wine-emulator-frontend \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --query properties.configuration.ingress.fqdn \
            -o tsv 2>/dev/null)
        
        if [ ! -z "$FRONTEND_FQDN" ]; then
            FRONTEND_URL="https://$FRONTEND_FQDN"
            check_success "Frontend deployed: $FRONTEND_URL"
            
            # Test frontend
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" 2>/dev/null)
            if [ "$HTTP_CODE" = "200" ]; then
                check_success "Frontend accessible (HTTP $HTTP_CODE)"
            else
                check_warning "Frontend returned HTTP $HTTP_CODE"
            fi
        else
            check_warning "Frontend FQDN not available"
        fi
    else
        check_warning "Frontend not deployed yet"
    fi
else
    check_warning "Azure resources not configured, skipping deployment tests"
fi

echo ""

################################################################################
# Summary
################################################################################

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Verification Summary                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✓ Successes: $SUCCESSES${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}✗ Errors: $ERRORS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 All checks passed! Configuration is perfect.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Configuration is functional but has some warnings.${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ Configuration has errors. Please fix them before deploying.${NC}"
    echo ""
    echo -e "${YELLOW}Suggested next steps:${NC}"
    echo "1. Run: ${GREEN}./setup-azure-resources.sh${NC}"
    echo "2. Run: ${GREEN}./setup-github-secrets.sh${NC}"
    echo "3. Run: ${GREEN}./verify-secrets.sh${NC} again"
    exit 1
fi
