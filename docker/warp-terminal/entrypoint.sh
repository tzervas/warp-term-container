#!/bin/bash
set -e

# Function to check required tools
check_requirements() {
    echo "Checking required tools..."
    local missing_tools=()
    local required_tools=("git" "gpg" "gh" "ttyd")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Error: Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    echo "All required tools are available"
}

# Function to setup authentication
setup_auth() {
    echo "Setting up authentication..."
    # Configure git with GPG key if provided
    if [ -n "$GPG_KEY" ]; then
        echo "$GPG_KEY" | gpg --import --batch
        if [ $? -ne 0 ]; then
            echo "Failed to import GPG key"
            exit 1
        fi
    fi

    # Configure GitHub CLI with token
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN" | gh auth login --with-token
        if [ $? -ne 0 ]; then
            echo "Failed to authenticate with GitHub"
            exit 1
        fi
    fi
}

# Function to setup project
setup_project() {
    if [ -n "$GITHUB_REPO" ]; then
        echo "Cloning repository $GITHUB_REPO..."
        gh repo clone "$GITHUB_REPO" /home/warpuser/project
        cd /home/warpuser/project
    elif [ -n "$PROJECT_PATH" ]; then
        echo "Using existing project at $PROJECT_PATH..."
        cd "$PROJECT_PATH"
    else
        echo "No project specified"
        cd /home/warpuser
    fi
}

# Main execution
check_requirements
setup_auth
setup_project

# Start ttyd
exec ttyd --port 7681 --permit-write bash
