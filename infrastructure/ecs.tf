# ECS Fargate: cluster, task definition, service. Game data on EFS.

resource "aws_security_group" "ecs_task" {
  name_prefix = "${var.project_name}-ecs-"
  description = "Vintage Story ECS task - game port 42420"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Vintage Story game TCP"
    from_port   = 42420
    to_port     = 42420
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Vintage Story game UDP"
    from_port   = 42420
    to_port     = 42420
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "FileBrowser web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "ecs_execution" {
  name_prefix = "${var.project_name}-ecs-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name_prefix = "${var.project_name}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_ecs_task_definition" "vintage_story" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu + (var.enable_filebrowser ? 256 : 0)
  memory                   = var.fargate_memory_mb + (var.enable_filebrowser ? 512 : 0)
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode(concat(
    [
      {
        name      = "vintagestory"
        image     = "${aws_ecr_repository.vintage_story_server.repository_url}:latest"
        essential = true

        portMappings = [
          { containerPort = 42420, protocol = "tcp", hostPort = 42420 },
          { containerPort = 42420, protocol = "udp", hostPort = 42420 }
        ]

        environment = [
          { name = "VS_VERSION", value = var.vs_version }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "ecs"
          }
        }

        mountPoints = [
          {
            sourceVolume  = "vintagestory-data"
            containerPath = "/var/vintagestory/data"
            readOnly      = false
          }
        ]
      }
    ],
    var.enable_filebrowser ? [
      {
        name      = "filebrowser"
        image     = "filebrowser/filebrowser:latest"
        essential = false

        portMappings = [
          { containerPort = 8080, protocol = "tcp", hostPort = 8080 }
        ]

        command = ["filebrowser", "--database", "/data/.filebrowser.db", "--root", "/data", "--port", "8080"]

        environment = [
          { name = "PUID", value = "1000" },
          { name = "PGID", value = "1000" }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "filebrowser"
          }
        }

        mountPoints = [
          {
            sourceVolume  = "vintagestory-data"
            containerPath = "/data"
            readOnly      = false
          }
        ]
      }
    ] : []
  ))

  volume {
    name = "vintagestory-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.vintage_story_data.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name             = "/ecs/${var.project_name}"
  retention_in_days = 14
}

resource "aws_ecs_service" "vintage_story" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.vintage_story.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = true
  }
}
