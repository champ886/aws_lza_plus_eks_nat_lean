# ── CLUSTER IAM ROLE ─────────────────────────────────────────────────────
resource "aws_iam_role" "cluster" {
  name = "${var.environment}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole" }]
  })
  tags = { Environment = var.environment, ManagedBy = "Terraform" }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── EKS CLUSTER ──────────────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]   # lock to corp CIDR in prod
    security_group_ids      = [aws_security_group.cluster.id]
  }

  # Enable OIDC — required for IRSA (all add-ons depend on this)
  tags       = { Environment = var.environment, ManagedBy = "Terraform" }
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# ── OIDC PROVIDER — enables IRSA for all add-ons ────────────────────────
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  tags            = { Environment = var.environment, ManagedBy = "Terraform" }
}

# ── NODE IAM ROLE ────────────────────────────────────────────────────────
resource "aws_iam_role" "node" {
  name = "${var.environment}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole" }]
  })
  tags = { Environment = var.environment, ManagedBy = "Terraform" }
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# ── SYSTEM NODE GROUP (on-demand, min 2) ─────────────────────────────────
# Hosts: CoreDNS, kube-proxy, VPC CNI, Karpenter controller, ArgoCD
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["m6i.large"]
  capacity_type   = "ON_DEMAND"

  scaling_config { desired_size = 2; min_size = 2; max_size = 4 }
  update_config  { max_unavailable = 1 }

  labels = { role = "system" }
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  # Subnet tags required by ALB controller
  tags = {
    Environment                                = var.environment
    ManagedBy                                  = "Terraform"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}

# ── EKS MANAGED ADD-ONS (AWS recommended — not Helm) ────────────────────
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
  tags = { Environment = var.environment }
}

resource "aws_eks_addon" "coredns" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on               = [aws_eks_node_group.system]
  tags = { Environment = var.environment }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
  tags = { Environment = var.environment }
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"
  resolve_conflicts_on_update = "OVERWRITE"
  tags = { Environment = var.environment }
}