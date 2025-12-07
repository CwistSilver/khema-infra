#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Validating Terraform configuration...${NC}\n"

# Initialize Terraform
echo "Running: tofu init -backend=false"
tofu init -backend=false > /dev/null

# Validate configuration
if tofu validate; then
    echo -e "${GREEN}✓ Configuration is valid${NC}"
else
    echo -e "${RED}✗ Configuration is invalid${NC}"
    exit 1
fi

# Format check
echo -e "\n${YELLOW}Checking code formatting...${NC}"
if tofu fmt -check -recursive; then
    echo -e "${GREEN}✓ Code formatting is correct${NC}"
else
    echo -e "${YELLOW}✗ Code needs formatting. Running: tofu fmt -recursive${NC}"
    tofu fmt -recursive
    echo -e "${GREEN}✓ Code formatted${NC}"
fi

echo -e "\n${GREEN}All validations passed!${NC}"
