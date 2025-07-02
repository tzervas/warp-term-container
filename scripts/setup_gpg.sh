#!/bin/bash

setup_gpg() {
    echo "Setting up GPG..."
    
    # Ensure GNUPGHOME is set
    if [ -z "$GNUPGHOME" ]; then
        echo "Error: GNUPGHOME environment variable is not set"
        return 1
    fi

    # Ensure proper permissions on GNUPGHOME directory
    if [ ! -d "$GNUPGHOME" ]; then
        mkdir -p "$GNUPGHOME"
    fi
    chmod 700 "$GNUPGHOME"
    
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

    # Check for intended GPG key
    if [ -z "$GPG_KEY_ID" ]; then
        echo "Error: GPG_KEY_ID environment variable is not set"
        return 1
    fi

    if ! gpg --list-secret-keys --keyid-format=long "$GPG_KEY_ID" > /dev/null 2>&1; then
        echo "Error: Intended GPG key ($GPG_KEY_ID) not found in keyring"
        return 1
    fi

    # Check if the key is usable for signing
    if ! gpg --dry-run --sign --local-user "$GPG_KEY_ID" --output /dev/null <<< "test" > /dev/null 2>&1; then
        echo "Error: Intended GPG key ($GPG_KEY_ID) is not usable for signing"
        return 1
    fi

    echo "GPG setup completed successfully with key $GPG_KEY_ID"
    return 0
}
