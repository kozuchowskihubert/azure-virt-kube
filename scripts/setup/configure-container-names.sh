#!/bin/bash

###############################################################################
# Container Name Configuration Script
###############################################################################
# Interactive script to configure container names and deployment settings
# for the Wine Emulator Platform
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🐳 Wine Emulator - Container Configuration Wizard        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

###############################################################################
# Default Values
###############################################################################
DEFAULT_APP_NAME="wine-emulator"
DEFAULT_BACKEND_NAME="wine-emulator-backend"
DEFAULT_FRONTEND_NAME="wine-emulator-frontend"
DEFAULT_WINE_NAME="wine-emulator-wine"
DEFAULT_ACR_NAME="wineemulatoracr"
DEFAULT_RESOURCE_GROUP="wine-emulator-rg"
DEFAULT_LOCATION="eastus"

###############################################################################
# Current Configuration Display
###############################################################################
echo -e "${CYAN}📋 Current Configuration:${NC}"
echo ""
echo -e "${GREEN}Application Name:${NC}      $DEFAULT_APP_NAME"
echo -e "${GREEN}Resource Group:${NC}        $DEFAULT_RESOURCE_GROUP"
echo -e "${GREEN}Azure Location:${NC}        $DEFAULT_LOCATION"
echo ""
echo -e "${CYAN}Container Names:${NC}"
echo -e "  ${GREEN}Backend:${NC}             $DEFAULT_BACKEND_NAME"
echo -e "  ${GREEN}Frontend:${NC}            $DEFAULT_FRONTEND_NAME"
echo -e "  ${GREEN}Wine Service:${NC}        $DEFAULT_WINE_NAME"
echo ""
echo -e "${CYAN}Azure Container Registry:${NC}"
echo -e "  ${GREEN}Name:${NC}                $DEFAULT_ACR_NAME"
echo -e "  ${GREEN}Server:${NC}              ${DEFAULT_ACR_NAME}.azurecr.io"
echo ""

###############################################################################
# Ask if user wants to customize
###############################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""
read -p "$(echo -e ${CYAN}Do you want to customize these names? [y/N]: ${NC})" CUSTOMIZE

if [[ ! "$CUSTOMIZE" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}✓ Using default configuration${NC}"
    APP_NAME="$DEFAULT_APP_NAME"
    BACKEND_NAME="$DEFAULT_BACKEND_NAME"
    FRONTEND_NAME="$DEFAULT_FRONTEND_NAME"
    WINE_NAME="$DEFAULT_WINE_NAME"
    ACR_NAME="$DEFAULT_ACR_NAME"
    RESOURCE_GROUP="$DEFAULT_RESOURCE_GROUP"
    LOCATION="$DEFAULT_LOCATION"
else
    ###########################################################################
    # Interactive Configuration
    ###########################################################################
    echo ""
    echo -e "${CYAN}🔧 Custom Configuration:${NC}"
    echo ""
    
    # Application Name
    read -p "$(echo -e ${GREEN}Application name ${NC}[${DEFAULT_APP_NAME}]: )" APP_NAME
    APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"
    
    # Resource Group
    read -p "$(echo -e ${GREEN}Resource group ${NC}[${DEFAULT_RESOURCE_GROUP}]: )" RESOURCE_GROUP
    RESOURCE_GROUP="${RESOURCE_GROUP:-$DEFAULT_RESOURCE_GROUP}"
    
    # Location
    echo ""
    echo -e "${YELLOW}Available Azure Locations:${NC}"
    echo "  • eastus (US East)"
    echo "  • westus2 (US West 2)"
    echo "  • westeurope (West Europe)"
    echo "  • northeurope (North Europe)"
    echo "  • southeastasia (Southeast Asia)"
    read -p "$(echo -e ${GREEN}Azure location ${NC}[${DEFAULT_LOCATION}]: )" LOCATION
    LOCATION="${LOCATION:-$DEFAULT_LOCATION}"
    
    # Container Names
    echo ""
    echo -e "${CYAN}Container App Names:${NC}"
    read -p "$(echo -e ${GREEN}Backend container name ${NC}[${APP_NAME}-backend]: )" BACKEND_NAME
    BACKEND_NAME="${BACKEND_NAME:-${APP_NAME}-backend}"
    
    read -p "$(echo -e ${GREEN}Frontend container name ${NC}[${APP_NAME}-frontend]: )" FRONTEND_NAME
    FRONTEND_NAME="${FRONTEND_NAME:-${APP_NAME}-frontend}"
    
    read -p "$(echo -e ${GREEN}Wine service container name ${NC}[${APP_NAME}-wine]: )" WINE_NAME
    WINE_NAME="${WINE_NAME:-${APP_NAME}-wine}"
    
    # ACR Name (must be alphanumeric, no hyphens)
    echo ""
    ACR_DEFAULT=$(echo "${APP_NAME}acr" | tr -d '-')
    read -p "$(echo -e ${GREEN}ACR name (alphanumeric only) ${NC}[${ACR_DEFAULT}]: )" ACR_NAME
    ACR_NAME="${ACR_NAME:-$ACR_DEFAULT}"
    # Remove any non-alphanumeric characters
    ACR_NAME=$(echo "$ACR_NAME" | tr -cd '[:alnum:]')
fi

###############################################################################
# Configuration Summary
###############################################################################
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  📊 Configuration Summary                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}General:${NC}"
echo -e "  Application Name:    ${GREEN}${APP_NAME}${NC}"
echo -e "  Resource Group:      ${GREEN}${RESOURCE_GROUP}${NC}"
echo -e "  Location:            ${GREEN}${LOCATION}${NC}"
echo ""

