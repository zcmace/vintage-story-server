#!/bin/bash
set -e

# Install Docker
dnf install -y docker
systemctl enable docker
systemctl start docker

# Create game data directory
mkdir -p /var/vintagestory/data
chown -R 1000:1000 /var/vintagestory/data

# ECR login (instance profile has ECR pull)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin ${ecr_registry}

# Vintage Story server
docker pull ${ecr_repository_url}:latest
docker run -d --name vintagestory_server --restart unless-stopped \
  -p 42420:42420 -p 42420:42420/udp \
  -v /var/vintagestory/data:/var/vintagestory/data \
  -e VS_VERSION=${vs_version} \
  ${ecr_repository_url}:latest

# Portainer - Docker management, container restarts, logs
docker run -d --name portainer --restart always \
  -p 9000:9000 -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest -H unix:///var/run/docker.sock

# FileBrowser - manage game files (config, mods, saves)
docker run -d --name filebrowser --restart unless-stopped \
  -p 8080:8080 \
  -v /var/vintagestory/data:/data \
  -e PUID=1000 -e PGID=1000 \
  filebrowser/filebrowser:latest --database /data/.filebrowser.db --root /data --port 8080
