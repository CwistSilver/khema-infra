#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo "Usage: $0 [plan|apply|destroy]"
    echo "  plan    - Show what will be created/changed"
    echo "  apply   - Deploy the infrastructure"
    echo "  destroy - Destroy all infrastructure"
    exit 1
}

# Check arguments
ACTION=${1:-plan}

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo -e "${RED}Error: Invalid action '${ACTION}'${NC}"
    usage
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Khema Infrastructure Deployment${NC}"
echo -e "${BLUE}Action: ${ACTION}${NC}"
echo -e "${BLUE}========================================${NC}"

# Check Azure CLI login
echo -e "\n${YELLOW}Checking Azure CLI authentication...${NC}"
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}Error: Not logged in to Azure CLI${NC}"
    echo "Please run: az login"
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}✓ Logged in to Azure subscription: ${SUBSCRIPTION}${NC}"

# Check for tfvars file
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
    exit 1
fi

# Initialize Terraform
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
tofu init

# Validate configuration
echo -e "\n${YELLOW}Validating configuration...${NC}"
tofu validate

# Run the requested action
case $ACTION in
    plan)
        echo -e "\n${YELLOW}Running Terraform plan...${NC}"
        tofu plan -out=tfplan
        echo -e "\n${GREEN}Plan saved to tfplan${NC}"
        echo -e "${YELLOW}To apply this plan, run: $0 apply${NC}"
        ;;

    apply)
        if [ -f "tfplan" ]; then
            echo -e "\n${YELLOW}Applying Terraform plan...${NC}"
            tofu apply tfplan
            rm -f tfplan
        else
            echo -e "\n${YELLOW}No plan file found, running plan and apply...${NC}"
            tofu plan -out=tfplan
            echo -e "\n${YELLOW}Review the plan above. Do you want to apply? (yes/no)${NC}"
            read -r response
            if [[ "$response" == "yes" ]]; then
                tofu apply tfplan
                rm -f tfplan
            else
                echo -e "${YELLOW}Apply cancelled${NC}"
                exit 0
            fi
        fi
        echo -e "\n${GREEN}✓ Deployment complete!${NC}"
        echo -e "\n${BLUE}Outputs:${NC}"
        tofu output
        ;;

    destroy)
        echo -e "\n${RED}WARNING: This will destroy ALL infrastructure!${NC}"
        echo -e "${YELLOW}This includes:${NC}"
        echo -e "  - PostgreSQL database (rg-khema-shared)"
        echo -e "  - Key Vault with all secrets"
        echo -e "  - Container Registry"
        echo -e "  - Langfuse VM and all data"
        echo -e "\n${YELLOW}Are you ABSOLUTELY sure? Type 'yes' to confirm:${NC}"
        read -r response
        if [[ "$response" == "yes" ]]; then
            tofu destroy
            echo -e "\n${GREEN}Resources destroyed${NC}"
        else
            echo -e "${YELLOW}Destroy cancelled${NC}"
            exit 0
        fi
        ;;
esac
