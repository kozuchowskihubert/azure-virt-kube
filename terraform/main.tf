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

# Create App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.app_name}-plan"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_resource_group.wine_emulator.location
  os_type             = "Linux"
  sku_name            = "P1v3"
  tags                = var.tags
}

# Wine Gaming App Service
resource "azurerm_linux_web_app" "wine_gaming" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_service_plan.app_service_plan.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id
  tags                = var.tags

  site_config {
    always_on = true
    
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/wine-gaming"
      docker_image_tag = "latest"
    }

    app_command_line = "/app/start-wine.sh"
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
  name                = "${var.app_name}-api"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_service_plan.app_service_plan.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id
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
  name                = "${var.app_name}-web"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_service_plan.app_service_plan.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id
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
