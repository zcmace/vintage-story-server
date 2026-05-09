resource "aws_s3_bucket" "downloads" {
  bucket_prefix = "${var.project_name}-downloads-"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-downloads"
  }
}

resource "aws_s3_bucket_public_access_block" "downloads" {
  bucket = aws_s3_bucket.downloads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "downloads" {
  bucket = aws_s3_bucket.downloads.id

  rule {
    id     = "expire-downloads"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }
  }
}

resource "aws_ssm_parameter" "downloads_bucket" {
  name  = "/${var.project_name}/downloads-bucket"
  type  = "String"
  value = aws_s3_bucket.downloads.bucket
}

resource "aws_iam_role_policy" "ec2_s3_upload" {
  name_prefix = "s3-upload-"
  role        = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.downloads.arn}/*"
      }
    ]
  })
}
