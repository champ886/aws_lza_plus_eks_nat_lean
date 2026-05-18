# ── NACL on private subnets — allow 443 out + security VPC, deny all else ─
resource "aws_network_acl" "private_eks" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.environment}-private-eks-nacl" }
}

resource "aws_network_acl_rule" "e_https" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow all egress to security VPC (peering path for NAT GW)
resource "aws_network_acl_rule" "e_security_vpc" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 105
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.1.0.0/16"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "e_eph_vpc" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "e_deny" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 32766
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "i_https" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "i_eph" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "i_vpc" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 120
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 0
  to_port        = 0
}

# Allow return traffic from security VPC
resource "aws_network_acl_rule" "i_security_vpc" {
  network_acl_id = aws_network_acl.private_eks.id
  rule_number    = 130
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.1.0.0/16"
  from_port      = 0
  to_port        = 0
}