# Warp Terminal Development Container

This repository contains a development container configuration for Warp Terminal AI development. It provides an isolated, consistent environment with all necessary dependencies and configurations pre-installed.

## Features

- Isolated development environment
- Pre-configured authentication setup
- GPG key management
- GitHub integration
- Atlassian (Confluence) integration
- Secure secrets management using system keyring

## Prerequisites

- Docker
- Docker Compose
- Git

## Setup

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd warp-term-container
   ```

2. Copy the example environment file and modify as needed:
   ```bash
   cp .env.example .env
   ```

3. Run the setup script:
   ```bash
   ./setup.sh
   ```

4. For GPG key setup (if needed):
   ```bash
   ./setup-gpg.sh
   ```

## Environment Variables

Required environment variables can be set in the `.env` file:

- `AUTH_METHOD`: Authentication method (default: keyring)
- `GITHUB_TOKEN`: GitHub Personal Access Token
- `GITHUB_REPO`: GitHub repository
- `GPG_KEY`: GPG key for signing
- `PROJECT_PATH`: Local project path
- `ATLASSIAN_TOKEN`: Atlassian API token
- `ATLASSIAN_EMAIL`: Atlassian account email
- `CONFLUENCE_DOMAIN`: Confluence domain

## Usage

### Using the Base Image

The base image is available at `ghcr.io/tzervas/warp-term-container` and can be used in two ways:

1. Direct usage with environment variables:
```bash
docker-compose up -d
```

2. Extending with custom configuration:
   - Copy `Dockerfile.custom` to your project
   - Modify it to add your specific configuration
   - Update `docker-compose.yml` to use your custom Dockerfile
   - Build and run:
```bash
docker-compose build
docker-compose up -d
```

Connect to the container:
```bash
docker-compose exec warp-terminal bash
```

### Configuration

The base image expects configuration through:
- Environment variables in `.env`
- Mounted volumes for credentials
- Custom Dockerfile for additional setup

See `Dockerfile.custom` for an example of how to extend the base image with your own configuration.

## Directory Structure

- `.devcontainer/`: VSCode development container configuration
- `docker-compose.yml`: Container orchestration configuration
- `Dockerfile`: Container image definition
- `entrypoint.sh`: Container initialization script
- `setup.sh`: Environment setup script
- `setup-gpg.sh`: GPG key setup script

## Security Notes

- Sensitive information is managed through the system keyring
- GPG keys are properly isolated and secured
- Environment variables containing secrets are not committed to version control

## License

MIT License - Copyright (c) Tyler Zervas
