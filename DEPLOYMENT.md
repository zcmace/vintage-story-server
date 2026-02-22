# Deployment Guide

Deploy the Vintage Story server to **AWS EC2** using GitHub Actions.

## Prerequisites

1. AWS account with appropriate permissions
2. GitHub repository
3. **Infrastructure**: Use the Terraform in **`infrastructure/`** to create the EC2 instance, ECR repository, and IAM. See `infrastructure/README.md` for `terraform init`, `plan`, and `apply`.

## GitHub Secrets (OIDC – no access keys)

The deploy workflow uses **OpenID Connect (OIDC)** so GitHub Actions assumes an IAM role. You do **not** store AWS access keys in GitHub.

Go to **Settings → Secrets and variables → Actions** and add:

### Required

| Secret | Description |
|--------|-------------|
| **`AWS_ROLE_ARN`** | Terraform output `github_actions_role_arn` |
| **`EC2_INSTANCE_ID`** | Terraform output `ec2_instance_id` |

When you run Terraform, set **`github_org`** and **`github_repo`** in `terraform.tfvars` to your GitHub organization/user and repository name so only workflows from that repo can assume the role.

### How to add secrets

1. Open `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Click **New repository secret**
3. Enter the name and value

## Deploy

1. **Apply Terraform** (once): `cd infrastructure && terraform apply` and note the outputs.
2. **Set the GitHub Secrets** above.
3. **Run the workflow**: Actions → **Deploy to AWS** → **Run workflow**.

The workflow will:

1. Build the Vintage Story server Docker image and push it to ECR
2. Deploy to EC2 via SSM (pull image, restart container)

Game data (worlds, saves, config) is stored on the EC2 root volume at `/var/vintagestory/data`.

## Web UI

- **Portainer** (`http://<instance-ip>:9000`): Restart the server, view logs, manage Docker. First visit: create admin user.
- **FileBrowser** (`http://<instance-ip>:8080`): Manage game files. Default login: admin / admin — change in Settings.

## Connecting to the server

Use the EC2 **public IP** (Terraform output `ec2_public_ip`). Players connect on port **42420**.

## Restarting the server

- **Portainer**: Containers → vintagestory_server → Restart
- **GitHub Actions**: Run the **Restart Server** workflow

## Local development

1. Copy `.env.example` to `.env` and set paths if needed.
2. Run `docker compose up -d`.

## Security

- **OIDC**: The workflow assumes an IAM role via GitHub OIDC; no long-lived AWS access keys are stored in GitHub.
- The Terraform role is scoped to your repo (`github_org`/`github_repo`); only workflows from that repository can assume it.
- The role has least privilege: ECR push, SSM SendCommand for deploys.

## Troubleshooting

- **Workflow can't assume role**: Ensure `AWS_ROLE_ARN` matches Terraform output `github_actions_role_arn`, and that `github_org`/`github_repo` in Terraform match your repository. The workflow needs `id-token: write` (already set in the workflow).
- **Deploy fails**: Check workflow logs; ensure `EC2_INSTANCE_ID` matches Terraform output. The EC2 instance must have SSM agent (Amazon Linux 2023 has it by default) and the instance profile with SSM permissions.
- **Container won't start**: SSH to the instance (or use SSM Session Manager) and run `docker logs vintagestory_server`. Check `/var/vintagestory/data/Logs` for Vintage Story errors.
