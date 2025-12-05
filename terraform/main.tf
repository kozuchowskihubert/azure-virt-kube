# Create Azure Resource Group
resource "azurerm_resource_group" "wine_emulator" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.app_name, "-", "")}acr"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_resource_group.wine_emulator.location
  sku                 = "Standard"
  admin_enabled       = true
  tags                = var.tags
}

# ===============================================
# KUBERNETES INFRASTRUCTURE (AKS)
# ===============================================

# Create Azure Kubernetes Service (AKS) cluster
resource "azurerm_kubernetes_cluster" "aks" {
  count               = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? 1 : 0
  name                = "${var.app_name}-aks"
  location            = azurerm_resource_group.wine_emulator.location
  resource_group_name = azurerm_resource_group.wine_emulator.name
  dns_prefix          = "${var.app_name}-aks"
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_node_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet[0].id
    
    # Enable auto-scaling
    enable_auto_scaling = true
    min_count          = var.aks_min_nodes
    max_count          = var.aks_max_nodes
    
    # Node configuration for Wine Gaming workloads
    os_disk_size_gb = 100
    os_disk_type    = "Managed"
    
    node_labels = {
      "workload" = "wine-gaming"
      "environment" = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = "10.2.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.2.0.0/24"
  }

  role_based_access_control_enabled = true

  # Enable monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs[0].id
  }

  # Auto-upgrade settings
  automatic_channel_upgrade = "patch"
  
  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].node_count
    ]
  }
}

# Create Virtual Network for AKS
resource "azurerm_virtual_network" "aks_vnet" {
  count               = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? 1 : 0
  name                = "${var.app_name}-aks-vnet"
  location            = azurerm_resource_group.wine_emulator.location
  resource_group_name = azurerm_resource_group.wine_emulator.name
  address_space       = ["10.1.0.0/16"]
  tags                = var.tags
}

# Create subnet for AKS nodes
resource "azurerm_subnet" "aks_subnet" {
  count                = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? 1 : 0
  name                 = "${var.app_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.wine_emulator.name
  virtual_network_name = azurerm_virtual_network.aks_vnet[0].name
  address_prefixes     = ["10.1.1.0/24"]
  
  # Enable service endpoints for ACR integration
  service_endpoints = ["Microsoft.ContainerRegistry"]
}

# Create Log Analytics workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "aks_logs" {
  count               = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? 1 : 0
  name                = "${var.app_name}-aks-logs"
  location            = azurerm_resource_group.wine_emulator.location
  resource_group_name = azurerm_resource_group.wine_emulator.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr" {
  count                = var.deployment_target == "kubernetes" || var.deployment_target == "both" ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.aks[0].kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# ===============================================
# APP SERVICE INFRASTRUCTURE
# ===============================================

# Create App Service Plan (only if deploying to App Service)
resource "azurerm_service_plan" "app_service_plan" {
  count               = var.deployment_target == "app-service" || var.deployment_target == "both" ? 1 : 0
  name                = "${var.app_name}-plan"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_resource_group.wine_emulator.location
  os_type             = "Linux"
  sku_name            = "P1v3"
  tags                = var.tags
}

