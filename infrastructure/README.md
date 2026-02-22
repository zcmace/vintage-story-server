# Infrastructure (Terraform)

Terraform for the Vintage Story server on **AWS EC2**. Provisions ECR, a single EC2 instance with Docker, and EBS for persistent game data. **Portainer** and **FileBrowser** provide a web UI for container restarts and file management.

## What gets created

| Resource | Purpose |
|----------|---------|
| **ECR repository** | `vintage-story-server` – GitHub Actions builds and pushes the image here. |
| **EC2 instance** | Amazon Linux 2023, Docker, Vintage Story + Portainer + FileBrowser. |
| **EBS (root volume)** | Game data stored at `/var/vintagestory/data` on the instance. |
| **Security group** | Ports 42420 (game), 9000/9443 (Portainer), 8080 (FileBrowser), 22 (SSH). |
| **IAM roles** | Instance profile (ECR pull, SSM); GitHub OIDC role (ECR push, SSM deploy). |

## Prerequisites

1. **Terraform** >= 1.5 (`terraform version`)
2. **AWS credentials** configured (`aws sts get-caller-identity`)

## Quick start

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed (github_org, github_repo required)
terraform init
terraform plan
terraform apply
```

After `apply`, note the outputs and set GitHub Secrets (see below).

## GitHub Secrets (OIDC – no access keys)

The workflow uses **OpenID Connect** so GitHub Actions assumes an IAM role; you do **not** need `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY`.

In **Settings → Secrets and variables → Actions** add:

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | Terraform output `github_actions_role_arn` |
| `EC2_INSTANCE_ID` | Terraform output `ec2_instance_id` |

**Terraform:** Set `github_org` and `github_repo` in `terraform.tfvars` to your GitHub org/user and repo name so the OIDC trust is scoped to that repository.

Then run the **Deploy to AWS** workflow (manual dispatch). It builds the image, pushes to ECR, and deploys to EC2 via SSM (no SSH keys).

## Web UI

| Service | URL | Purpose |
|---------|-----|---------|
| **Portainer** | `http://<instance-ip>:9000` | Docker management, restart containers, view logs |
| **FileBrowser** | `http://<instance-ip>:8080` | Manage game files (config, mods, saves). Default: admin / admin |

## Connecting to the game

After deploy, use the EC2 instance **public IP** (Terraform output `ec2_public_ip`). Players connect on port **42420**.

## Optional: custom VPC

In `terraform.tfvars`:

```hcl
use_default_vpc = false
vpc_id          = "vpc-xxxxxxxx"
subnet_ids      = ["subnet-xxxxxxxx"]
```

Use a **public** subnet so the instance can reach ECR and the internet.

## Optional: restrict SSH

By default SSH (port 22) is open to `0.0.0.0/0`. Restrict in `terraform.tfvars`:

```hcl
ssh_allowed_cidrs = ["YOUR_IP/32"]
```

## Destroying

```bash
terraform destroy
```

This removes the EC2 instance (and all game data on it), ECR repository, and related IAM/security groups.
