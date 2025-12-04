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