# Wine Gaming App Service
resource "azurerm_linux_web_app" "wine_gaming" {
  count               = var.deployment_target == "app-service" || var.deployment_target == "both" ? 1 : 0
  name                = var.app_name
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_service_plan.app_service_plan[0].location
  service_plan_id     = azurerm_service_plan.app_service_plan[0].id
  tags                = var.tags

  site_config {
    always_on = true
    
    application_stack {
      docker_image     = var.wine_gaming_image != "" ? split(":", var.wine_gaming_image)[0] : "${azurerm_container_registry.acr.login_server}/wine-gaming"
      docker_image_tag = var.wine_gaming_image != "" ? split(":", var.wine_gaming_image)[1] : "latest"
    }

    app_command_line = "/app/start-wine.sh"
    
    # Health check configuration
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 2
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL      = azurerm_container_registry.acr.login_server
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                   = "5900"
    
    # Wine Environment
    DISPLAY                         = ":99"
    VNC_PASSWORD                   = "haos"
    WINE_DEBUG                     = "-all"
    WINEARCH                       = "win32"
    WINEPREFIX                     = "/home/wineuser/.wine"
    
    # Gaming Configuration
    GAME_RESOLUTION                = "800x600"
    VNC_GEOMETRY                   = "800x600"
    ENABLE_AUDIO                   = "false"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}

# Backend API App Service
resource "azurerm_linux_web_app" "backend_api" {
  count               = var.deployment_target == "app-service" || var.deployment_target == "both" ? 1 : 0
  name                = "${var.app_name}-api"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_service_plan.app_service_plan[0].location
  service_plan_id     = azurerm_service_plan.app_service_plan[0].id
  tags                = var.tags

  site_config {
    always_on = true
    
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/backend-api"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL      = azurerm_container_registry.acr.login_server
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                   = "8000"
    
    # Backend Configuration
    ENV                            = "production"
    DEBUG                          = "false"
    WINE_CONTAINER_URL             = "https://${var.app_name}.azurewebsites.net"
    VNC_HOST                       = "${var.app_name}.azurewebsites.net"
    VNC_PORT                       = "5900"
  }
}

# Frontend Web App Service
resource "azurerm_linux_web_app" "frontend_web" {
  count               = var.deployment_target == "app-service" || var.deployment_target == "both" ? 1 : 0
  name                = "${var.app_name}-web"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_service_plan.app_service_plan[0].location
  service_plan_id     = azurerm_service_plan.app_service_plan[0].id
  tags                = var.tags

  site_config {
    always_on = true
    
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/frontend-web"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL      = azurerm_container_registry.acr.login_server
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                   = "3000"
    
    # Frontend Configuration
    NODE_ENV                       = "production"
    NEXT_PUBLIC_API_URL           = "https://${var.app_name}-api.azurewebsites.net"
    NEXT_PUBLIC_VNC_URL           = "wss://${var.app_name}.azurewebsites.net/vnc"
    NEXT_PUBLIC_WINE_URL          = "https://${var.app_name}.azurewebsites.net"
  }
}

# NOTE: Kubernetes resources commented out - using Azure Container Apps instead
# Uncomment these resources if deploying to AKS or k3d cluster

# # Create Kubernetes Namespace
# resource "kubernetes_namespace" "wine_emulator" {
#   metadata {
#     name = var.namespace
#     labels = {
#       name        = var.namespace
#       environment = var.tags["Environment"]
#     }
#   }
# }

# # Create ConfigMap for Wine Configuration
# resource "kubernetes_config_map" "wine_config" {
#   metadata {
#     name      = "${var.app_name}-config"
#     namespace = kubernetes_namespace.wine_emulator.metadata[0].name
#   }

#   data = {
#     "wine.conf" = <<-EOT
#       # Wine Configuration
#       WINEDEBUG=-all
#       WINEARCH=win64
#       DISPLAY=:0
#     EOT
#   }
# }

# # Create Persistent Volume Claim for Wine Prefix
# resource "kubernetes_persistent_volume_claim" "wine_storage" {
#   metadata {
#     name      = "${var.app_name}-storage"
#     namespace = kubernetes_namespace.wine_emulator.metadata[0].name
#   }

#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = var.storage_size
#       }
#     }
#   }
# }

# # Create Deployment for Wine Emulator
# resource "kubernetes_deployment" "wine_emulator" {
#   metadata {
#     name      = var.app_name
#     namespace = kubernetes_namespace.wine_emulator.metadata[0].name
#     labels = {
#       app     = var.app_name
#       version = var.app_version
#     }
#   }

#   spec {
#     replicas = var.replicas

#     selector {
#       match_labels = {
#         app = var.app_name
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app     = var.app_name
#           version = var.app_version
#         }
#       }

#       spec {
#         container {
#           name  = "wine-emulator"
#           image = var.container_image

#           port {
#             container_port = 8080
#             name           = "http"
#           }

#           port {
#             container_port = 5900
#             name           = "vnc"
#           }

#           env {
#             name  = "WINEARCH"
#             value = "win64"
#           }

#           env {
#             name  = "DISPLAY"
#             value = ":0"
#           }

#           volume_mount {
#             name       = "wine-storage"
#             mount_path = "/root/.wine"
#           }

#           volume_mount {
#             name       = "config"
#             mount_path = "/etc/wine"
#           }

#           resources {
#             limits = {
#               cpu    = "2000m"
#               memory = "4Gi"
#             }
#             requests = {
#               cpu    = "500m"
#               memory = "1Gi"
#             }
#           }

#           liveness_probe {
#             http_get {
#               path = "/health"
#               port = 8080
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#           }

#           readiness_probe {
#             http_get {
#               path = "/ready"
#               port = 8080
#             }
#             initial_delay_seconds = 10
#             period_seconds        = 5
#           }
#         }

#         volume {
#           name = "wine-storage"
#           persistent_volume_claim {
#             claim_name = kubernetes_persistent_volume_claim.wine_storage.metadata[0].name
#           }
#         }

#         volume {
#           name = "config"
#           config_map {
#             name = kubernetes_config_map.wine_config.metadata[0].name
#           }
#         }
#       }
#     }
#   }
# }

# # Create Service for Wine Emulator
# resource "kubernetes_service" "wine_emulator" {
#   metadata {
#     name      = var.app_name
#     namespace = kubernetes_namespace.wine_emulator.metadata[0].name
#     labels = {
#       app = var.app_name
#     }
#   }

#   spec {
#     type = var.service_type

#     selector = {
#       app = var.app_name
#     }

#     port {
#       name        = "http"
#       port        = var.service_port
#       target_port = 8080
#       protocol    = "TCP"
#     }

#     port {
#       name        = "vnc"
#       port        = 5900
#       target_port = 5900
#       protocol    = "TCP"
#     }
#   }
# }

# # Create Ingress for Wine Emulator (optional)
# resource "kubernetes_ingress_v1" "wine_emulator" {
#   metadata {
#     name      = var.app_name
#     namespace = kubernetes_namespace.wine_emulator.metadata[0].name
#     annotations = {
#       "kubernetes.io/ingress.class" = "traefik"
#     }
#   }

#   spec {
#     rule {
#       host = "wine-emulator.local"

#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"

#           backend {
#             service {
#               name = kubernetes_service.wine_emulator.metadata[0].name
#               port {
#                 number = var.service_port
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
