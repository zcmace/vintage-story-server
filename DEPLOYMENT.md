# Deployment Guide

This guide covers deploying the Vintage Story server on any Linux host with Docker installed.

## Prerequisites

- A server with Docker and Docker Compose v2 (any VPS, home server, or cloud instance)
- Port 42420 open (TCP + UDP) for game traffic
- Port 8080 open for FileBrowser (optional)

## Deploy

### Option A: Pull from GitHub Container Registry (recommended)

No build step required. Pull the pre-built image and start:

```bash
docker compose up -d
```

To pin a specific version:

```bash
VS_VERSION=1.22.1 docker compose up -d
```

### Option B: Build locally

```bash
docker compose up -d --build
```

Or build and push your own image using the **Build and Push** GitHub Actions workflow, then reference it:

```bash
IMAGE=ghcr.io/your-username/vintage-story-server VS_VERSION=1.22.1 docker compose up -d
```

## Game Data

All saves, configs, and mods are stored in `VS_DATA_PATH` (default: `./vintage_story/data`). This directory persists across container restarts and upgrades.

To use a custom path:

```bash
VS_DATA_PATH=/mnt/data docker compose up -d
```

## FileBrowser

FileBrowser starts automatically alongside the game server at port 8080.

- **URL:** `http://<your-ip>:8080`
- **Default credentials:** `admin` / `adminpassword`
- Change your password after first login via **Settings → Password**

## Server Console

To run in-game server commands:

```bash
# Single command
docker exec vintagestory_server bash -c "cd /home/vintagestory/server && ./server.sh command '/help'"

# Interactive screen session
docker exec -it vintagestory_server screen -r vintagestory_server
```

Detach from screen with **Ctrl+A**, then **D**.

## Connecting to the Game

In Vintage Story: **Multiplayer → Add new server** → enter your server's IP address. Port 42420 is used automatically.

## Stopping the Server

```bash
docker compose down
```

Game data is preserved in `VS_DATA_PATH`.
