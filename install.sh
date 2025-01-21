#!/bin/bash

set -e

# Function to display status messages
status_message() {
    echo "==== $1 ===="
}

# Function to prompt the user for installation options
select_option() {
    echo "Please select an option:"
    echo "1. Install as fresh code"
    echo "2. Update code to latest version"
    read -p "Enter your choice [1 or 2]: " option

    case $option in
        1)
            status_message "Selected: Install as fresh code"
            fresh_install
            ;;
        2)
            status_message "Selected: Update to Latest Version"
            update_version
            ;;
        *)
            echo "Invalid option. Please choose 1 or 2."
            exit 1
            ;;
    esac
}

# Function to perform a fresh installation
fresh_install() {
    # Load environment variables from .env file
    status_message "Loading environment variables"
    if [ -f .env ]; then
        set -o allexport
        source .env
        set +o allexport
    else
        echo ".env file not found! Please make sure the environment variables are set."
        exit 1
    fi

    # Prompt user for Admin Panel URL
    read -p "Enter Admin Panel URL (without trailing /): " ADMIN_PANEL_URL
    ADMIN_PANEL_URL="${ADMIN_PANEL_URL%/}"  # Remove trailing slash if present
    update_env_variable "NEXT_PUBLIC_API_URL" "$ADMIN_PANEL_URL"

    # Prompt user for Website URL
    read -p "Enter Website URL (without trailing /): " WEBSITE_URL
    WEBSITE_URL="${WEBSITE_URL%/}"  # Remove trailing slash if present
    update_env_variable "NEXT_PUBLIC_WEB_URL" "$WEBSITE_URL"

    # Prompt user for Google Maps API Key
    read -p "Enter Google Maps API Key: " GOOGLE_API_KEY
    update_env_variable "NEXT_PUBLIC_GOOGLE_API" "$GOOGLE_API_KEY"

    # Proceed with the rest of the fresh installation steps
    status_message "Installing NVM"
    wget -O nvm.sh https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

    # Load NVM and install Node.js
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    status_message "Installing Node.js"
    nvm install 20

    # Install PM2 if not installed
    if ! pm2 -v ; then
        status_message "Installing PM2"
        npm install -g pm2
    fi

    # Find an available port and update config files
    find_available_port_and_update

    # Install project dependencies and build the project
    install_dependencies_and_build

    # Start the project with PM2
    status_message "Starting the project with PM2"
    pm2 start npm --name "ebroker" -- start

    # Save PM2 processes
    pm2 save
    status_message "Installation and deployment complete!"
}

# Function to perform version update (install dependencies, build, restart PM2)
update_version() {
    status_message "Updating from v-1.1.8 to v-1.1.9"

    # Install project dependencies and rebuild the project
    install_dependencies_and_build

    # Get the process ID for the 'ebroker' process
    PROCESS_ID=$(pm2 list | grep "ebroker" | awk '{print $2}')

    if [ -n "$PROCESS_ID" ]; then
        # Restart the project using the ID
        status_message "Restarting the 'ebroker' project with PM2 (ID: $PROCESS_ID)"
        pm2 restart $PROCESS_ID

        # Save PM2 processes
        pm2 save
        status_message "Version update and deployment complete!"
    else
        status_message "Error: 'ebroker' process not found in PM2 list"
    fi
}

# Function to install dependencies and build the project
install_dependencies_and_build() {
    # Install project dependencies
    status_message "Installing project dependencies"
    npm install

    # Build the project
    status_message "Building the project"
    npm run build
}

# Function to find an available port and update .htaccess and package.json
find_available_port_and_update() {
    status_message "Finding an available port"
    PORT=$(find_available_port)
    if [ $? -ne 0 ]; then
        exit 1
    fi
    echo "Found available port: $PORT"

    # Update .htaccess and package.json files with the new port
    status_message "Updating .htaccess file"
    sed -i "s/http:\/\/127\.0\.0\.1:[0-9]*\//http:\/\/127.0.0.1:$PORT\//g" .htaccess

    status_message "Updating package.json file"
    sed -i "s/NODE_PORT=*[0-9]*/NODE_PORT=$PORT/" package.json
}

# Function to find an available port
find_available_port() {
    for port in $(seq 8003 9001); do
        if ! sudo lsof -i :$port > /dev/null 2>&1; then
            echo $port
            return 0
        fi
    done
    echo "No available ports found between 8001 and 9001" >&2
    return 1
}

# Function to update the .env variable
update_env_variable() {
    local VARIABLE_NAME=$1
    local NEW_VALUE=$2

    # Update the variable in the .env file
    if grep -q "^$VARIABLE_NAME=" .env; then
        sed -i "s|^$VARIABLE_NAME=.*|$VARIABLE_NAME=\"$NEW_VALUE\"|" .env
    else
        echo "$VARIABLE_NAME=\"$NEW_VALUE\"" >> .env
    fi

    status_message "Updated $VARIABLE_NAME in .env file"
}

# Start script by prompting for options
select_option
