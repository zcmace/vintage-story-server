# Updating the Game Server Version

Check [vintagestory.at/downloads](https://www.vintagestory.at/downloads) for the latest stable release before updating.

## How versioning works

The version flows through the system like this:

1. **`infrastructure/terraform.tfvars`** → sets `vs_version`, stored in SSM Parameter Store
2. **Deploy workflow** → reads version from SSM, passes it as a Docker build arg
3. **Dockerfile** → downloads that version's server binary during image build
4. **Running container** → uses the version baked into the image

The simplest update path is to trigger the **Deploy to AWS** workflow with a version override — no file edits needed.

---

## Option A: One-click via GitHub Actions (easiest)

1. Go to your repo → **Actions** → **Deploy to AWS**
2. Click **Run workflow**
3. Enter the new version (e.g. `1.22.1`) in the **vs_version** input field
4. Click **Run workflow**

The workflow builds a new image with that version and redeploys it. The SSM parameter is NOT updated by this method — if you later deploy without a version override, it will revert to whatever is in SSM.

---

## Option B: Update SSM + redeploy (permanent change)

Use this if you want all future deploys (without a version override) to use the new version.

1. Edit `infrastructure/terraform.tfvars`:
   ```hcl
   vs_version = "1.22.1"
   ```

2. Apply Terraform to update the SSM parameter:
   ```bash
   cd infrastructure
   terraform apply
   ```

3. Trigger the **Deploy to AWS** workflow (no version override needed — it reads from SSM).

---

## Updating for local development

If you run the server locally with `docker compose`, update `VS_VERSION` in your `.env` file:

```
VS_VERSION=1.22.1
```

Then restart: `docker compose up -d --build`

---

## Rollback

Run **Deploy to AWS** with the previous version number as the override input. Game save data is on a separate EBS volume and is not affected by version changes.
