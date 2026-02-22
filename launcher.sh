#!/bin/bash

# This launcher starts the server and makes a hook to the SIGTERM signal
# So, when a docker stop is executed, the server is stopped properly

# Source .env file if it exists to load VS_VERSION
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Fallback to environment variable if VS_VERSION is not set
VS_VERSION=${VS_VERSION:-1.21.6}

#Define cleanup procedure
cleanup() {
    echo "Container stopped, performing cleanup..."
    ./server.sh stop
}

#Download server 
download_server() {
    # Download the server archive for the indicated version.
    # Newer versions (1.19+) use: vs_server_linux-x64_${VS_VERSION}.tar.gz
    # Older versions use: vs_server_${VS_VERSION}.tar.gz
    BASE_URL="https://cdn.vintagestory.at/gamefiles/stable"
    NEW_STYLE="vs_server_linux-x64_${VS_VERSION}.tar.gz"
    OLD_STYLE="vs_server_${VS_VERSION}.tar.gz"

    if wget -q "${BASE_URL}/${NEW_STYLE}"; then
        tar xzf "${NEW_STYLE}"
        rm -f "${NEW_STYLE}"
    elif wget -q "${BASE_URL}/${OLD_STYLE}"; then
        tar xzf "${OLD_STYLE}"
        rm -f "${OLD_STYLE}"
    else
        echo "ERROR: Failed to download server. Tried: ${NEW_STYLE} and ${OLD_STYLE}"
        echo "Check VS_VERSION (${VS_VERSION}) and available files at ${BASE_URL}/"
        exit 1
    fi

    chmod +x ./server.sh
    echo "Server files downloaded. Suggest configuring and restarting the container to run the server."
}


if [ ! -f ./server.sh ]; then
    echo "Server runtime is missing. Downloading indicated version set in environment variables: ${VS_VERSION}."
    download_server
fi

if [ -f ./server.sh ]; then
    # Trap SIGTERM
    trap 'true' SIGTERM

    # Start the server
    ./server.sh start
    # Sleep to prevent a container stop
    sleep infinity &

    # Wait
    wait

    # Cleanup
    cleanup
fi
