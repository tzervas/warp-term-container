#!/bin/bash
set -e

# Constants
USERS_FILE="secrets/traefik-users.txt"
USERS_FILE_BACKUP="secrets/traefik-users.txt.bak"
MIN_PASSWORD_LENGTH=16

# Function to generate a secure random password
generate_password() {
    local length=${1:-$MIN_PASSWORD_LENGTH}
    # Generate password using /dev/urandom, filtering out problematic shell metacharacters
    # Exclude: backtick (`), single quote ('), double quote ("), dollar ($), backslash (\), and space
    # Allowed: A-Za-z0-9!#$%\&()*+,-./:;<=>?@[]^_{|}~
    tr -dc 'A-Za-z0-9!#$%\&()*+,-./:;<=>?@[]^_{|}~' < /dev/urandom | head -c "$length"
    if [[ "$length" -lt 32 ]]; then
        echo "Warning: Password excludes certain shell metacharacters for safety." >&2
    fi
}

# Function to create a new user
create_user() {
    local username=$1
    local password=${2:-$(generate_password)}
    
    # Validate inputs
    if [ -z "$username" ]; then
        echo "Error: Username is required"
        exit 1
    fi
    
    if [ ${#password} -lt $MIN_PASSWORD_LENGTH ]; then
        echo "Error: Password must be at least $MIN_PASSWORD_LENGTH characters"
        exit 1
    fi
    
    # Create users file if it doesn't exist
    mkdir -p "$(dirname "$USERS_FILE")"
    touch "$USERS_FILE"
    
    # Check if user already exists
    if grep -Fq "^$username:" "$USERS_FILE" 2>/dev/null; then
        echo "Error: User $username already exists"
        exit 1
    fi
    
    # Generate hashed password using htpasswd
    local hashed_entry
    hashed_entry=$(htpasswd -nbB "$username" "$password")
    
    # Backup current file with timestamp to avoid overwriting
    timestamp=$(date +"%Y%m%d_%H%M%S")
    cp "$USERS_FILE" "${USERS_FILE_BACKUP}.${timestamp}"
    
    # Add new user
    echo "$hashed_entry" >> "$USERS_FILE"
    chmod 600 "$USERS_FILE"
    
    echo "User $username created successfully"
    echo "Password: $password"
    echo "Please save this password securely"
}

# Function to rotate user password
rotate_password() {
    local username=$1
    local new_password=${2:-$(generate_password)}
    
    # Validate inputs
    if [ -z "$username" ]; then
        echo "Error: Username is required"
        exit 1
    fi
    
    if [ ! -f "$USERS_FILE" ]; then
        echo "Error: Users file not found"
        exit 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_FILE"; then
        echo "Error: User $username not found"
        exit 1
    fi
    
    # Generate new hash
    local new_hash
    new_hash=$(htpasswd -nbB "$username" "$new_password")
    
    # Backup current file with timestamp to avoid overwriting
    timestamp=$(date +"%Y%m%d_%H%M%S")
    cp "$USERS_FILE" "${USERS_FILE_BACKUP}.${timestamp}"
    
    # Update password
    escaped_username=$(printf "%s" "$username" | sed 's/[].[^$*\]/\\&/g')
    sed -i "s|^$escaped_username:.*|$new_hash|" "$USERS_FILE"
    chmod 600 "$USERS_FILE"
    
    echo "Password rotated for user $username"
    echo "New password: $new_password"
    echo "Please save this password securely"
}

# Function to list users
list_users() {
    if [ ! -f "$USERS_FILE" ]; then
        echo "No users found"
        return
    fi
    
    echo "Current users:"
    cut -d: -f1 "$USERS_FILE"
}

# Function to delete user
delete_user() {
    local username=$1
    
    if [ -z "$username" ]; then
        echo "Error: Username is required"
        exit 1
    fi
    
    if [ ! -f "$USERS_FILE" ]; then
        echo "Error: Users file not found"
        exit 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_FILE"; then
        echo "Error: User $username not found"
        exit 1
    fi
    
    # Backup current file with timestamp to avoid overwriting
    timestamp=$(date +"%Y%m%d_%H%M%S")
    cp "$USERS_FILE" "${USERS_FILE_BACKUP}.${timestamp}"
    
    # Remove user
    escaped_username=$(printf "%s" "$username" | sed 's/[].[^$*\]/\\&/g')
    sed -i "/^$escaped_username:/d" "$USERS_FILE"
    chmod 600 "$USERS_FILE"
    
    echo "User $username deleted successfully"
}

# Help function
show_help() {
    echo "Usage: $0 COMMAND [args]"
    echo ""
    echo "Commands:"
    echo "  create USERNAME [PASSWORD]  Create a new user"
    echo "  rotate USERNAME [PASSWORD]  Rotate password for existing user"
    echo "  list                       List all users"
    echo "  delete USERNAME            Delete a user"
    echo "  help                       Show this help message"
    echo ""
    echo "If PASSWORD is not provided, a secure random password will be generated"
}

# Main script logic
case "$1" in
    create)
        create_user "$2" "$3"
        ;;
    rotate)
        rotate_password "$2" "$3"
        ;;
    list)
        list_users
        ;;
    delete)
        delete_user "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$1'"
        show_help
        exit 1
        ;;
esac
