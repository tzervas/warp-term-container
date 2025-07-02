#!/bin/bash

setup_gpg() {
    echo "Setting up GPG..."
    
    # Ensure proper permissions on .gnupg directory
    if [ ! -d "$HOME/.gnupg" ]; then
        mkdir -p "$HOME/.gnupg"
    fi
    chmod 700 "$HOME/.gnupg"
    
    # If GPG_KEY is provided, attempt to import it
    if [ -n "$GPG_KEY" ]; then
        echo "Importing GPG key..."
        echo "$GPG_KEY" | gpg --import --batch
        if [ $? -ne 0 ]; then
            echo "Failed to import GPG key"
            return 1
        fi
    fi
    
    # Verify GPG setup
    if ! gpg --list-secret-keys --keyid-format=long > /dev/null 2>&1; then
        echo "Warning: No GPG keys found in keyring"
        return 1
    fi
    
    echo "GPG setup completed successfully"
    return 0
}
