#!/bin/bash
set -e

# Set GPG Home
export GNUPGHOME=/home/warp/.gnupg

# Ensure the directory exists and fix permissions
mkdir -p $GNUPGHOME
chmod 700 $GNUPGHOME

# Import the GPG key
gpg --batch --yes --import /tmp/warp-ai.key

# Clean up
rm /tmp/warp-ai.key
