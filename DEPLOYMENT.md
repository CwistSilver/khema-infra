# Deployment Guide

Complete guide for deploying Khema infrastructure using Terraform/OpenTofu.

## Prerequisites

1. **OpenTofu or Terraform** (>= 1.0)
   ```bash
   tofu --version
   ```

2. **Azure CLI** (logged in)
   ```bash
   az login
   az account show
   ```

3. **Existing Azure Resources**
   - Resource Group: `rg-khema-shared`
   - PostgreSQL Server: `khema-postgresql`

## Quick Start

### 1. Generate Secrets

Run the secret generation script:

```bash
./scripts/generate-secrets.sh
```

This will generate:
- `LANGFUSE_SECRET_SALT` (32 characters)
- `NEXTAUTH_SECRET` (32 characters)

Save these securely!

### 2. Configure Environment

Copy the example tfvars file:

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and fill in:

```hcl
# PostgreSQL Credentials (from existing database)
postgresql_admin_username = "your_username"
postgresql_admin_password = "your_password"

# Generated secrets from step 1
langfuse_secret_salt = "generated_salt_here"
nextauth_secret      = "generated_nextauth_secret_here"

# Temporary URL (will update after first deployment)
nextauth_url = "https://temp-url.azurecontainerapps.io"
```

**Option: Use Environment Variables** (Recommended)

Instead of storing secrets in `terraform.tfvars`, export them:

```bash
export TF_VAR_postgresql_admin_username="your_username"
export TF_VAR_postgresql_admin_password="your_password"
export TF_VAR_langfuse_secret_salt="generated_salt"
export TF_VAR_nextauth_secret="generated_secret"
export TF_VAR_nextauth_url="https://temp-url.azurecontainerapps.io"
```

### 3. Deploy Infrastructure

Using the deployment script:

```bash
# Plan deployment
./scripts/local-deploy.sh dev plan

# Apply deployment
./scripts/local-deploy.sh dev apply
```

Or manually:

```bash
cd environments/dev
tofu init
tofu plan -out=tfplan
tofu apply tfplan
```

### 4. Update NextAuth URL

After first deployment, get the application URL:

```bash
tofu output langfuse_web_url
```

Update `terraform.tfvars` with the actual URL:

```hcl
nextauth_url = "https://ca-langfuse-web-dev-xxxxx.azurecontainerapps.io"
```

Re-apply:

```bash
tofu apply
```

### 5. Access Langfuse

1. Get the URL:
   ```bash
   tofu output langfuse_web_url
   ```

2. Open in browser and create your first admin account

## Development Workflow

### Validate Configuration

Before deploying, validate your configuration:

```bash
./scripts/validate.sh
```

This checks:
- Terraform syntax
- Configuration validity
- Code formatting

### Plan Changes

Always plan before applying:

```bash
cd environments/dev
tofu plan
```

### Apply Changes

Apply planned changes:

```bash
tofu apply
```

### View Outputs

See deployment information:

```bash
tofu output
```

### Destroy Resources

To tear down the environment:

```bash
./scripts/local-deploy.sh dev destroy
```

## Production Deployment

### Prerequisites

1. **Set up remote state storage:**

   Create Azure Storage for Terraform state:

   ```bash
   # Create resource group for Terraform state
   az group create --name rg-khema-terraform --location westeurope

   # Create storage account
   az storage account create \
     --name stkhematerraform \
     --resource-group rg-khema-terraform \
     --location westeurope \
     --sku Standard_LRS \
     --encryption-services blob

   # Create container
   az storage container create \
     --name tfstate \
     --account-name stkhematerraform
   ```

2. **Enable state locking:**

   ```bash
   # Enable versioning
   az storage blob service-properties update \
     --account-name stkhematerraform \
     --enable-versioning true

   # Enable soft delete
   az storage blob service-properties update \
     --account-name stkhematerraform \
     --enable-delete-retention true \
     --delete-retention-days 7
   ```

