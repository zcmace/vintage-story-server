# Use default VPC and subnets, or supplied VPC/subnets.
# Instance must be in a PUBLIC subnet (route to Internet Gateway) for inbound access.

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

# Prefer public subnets (map_public_ip_on_launch) for default VPC - required for SSM over internet
locals {
  subnet_ids = var.use_default_vpc ? data.aws_subnets.selected.ids : var.subnet_ids
  public_subnet_id = try(
    [for s in data.aws_subnet.selected : s.id if s.map_public_ip_on_launch][0],
    local.subnet_ids[0]
  )
}
