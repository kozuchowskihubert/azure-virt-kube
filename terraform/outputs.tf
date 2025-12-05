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

# App Service URLs
output "wine_emulator_url" {
  description = "URL for the Wine Gaming App Service"
  value       = "https://${azurerm_linux_web_app.wine_gaming.default_hostname}"
}

output "backend_api_url" {
  description = "URL for the Backend API App Service"
  value       = "https://${azurerm_linux_web_app.backend_api.default_hostname}"
}

output "frontend_web_url" {
  description = "URL for the Frontend Web App Service"
  value       = "https://${azurerm_linux_web_app.frontend_web.default_hostname}"
}

# VNC Connection Info
output "vnc_connection_info" {
  description = "VNC connection details"
  value = {
    host     = azurerm_linux_web_app.wine_gaming.default_hostname
    port     = 5900
    password = "haos"
    url      = "vnc://${azurerm_linux_web_app.wine_gaming.default_hostname}:5900"
  }
}

# Complete deployment summary
output "deployment_summary" {
  description = "Complete deployment information"
  value = {
    wine_gaming_app    = "https://${azurerm_linux_web_app.wine_gaming.default_hostname}"
    backend_api        = "https://${azurerm_linux_web_app.backend_api.default_hostname}"
    frontend_web       = "https://${azurerm_linux_web_app.frontend_web.default_hostname}"
    container_registry = azurerm_container_registry.acr.login_server
    resource_group     = azurerm_resource_group.wine_emulator.name
    location          = azurerm_resource_group.wine_emulator.location
    app_service_plan   = azurerm_service_plan.app_service_plan.name
  }
}
