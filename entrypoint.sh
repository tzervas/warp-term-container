#!/bin/bash
set -e

# Set GPG Home
export GNUPGHOME=/home/warp/.gnupg

# Function to check required tools
check_requirements() {
    echo "Checking required tools..."
    for cmd in git gpg gh secret-tool; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd is not installed"
            exit 1
        fi
    done
}

# Function to setup authentication based on method
setup_auth() {
    echo "Setting up authentication..."
    # Import GPG key
    if gpg --list-secret-keys --keyid-format=long | grep -q "884E9E08D0C7DF6C"; then
        echo "GPG key already imported"
    else
        echo "Error: GPG key not found"
        exit 1
    fi
    case "$AUTH_METHOD" in
        keyring)
            echo "Using system keyring for authentication..."
            # Verify keyring access
            if ! secret-tool lookup test test &>/dev/null; then
                echo "Warning: Unable to access system keyring"
            fi
            ;;
        env)
            echo "Using environment variables for authentication..."
            # Set up GPG key if provided
            if [ -n "$GPG_KEY" ]; then
                echo "$GPG_KEY" | gpg --import
            fi
            # Configure git with provided credentials
            if [ -n "$GITHUB_TOKEN" ]; then
                gh auth login --with-token <<< "$GITHUB_TOKEN"
            fi
            ;;
        file)
            echo "Using file-based authentication..."
            if [ -f "/run/secrets/github_token" ]; then
                gh auth login --with-token < /run/secrets/github_token
            fi
            if [ -f "/run/secrets/gpg_key" ]; then
                gpg --import /run/secrets/gpg_key
            fi
            ;;
        *)
            echo "Invalid AUTH_METHOD specified"
            exit 1
            ;;
    esac
}

# Function to setup project
setup_project() {
    if [ -n "$GITHUB_REPO" ]; then
        echo "Cloning repository $GITHUB_REPO..."
        gh repo clone "$GITHUB_REPO" /home/warp/project
        cd /home/warp/project
    elif [ -n "$PROJECT_PATH" ]; then
        echo "Using existing project at $PROJECT_PATH..."
        cd "$PROJECT_PATH"
    else
        echo "No project specified"
        exit 1
    fi
}

# Setup authentication
setup_auth

# Ensure UV virtual environment is active
uv venv
source .venv/bin/activate

# Setup project
setup_project

# Install project dependencies if pyproject.toml exists
if [ -f "pyproject.toml" ]; then
    echo "Installing project dependencies..."
    uv pip install -e ".[dev]"
fi

# Execute command if provided, otherwise start shell
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec /bin/bash
fi
