# Vintage Story Server

Self-host a [Vintage Story](https://www.vintagestory.at/) dedicated server using Docker. Run it on any VPS, home server, or cloud instance — no vendor lock-in.

## What You Get

- **Game server** – Vintage Story dedicated server on port 42420
- **FileBrowser** – Web UI to manage config, mods, and saves (port 8080)
- **GitHub Actions** – Build and push a versioned Docker image to GHCR, and pull backups via SSH

## Quick Start

Any machine with Docker installed:

```bash
docker compose up -d
```

This pulls the latest image from GitHub Container Registry and starts the server. Game data is stored in `./vintage_story/data`.

Connect in-game: **Multiplayer → Add new server** → enter your server's IP. Port 42420 is used automatically.

## Configuration

All variables have defaults. Override at runtime or in a shell environment:

| Variable | Default | Description |
|----------|---------|-------------|
| `VS_VERSION` | `latest` | Vintage Story version tag |
| `VS_DATA_PATH` | `./vintage_story/data` | Host path for game data |
| `IMAGE` | `ghcr.io/zcmace/vintage-story-server` | Docker image to use |
| `FB_ADMIN_PASSWORD` | `adminpassword` | FileBrowser initial password (min 12 chars) |

Example:
```bash
VS_VERSION=1.22.1 VS_DATA_PATH=/mnt/data docker compose up -d
```

## FileBrowser

Available at `http://<your-ip>:8080`.

Default credentials: `admin` / `adminpassword`

After first login, change your password via **Settings → Password** (no minimum length enforced).

## GitHub Actions Workflows

| Workflow | What it does |
|----------|-------------|
| **Build and Push** | Builds a versioned Docker image and pushes to `ghcr.io`. Trigger manually with a version input. |
| **Download Backup** | SSHes into your server, tars the game data directory, and uploads it as a downloadable artifact. |

### Secrets required

**Build and Push:** None — uses `GITHUB_TOKEN` automatically.

**Download Backup:**

| Secret | Value |
|--------|-------|
| `SSH_HOST` | Server IP or hostname |
| `SSH_USER` | SSH username |
| `SSH_PRIVATE_KEY` | Contents of your private key |

## Updating the Server Version

See [UPDATING.md](UPDATING.md).

## Backing Up

Run **Download Backup** from the Actions tab. It creates a fresh archive of your game data and uploads it as an artifact (kept 7 days).

## License

MIT
