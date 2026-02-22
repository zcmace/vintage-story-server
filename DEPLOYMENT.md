# Deployment Guide

Deploy the Vintage Story server to **AWS ECS Fargate** using GitHub Actions.

## Prerequisites

1. AWS account with appropriate permissions
2. GitHub repository
3. **Infrastructure**: Use the Terraform in **`infrastructure/`** to create the ECS cluster, ECR repository, Fargate service, and EFS. See `infrastructure/README.md` for `terraform init`, `plan`, and `apply`.

## GitHub Secrets (OIDC – no access keys)

The deploy workflow uses **OpenID Connect (OIDC)** so GitHub Actions assumes an IAM role. You do **not** store AWS access keys in GitHub.

Go to **Settings → Secrets and variables → Actions** and add:

### Required

| Secret | Description |
|--------|-------------|
| **`AWS_ROLE_ARN`** | Terraform output `github_actions_role_arn` (IAM role created for GitHub OIDC) |
| **`ECS_CLUSTER_NAME`** | Terraform output `ecs_cluster_name` (e.g. `vintage-story-cluster`) |
| **`ECS_SERVICE_NAME`** | Terraform output `ecs_service_name` (e.g. `vintage-story-service`) |
| **`ECS_TASK_DEFINITION`** | Terraform output `ecs_task_definition_family` (e.g. `vintage-story-task`) |

When you run Terraform, set **`github_org`** and **`github_repo`** in `terraform.tfvars` to your GitHub organization/user and repository name so only workflows from that repo can assume the role.

### How to add secrets

1. Open `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Click **New repository secret**
3. Enter the name and value

## Deploy

1. **Apply Terraform** (once): `cd infrastructure && terraform apply` and note the ECS outputs.
2. **Set the GitHub Secrets** above.
3. **Run the workflow**: Actions → **Deploy to AWS** → **Run workflow**.

The workflow will:

1. Build the Vintage Story server Docker image and push it to ECR
2. Deploy to ECS Fargate (new task definition revision, service update, wait for stability)

Game data (worlds, saves, config) is stored on EFS and persists across deployments.

## Connecting to the server

After a successful deploy, in the AWS ECS console: **Clusters** → your cluster → **Tasks** → open the running task and copy its **Public IP**. Players connect to that IP on port **42420**.

## Local development

1. Copy `.env.example` to `.env` and set paths if needed.
2. Run `docker compose up -d`.

## Security

- **OIDC**: The workflow assumes an IAM role via GitHub OIDC; no long-lived AWS access keys are stored in GitHub.
- The Terraform role is scoped to your repo (`github_org`/`github_repo`); only workflows from that repository can assume it.
- The role has least privilege: ECR push for the repo’s image, ECS describe/register task definition, update service, and PassRole for the ECS task roles.

## Troubleshooting

- **Workflow can’t assume role**: Ensure `AWS_ROLE_ARN` matches Terraform output `github_actions_role_arn`, and that `github_org`/`github_repo` in Terraform match your repository. The workflow needs `id-token: write` (already set in the workflow).
- **Deploy fails**: Check workflow logs; ensure `ECS_CLUSTER_NAME`, `ECS_SERVICE_NAME`, and `ECS_TASK_DEFINITION` match your Terraform outputs.
- **Task won’t start**: Check ECS task logs in CloudWatch (`/ecs/vintage-story`); ensure the container can mount EFS and reach the internet (e.g. subnets with NAT or public IP).
