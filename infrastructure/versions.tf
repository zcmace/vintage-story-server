terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state (recommended for team use)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "vintage-story-server/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "vintage-story-server"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
