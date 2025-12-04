# Azure Container Apps Environment
resource "azurerm_container_app_environment" "wine_env" {
  name                       = "${var.app_name}-env"
  location                   = azurerm_resource_group.wine_emulator.location
  resource_group_name        = azurerm_resource_group.wine_emulator.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.wine_logs.id
  tags                       = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "wine_logs" {
  name                = "${var.app_name}-logs"
  location            = azurerm_resource_group.wine_emulator.location
  resource_group_name = azurerm_resource_group.wine_emulator.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Azure Database for PostgreSQL
resource "azurerm_postgresql_flexible_server" "wine_db" {
  name                   = "${var.app_name}-db"
  resource_group_name    = azurerm_resource_group.wine_emulator.name
  location               = azurerm_resource_group.wine_emulator.location
  version                = "15"
  administrator_login    = "winadmin"
  administrator_password = random_password.db_password.result
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  backup_retention_days  = 7
  tags                   = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "wine_emulator_db" {
  name      = "wine_emulator"
  server_id = azurerm_postgresql_flexible_server.wine_db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "wine_cache" {
  name                = "${var.app_name}-cache"
  location            = azurerm_resource_group.wine_emulator.location
  resource_group_name = azurerm_resource_group.wine_emulator.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  tags                = var.tags
}

# Storage Account for Wine data
resource "azurerm_storage_account" "wine_storage" {
  name                     = "${replace(var.app_name, "-", "")}sa"
  resource_group_name      = azurerm_resource_group.wine_emulator.name
  location                 = azurerm_resource_group.wine_emulator.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_share" "wine_share" {
  name                 = "wine-data"
  storage_account_name = azurerm_storage_account.wine_storage.name
  quota                = 100
}

# Container App - Backend API
resource "azurerm_container_app" "backend" {
  name                         = "${var.app_name}-backend"
  container_app_environment_id = azurerm_container_app_environment.wine_env.id
  resource_group_name          = azurerm_resource_group.wine_emulator.name
  revision_mode                = "Single"

  template {
    container {
      name   = "backend"
      image  = "${azurerm_container_registry.acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${azurerm_postgresql_flexible_server.wine_db.administrator_login}:${random_password.db_password.result}@${azurerm_postgresql_flexible_server.wine_db.fqdn}:5432/${azurerm_postgresql_flexible_server_database.wine_emulator_db.name}"
      }

      env {
        name  = "REDIS_URL"
        value = "rediss://:${azurerm_redis_cache.wine_cache.primary_access_key}@${azurerm_redis_cache.wine_cache.hostname}:6380"
      }

      env {
        name  = "WINE_SERVICE_URL"
        value = "http://${azurerm_container_app.wine_service.latest_revision_fqdn}"
      }
    }

    min_replicas = 1
    max_replicas = 5
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  tags = var.tags
}

# Container App - Frontend
resource "azurerm_container_app" "frontend" {
  name                         = "${var.app_name}-frontend"
  container_app_environment_id = azurerm_container_app_environment.wine_env.id
  resource_group_name          = azurerm_resource_group.wine_emulator.name
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.acr.login_server}/frontend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "NEXT_PUBLIC_API_URL"
        value = "https://${azurerm_container_app.backend.latest_revision_fqdn}"
      }

      env {
        name  = "NEXT_PUBLIC_WINE_VNC_URL"
        value = "https://${azurerm_container_app.wine_service.latest_revision_fqdn}"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  tags = var.tags
}

# Container App - Wine Service
# Supports x86 to x64 translation via Wine
# Compatible with both AMD64 and ARM64 architectures
resource "azurerm_container_app" "wine_service" {
  name                         = "${var.app_name}-wine"
  container_app_environment_id = azurerm_container_app_environment.wine_env.id
  resource_group_name          = azurerm_resource_group.wine_emulator.name
  revision_mode                = "Single"

  template {
    container {
      name   = "wine"
      image  = "${azurerm_container_registry.acr.login_server}/wine-service:latest"
      cpu    = 2
      memory = "4Gi"

      env {
        name  = "WINEARCH"
        value = "win64"  # Supports both x86 (32-bit) and x64 (64-bit) Windows applications
      }

      env {
        name  = "DISPLAY"
        value = ":0"
      }

      env {
        name  = "BOX86_NOBANNER"
        value = "1"  # For ARM64 systems with box86/box64 emulation
      }

      env {
        name  = "BOX64_NOBANNER"
        value = "1"  # For ARM64 x86_64 emulation
      }
    }

    min_replicas = 1
    max_replicas = 2
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  tags = var.tags
}
