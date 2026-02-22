# Use default VPC and subnets, or supplied VPC/subnets.

data "aws_vpc" "selected" {
  id = var.use_default_vpc ? data.aws_vpc.default[0].id : var.vpc_id
}

data "aws_vpc" "default" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.selected.ids)
  id       = each.value
}

locals {
  subnet_ids = var.use_default_vpc ? data.aws_subnets.selected.ids : var.subnet_ids
}
