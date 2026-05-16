resource "aws_security_group" "cluster" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "EKS control plane"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.environment}-eks-cluster-sg" }
}

resource "aws_security_group" "nodes" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "EKS worker nodes"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.environment}-eks-nodes-sg" }
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-eks-alb-sg"
  description = "Internet-facing ALB"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.environment}-eks-alb-sg" }
}

# Nodes → HTTPS only egress (NAT GW path for public registries)
resource "aws_security_group_rule" "nodes_egress_https" {
  type = "egress"; from_port = 443; to_port = 443; protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]; security_group_id = aws_security_group.nodes.id
}

# Nodes → full intra-VPC (kubelet, CNI, pod-to-pod)
resource "aws_security_group_rule" "nodes_egress_vpc" {
  type = "egress"; from_port = 0; to_port = 65535; protocol = "-1"
  cidr_blocks = ["10.0.0.0/16"]; security_group_id = aws_security_group.nodes.id
}

# Control plane → nodes
resource "aws_security_group_rule" "cluster_to_nodes" {
  type = "ingress"; from_port = 0; to_port = 65535; protocol = "-1"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.nodes.id
}

# Nodes → cluster API
resource "aws_security_group_rule" "nodes_to_cluster" {
  type = "ingress"; from_port = 443; to_port = 443; protocol = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
}

# ALB ingress from internet
resource "aws_security_group_rule" "alb_ingress_http" {
  type = "ingress"; from_port = 80; to_port = 80; protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]; security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type = "ingress"; from_port = 443; to_port = 443; protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]; security_group_id = aws_security_group.alb.id
}

# ALB → nodes only
resource "aws_security_group_rule" "alb_to_nodes" {
  type = "egress"; from_port = 0; to_port = 65535; protocol = "-1"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.alb.id
}

resource "aws_security_group_rule" "nodes_ingress_alb" {
  type = "ingress"; from_port = 30000; to_port = 32767; protocol = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.nodes.id
}