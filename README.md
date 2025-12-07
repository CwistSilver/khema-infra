# Khema Infrastructure

Infrastructure as Code (IaC) for Khema services using Terraform/OpenTofu on Azure.

## Overview

Cost-optimized infrastructure for self-hosting services on Azure. Currently deploys Langfuse LLM observability platform using a single VM with Docker Compose (~48€/month total).

## Architecture

```
┌─────────────────────────────────────────────┐
│   rg-khema-shared (Shared Resources)       │
│  ┌──────────────────────────────────────┐  │
│  │ PostgreSQL Flexible Server (B1ms)    │  │
│  │ - 1 vCore, 2GB RAM                   │  │
│  │ - 32GB Storage                       │  │
│  │ - Cost: ~18€/month                   │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ Azure Key Vault                      │  │
│  │ - Stores all secrets                 │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ Container Registry (crkhema)         │  │
│  │ - Basic SKU                          │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│   rg-khema-langfuse (Langfuse Service)      │
│  ┌──────────────────────────────────────┐  │
│  │ VM (Standard_B2s)                    │  │
│  │ - 2 vCPU, 4GB RAM                    │  │
│  │ - Cost: ~30€/month                   │  │
│  │                                      │  │
│  │ Docker Compose:                      │  │
│  │  ├─ Langfuse Web (port 3000)        │  │
│  │  ├─ Langfuse Worker                 │  │
│  │  ├─ Clickhouse                      │  │
│  │  └─ Redis                           │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Structure

```
khema-infra/
├── main.tf                   # Root configuration
├── variables.tf              # Input variables
├── outputs.tf                # Outputs
├── backend.tf                # State backend config
├── terraform.tfvars.example  # Configuration template
├── modules/
│   ├── shared-resources/     # PostgreSQL, Key Vault, ACR
│   └── langfuse-vm/          # VM with Docker Compose
└── scripts/
    ├── local-deploy.sh       # Deployment automation
    ├── validate.sh           # Configuration validation
    └── generate-secrets.sh   # Secret generation
```

## Cost Breakdown

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| PostgreSQL Flexible Server | B_Standard_B1ms | ~18€ |
| Linux VM | Standard_B2s | ~30€ |
| Storage & Networking | - | ~1€ |
| **Total** | | **~48-50€** |

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.0 or Terraform >= 1.0
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (logged in)
- SSH key pair for VM access

## Quick Start

### One-Command Deployment

```bash
./deploy.sh
```

That's it! The script will:
- ✅ Check prerequisites (Azure CLI, OpenTofu/Terraform)
- ✅ Verify Azure login
- ✅ Generate or use existing SSH key
- ✅ Prompt for PostgreSQL credentials (or use env vars)
- ✅ Generate Langfuse secrets automatically
- ✅ Create configuration
- ✅ Deploy everything to Azure
- ✅ Show the Langfuse URL

**Total time**: ~10 minutes

After deployment:
- Wait 2-3 minutes for Docker services to start
- Open the Langfuse URL shown in the output
- Create your first admin account

### Alternative: Manual Deployment

If you prefer more control:

```bash
# 1. Configure (optional - deploy.sh does this)
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

# 2. Deploy step-by-step
./scripts/validate.sh
./scripts/local-deploy.sh plan
./scripts/local-deploy.sh apply
```

## Shared Resources

Resources in `rg-khema-shared` are used across multiple services:

- **PostgreSQL**: Shared database server for all services
- **Key Vault**: Centralized secret management
- **Container Registry**: For custom Docker images

## Services

### Langfuse

Self-hosted LLM observability platform.

**Components**:
- Langfuse Web UI (port 3000)
- Langfuse Worker (background jobs)
- Clickhouse (OLAP database for traces)
- Redis (cache and queue)
- PostgreSQL database `langfuse` (on shared server)

**Access**:
```bash
# SSH to VM
ssh azureuser@<public-ip>

# View logs
cd /opt/langfuse
docker compose logs -f

# Restart services
docker compose restart

# Update Langfuse
docker compose pull
docker compose up -d
```

## Management

### View Outputs

```bash
tofu output
```

### Update Infrastructure

```bash
# Make changes to .tf files
./scripts/validate.sh
./scripts/local-deploy.sh plan
./scripts/local-deploy.sh apply
```

### Destroy Infrastructure

```bash
./scripts/local-deploy.sh destroy
```

**WARNING**: This destroys ALL data including databases!

## Remote State (Recommended for Production)

Store Terraform state in Azure Storage:

```bash
# Create storage account
az storage account create \
  --name stkhematerraform \
  --resource-group rg-khema-shared \
  --location westeurope \
  --sku Standard_LRS

# Create container
az storage container create \
  --name tfstate \
  --account-name stkhematerraform

# Uncomment backend block in backend.tf
# Then migrate state
tofu init -migrate-state
```

## Security

- ✅ Secrets stored in Azure Key Vault
- ✅ PostgreSQL requires SSL
- ✅ VM accessible only via SSH key
- ✅ Network Security Groups limit access
- ✅ Container Registry with admin access

**Best Practices**:
- Never commit `terraform.tfvars`
- Use environment variables for secrets
- Rotate credentials regularly
- Use Azure AD authentication where possible

## Adding New Services

To add a new service:

1. Create a new module in `modules/<service-name>/`
2. Add module call in `main.tf`
3. Update outputs and documentation
4. Deploy with `./scripts/local-deploy.sh apply`

## Troubleshooting

### Langfuse not accessible

```bash
# SSH to VM
ssh azureuser@<public-ip>

# Check services
cd /opt/langfuse
docker compose ps
docker compose logs

# Restart if needed
docker compose restart
```

### PostgreSQL connection issues

```bash
# Test from VM
docker exec langfuse-web sh -c 'apt-get update && apt-get install -y postgresql-client'
docker exec langfuse-web psql "$DATABASE_URL" -c "SELECT version();"
```

### VM not accessible

Check Network Security Group rules and VM status in Azure Portal.

## Documentation

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment guide.

## License

Private - Khema internal use only