echo -e "${CYAN}Container Applications:${NC}"
echo -e "  Backend:             ${GREEN}${BACKEND_NAME}${NC}"
echo -e "  Frontend:            ${GREEN}${FRONTEND_NAME}${NC}"
echo -e "  Wine Service:        ${GREEN}${WINE_NAME}${NC}"
echo ""

echo -e "${CYAN}Container Registry:${NC}"
echo -e "  ACR Name:            ${GREEN}${ACR_NAME}${NC}"
echo -e "  ACR Server:          ${GREEN}${ACR_NAME}.azurecr.io${NC}"
echo ""

echo -e "${CYAN}Image Names:${NC}"
echo -e "  Backend:             ${GREEN}${ACR_NAME}.azurecr.io/backend:latest${NC}"
echo -e "  Frontend:            ${GREEN}${ACR_NAME}.azurecr.io/frontend:latest${NC}"
echo -e "  Wine Service:        ${GREEN}${ACR_NAME}.azurecr.io/wine-service:latest${NC}"
echo ""

###############################################################################
# Confirm Configuration
###############################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""
read -p "$(echo -e ${CYAN}Is this configuration correct? [Y/n]: ${NC})" CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Configuration cancelled. Run the script again to reconfigure.${NC}"
    exit 0
fi

###############################################################################
# Save Configuration
###############################################################################
echo ""
echo -e "${YELLOW}💾 Saving configuration...${NC}"

CONFIG_FILE="terraform/terraform.tfvars"
cat > "$CONFIG_FILE" << EOF
# Wine Emulator Platform Configuration
# Generated: $(date)

# Application Configuration
app_name     = "$APP_NAME"
app_version  = "1.0.0"

# Azure Configuration
location            = "$LOCATION"
resource_group_name = "$RESOURCE_GROUP"

# Container Names (defined in azure-resources.tf)
# Backend:  ${BACKEND_NAME}
# Frontend: ${FRONTEND_NAME}
# Wine:     ${WINE_NAME}

# Tags
tags = {
  Environment = "Production"
  Project     = "Wine Emulator Platform"
  ManagedBy   = "Terraform"
  Platform    = "Azure Container Apps"
}
EOF

echo -e "${GREEN}✓ Configuration saved to: ${CONFIG_FILE}${NC}"

###############################################################################
# Update GitHub Secrets
###############################################################################
echo ""
read -p "$(echo -e ${CYAN}Update GitHub secrets with new names? [Y/n]: ${NC})" UPDATE_SECRETS

if [[ ! "$UPDATE_SECRETS" =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${YELLOW}📤 Updating GitHub secrets...${NC}"
    
    # Check if gh is installed
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) not found${NC}"
        echo -e "${YELLOW}Install with: brew install gh${NC}"
        exit 1
    fi
    
    REPO="kozuchowskihubert/azure-virt-kube"
    
    echo "$RESOURCE_GROUP" | gh secret set AZURE_RESOURCE_GROUP -R "$REPO"
    echo -e "${GREEN}✓ Set AZURE_RESOURCE_GROUP${NC}"
    
    echo "$LOCATION" | gh secret set AZURE_LOCATION -R "$REPO"
    echo -e "${GREEN}✓ Set AZURE_LOCATION${NC}"
    
    echo "$ACR_NAME" | gh secret set ACR_NAME -R "$REPO"
    echo -e "${GREEN}✓ Set ACR_NAME${NC}"
    
    echo "${ACR_NAME}.azurecr.io" | gh secret set ACR_LOGIN_SERVER -R "$REPO"
    echo -e "${GREEN}✓ Set ACR_LOGIN_SERVER${NC}"
    
    echo ""
    echo -e "${GREEN}✓ GitHub secrets updated${NC}"
fi

###############################################################################
# Next Steps
###############################################################################
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     ✅ Configuration Complete!                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📋 Next Steps:${NC}"
echo ""
echo -e "${YELLOW}1. Review Terraform configuration:${NC}"
echo -e "   cat terraform/terraform.tfvars"
echo ""
echo -e "${YELLOW}2. Initialize Terraform:${NC}"
echo -e "   cd terraform && terraform init"
echo ""
echo -e "${YELLOW}3. Plan infrastructure:${NC}"
echo -e "   terraform plan -out=tfplan"
echo ""
echo -e "${YELLOW}4. Apply infrastructure:${NC}"
echo -e "   terraform apply tfplan"
echo ""
echo -e "${YELLOW}5. Or use the automated deployment script:${NC}"
echo -e "   ./terraform-deploy.sh"
echo ""

echo -e "${GREEN}✨ Configuration saved and ready for deployment!${NC}"
echo ""

###############################################################################
# Display Configuration Files
###############################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📄 Generated Configuration File:${NC}"
echo ""
cat "$CONFIG_FILE"
echo ""