3. **Configure backend:**

   Edit `environments/prod/backend.tf` and uncomment the backend block:

   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "rg-khema-terraform"
       storage_account_name = "stkhematerraform"
       container_name       = "tfstate"
       key                  = "prod.terraform.tfstate"
     }
   }
   ```

4. **Migrate state:**

   ```bash
   cd environments/prod
   tofu init -migrate-state
   ```

### Deploy Production

1. Configure production variables:

   ```bash
   cd environments/prod
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with production values
   ```

2. Use **Azure Key Vault** for secrets (recommended):

   ```bash
   # Store secrets in Key Vault
   az keyvault secret set --vault-name khema-keyvault \
     --name langfuse-secret-salt --value "your_secret"

   # Reference in Terraform (alternative approach)
   ```

3. Deploy:

   ```bash
   ./scripts/local-deploy.sh prod plan
   ./scripts/local-deploy.sh prod apply
   ```

## Cost Optimization

### Development Environment

The dev environment is configured for minimal cost:

- **Scale to Zero**: `min_replicas = 0` - no cost when idle
- **Smaller Resources**: 0.5 CPU, 1Gi memory
- **Basic Redis**: Smallest SKU
- **LRS Storage**: Locally redundant storage

**Estimated Dev Cost**: ~€10-20/month (mostly Redis when running)

### Production Environment

Production is configured for reliability:

- **Always Available**: `min_replicas = 1`
- **Better Resources**: 1.0 CPU, 2Gi memory
- **Standard Redis**: Better performance and SLA
- **Higher Limits**: Up to 20 replicas

**Estimated Prod Cost**: ~€50-150/month (depending on usage)

## Monitoring

### View Logs

Using Azure CLI:

```bash
# Get the container app name
CA_NAME=$(tofu output -raw container_app_web_id | rev | cut -d'/' -f1 | rev)

# Stream logs
az containerapp logs show \
  --name $CA_NAME \
  --resource-group rg-khema-dev \
  --follow
```

### Metrics

View metrics in Azure Portal:
- Navigate to Container App
- Click "Metrics"
- Monitor: Requests, CPU, Memory, Replicas

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Verify PostgreSQL credentials
   - Check firewall rules on PostgreSQL server
   - Ensure SSL mode is enabled

2. **Container App Not Starting**
   - Check container logs
   - Verify environment variables
   - Check image pull status

3. **Scale to Zero Not Working**
   - Verify `min_replicas = 0`
   - Check scaling rules configuration
   - May take 5-10 minutes to scale down

4. **NextAuth Errors**
   - Ensure `nextauth_url` matches actual URL
   - Verify `nextauth_secret` is set
   - Check that URL is accessible

### Debug Commands

```bash
# Check resource group
az group show --name rg-khema-dev

# Check container app status
az containerapp show --name ca-langfuse-web-dev --resource-group rg-khema-dev

# Check replicas
az containerapp revision list --name ca-langfuse-web-dev --resource-group rg-khema-dev

# Check logs
az containerapp logs show --name ca-langfuse-web-dev --resource-group rg-khema-dev --tail 100
```

## CI/CD Pipeline (Future)

Planned GitHub Actions workflow:

1. **Pull Request**: Validate and plan
2. **Merge to main**: Auto-deploy to dev
3. **Tag release**: Manual approval to deploy to prod

## Security Best Practices

1. **Never commit secrets** - Use environment variables or Key Vault
2. **Use remote state** for production
3. **Enable state locking** to prevent concurrent modifications
4. **Review plans** before applying
5. **Use separate service principals** for CI/CD
6. **Enable Azure AD authentication** for PostgreSQL
7. **Use managed identities** where possible

## Updating Langfuse

To update Langfuse to a new version:

1. Update the image tag in `modules/langfuse/main.tf`:
   ```hcl
   image = "langfuse/langfuse:v2.x.x"
   ```

2. Plan and apply:
   ```bash
   tofu plan
   tofu apply
   ```

3. Container Apps will perform a rolling update

## Backup and Recovery

### Database Backups

PostgreSQL Flexible Server has automatic backups enabled. To restore:

```bash
az postgres flexible-server restore \
  --resource-group rg-khema-shared \
  --name khema-postgresql-restored \
  --source-server khema-postgresql \
  --restore-time "2024-01-15T13:10:00Z"
```

### State File Backups

State files in Azure Storage are versioned and have soft-delete enabled.

## Additional Resources

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)
- [Langfuse Documentation](https://langfuse.com/docs/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
