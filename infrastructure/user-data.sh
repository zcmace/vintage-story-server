#!/bin/bash
set -e

# Install SSM agent
sudo dnf install -y "https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm"

# Start it
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Serial Console fallback: set password for ec2-user and root (login: ec2-user or root)
if [ -n "${serial_console_password_b64}" ]; then
  PW=$(echo "${serial_console_password_b64}" | base64 -d)
  printf 'ec2-user:%s\n' "$PW" | chpasswd
  printf 'root:%s\n' "$PW" | chpasswd
fi

# Disable host firewall - security group handles network access
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
iptables -F 2>/dev/null || true
iptables -F INPUT 2>/dev/null || true

# Install Docker
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
usermod -aG docker ssm-user

# Create game data directory
mkdir -p /var/vintagestory/data
chown -R 1000:1000 /var/vintagestory/data

# ECR login (instance profile has ECR pull)
# Use region from Terraform - IMDSv2 requires token, metadata curl can fail at boot
# Command substitution avoids "Cannot perform interactive login from a non tty device" when run via SSM
REGION="${aws_region}"
AWS_PAGER="" docker login -u AWS -p "$(aws ecr get-login-password --region "$REGION")" ${ecr_registry}

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
# Override healthcheck: image defaults to port 80, we use 8080
docker run -d --name filebrowser --restart unless-stopped \
  -p 8080:8080 \
  -v /var/vintagestory/data:/data \
  -e PUID=1000 -e PGID=1000 \
  --health-cmd="wget -qO- http://127.0.0.1:8080/health || exit 1" \
  --health-interval=30s --health-timeout=3s --health-retries=3 \
  filebrowser/filebrowser:latest --database /data/.filebrowser.db --root /data --port 8080
