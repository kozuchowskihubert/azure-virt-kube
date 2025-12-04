#!/bin/bash

################################################################################
# Apply Terraform Secrets to GitHub
# This script extracts secrets from Terraform output and sets them in GitHub
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO="kozuchowskihubert/azure-virt-kube"
TERRAFORM_DIR="../terraform"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Apply Terraform Secrets to GitHub                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Prerequisites
################################################################################

echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not installed${NC}"
    echo "Install from: https://www.terraform.io/downloads"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not installed${NC}"
    echo "Install: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

################################################################################
# Extract Terraform Outputs
################################################################################

echo -e "${YELLOW}[2/4] Extracting Terraform secrets...${NC}"

cd "$TERRAFORM_DIR"

# Check if Terraform has been applied
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}❌ No Terraform state found${NC}"
    echo "Run: cd terraform && terraform apply"
    exit 1
fi

# Extract secrets as JSON
echo "Extracting secrets from Terraform state..."
SECRETS_JSON=$(terraform output -json github_secrets_json 2>/dev/null)

if [ -z "$SECRETS_JSON" ]; then
    echo -e "${RED}❌ Failed to extract secrets from Terraform${NC}"
    exit 1
fi

# Parse the JSON (it's double-encoded)
SECRETS=$(echo "$SECRETS_JSON" | jq -r '.')

echo -e "${GREEN}✓ Secrets extracted${NC}"
echo ""

################################################################################
# Set GitHub Secrets
################################################################################

echo -e "${YELLOW}[3/4] Setting GitHub secrets...${NC}"
echo ""

# Function to set secret
set_secret() {
    local name=$1
    local value=$2
    
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo -e "  ${YELLOW}⚠️  Skipping $name (empty)${NC}"
        return
    fi
    
    if echo "$value" | gh secret set "$name" -R "$REPO" 2>/dev/null; then
        echo -e "  ${GREEN}✓ $name${NC}"
    else
        echo -e "  ${RED}✗ $name (failed)${NC}"
    fi
}

# Set each secret
echo "$SECRETS" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS='=' read -r key value; do
    set_secret "$key" "$value"
done

echo ""
echo -e "${GREEN}✓ GitHub secrets configured${NC}"
echo ""

################################################################################
# Verify Secrets
################################################################################

echo -e "${YELLOW}[4/4] Verifying secrets...${NC}"

SECRET_COUNT=$(gh secret list -R "$REPO" | wc -l)
echo -e "${GREEN}✓ Total secrets: $SECRET_COUNT${NC}"
echo ""

gh secret list -R "$REPO"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✅ GitHub Secrets Configured from Terraform!         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Next steps:${NC}"
echo "1. Review secrets: gh secret list -R $REPO"
echo "2. Trigger deployment: git push origin main"
echo "3. Monitor: gh workflow list -R $REPO"
echo ""
