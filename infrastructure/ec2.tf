# EC2 instance with Docker. Game data on EBS. Portainer + FileBrowser for web UI.

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-"
  description = "Vintage Story EC2 - game, Portainer, FileBrowser"
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
    description = "Portainer web UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Portainer HTTPS"
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "FileBrowser web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (optional)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
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

resource "aws_iam_role" "ec2" {
  name_prefix = "${var.project_name}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ec2_ecr" {
  name_prefix = "ecr-"
  role        = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = aws_ecr_repository.vintage_story_server.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.project_name}-"
  role        = aws_iam_role.ec2.name
}

resource "aws_instance" "vintage_story" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = local.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.ec2_root_volume_gb
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    ecr_registry       = split("/", aws_ecr_repository.vintage_story_server.repository_url)[0]
    ecr_repository_url = aws_ecr_repository.vintage_story_server.repository_url
    vs_version        = var.vs_version
  })

  tags = {
    Name = "${var.project_name}-server"
  }
}
