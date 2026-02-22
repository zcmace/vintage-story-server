# Infrastructure (Terraform)

Terraform for the Vintage Story server on **AWS ECS Fargate**. Provisions ECR, ECS cluster, Fargate task definition and service, and EFS for persistent game data.

## What gets created

| Resource | Purpose |
|----------|---------|
| **ECR repository** | `vintage-story-server` – GitHub Actions builds and pushes the image here. |
| **ECS cluster** | Fargate cluster for the game server. |
| **Task definition & service** | One Fargate task, port 42420, public IP for player connections. |
| **EFS** | Persistent storage for world/saves/config; mounted at `/var/vintagestory/data`. |
| **Security groups** | ECS task: 42420 TCP/UDP. EFS: NFS from ECS tasks. |
| **IAM roles** | Task execution (ECR, logs) and task role. |

## Prerequisites

1. **Terraform** >= 1.5 (`terraform version`)
2. **AWS credentials** configured (`aws sts get-caller-identity`)

## Quick start

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed (optional)
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
| `AWS_ROLE_ARN` | Terraform output `github_actions_role_arn` (IAM role for OIDC) |
| `ECS_CLUSTER_NAME` | Terraform output `ecs_cluster_name` (e.g. `vintage-story-cluster`) |
| `ECS_SERVICE_NAME` | Terraform output `ecs_service_name` (e.g. `vintage-story-service`) |
| `ECS_TASK_DEFINITION` | Terraform output `ecs_task_definition_family` (e.g. `vintage-story-task`) |

**Terraform:** Set `github_org` and `github_repo` in `terraform.tfvars` to your GitHub org/user and repo name so the OIDC trust is scoped to that repository.

Then run the **Deploy to AWS** workflow (manual dispatch). It builds the image, pushes to ECR, and deploys to ECS Fargate.

## Connecting to the game

After deploy, the Fargate task gets a public IP. In the AWS ECS console: **Clusters** → your cluster → **Tasks** → select the running task → **Public IP**. Players connect to that IP on port **42420**.

## Optional: custom VPC

In `terraform.tfvars`:

```hcl
use_default_vpc = false
vpc_id          = "vpc-xxxxxxxx"
subnet_ids      = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
```

## Optional: remote state

Uncomment the `backend "s3"` block in `versions.tf`, create the S3 bucket (and optional DynamoDB table for locking), then run `terraform init -migrate-state`.

## Destroying

```bash
terraform destroy
```

This removes the cluster, service, task definition, EFS (and all game data on EFS), ECR repository, and related IAM/security groups.
