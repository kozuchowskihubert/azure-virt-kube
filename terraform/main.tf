# Create Azure Resource Group
resource "azurerm_resource_group" "wine_emulator" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Azure Container Registry (optional - for custom Wine images)
resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.app_name, "-", "")}acr"
  resource_group_name = azurerm_resource_group.wine_emulator.name
  location            = azurerm_resource_group.wine_emulator.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
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
