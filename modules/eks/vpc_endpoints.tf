data "aws_region" "current" {}

resource "aws_vpc_endpoint" "interface" {
  for_each = {
    ecr_api = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
    ecr_dkr = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
    sts     = "com.amazonaws.${data.aws_region.current.name}.sts"
    logs    = "com.amazonaws.${data.aws_region.current.name}.logs"
    ec2     = "com.amazonaws.${data.aws_region.current.name}.ec2"
  }
  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.nodes.id]
  private_dns_enabled = true
  tags = { Name = "${var.environment}-${each.key}-ep", ManagedBy = "Terraform" }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids
  tags              = { Name = "${var.environment}-s3-ep" }
}