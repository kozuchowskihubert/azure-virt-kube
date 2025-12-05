# =============================================================================
# Service Principal for GitHub Actions - DISABLED
# =============================================================================
# 
# NOTE: We already have AZURE_CREDENTIALS configured in GitHub Secrets
# These resources are commented out to avoid Azure AD permission issues
# Our existing service principal has the necessary permissions

# Create Azure AD Application - DISABLED (using existing service principal)
# resource "azuread_application" "github_actions" {
#   display_name = "${var.app_name}-github-actions"
# }

# Create Service Principal - DISABLED (using existing service principal)
# resource "azuread_service_principal" "github_actions" {
#   client_id = azuread_application.github_actions.client_id
# }

# Create Service Principal Password - DISABLED (using existing service principal)
# resource "azuread_service_principal_password" "github_actions" {
#   service_principal_id = azuread_service_principal.github_actions.id
#   end_date_relative    = "17520h" # 2 years
# }

# Role assignments will use data sources for existing service principal instead

# =============================================================================
# Data Sources for Existing Service Principal
# =============================================================================

# Get current Azure client configuration (our existing service principal)
data "azurerm_client_config" "current" {}

# Assign Contributor role to existing Service Principal for the Resource Group
resource "azurerm_role_assignment" "github_actions_contributor" {
  scope                = azurerm_resource_group.wine_emulator.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign AcrPush role for Container Registry to existing Service Principal
resource "azurerm_role_assignment" "github_actions_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

# =============================================================================
# Random Secrets Generation
# =============================================================================

resource "random_password" "secret_key" {
  length  = 64
  special = true
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

# =============================================================================
# GitHub Secrets (using GitHub provider)
# =============================================================================

# Note: Requires GitHub provider to be configured
# terraform {
#   required_providers {
#     github = {
#       source  = "integrations/github"
#       version = "~> 5.0"
#     }
#   }
# }

# Uncomment and configure if using GitHub provider:
# resource "github_actions_secret" "azure_credentials" {
#   repository      = "azure-virt-kube"
#   secret_name     = "AZURE_CREDENTIALS"
#   plaintext_value = jsonencode({
#     clientId       = azuread_application.github_actions.client_id
#     clientSecret   = azuread_service_principal_password.github_actions.value
#     subscriptionId = data.azurerm_client_config.current.subscription_id
#     tenantId       = data.azurerm_client_config.current.tenant_id
#   })
# }

# =============================================================================
# Data Sources for Subscription Info
# =============================================================================

data "azurerm_subscription" "current" {}
