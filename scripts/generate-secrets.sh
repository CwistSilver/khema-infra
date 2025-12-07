#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating secrets for Langfuse deployment${NC}\n"

# Generate SALT (32 characters)
SALT=$(openssl rand -base64 32 | tr -d '\n')
echo -e "${GREEN}LANGFUSE_SECRET_SALT:${NC}"
echo "$SALT"
echo ""

# Generate NextAuth Secret (32 characters)
NEXTAUTH=$(openssl rand -base64 32 | tr -d '\n')
echo -e "${GREEN}NEXTAUTH_SECRET:${NC}"
echo "$NEXTAUTH"
echo ""

echo -e "${YELLOW}Add these to your terraform.tfvars file or export as environment variables:${NC}"
echo ""
echo "export TF_VAR_langfuse_secret_salt=\"$SALT\""
echo "export TF_VAR_nextauth_secret=\"$NEXTAUTH\""
echo ""
echo -e "${YELLOW}Or add to terraform.tfvars:${NC}"
echo ""
echo "langfuse_secret_salt = \"$SALT\""
echo "nextauth_secret      = \"$NEXTAUTH\""
echo ""
echo -e "${YELLOW}IMPORTANT: Keep these secrets secure and never commit them to git!${NC}"
