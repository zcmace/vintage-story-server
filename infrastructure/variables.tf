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
  default     = 5
}

# -----------------------------------------------------------------------------
# EC2
# -----------------------------------------------------------------------------
variable "ec2_instance_type" {
  description = "EC2 instance type for the game server"
  type        = string
  default     = "t3.small"
}

variable "ec2_root_volume_gb" {
  description = "Root EBS volume size in GB (game data stored here)"
  type        = number
  default     = 30
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH (use 0.0.0.0/0 to allow all, or your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_key_name" {
  description = "EC2 key pair for SSH/EC2 Instance Connect. Leave null to use Session Manager only (Connect → Session Manager tab)."
  type        = string
  default     = null
}

variable "serial_console_password" {
  description = "Password for ec2-user (Serial Console fallback). Set to enable EC2 Serial Console login when SSM/SSH unavailable."
  type        = string
  default     = null
  sensitive   = true
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
