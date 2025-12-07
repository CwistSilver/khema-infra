#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Validating Terraform configurations...${NC}"

# Find all environment directories
for env_dir in environments/*/; do
    env_name=$(basename "$env_dir")
    echo -e "\n${YELLOW}Validating ${env_name} environment...${NC}"

    cd "$env_dir"

    # Initialize Terraform
    echo "Running: tofu init -backend=false"
    tofu init -backend=false > /dev/null

    # Validate configuration
    if tofu validate; then
        echo -e "${GREEN}✓ ${env_name} configuration is valid${NC}"
    else
        echo -e "${RED}✗ ${env_name} configuration is invalid${NC}"
        exit 1
    fi

    # Format check
    if tofu fmt -check -recursive; then
        echo -e "${GREEN}✓ ${env_name} formatting is correct${NC}"
    else
        echo -e "${RED}✗ ${env_name} needs formatting. Run: tofu fmt -recursive${NC}"
        exit 1
    fi

    cd - > /dev/null
done

echo -e "\n${GREEN}All validations passed!${NC}"
