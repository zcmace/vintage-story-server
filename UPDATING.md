# Updating the Server Version

Check [vintagestory.at/downloads](https://www.vintagestory.at/downloads) for the latest stable release.

## Option A: Rebuild via GitHub Actions (recommended)

1. Go to your repo → **Actions** → **Build and Push**
2. Click **Run workflow**
3. Enter the new version (e.g. `1.22.1`) and run

Once the image is pushed to GHCR, pull and restart on your server:

```bash
docker compose pull && docker compose up -d
```

## Option B: Build locally

```bash
docker compose down
docker compose build --build-arg VS_VERSION=1.22.1
docker compose up -d
```

Or just pass the version at runtime (pulls from GHCR):

```bash
VS_VERSION=1.22.1 docker compose up -d
```

## Rollback

Run the same steps with the previous version number. Game save data is in `VS_DATA_PATH` and is not affected by version changes.
