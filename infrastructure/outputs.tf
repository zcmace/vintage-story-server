output "ecr_repository_url" {
  description = "ECR repository URL for the Vintage Story server image"
  value       = aws_ecr_repository.vintage_story_server.repository_url
}

output "ecr_registry" {
  description = "ECR registry host (account.dkr.ecr.region.amazonaws.com)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

output "ecs_cluster_name" {
  description = "ECS cluster name (for GitHub Actions deploy)"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name (for GitHub Actions deploy)"
  value       = aws_ecs_service.vintage_story.name
}

output "ecs_task_definition_family" {
  description = "ECS task definition family (for GitHub Actions deploy)"
  value       = aws_ecs_task_definition.vintage_story.family
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC. Set as GitHub secret AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}

output "github_secrets_required" {
  description = "GitHub Secrets required for the deploy workflow (OIDC: no access keys)"
  value = [
    "AWS_ROLE_ARN (use github_actions_role_arn output)",
    "ECS_CLUSTER_NAME (use ecs_cluster_name output)",
    "ECS_SERVICE_NAME (use ecs_service_name output)",
    "ECS_TASK_DEFINITION (use ecs_task_definition_family output)"
  ]
}
