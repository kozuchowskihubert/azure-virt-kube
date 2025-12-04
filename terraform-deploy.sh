#!/bin/bash

################################################################################
# Complete Terraform Deploy Script
# Creates all Azure resources and configures GitHub secrets
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TERRAFORM_DIR="./terraform"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Wine Emulator Platform - Terraform Deployment               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Step 1: Prerequisites
################################################################################

echo -e "${CYAN}[1/6] Checking prerequisites...${NC}"
echo ""

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not installed${NC}"
    echo "Install from: https://www.terraform.io/downloads"
    echo "Or use: brew install terraform"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed: $(terraform version -json | jq -r '.terraform_version')${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not installed${NC}"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    echo "Or use: brew install azure-cli"
    exit 1
fi
echo -e "${GREEN}✓ Azure CLI installed${NC}"

# Check Azure login
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo "Run: az login"
    exit 1
fi
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}✓ Logged in to Azure: $SUBSCRIPTION_NAME${NC}"

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not installed (optional)${NC}"
    echo "For automated secret setup, install: brew install gh"
    GH_AVAILABLE=false
else
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✓ GitHub CLI authenticated${NC}"
        GH_AVAILABLE=true
    else
        echo -e "${YELLOW}⚠️  GitHub CLI not authenticated${NC}"
        GH_AVAILABLE=false
    fi
fi

echo ""

################################################################################
# Step 2: Terraform Init
################################################################################

echo -e "${CYAN}[2/6] Initializing Terraform...${NC}"
echo ""

cd "$TERRAFORM_DIR"

terraform init -upgrade

echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

################################################################################
# Step 3: Terraform Plan
################################################################################

echo -e "${CYAN}[3/6] Planning infrastructure...${NC}"
echo ""

terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}Review the plan above. Continue? (yes/no)${NC}"
read -p "> " CONTINUE

if [[ ! $CONTINUE =~ ^[Yy](es)?$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 0
fi

echo ""

################################################################################
# Step 4: Terraform Apply
################################################################################

echo -e "${CYAN}[4/6] Creating Azure resources...${NC}"
echo ""
echo -e "${YELLOW}This will create:${NC}"
echo "  • Resource Group"
echo "  • Container Registry (ACR)"
echo "  • PostgreSQL Flexible Server"
echo "  • Redis Cache"
echo "  • Storage Account"
echo "  • Container Apps Environment"
echo "  • Log Analytics Workspace"
echo "  • Service Principal for GitHub"
echo ""

terraform apply tfplan

echo ""
echo -e "${GREEN}✓ Azure resources created${NC}"
echo ""

################################################################################
# Step 5: Extract Outputs
################################################################################

echo -e "${CYAN}[5/6] Extracting outputs...${NC}"
echo ""

# Show deployment summary
terraform output deployment_summary

# Save secrets to file
terraform output -json github_secrets_json > /tmp/github-secrets.json
echo -e "${GREEN}✓ Secrets saved to /tmp/github-secrets.json${NC}"
echo ""

################################################################################
# Step 6: Configure GitHub Secrets
################################################################################

echo -e "${CYAN}[6/6] Configuring GitHub secrets...${NC}"
echo ""

if [ "$GH_AVAILABLE" = true ]; then
    echo "Setting up GitHub secrets automatically..."
    cd ..
    ./scripts/apply-terraform-secrets.sh
else
    echo -e "${YELLOW}⚠️  GitHub CLI not available${NC}"
    echo ""
    echo "To set secrets manually:"
    echo "1. Extract secrets: terraform output -json github_secrets_json | jq"
    echo "2. Go to: https://github.com/kozuchowskihubert/azure-virt-kube/settings/secrets/actions"
    echo "3. Add each secret manually"
    echo ""
    echo "Or install GitHub CLI and run:"
    echo "  brew install gh"
    echo "  gh auth login"
    echo "  ./scripts/apply-terraform-secrets.sh"
fi

echo ""

################################################################################
# Summary
################################################################################

cd "$TERRAFORM_DIR"

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Deployment Complete!                                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 Resources Created:${NC}"
terraform output -json | jq -r '
  .resource_group_name.value as $rg |
  .container_registry_login_server.value as $acr |
  .database_host.value as $db |
  .redis_host.value as $redis |
  "  • Resource Group: " + $rg,
  "  • Container Registry: " + $acr,
  "  • PostgreSQL: " + $db,
  "  • Redis: " + $redis
'
echo ""

echo -e "${BLUE}🔗 URLs:${NC}"
echo "  • Frontend: $(terraform output -raw frontend_url 2>/dev/null || echo 'Not deployed yet')"
echo "  • Backend: $(terraform output -raw backend_url 2>/dev/null || echo 'Not deployed yet')"
echo "  • Wine Service: $(terraform output -raw wine_service_url 2>/dev/null || echo 'Not deployed yet')"
echo ""

echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. View secrets (if needed):"
echo "   ${GREEN}terraform output -json github_secrets_json | jq${NC}"
echo ""
echo "2. Build and push Docker images:"
echo "   ${GREEN}ACR_SERVER=\$(terraform output -raw container_registry_login_server)${NC}"
echo "   ${GREEN}az acr login --name \$(terraform output -raw container_registry_name 2>/dev/null | tr -d '\\n')${NC}"
echo "   ${GREEN}cd .. && ./build-arm.sh multi${NC}"
echo "   ${GREEN}docker tag wine-emulator:latest \$ACR_SERVER/wine-emulator:latest${NC}"
echo "   ${GREEN}docker push \$ACR_SERVER/wine-emulator:latest${NC}"
echo ""
echo "3. Deploy via GitHub Actions:"
echo "   ${GREEN}git push origin main${NC}"
echo ""
echo "4. Monitor deployment:"
echo "   ${GREEN}gh run watch -R kozuchowskihubert/azure-virt-kube${NC}"
echo ""

echo -e "${BLUE}🔐 Security:${NC}"
echo "  • Secrets stored in GitHub: https://github.com/kozuchowskihubert/azure-virt-kube/settings/secrets/actions"
echo "  • Service Principal created with minimal permissions"
echo "  • All passwords randomly generated"
echo ""

echo -e "${GREEN}🎉 Ready to deploy!${NC}"
