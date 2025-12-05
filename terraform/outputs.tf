output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.wine_emulator.name
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.wine_emulator.location
}

output "deployment_target" {
  description = "Deployment target used"
  value       = var.deployment_target
}

# ===============================================
# CONTAINER REGISTRY OUTPUTS
# ===============================================

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

# ===============================================
# APP SERVICE OUTPUTS (when deployed)
# ===============================================

output "wine_emulator_url" {
  description = "URL for the Wine Gaming App Service"
  value       = var.deployment_target == "app-service" || var.deployment_target == "both" ? "https://${azurerm_linux_web_app.wine_gaming[0].default_hostname}" : ""
}

output "backend_api_url" {
  description = "URL for the Backend API App Service"
  value       = var.deployment_target == "app-service" || var.deployment_target == "both" ? "https://${azurerm_linux_web_app.backend_api[0].default_hostname}" : ""
}

output "frontend_web_url" {
  description = "URL for the Frontend Web App Service"
  value       = var.deployment_target == "app-service" || var.deployment_target == "both" ? "https://${azurerm_linux_web_app.frontend_web[0].default_hostname}" : ""
}

# VNC Connection Info for App Service
output "vnc_connection_info" {
  description = "VNC connection details for App Service deployment"
  value = var.deployment_target == "app-service" || var.deployment_target == "both" ? {
    host     = azurerm_linux_web_app.wine_gaming[0].default_hostname
    port     = 5900
    password = "haos"
    url      = "vnc://${azurerm_linux_web_app.wine_gaming[0].default_hostname}:5900"
  } : null
}

# ===============================================
# KUBERNETES OUTPUTS (when deployed)
# ===============================================

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? azurerm_kubernetes_cluster.aks[0].name : ""
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? azurerm_kubernetes_cluster.aks[0].fqdn : ""
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? azurerm_kubernetes_cluster.aks[0].id : ""
}

output "aks_node_resource_group" {
  description = "Resource group for AKS nodes"
  value       = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? azurerm_kubernetes_cluster.aks[0].node_resource_group : ""
}

output "aks_kubelet_identity" {
  description = "Kubelet identity for AKS cluster"
  value = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? {
    client_id = azurerm_kubernetes_cluster.aks[0].kubelet_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.aks[0].kubelet_identity[0].object_id
  } : null
  sensitive = true
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
