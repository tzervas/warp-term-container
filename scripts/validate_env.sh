#!/bin/bash

# Required environment variables
REQUIRED_VARS=(
    "AUTH_METHOD"
    "GITHUB_TOKEN"
    "GITHUB_REPO"
)

# Optional environment variables with their default values
declare -A OPTIONAL_VARS=(
    ["USER_UID"]="1000"
    ["USER_GID"]="1000"
)

validate_environment() {
    local missing_vars=()
    
    echo "Validating environment variables..."
    
    # Check required variables
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    # Set defaults for optional variables if not set
    for var in "${!OPTIONAL_VARS[@]}"; do
        if [[ -z "${!var}" ]]; then
            export "$var"="${OPTIONAL_VARS[$var]}"
            echo "Setting default value for $var: ${OPTIONAL_VARS[$var]}"
        fi
    done
    
    # If any required variables are missing, fail with error
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "ERROR: Missing required environment variables:"
        printf '%s\n' "${missing_vars[@]}"
        exit 1
    fi
    
    echo "Environment validation completed successfully"
}
