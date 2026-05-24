# ============================================================================
# EKS ADD-ONS MODULE - Managed add-ons only
# ============================================================================

# ─────────────────────────────────────────────────────────────────────────
# VPC CNI Add-on
# ─────────────────────────────────────────────────────────────────────────
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_version_vpc_cni
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = {
    Name        = "${var.cluster_name}-vpc-cni"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# CoreDNS Add-on
# ─────────────────────────────────────────────────────────────────────────
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.addon_version_coredns
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_addon.vpc_cni]

  tags = {
    Name        = "${var.cluster_name}-coredns"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# kube-proxy Add-on
# ─────────────────────────────────────────────────────────────────────────
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_version_kube_proxy
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = {
    Name        = "${var.cluster_name}-kube-proxy"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# Pod Identity Agent Add-on
# ─────────────────────────────────────────────────────────────────────────
resource "aws_eks_addon" "pod_identity" {
  count = var.enable_pod_identity ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = {
    Name        = "${var.cluster_name}-pod-identity-agent"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}