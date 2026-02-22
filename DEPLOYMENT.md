# Deployment Guide – Vintage Story Server on AWS

This guide walks you through deploying a Vintage Story game server to AWS. No prior AWS or Terraform experience required.

## Overview

You will:

1. Create an AWS account (if needed)
2. Install Terraform and the AWS CLI
3. Run Terraform to create the server infrastructure
4. Add two secrets to your GitHub repository
5. Deploy the server with one click from GitHub Actions

**Estimated time:** 20–30 minutes  
**Cost:** ~$15–25/month (t3.small EC2 + Elastic IP)

---

## Prerequisites

### 1. AWS Account

- Sign up at [aws.amazon.com](https://aws.amazon.com)
- You’ll need a credit card; the free tier helps reduce cost for new accounts

### 2. Terraform

Terraform provisions the server and related resources.

- **Windows:** Download from [terraform.io/downloads](https://www.terraform.io/downloads) and add to PATH
- **macOS:** `brew install terraform`
- **Linux:** See [terraform.io/docs/install](https://developer.hashicorp.com/terraform/install)

Verify: `terraform version` (need 1.5 or newer)

### 3. AWS CLI

Used to authenticate Terraform with AWS.

- Install: [docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Configure: `aws configure` and enter your Access Key ID, Secret Access Key, and region (e.g. `us-east-1`)

Verify: `aws sts get-caller-identity` (should print your account info)

---

## Step 1: Fork the Repository

1. Open this repository on GitHub
2. Click **Fork** to create a copy under your account
3. Clone your fork: `git clone https://github.com/YOUR_USERNAME/vintage-story-server.git`

---

## Step 2: Configure Terraform

1. Go to the infrastructure folder:
   ```bash
   cd vintage-story-server/infrastructure
   ```

2. Copy the example config:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` in any text editor. **You must change these:**
   ```hcl
   github_org   = "YOUR_GITHUB_USERNAME"   # e.g. "johndoe"
   github_repo  = "vintage-story-server"   # your repo name (usually keep as-is)
   ```

   Optional settings (defaults are fine for most users):
   - `aws_region` – AWS region (default: `us-east-1`)
   - `ec2_instance_type` – Server size (default: `t3.small`)
   - `vs_version` – Vintage Story version (default: `1.21.6`)

4. **Do not commit** `terraform.tfvars` if it contains secrets (e.g. `serial_console_password`). It’s in `.gitignore` by default.

---

## Step 3: Run Terraform

1. Initialize Terraform (downloads providers):
   ```bash
   terraform init
   ```

2. Preview what will be created:
   ```bash
   terraform plan
   ```

3. Create the infrastructure:
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

4. **Save the outputs.** You’ll need them for GitHub. Example:
   ```
   ec2_public_ip         = "54.123.45.67"      ← Players connect to this IP
   portainer_url         = "http://54.123.45.67:9000"
   filebrowser_url       = "http://54.123.45.67:8080"
   github_actions_role_arn = "arn:aws:iam::123456789:role/..."
   ec2_instance_id       = "i-0abc123def456"
   ```

---

## Step 4: Add GitHub Secrets

GitHub Actions needs two secrets to deploy. No AWS access keys are stored in GitHub; it uses OIDC to assume a role.

1. Open your repo: `https://github.com/YOUR_USERNAME/vintage-story-server`
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these two secrets:

| Secret Name      | Value (from Terraform output)     |
|------------------|-----------------------------------|
| `AWS_ROLE_ARN`   | `github_actions_role_arn`         |
| `EC2_INSTANCE_ID`| `ec2_instance_id`                |

---

## Step 5: Deploy the Server

1. In your repo, go to **Actions**
2. Select **Deploy to AWS**
3. Click **Run workflow** → **Run workflow**
4. Wait a few minutes. The workflow will:
   - Build the Vintage Story Docker image
   - Push it to AWS ECR
   - Deploy to your EC2 instance via SSM

When it finishes, your server is running.

---

## Connecting to the Game

1. In Vintage Story: **Multiplayer** → **Add new server**
2. Enter the **public IP** (Terraform output `ec2_public_ip`)
3. Port 42420 is used automatically
4. Add the server and join

---

## Web UIs

| Service     | URL                         | Purpose                                      |
|-------------|-----------------------------|----------------------------------------------|
| **Portainer** | `http://<your-ip>:9000`   | Restart server, view logs, manage containers |
| **FileBrowser** | `http://<your-ip>:8080` | Edit config, add mods, manage saves          |

**FileBrowser:** First login is `admin` / `admin`. Change the password in Settings immediately.

**Portainer:** On first visit, create an admin account (one-time setup).

---

## Server Console Commands

To run server commands (e.g. `/whitelist add`, `/announce`):

**Option A – Single command:**
```bash
docker exec -it vintagestory_server bash -c "cd /home/vintagestory/server && ./server.sh command '/help'"
```
Replace `/help` with any server command.

**Option B – Interactive console:**
```bash
docker exec -it vintagestory_server screen -r vintagestory_server
```
Type commands and press Enter. Detach with **Ctrl+A**, then **D**.

You need shell access first: EC2 Console → select instance → **Connect** → **Session Manager** tab.

---

## Restarting the Server

- **Portainer:** Containers → vintagestory_server → Restart
- **GitHub Actions:** Actions → Restart Server → Run workflow

---

## Updating the Game Version

1. Edit `infrastructure/terraform.tfvars`:
   ```hcl
   vs_version = "1.22.0"   # or whatever version you want
   ```
2. Run `terraform apply`
3. Run the **Deploy to AWS** workflow to rebuild and redeploy

---

## Troubleshooting

### Workflow can’t assume role
- Confirm `AWS_ROLE_ARN` matches Terraform output `github_actions_role_arn`
- Ensure `github_org` and `github_repo` in `terraform.tfvars` match your repo

### Deploy fails
- Check workflow logs for the exact error
- Confirm `EC2_INSTANCE_ID` matches Terraform output `ec2_instance_id`
- Instance must be running; SSM agent is included on Amazon Linux 2023

### Can’t connect to the game
- Check security group allows port 42420 (Terraform does this by default)
- Use the Elastic IP from `ec2_public_ip`, not a temporary IP

### Container won’t start
- Use Session Manager to connect, then: `docker logs vintagestory_server`
- Check Vintage Story logs: `/var/vintagestory/data/Logs/`

### FileBrowser wrong credentials
- Default is `admin` / `admin` only for a new database
- To reset: stop container, delete `/var/vintagestory/data/.filebrowser.db`, restart container

---

## Security Notes

- **OIDC:** GitHub Actions assumes an IAM role; no long-lived AWS keys in GitHub
- **Scoped role:** Only workflows from your repo can assume the role
- **SSH:** By default port 22 is open. Restrict in `terraform.tfvars`:
  ```hcl
  ssh_allowed_cidrs = ["YOUR_IP/32"]
  ```

---

## Destroying (Removing Everything)

To delete the server and all resources:

```bash
cd infrastructure
terraform destroy
```

Type `yes` when prompted. **This deletes all game data** on the instance.
