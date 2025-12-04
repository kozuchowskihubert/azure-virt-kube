output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.wine_emulator.name
}

output "container_registry_login_server" {
  description = "Login server for Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Admin password for Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "frontend_url" {
  description = "URL for the frontend application"
  value       = "https://${azurerm_container_app.frontend.latest_revision_fqdn}"
}

output "backend_url" {
  description = "URL for the backend API"
  value       = "https://${azurerm_container_app.backend.latest_revision_fqdn}"
}

output "wine_service_url" {
  description = "URL for the Wine emulator service"
  value       = "https://${azurerm_container_app.wine_service.latest_revision_fqdn}"
}

output "database_host" {
  description = "PostgreSQL database host"
  value       = azurerm_postgresql_flexible_server.wine_db.fqdn
  sensitive   = true
}

output "redis_host" {
  description = "Redis cache host"
  value       = azurerm_redis_cache.wine_cache.hostname
  sensitive   = true
}

# =============================================================================
# GitHub Secrets Output - Complete JSON for automation
# =============================================================================

output "github_secrets_json" {
  description = "All GitHub secrets in JSON format for automation"
  sensitive   = true
  value = jsonencode({
    AZURE_CREDENTIALS = jsonencode({
      clientId       = azuread_application.github_actions.client_id
      clientSecret   = azuread_service_principal_password.github_actions.value
      subscriptionId = data.azurerm_client_config.current.subscription_id
      tenantId       = data.azurerm_client_config.current.tenant_id
    })
    
    ACR_LOGIN_SERVER = azurerm_container_registry.acr.login_server
    ACR_USERNAME     = azurerm_container_registry.acr.admin_username
    ACR_PASSWORD     = azurerm_container_registry.acr.admin_password
    REGISTRY_NAME    = azurerm_container_registry.acr.name
    
    DATABASE_URL      = "postgresql://${azurerm_postgresql_flexible_server.wine_db.administrator_login}:${random_password.db_password.result}@${azurerm_postgresql_flexible_server.wine_db.fqdn}:5432/${azurerm_postgresql_flexible_server_database.wine_emulator_db.name}"
    POSTGRES_HOST     = azurerm_postgresql_flexible_server.wine_db.fqdn
    POSTGRES_USER     = azurerm_postgresql_flexible_server.wine_db.administrator_login
    POSTGRES_PASSWORD = random_password.db_password.result
    POSTGRES_DB       = azurerm_postgresql_flexible_server_database.wine_emulator_db.name
    
    REDIS_URL  = "rediss://:${azurerm_redis_cache.wine_cache.primary_access_key}@${azurerm_redis_cache.wine_cache.hostname}:6380"
    REDIS_HOST = azurerm_redis_cache.wine_cache.hostname
    REDIS_KEY  = azurerm_redis_cache.wine_cache.primary_access_key
    
    STORAGE_ACCOUNT_NAME      = azurerm_storage_account.wine_storage.name
    STORAGE_CONNECTION_STRING = azurerm_storage_account.wine_storage.primary_connection_string
    
    AZURE_RESOURCE_GROUP   = azurerm_resource_group.wine_emulator.name
    AZURE_SUBSCRIPTION_ID  = data.azurerm_client_config.current.subscription_id
    AZURE_LOCATION         = azurerm_resource_group.wine_emulator.location
    CONTAINER_ENV          = azurerm_container_app_environment.wine_env.name
    
    LOG_ANALYTICS_WORKSPACE_ID = azurerm_log_analytics_workspace.wine_logs.workspace_id
    LOG_ANALYTICS_KEY          = azurerm_log_analytics_workspace.wine_logs.primary_shared_key
    
    SECRET_KEY = random_password.secret_key.result
    JWT_SECRET = random_password.jwt_secret.result
    
    WINE_VERSION = "8.0"
    WINEARCH     = "win64"
    DISPLAY      = ":0"
  })
}

output "deployment_summary" {
  description = "Deployment summary and next steps"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════╗
    ║  ✅ Azure Resources Created - Wine Emulator Platform   ║
    ╚══════════════════════════════════════════════════════════╝
    
    📊 Resources:
       • Resource Group: ${azurerm_resource_group.wine_emulator.name}
       • ACR: ${azurerm_container_registry.acr.login_server}
       • Database: ${azurerm_postgresql_flexible_server.wine_db.fqdn}
       • Redis: ${azurerm_redis_cache.wine_cache.hostname}
    
    🚀 Next Steps:
    
    1. Export secrets:
       terraform output -json github_secrets_json > /tmp/secrets.json
    
    2. Set GitHub secrets:
       cd .. && ./scripts/apply-terraform-secrets.sh
    
    3. Push to trigger deployment:
       git push origin main
    
  EOT
}
