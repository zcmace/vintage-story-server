# Updating the Game Server Version

This guide covers how to update the Vintage Story server version on your EC2 deployment.

## How versioning works

The server binary is downloaded **at Docker image build time** using the `VS_VERSION` value in the `Dockerfile`. That means updating the version requires rebuilding and redeploying the Docker image. There are four files that hold the version string and must be kept in sync:

| File | Purpose |
|------|---------|
| `Dockerfile` | Downloads the server binary during image build — **this is the critical one** |
| `.github/workflows/deploy.yml` | Passed as a runtime env var to the container |
| `infrastructure/terraform.tfvars` | Used if you ever destroy and reprovision the EC2 instance |
| `.env` | Used for local Docker development only |

## Step-by-step update

> Replace `NEW_VERSION` below with the target version number (e.g. `1.20.0`).  
> Check [vintagestory.at/downloads](https://www.vintagestory.at/downloads) for the latest stable release.

### 1. Update the Dockerfile

`Dockerfile` line 7:

```diff
- ENV VS_VERSION=1.21.6
+ ENV VS_VERSION=NEW_VERSION
```

### 2. Update the deploy workflow

`.github/workflows/deploy.yml` line 75:

```diff
- "docker run -d --name vintagestory_server ... -e VS_VERSION=1.21.6 " + $img
+ "docker run -d --name vintagestory_server ... -e VS_VERSION=NEW_VERSION " + $img
```

The full line looks like this — only change the version number at the end:

```
"docker run -d --name vintagestory_server --restart unless-stopped -p 42420:42420 -p 42420:42420/udp -v /var/vintagestory/data:/var/vintagestory/data -e VS_VERSION=NEW_VERSION " + $img
```

### 3. Update the Terraform variable

`infrastructure/terraform.tfvars`:

```diff
- vs_version = "1.21.6"
+ vs_version = "NEW_VERSION"
```

This is only used when EC2 is first provisioned (or after `terraform destroy` + `terraform apply`), but keeping it in sync avoids confusion later.

### 4. Update your local `.env` (optional)

`.env`:

```diff
- VS_VERSION=1.21.6
+ VS_VERSION=NEW_VERSION
```

Only needed if you run the server locally with `docker compose`.

### 5. Commit and push

```bash
git add Dockerfile .github/workflows/deploy.yml infrastructure/terraform.tfvars .env
git commit -m "chore: update Vintage Story server to vNEW_VERSION"
git push
```

### 6. Trigger the deploy workflow

1. Go to your repository on GitHub.
2. Click **Actions** → **Deploy to AWS**.
3. Click **Run workflow** → **Run workflow**.

The workflow will:
- Build a new Docker image with the updated server binary
- Push it to ECR
- Pull it on the EC2 instance and restart the container

### 7. Verify the update

Once the workflow completes, connect to Portainer at `http://<your-ip>:9000` and check the `vintagestory_server` container logs. You should see the new version in the startup output.

Alternatively, connect to the server in Vintage Story — the version is shown in the multiplayer server list.

## Rollback

If something goes wrong, revert all four files to the previous version number, commit, push, and re-run the deploy workflow. Game save data is stored in `/var/vintagestory/data` on the EC2 instance and is not affected by version changes.
