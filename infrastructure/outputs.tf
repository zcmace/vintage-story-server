output "ecr_repository_url" {
  description = "ECR repository URL for the Vintage Story server image"
  value       = aws_ecr_repository.vintage_story_server.repository_url
}

output "ecr_registry" {
  description = "ECR registry host (account.dkr.ecr.region.amazonaws.com)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

output "ec2_instance_id" {
  description = "EC2 instance ID (for SSM deploy)"
  value       = aws_instance.vintage_story.id
}

output "ec2_public_ip" {
  description = "EC2 Elastic IP - connect to game on port 42420 (static, survives instance restart)"
  value       = aws_eip.vintage_story.public_ip
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC. Set as GitHub secret AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}

output "portainer_url" {
  description = "Portainer web UI - manage Docker, restart containers. First visit: create admin user."
  value       = "http://${aws_eip.vintage_story.public_ip}:9000"
}

output "filebrowser_url" {
  description = "FileBrowser web UI - manage game files. Default login: admin / admin - change in Settings!"
  value       = "http://${aws_eip.vintage_story.public_ip}:8080"
}

output "github_secrets_required" {
  description = "GitHub Secrets required for the deploy workflow (OIDC: no access keys)"
  value = [
    "AWS_ROLE_ARN (use github_actions_role_arn output)",
    "EC2_INSTANCE_ID (use ec2_instance_id output)"
  ]
}
