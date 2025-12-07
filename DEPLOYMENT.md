# Deployment Guide

Complete guide for deploying Khema infrastructure with Langfuse on Azure.

## Architecture Overview

**Cost-Optimized Setup**: ~48-50€/month

- **rg-khema-shared**: PostgreSQL, Key Vault, Container Registry (shared across services)
- **rg-khema-langfuse**: VM running Langfuse via Docker Compose

## Prerequisites

1. **OpenTofu** >= 1.0
   ```bash
   tofu --version
   ```

2. **Azure CLI** (logged in)
   ```bash
   az login
   az account show
   ```

3. **SSH Key Pair**
   ```bash
   # Generate if you don't have one
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

## Deployment Steps

### Step 1: Generate Secrets

```bash
cd khema-infra
./scripts/generate-secrets.sh
```

This generates:
- `LANGFUSE_SECRET_SALT` (32+ characters)
- `NEXTAUTH_SECRET` (32+ characters)

**Save these securely!** You'll need them in the next step.

### Step 2: Configure Variables

**Option A: Using terraform.tfvars (easier for testing)**

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
location = "westeurope"

postgresql_admin_username = "khemaadmin"
postgresql_admin_password = "YourSecurePassword123!"  # Min 8 chars

ssh_public_key = "ssh-rsa AAAAB3Nza... your-email@example.com"

langfuse_secret_salt = "paste_generated_salt_here"
nextauth_secret      = "paste_generated_secret_here"
```

**Option B: Using Environment Variables (recommended for production)**

```bash
export TF_VAR_location="westeurope"
export TF_VAR_postgresql_admin_username="khemaadmin"
export TF_VAR_postgresql_admin_password="$(openssl rand -base64 16)"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
export TF_VAR_langfuse_secret_salt="$(openssl rand -base64 32)"
export TF_VAR_nextauth_secret="$(openssl rand -base64 32)"
```

### Step 3: Validate Configuration

```bash
./scripts/validate.sh
```

This checks:
- Terraform syntax
- Variable validations
- Code formatting

### Step 4: Plan Deployment

```bash
./scripts/local-deploy.sh plan
```

Review the plan carefully. It will create:
- 2 Resource Groups
- PostgreSQL Flexible Server
- Key Vault
- Container Registry
- Virtual Machine
- Networking resources

### Step 5: Deploy Infrastructure

```bash
./scripts/local-deploy.sh apply
```

This will:
1. Create shared resources (~5 minutes)
2. Create VM and install Docker (~3 minutes)
3. Start Langfuse services (~2 minutes)

**Total time**: ~10 minutes

### Step 6: Access Langfuse

Get deployment information:

```bash
tofu output
```

You'll see:
```
langfuse_url = "http://20.93.XXX.XXX:3000"
ssh_command  = "ssh azureuser@20.93.XXX.XXX"
```

**Wait 2-3 minutes** for Docker services to start, then:

1. Open the `langfuse_url` in your browser
2. Create your first admin account
3. Start using Langfuse!

## Post-Deployment

### View All Resources

```bash
# Shared resources
az resource list --resource-group rg-khema-shared --output table

# Langfuse resources
az resource list --resource-group rg-khema-langfuse --output table
```

### Access the VM

```bash
# SSH into the VM
ssh azureuser@<public-ip>

# Check Docker services
cd /opt/langfuse
docker compose ps

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f langfuse-web
docker compose logs -f clickhouse
```

### Verify PostgreSQL Connection

```bash
# From your local machine
az postgres flexible-server show \
  --name khema-postgresql \
  --resource-group rg-khema-shared

# Test connection from VM
ssh azureuser@<public-ip>
docker exec langfuse-web sh -c 'apt-get update && apt-get install -y postgresql-client'
docker exec langfuse-web psql "postgresql://user:pass@khema-postgresql.postgres.database.azure.com:5432/langfuse?sslmode=require" -c "SELECT version();"
```

### View Secrets in Key Vault

```bash
# List all secrets
az keyvault secret list --vault-name <key-vault-name> --output table

# Get a secret
az keyvault secret show --vault-name <key-vault-name> --name postgresql-connection-string
```

## Management

### Update Langfuse

```bash
# SSH to VM
ssh azureuser@<public-ip>

# Pull latest images
cd /opt/langfuse
docker compose pull

# Restart with new images
docker compose up -d

# View logs
docker compose logs -f
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart langfuse-web
docker compose restart clickhouse
```

### Scale Resources

**Increase VM size**:

Edit `main.tf`:
```hcl
vm_size = "Standard_B4ms"  # 4 vCPU, 16GB RAM
```

Then:
```bash
./scripts/local-deploy.sh plan
./scripts/local-deploy.sh apply
```

**Increase PostgreSQL size**:

Edit `main.tf`:
```hcl
postgresql_sku_name   = "B_Standard_B2s"  # 2 vCores, 4GB RAM
postgresql_storage_mb = 65536              # 64GB
```

Then apply changes.

### Backup and Restore

**PostgreSQL Backups** (automatic):

```bash
# List backups
az postgres flexible-server backup list \
  --name khema-postgresql \
  --resource-group rg-khema-shared

# Restore to point in time
az postgres flexible-server restore \
  --name khema-postgresql-restored \
  --source-server khema-postgresql \
  --resource-group rg-khema-shared \
  --restore-time "2024-01-15T10:00:00Z"
```

**VM Backup**:

```bash
# Create snapshot
az snapshot create \
  --resource-group rg-khema-langfuse \
  --name vm-langfuse-snapshot-$(date +%Y%m%d) \
  --source $(az vm show -g rg-khema-langfuse -n vm-langfuse --query "storageProfile.osDisk.managedDisk.id" -o tsv)
```

## Monitoring

### View Logs

```bash
# All services
ssh azureuser@<public-ip> 'cd /opt/langfuse && docker compose logs --tail=100'

# Follow logs in real-time
ssh azureuser@<public-ip> 'cd /opt/langfuse && docker compose logs -f'
```

### Resource Usage

```bash
# VM metrics
az vm list-usage --location westeurope --output table

# PostgreSQL metrics
az monitor metrics list \
  --resource $(az postgres flexible-server show -n khema-postgresql -g rg-khema-shared --query id -o tsv) \
  --metric cpu_percent \
  --output table
```

### Set up Alerts

```bash
# CPU alert for VM
az monitor metrics alert create \
  --name vm-langfuse-high-cpu \
  --resource-group rg-khema-langfuse \
  --scopes $(az vm show -g rg-khema-langfuse -n vm-langfuse --query id -o tsv) \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when CPU exceeds 80%"
```

## Cost Management

### View Current Costs

```bash
# Cost for resource groups
az consumption usage list \
  --start-date $(date -d "1 month ago" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  | jq -r '.[] | select(.instanceName | contains("khema")) | "\(.instanceName): \(.pretaxCost) \(.currency)"'
```

### Cost Optimization Tips

1. **Stop VM when not in use** (saves ~30€/month):
   ```bash
   az vm deallocate -g rg-khema-langfuse -n vm-langfuse
   az vm start -g rg-khema-langfuse -n vm-langfuse
   ```

2. **Use Reserved Instances** for long-term savings (30-50% discount)

3. **Downgrade PostgreSQL** if usage is low:
   ```hcl
   postgresql_sku_name = "B_Standard_B1ms"  # Cheapest option
   ```

## Troubleshooting

### Langfuse not accessible

```bash
# Check VM is running
az vm get-instance-view \
  --name vm-langfuse \
  --resource-group rg-khema-langfuse \
  --query instanceView.statuses[1].displayStatus

# Check NSG rules
az network nsg rule list \
  --nsg-name nsg-langfuse \
  --resource-group rg-khema-langfuse \
  --output table

# Check Docker services
ssh azureuser@<public-ip> 'docker compose -f /opt/langfuse/docker-compose.yml ps'
```

### PostgreSQL connection failed

```bash
# Check firewall rules
az postgres flexible-server firewall-rule list \
  --name khema-postgresql \
  --resource-group rg-khema-shared \
  --output table

# Add your IP if needed
az postgres flexible-server firewall-rule create \
  --name khema-postgresql \
  --resource-group rg-khema-shared \
  --rule-name AllowMyIP \
  --start-ip-address YOUR_IP \
  --end-ip-address YOUR_IP
```

### Docker Compose issues

```bash
# SSH to VM
ssh azureuser@<public-ip>

# Check Docker service
sudo systemctl status docker

# Recreate containers
cd /opt/langfuse
docker compose down
docker compose up -d

# View specific service logs
docker compose logs langfuse-web
docker compose logs clickhouse
```

### Key Vault access denied

```bash
# Grant yourself access
az keyvault set-policy \
  --name <key-vault-name> \
  --upn your-email@example.com \
  --secret-permissions get list set delete
```

## Security Best Practices

1. **Rotate credentials regularly**:
   ```bash
   # Update PostgreSQL password
   az postgres flexible-server update \
     --name khema-postgresql \
     --resource-group rg-khema-shared \
     --admin-password "NewSecurePassword123!"

   # Update in Key Vault
   az keyvault secret set \
     --vault-name <key-vault-name> \
     --name postgresql-admin-password \
     --value "NewSecurePassword123!"

   # Update environment in VM
   # SSH and update docker-compose.yml, then restart
   ```

2. **Restrict SSH access**:
   ```bash
   # Update NSG to allow only your IP
   az network nsg rule update \
     --resource-group rg-khema-langfuse \
     --nsg-name nsg-langfuse \
     --name SSH \
     --source-address-prefixes YOUR_IP/32
   ```

3. **Enable Azure AD authentication** for PostgreSQL

4. **Use managed identities** where possible

## Destroying Infrastructure

**WARNING**: This destroys ALL data!

```bash
./scripts/local-deploy.sh destroy
```

Or manually:
```bash
az group delete --name rg-khema-langfuse --yes --no-wait
az group delete --name rg-khema-shared --yes --no-wait
```

## Remote State Setup (Production)

Store state in Azure Storage for team collaboration:

```bash
# Create storage account
az storage account create \
  --name stkhematerraform \
  --resource-group rg-khema-shared \
  --location westeurope \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name stkhematerraform

# Enable versioning
az storage blob service-properties update \
  --account-name stkhematerraform \
  --enable-versioning true

# Edit backend.tf and uncomment the backend block
# Then migrate:
tofu init -migrate-state
```

## Next Steps

- Set up SSL/TLS with Let's Encrypt
- Configure custom domain
- Set up monitoring dashboards
- Configure automated backups
- Add more services to the infrastructure

## Support

For issues or questions:
- Check logs: `docker compose logs`
- Review Terraform state: `tofu show`
- Azure Portal: https://portal.azure.com
