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
    echo "Usage: $0 <environment> [plan|apply|destroy]"
    echo "  environment: dev or prod"
    echo "  action: plan (default), apply, or destroy"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

ENV=$1
ACTION=${2:-plan}
ENV_DIR="environments/${ENV}"

# Validate environment
if [ ! -d "$ENV_DIR" ]; then
    echo -e "${RED}Error: Environment '${ENV}' not found${NC}"
    echo "Available environments: dev, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo -e "${RED}Error: Invalid action '${ACTION}'${NC}"
    usage
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Environment: ${ENV}${NC}"
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

# Change to environment directory
cd "$ENV_DIR"

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
        echo -e "${YELLOW}To apply this plan, run: $0 ${ENV} apply${NC}"
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
        echo -e "\n${RED}WARNING: This will destroy all resources in ${ENV}!${NC}"
        echo -e "${YELLOW}Are you sure? Type 'yes' to confirm:${NC}"
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

cd - > /dev/null
