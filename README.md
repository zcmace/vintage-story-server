# Vintage Story Server on AWS

> **Disclaimer:** I am not an expert and have not tested this in another AWS account, this is what worked for me. By hosting this, you are accepting the risks and costs of self-hosting on AWS. If you find any issues with the setup feel free to open an issue and I'll do my best to resolve.

Self-host a [Vintage Story](https://www.vintagestory.at/) game server on AWS with one-click deploys from GitHub. No AWS access keys stored in GitHub—uses OIDC for secure deployments.

## What You Get

- **Game server** – Vintage Story dedicated server on EC2 (port 42420)
- **Portainer** – Web UI to restart the server, view logs, manage Docker (port 9000)
- **FileBrowser** – Web UI to manage game files: config, mods, saves (port 8080)
- **GitHub Actions** – Deploy and restart from your repo with a button click

## Quick Start

1. **Fork this repository** to your GitHub account.
2. **Set up AWS** – Create an account at [aws.amazon.com](https://aws.amazon.com) if needed.
3. **Deploy** – Follow [DEPLOYMENT.md](DEPLOYMENT.md) for step-by-step instructions.

## Documentation

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Full deployment guide: AWS setup, Terraform, GitHub Secrets |
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

## Managing the Server

- **Restart**: Portainer → Containers → vintagestory_server → Restart  
- **Files**: FileBrowser at `http://<your-ip>:8080` (default login: admin / admin)  
- **Console commands**: See [DEPLOYMENT.md#server-console-commands](DEPLOYMENT.md#server-console-commands)

## License

MIT
