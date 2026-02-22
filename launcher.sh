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
    # Download the server archive. Newer versions (1.19+) use vs_server_linux-x64_*.tar.gz
    NEW_STYLE="vs_server_linux-x64_${VS_VERSION}.tar.gz"
    OLD_STYLE="vs_server_${VS_VERSION}.tar.gz"
    # CDN and mirror - some environments (e.g. AWS) may be blocked by CDN
    URLS=(
        "https://cdn.vintagestory.at/gamefiles/stable/${NEW_STYLE}"
        "https://account.vintagestory.at/files/stable/${NEW_STYLE}"
        "https://cdn.vintagestory.at/gamefiles/stable/${OLD_STYLE}"
        "https://account.vintagestory.at/files/stable/${OLD_STYLE}"
    )

    ARCHIVE=""
    for url in "${URLS[@]}"; do
        echo "Trying: $url"
        filename=$(basename "$url")
        if wget -q --user-agent="VintageStoryServer/1.0" "$url" -O "$filename" 2>/dev/null && [ -s "$filename" ]; then
            ARCHIVE="$filename"
            break
        fi
        # Fallback to curl (sometimes works when wget fails, e.g. TLS in AWS)
        if command -v curl >/dev/null 2>&1; then
            if curl -sSL -A "VintageStoryServer/1.0" "$url" -o "$filename" 2>/dev/null && [ -s "$filename" ]; then
                ARCHIVE="$filename"
                break
            fi
        fi
        rm -f "$filename" 2>/dev/null
    done

    if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
        echo "ERROR: Failed to download server. Tried all URLs."
        echo "Check VS_VERSION (${VS_VERSION}) and network access from this environment."
        exit 1
    fi

    tar xzf "$ARCHIVE"
    rm -f "$ARCHIVE"
    chmod +x ./server.sh
    echo "Server files downloaded."
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
