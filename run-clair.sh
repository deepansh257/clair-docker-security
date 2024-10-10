#!/usr/bin/env bash

# Function to check if a command executed successfully
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error executing the previous command!"
        exit 1
    fi
}

# Start the Clair and database containers
docker rm -f clairdb
docker rm -f clair
docker-compose up -d 
check_command

# Give some time for the database to initialize. 
# Note: It's better to have a health check to confirm when the db is ready, but for simplicity, we use sleep here.
sleep 20

# Get Docker's bridge network gateway
DOCKER_GATEWAY=$(docker network inspect bridge --format "{{range .IPAM.Config}}{{.Gateway}}{{end}}")
check_command
echo "$DOCKER_GATEWAY"

# Download and prepare the clair-scanner
if [ ! -f clair-scanner ]; then
    echo "Downloading clair-scanner..."
    wget -qO clair-scanner https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
    check_command
    echo "Setting execute permissions on clair-scanner..."
    chmod +x clair-scanner
fi

# Scan the specified Docker image
./clair-scanner --ip="$DOCKER_GATEWAY" --report "/home/nashtech/ClaireScan/claire_data.json" infoslack/dvwa
check_command