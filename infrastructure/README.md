# Infrastructure (Terraform)

Terraform config for running a Vintage Story server on **AWS EC2**. Creates the server, storage, and everything needed for one-click deploys from GitHub.

**New to Terraform?** Follow the main [DEPLOYMENT.md](../DEPLOYMENT.md) guide—it covers setup step by step.

---

## What Gets Created

| Resource | Purpose |
|----------|---------|
| **ECR repository** | Stores the Vintage Story Docker image. GitHub Actions builds and pushes here. |
| **EC2 instance** | Amazon Linux 2023 with Docker. Runs Vintage Story, Portainer, and FileBrowser. |
| **Elastic IP** | Static public IP so players can always connect to the same address. |
| **EBS volume** | Root disk. Game data lives at `/var/vintagestory/data`. |
| **Security group** | Firewall rules: 42420 (game), 9000/9443 (Portainer), 8080 (FileBrowser), 22 (SSH). |
| **IAM roles** | Instance role (ECR pull, SSM); GitHub OIDC role (ECR push, SSM deploy). |

---

## Quick Start

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set github_org and github_repo
terraform init
terraform plan
terraform apply
```

After `apply`, copy the outputs and add them as GitHub Secrets (see [DEPLOYMENT.md](../DEPLOYMENT.md#step-4-add-github-secrets)).

---

## Configuration (terraform.tfvars)

Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust.

### Required

| Variable | Description |
|----------|-------------|
| `github_org` | Your GitHub username or organization (e.g. `johndoe`) |
| `github_repo` | Repository name (e.g. `vintage-story-server`) |

### Optional (defaults are fine for most users)

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `ec2_instance_type` | `t3.small` | Instance size (~$15/mo). Use `t3.medium` for more players. |
| `ec2_root_volume_gb` | `30` | Disk size for game data |
| `vs_version` | `1.21.6` | Vintage Story server version |

### Optional: Security & Access

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_allowed_cidrs` | `["0.0.0.0/0"]` | Restrict SSH: use `["YOUR_IP/32"]` for your IP only |
| `ssh_key_name` | `null` | EC2 key pair name for SSH. Leave null to use Session Manager only. |
| `serial_console_password` | `null` | Password for Serial Console fallback (when SSM/SSH fail) |

### Optional: Custom VPC

If you don’t use the default VPC:

```hcl
use_default_vpc = false
vpc_id          = "vpc-xxxxxxxx"
subnet_ids      = ["subnet-xxxxxxxx"]
```

Use a **public** subnet so the instance can reach the internet and ECR.

---

## Outputs

After `terraform apply`, you’ll see:

| Output | Use |
|--------|-----|
| `ec2_public_ip` | IP players use to connect (port 42420) |
| `portainer_url` | Portainer web UI |
| `filebrowser_url` | FileBrowser web UI |
| `github_actions_role_arn` | GitHub secret `AWS_ROLE_ARN` |
| `ec2_instance_id` | GitHub secret `EC2_INSTANCE_ID` |

---

## Accessing the Server (No SSH Key)

Use **Session Manager**:

1. AWS Console → EC2 → Instances
2. Select your instance
3. **Connect** → **Session Manager** tab → **Connect**

No SSH key or bastion host needed.

---

## Destroying

To remove everything (including game data):

```bash
terraform destroy
```

Type `yes` when prompted.

---

## File Layout

| File | Purpose |
|------|---------|
| `ec2.tf` | EC2 instance, Elastic IP, security group, user-data |
| `ecr.tf` | ECR repository and lifecycle policy |
| `vpc.tf` | VPC/subnet selection |
| `github-oidc.tf` | IAM role for GitHub Actions OIDC |
| `iam.tf` | Instance profile and ECR permissions |
| `variables.tf` | Variable definitions |
| `outputs.tf` | Output values |
| `versions.tf` | Terraform and provider versions |
