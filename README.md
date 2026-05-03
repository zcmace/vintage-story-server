# Vintage Story Server on AWS

> **Disclaimer:** I am not an expert and have not tested this in another AWS account, this is what worked for me. By hosting this, you are accepting the risks and costs of self-hosting on AWS. If you find any issues with the setup feel free to open an issue and I'll do my best to resolve.

Self-host a [Vintage Story](https://www.vintagestory.at/) game server on AWS with one-click deploys from GitHub. No AWS access keys stored in GitHub—uses OIDC for secure deployments.

## What You Get

- **Game server** – Vintage Story dedicated server on EC2 (port 42420)
- **Portainer** – Web UI to restart the server, view logs, manage Docker (port 9000)
- **FileBrowser** – Web UI to manage game files: config, mods, saves (port 8080)
- **GitHub Actions** – Deploy, start, stop, restart, and backup from your repo with a button click
- **Persistent save data** – Dedicated EBS volume (survives instance replacement)
- **No SSH keys required** – All server access via AWS SSM

## Quick Start

1. **Fork this repository** to your GitHub account.
2. **Set up AWS** – Create an account at [aws.amazon.com](https://aws.amazon.com) if needed.
3. **Deploy** – Follow [DEPLOYMENT.md](DEPLOYMENT.md) for step-by-step instructions.

## Documentation

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Full deployment guide: AWS setup, Terraform, GitHub Secrets |
| [UPDATING.md](UPDATING.md) | How to update the game server version |
| [infrastructure/README.md](infrastructure/README.md) | Terraform details, options, and troubleshooting |

## Local Development

Run the server locally with Docker:

```bash
cp .env.example .env
docker compose up -d
```

Connect to `localhost:42420`. Game data is in `./vintage_story/data`.

## Connecting to Your Server

After deployment, players connect using the **public IP** (shown in Terraform output). Add the server in Vintage Story: **Multiplayer → Add new server** → enter the IP. Port 42420 is used automatically.

## GitHub Actions Workflows

All server operations are available from **Actions** in your GitHub repository. No SSH or AWS Console access needed.

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **Deploy to AWS** | Manual | Builds Docker image, pushes to ECR, pulls and runs on EC2. Optionally accepts a version override. |
| **Start Server** | Manual | Starts the EC2 instance (if stopped), waits for SSM, then starts all containers. |
| **Stop Server** | Manual | Gracefully stops the game container, then stops the EC2 instance to save money. |
| **Restart Server** | Manual | Restarts the game container (and ensures Portainer/FileBrowser are running) without stopping EC2. |
| **Download Server Files** | Manual | Zips all game data on the server, stages it in S3, and delivers it as a downloadable GitHub Actions artifact (kept for 7 days). |

## Updating the Game Version

The server version is stored in one place: the `vs_version` variable in `infrastructure/variables.tf` (default `1.22.1`).

To update:
1. Change `vs_version` in `variables.tf` (or pass it as an input when triggering the deploy workflow).
2. Run **Deploy to AWS** — it resolves the version, rebuilds the image, and redeploys.

## Saving Money: Start/Stop

The server costs nothing when the EC2 instance is stopped. Use the **Start Server** and **Stop Server** workflows to turn it on and off between play sessions. Save data is on a dedicated EBS volume and is never lost when the instance stops or is replaced.

## Managing the Server

- **Web UI**: Portainer at `http://<your-ip>:9000` — view logs, restart containers, open a terminal
- **Files**: FileBrowser at `http://<your-ip>:8080` — browse/edit config, upload mods, download saves
- **Backup**: Run **Download Server Files** from Actions — downloads the full `/var/vintagestory/data` as a zip artifact
- **Console commands**: See [DEPLOYMENT.md#server-console-commands](DEPLOYMENT.md#server-console-commands)

## Infrastructure Overview

All cloud resources are managed by Terraform in `infrastructure/`.

| Resource | Purpose |
|----------|---------|
| EC2 instance | Runs Docker and all server containers |
| EBS data volume (20 GB, `prevent_destroy`) | Persistent game data — survives instance replacement or `terraform destroy` |
| Elastic IP | Static public IP so the server address never changes |
| ECR repository | Stores the Docker image |
| S3 bucket | Temporary staging for server file downloads (1-day auto-expiry) |
| SSM Parameters | Single source of truth for `vs_version` and the downloads bucket name |
| IAM / OIDC | GitHub Actions assumes an AWS role — no long-lived access keys stored in GitHub |
| CloudWatch alarm | Stops EC2 after 30 min of no player traffic; sends email alert |

## License

MIT
