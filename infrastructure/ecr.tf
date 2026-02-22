# ECR repository for the Vintage Story server Docker image.
# GitHub Actions builds and pushes here; ECS Fargate pulls from here on deploy.

resource "aws_ecr_repository" "vintage_story_server" {
  name                 = "vintage-story-server"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "vintage_story_server" {
  count      = var.ecr_image_retention_count > 0 ? 1 : 0
  repository = aws_ecr_repository.vintage_story_server.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_image_retention_count} untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
