# Khema Infrastructure

Infrastructure as Code (IaC) for Khema services using Terraform on Azure.

## Overview

This repository contains Terraform configurations for deploying and managing Khema infrastructure on Azure. The infrastructure is designed to be modular, scalable, and cost-effective using serverless technologies where possible.

## Structure

```
khema-infra/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment
│   └── prod/             # Production environment
├── modules/              # Reusable Terraform modules
│   └── langfuse/         # Langfuse deployment module
└── scripts/              # Utility scripts
```

## Prerequisites

- [OpenTofu](https://opentofu.org/) or [Terraform](https://www.terraform.io/) >= 1.0
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) logged in
- Access to Azure subscription

## Shared Resources

The following resources are shared across services and managed in resource group `rg-khema-shared`:

- **PostgreSQL Database**: `khema-postgresql` - Used by multiple services

## Current Services

### Langfuse

Self-hosted LLM observability platform deployed using Azure Container Apps (serverless, pay-per-use).

**Resources**:
- Azure Container Apps (Web + Worker)
- Azure Cache for Redis
- Azure Storage Account
- Uses shared PostgreSQL database

## Local Development

### Initialize and Plan

```bash
cd environments/dev
tofu init
tofu plan -out=tfplan
```

### Apply Changes

```bash
tofu apply tfplan
```

### Validate Configuration

```bash
../../scripts/validate.sh
```

## Deployment

### Manual Deployment

1. Navigate to the environment directory:
   ```bash
   cd environments/dev  # or prod
   ```

2. Initialize Terraform:
   ```bash
   tofu init
   ```

3. Review the plan:
   ```bash
   tofu plan
   ```

4. Apply the configuration:
   ```bash
   tofu apply
   ```

### CI/CD Pipeline

(Coming soon - will use GitHub Actions for automated deployments)

## Adding New Services

1. Create a new module in `modules/<service-name>/`
2. Add the module to the appropriate environment configuration
3. Update this README with service details

## Security

- Sensitive values should be stored in Azure Key Vault
- Never commit `.tfvars` files (they are gitignored)
- Use environment variables or `.tfvars.example` as templates

## License

Private - Khema internal use only
