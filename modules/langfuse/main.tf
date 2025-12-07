terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Data source for existing PostgreSQL server
data "azurerm_postgresql_flexible_server" "existing" {
  name                = var.postgresql_server_name
  resource_group_name = var.shared_resource_group_name
}

# Create database for Langfuse
resource "azurerm_postgresql_flexible_server_database" "langfuse" {
  name      = var.postgresql_database_name
  server_id = data.azurerm_postgresql_flexible_server.existing.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Redis Cache for session storage
resource "azurerm_redis_cache" "langfuse" {
  name                = "redis-langfuse-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
    enable_authentication = true
  }

  tags = var.tags
}

# Storage Account for blob storage
resource "azurerm_storage_account" "langfuse" {
  name                     = "stlangfuse${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "langfuse" {
  name                  = "langfuse-uploads"
  storage_account_id    = azurerm_storage_account.langfuse.id
  container_access_type = "private"
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "langfuse" {
  name                = "log-langfuse-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "langfuse" {
  name                       = "cae-langfuse-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.langfuse.id

  tags = var.tags
}

# Container App for Langfuse Web
resource "azurerm_container_app" "langfuse_web" {
  name                         = "ca-langfuse-web-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.langfuse.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = var.container_app_min_replicas
    max_replicas = var.container_app_max_replicas

    container {
      name   = "langfuse-web"
      image  = "langfuse/langfuse:latest"
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.postgresql_admin_username}:${var.postgresql_admin_password}@${data.azurerm_postgresql_flexible_server.existing.fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
      }

      env {
        name  = "DIRECT_URL"
        value = "postgresql://${var.postgresql_admin_username}:${var.postgresql_admin_password}@${data.azurerm_postgresql_flexible_server.existing.fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
      }

      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.langfuse.hostname
      }

      env {
        name  = "REDIS_PORT"
        value = "6380"
      }

      env {
        name  = "REDIS_AUTH"
        value = azurerm_redis_cache.langfuse.primary_access_key
      }

      env {
        name  = "REDIS_CONNECTION_STRING"
        value = "rediss://:${azurerm_redis_cache.langfuse.primary_access_key}@${azurerm_redis_cache.langfuse.hostname}:6380"
      }

      env {
        name  = "SALT"
        value = var.langfuse_secret_salt
      }

      env {
        name  = "NEXTAUTH_SECRET"
        value = var.nextauth_secret
      }

      env {
        name  = "NEXTAUTH_URL"
        value = var.nextauth_url
      }

      env {
        name  = "S3_ENDPOINT"
        value = azurerm_storage_account.langfuse.primary_blob_endpoint
      }

      env {
        name  = "S3_ACCESS_KEY_ID"
        value = azurerm_storage_account.langfuse.name
      }

      env {
        name  = "S3_SECRET_ACCESS_KEY"
        value = azurerm_storage_account.langfuse.primary_access_key
      }

      env {
        name  = "S3_BUCKET_NAME"
        value = azurerm_storage_container.langfuse.name
      }

      env {
        name  = "S3_REGION"
        value = var.location
      }

      env {
        name  = "LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES"
        value = "false"
      }

      env {
        name  = "TELEMETRY_ENABLED"
        value = "false"
      }

      env {
        name  = "LANGFUSE_INIT_PROJECT_ID"
        value = ""
      }

      env {
        name  = "LANGFUSE_INIT_PROJECT_SECRET_KEY"
        value = ""
      }

      env {
        name  = "LANGFUSE_INIT_PROJECT_PUBLIC_KEY"
        value = ""
      }
    }

    http_scale_rule {
      name                = "http-scale"
      concurrent_requests = 100
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = var.tags
}

# Container App for Langfuse Worker
resource "azurerm_container_app" "langfuse_worker" {
  name                         = "ca-langfuse-worker-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.langfuse.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = var.container_app_min_replicas
    max_replicas = var.container_app_max_replicas

    container {
      name   = "langfuse-worker"
      image  = "langfuse/langfuse:latest"
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.postgresql_admin_username}:${var.postgresql_admin_password}@${data.azurerm_postgresql_flexible_server.existing.fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
      }

      env {
        name  = "DIRECT_URL"
        value = "postgresql://${var.postgresql_admin_username}:${var.postgresql_admin_password}@${data.azurerm_postgresql_flexible_server.existing.fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
      }

      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.langfuse.hostname
      }

      env {
        name  = "REDIS_PORT"
        value = "6380"
      }

      env {
        name  = "REDIS_AUTH"
        value = azurerm_redis_cache.langfuse.primary_access_key
      }

      env {
        name  = "REDIS_CONNECTION_STRING"
        value = "rediss://:${azurerm_redis_cache.langfuse.primary_access_key}@${azurerm_redis_cache.langfuse.hostname}:6380"
      }

      env {
        name  = "SALT"
        value = var.langfuse_secret_salt
      }

      env {
        name  = "S3_ENDPOINT"
        value = azurerm_storage_account.langfuse.primary_blob_endpoint
      }

      env {
        name  = "S3_ACCESS_KEY_ID"
        value = azurerm_storage_account.langfuse.name
      }

      env {
        name  = "S3_SECRET_ACCESS_KEY"
        value = azurerm_storage_account.langfuse.primary_access_key
      }

      env {
        name  = "S3_BUCKET_NAME"
        value = azurerm_storage_container.langfuse.name
      }

      env {
        name  = "S3_REGION"
        value = var.location
      }

      env {
        name  = "LANGFUSE_WORKER_HOST"
        value = "0.0.0.0"
      }

      env {
        name  = "LANGFUSE_WORKER_PORT"
        value = "3030"
      }

      env {
        name  = "TELEMETRY_ENABLED"
        value = "false"
      }
    }

    cpu_scale_rule {
      name                = "cpu-scale"
      cpu_percentage      = 80
      concurrent_requests = "100"
    }
  }

  tags = var.tags
}
