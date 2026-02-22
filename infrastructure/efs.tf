# EFS for persistent game data (world, saves, config) for ECS Fargate tasks.

resource "aws_efs_file_system" "vintage_story_data" {
  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "vintage_story_data" {
  for_each = toset(local.subnet_ids)

  file_system_id  = aws_efs_file_system.vintage_story_data.id
  subnet_id       = each.value
  security_groups = [aws_security_group.ecs_efs.id]
}

resource "aws_security_group" "ecs_efs" {
  name_prefix = "${var.project_name}-efs-"
  description = "Allow ECS tasks to mount EFS"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "NFS from ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
