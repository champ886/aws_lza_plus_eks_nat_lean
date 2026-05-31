# ============================================================================
# TRANSIT GATEWAY MODULE
# Hub-and-spoke architecture for centralised egress via Security VPC
# All workload VPCs route internet traffic through Security VPC NAT Gateway
# ============================================================================

# ─────────────────────────────────────────────────────────────────────────
# Transit Gateway
# Lives in the Security account - the hub of the network
# ─────────────────────────────────────────────────────────────────────────
resource "aws_ec2_transit_gateway" "main" {
  provider = aws.security

  description                     = "Shared Transit Gateway - centralised egress hub"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "enable"   # Auto-accept cross-account attachments
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name        = "${var.environment}-tgw"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# Share TGW with workload accounts via Resource Access Manager
# Allows Dev and Prod accounts to attach their VPCs
# ─────────────────────────────────────────────────────────────────────────
resource "aws_ram_resource_share" "tgw" {
  provider = aws.security

  name                      = "${var.environment}-tgw-share"
  allow_external_principals = false # Only share within AWS Organization

  tags = {
    Name        = "${var.environment}-tgw-share"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_ram_resource_association" "tgw" {
  provider = aws.security

  resource_arn       = aws_ec2_transit_gateway.main.arn
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

# Share with Dev account
resource "aws_ram_principal_association" "dev" {
  provider = aws.security

  principal          = var.dev_account_id
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

# Share with Prod account
resource "aws_ram_principal_association" "prod" {
  provider = aws.security

  principal          = var.prod_account_id
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

# ─────────────────────────────────────────────────────────────────────────
# TGW Attachment - Security VPC (the hub)
# Attaches to private subnets - NAT gateway handles internet egress
# ─────────────────────────────────────────────────────────────────────────
resource "aws_ec2_transit_gateway_vpc_attachment" "security" {
  provider = aws.security

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.security_vpc_id
  subnet_ids         = var.security_private_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name        = "${var.environment}-tgw-security-attachment"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# TGW Attachment - Dev VPC (spoke)
# Cross-account attachment - accepted automatically via RAM sharing
# ─────────────────────────────────────────────────────────────────────────
resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  provider = aws.dev

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.dev_vpc_id
  subnet_ids         = var.dev_private_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name        = "${var.environment}-tgw-dev-attachment"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_ram_principal_association.dev,
    aws_ram_resource_association.tgw,
  ]
}

# ─────────────────────────────────────────────────────────────────────────
# TGW Attachment - Prod VPC (spoke)
# ─────────────────────────────────────────────────────────────────────────
resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  provider = aws.prod

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.prod_vpc_id
  subnet_ids         = var.prod_private_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name        = "${var.environment}-tgw-prod-attachment"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_ram_principal_association.prod,
    aws_ram_resource_association.tgw,
  ]
}

# ─────────────────────────────────────────────────────────────────────────
# TGW Route Table - Default route to Security VPC
# All traffic from spokes (dev/prod) defaults to Security VPC
# Security VPC then routes to NAT Gateway for internet egress
# ─────────────────────────────────────────────────────────────────────────
resource "aws_ec2_transit_gateway_route" "default_to_security" {
  provider = aws.security

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.main.association_default_route_table_id
}

# ─────────────────────────────────────────────────────────────────────────
# Dev VPC Routes - Send internet traffic via TGW
# Replaces the old peering-based internet route
# ─────────────────────────────────────────────────────────────────────────
resource "aws_route" "dev_internet_via_tgw_az_a" {
  provider = aws.dev

  route_table_id         = var.dev_private_route_table_az_a_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.dev]
}

resource "aws_route" "dev_internet_via_tgw_az_b" {
  provider = aws.dev

  route_table_id         = var.dev_private_route_table_az_b_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.dev]
}

# ─────────────────────────────────────────────────────────────────────────
# Prod VPC Routes - Send internet traffic via TGW
# ─────────────────────────────────────────────────────────────────────────
resource "aws_route" "prod_internet_via_tgw_az_a" {
  provider = aws.prod

  route_table_id         = var.prod_private_route_table_az_a_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.prod]
}

resource "aws_route" "prod_internet_via_tgw_az_b" {
  provider = aws.prod

  route_table_id         = var.prod_private_route_table_az_b_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.prod]
}

# ─────────────────────────────────────────────────────────────────────────
# Security VPC Routes - Route spoke traffic to NAT Gateway
# When traffic arrives from TGW (from dev/prod), route to NAT for egress
# ─────────────────────────────────────────────────────────────────────────

# Security private subnets - route dev/prod CIDRs back via TGW
resource "aws_route" "security_to_dev_via_tgw_az_a" {
  provider = aws.security

  route_table_id         = var.security_private_route_table_az_a_id
  destination_cidr_block = var.dev_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.security]
}

resource "aws_route" "security_to_dev_via_tgw_az_b" {
  provider = aws.security

  route_table_id         = var.security_private_route_table_az_b_id
  destination_cidr_block = var.dev_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.security]
}

resource "aws_route" "security_to_prod_via_tgw_az_a" {
  provider = aws.security

  route_table_id         = var.security_private_route_table_az_a_id
  destination_cidr_block = var.prod_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.security]
}

resource "aws_route" "security_to_prod_via_tgw_az_b" {
  provider = aws.security

  route_table_id         = var.security_private_route_table_az_b_id
  destination_cidr_block = var.prod_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.security]
}

# Security PUBLIC route table - return traffic from NAT back to spokes
resource "aws_route" "security_public_to_dev" {
  provider = aws.security

  route_table_id         = var.security_public_route_table_id
  destination_cidr_block = var.dev_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.security]
}

resource "aws_route" "security_public_to_prod" {
  provider = aws.security

  route_table_id         = var.security_public_route_table_id
  destination_cidr_block = var.prod_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.security]
}
