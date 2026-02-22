variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. prod, staging)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "vintage-story"
}

variable "use_default_vpc" {
  description = "Use default VPC and subnets. Set to false to use vpc_id and subnet_ids."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID (required if use_default_vpc = false)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS tasks (required if use_default_vpc = false)"
  type        = list(string)
  default     = null
}

# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------
variable "ecr_image_retention_count" {
  description = "Number of untagged images to retain in ECR (0 = keep all)"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# ECS Fargate
# -----------------------------------------------------------------------------
variable "fargate_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "fargate_memory_mb" {
  description = "Fargate task memory in MB (512, 1024, 2048, 4096, 8192, 16384)"
  type        = number
  default     = 1024
}

variable "vs_version" {
  description = "Vintage Story server version (env var for container)"
  type        = string
  default     = "1.21.6"
}

# -----------------------------------------------------------------------------
# GitHub OIDC (for Actions to assume role without access keys)
# -----------------------------------------------------------------------------
variable "github_org" {
  description = "GitHub organization or user that owns the repository (e.g. myorg or myuser)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. vintage-story-server). Full repo = github_org/github_repo."
  type        = string
}
