# Langfuse Module

Terraform module for deploying Langfuse on Azure using Container Apps (serverless, pay-per-use).

## Features

- **Serverless**: Azure Container Apps with scale-to-zero capability
- **Cost-effective**: Pay only when the application is being used
- **Shared Database**: Uses existing PostgreSQL server in shared resource group
- **Redis Cache**: For session storage and caching
- **Blob Storage**: Azure Storage Account for file uploads
- **High Availability**: Auto-scaling based on HTTP requests and CPU usage

## Architecture

```
┌─────────────────────────────────────────┐
│   Azure Container Apps Environment      │
│  ┌─────────────┐    ┌───────────────┐  │
│  │ Langfuse    │    │ Langfuse      │  │
│  │ Web App     │    │ Worker        │  │
│  │ (Port 3000) │    │ (Port 3030)   │  │
│  └──────┬──────┘    └───────┬───────┘  │
└─────────┼──────────────────┼───────────┘
          │                  │
          │                  │
    ┌─────▼──────────────────▼─────┐
    │   Shared PostgreSQL Server    │
    │   (rg-khema-shared)           │
    │   Database: langfuse          │
    └───────────────────────────────┘
          │                  │
    ┌─────▼──────┐    ┌─────▼──────┐
    │   Redis    │    │  Storage   │
    │   Cache    │    │  Account   │
    └────────────┘    └────────────┘
```

## Resources Created

- Azure Container Apps Environment
- Container App (Web)
- Container App (Worker)
- Azure Cache for Redis
- Azure Storage Account
- Storage Container
- PostgreSQL Database (in existing server)
- Log Analytics Workspace

## Usage

```hcl
module "langfuse" {
  source = "../../modules/langfuse"

  environment                  = "dev"
  location                     = "westeurope"
  resource_group_name          = "rg-khema-dev"
  shared_resource_group_name   = "rg-khema-shared"
  postgresql_server_name       = "khema-postgresql"
  postgresql_database_name     = "langfuse"
  postgresql_admin_username    = var.postgresql_admin_username
  postgresql_admin_password    = var.postgresql_admin_password
  langfuse_secret_salt         = var.langfuse_secret_salt
  nextauth_secret              = var.nextauth_secret
  nextauth_url                 = "https://langfuse.example.com"
  container_app_min_replicas   = 0  # Scale to zero
  container_app_max_replicas   = 10

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, prod) | string | - | yes |
| location | Azure region | string | westeurope | no |
| resource_group_name | Resource group name | string | - | yes |
| shared_resource_group_name | Shared resource group name | string | rg-khema-shared | no |
| postgresql_server_name | PostgreSQL server name | string | khema-postgresql | no |
| postgresql_database_name | Database name for Langfuse | string | langfuse | no |
| postgresql_admin_username | PostgreSQL admin username | string | - | yes |
| postgresql_admin_password | PostgreSQL admin password | string | - | yes |
| langfuse_secret_salt | Secret salt (min 32 chars) | string | - | yes |
| nextauth_secret | NextAuth secret (min 32 chars) | string | - | yes |
| nextauth_url | NextAuth URL | string | - | yes |
| container_app_min_replicas | Min replicas (0 for scale-to-zero) | number | 0 | no |
| container_app_max_replicas | Max replicas | number | 10 | no |
| container_cpu | CPU cores per container | string | 1.0 | no |
| container_memory | Memory per container | string | 2Gi | no |
| redis_sku | Redis SKU | string | Basic | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| langfuse_web_url | URL of the Langfuse web application |
| langfuse_web_fqdn | FQDN of the Langfuse web application |
| container_app_web_id | ID of the web container app |
| container_app_worker_id | ID of the worker container app |
| redis_hostname | Redis cache hostname |
| storage_account_name | Storage account name |
| database_name | PostgreSQL database name |

## Cost Optimization

- **Scale to Zero**: Set `container_app_min_replicas = 0` to scale to zero when not in use
- **Redis Tier**: Use `Basic` SKU for development, consider `Standard` for production
- **Storage**: Uses LRS (Locally Redundant Storage) for cost savings

## Security

- All connections use TLS/SSL
- Secrets are marked as sensitive
- Redis requires authentication
- Storage containers are private
- PostgreSQL requires SSL mode

## First-time Setup

After deploying, you need to:

1. Access the Langfuse web URL (output: `langfuse_web_url`)
2. Create your first admin account
3. Configure your project settings

## Monitoring

Logs are sent to Log Analytics Workspace. You can query logs using:

```bash
az monitor log-analytics query \
  -w <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | limit 100"
```
