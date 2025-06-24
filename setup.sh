#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Setting up Warp Terminal development environment..."

# Check if .env exists, if not create from example
if [ ! -f .env ]; then
    if [ ! -f .env.example ]; then
        echo -e "${RED}Error: .env.example not found${NC}"
        exit 1
    fi
    cp .env.example .env
    echo -e "${GREEN}Created .env file from example${NC}"
fi

# Function to get secret-tool value
get_secret() {
    local name=$1
    secret-tool lookup "$name" token 2>/dev/null || echo ""
}

# Update .env with values from secret-tool if using keyring auth
if grep -q "AUTH_METHOD=keyring" .env; then
    echo "Using keyring authentication method..."
    
    # GitHub Token
    GITHUB_TOKEN=$(get_secret "github")
    if [ -n "$GITHUB_TOKEN" ]; then
        sed -i "s|GITHUB_TOKEN=.*|GITHUB_TOKEN=$GITHUB_TOKEN|" .env
        echo -e "${GREEN}Updated GitHub token from keyring${NC}"
    fi

    # Atlassian Token
    ATLASSIAN_TOKEN=$(get_secret "atlassian")
    if [ -n "$ATLASSIAN_TOKEN" ]; then
        sed -i "s|ATLASSIAN_TOKEN=.*|ATLASSIAN_TOKEN=$ATLASSIAN_TOKEN|" .env
        echo -e "${GREEN}Updated Atlassian token from keyring${NC}"
    fi
fi

# Set up GPG key if available
GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "884E9E08D0C7DF6C" | awk '{print $2}' | cut -d'/' -f2)
if [ -n "$GPG_KEY_ID" ]; then
    sed -i "s|GPG_KEY_ID=.*|GPG_KEY_ID=$GPG_KEY_ID|" .env
    echo -e "${GREEN}Updated GPG key ID${NC}"
fi

echo -e "${GREEN}Setup complete! Please review your .env file and update any remaining values.${NC}"
