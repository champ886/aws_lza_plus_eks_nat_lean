# ============================================================================
# AWS LOAD BALANCER CONTROLLER MODULE
# ============================================================================

# ─────────────────────────────────────────────────────────────────────────
# IAM Policy for the Load Balancer Controller
# ─────────────────────────────────────────────────────────────────────────
resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/alb-controller-policy.json")

  tags = {
    Name        = "${var.cluster_name}-alb-controller-policy"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# IAM Role for the Load Balancer Controller (IRSA)
# ─────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.cluster_name}-alb-controller-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

# ─────────────────────────────────────────────────────────────────────────
# Helm Release - AWS Load Balancer Controller
# Uses ap-southeast-2 regional ECR mirror instead of public.ecr.aws
# public.ecr.aws is NOT reachable from private subnets without extra config
# 602401143452.dkr.ecr.<region>.amazonaws.com IS reachable via ECR VPC endpoint
# ─────────────────────────────────────────────────────────────────────────
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  # Override image to use regional ECR (reachable via VPC endpoint)
  # instead of public.ecr.aws (not reachable from private subnets)
  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [aws_iam_role_policy_attachment.alb_controller]
}

# ─────────────────────────────────────────────────────────────────────────
# Tag subnets for ALB discovery
# ─────────────────────────────────────────────────────────────────────────

# Public subnets → internet-facing ALB
resource "aws_ec2_tag" "public_subnet_alb" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# Private subnets → internal ALB (future use)
resource "aws_ec2_tag" "private_subnet_alb" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

# Cluster ownership tag so controller knows which subnets belong to it
resource "aws_ec2_tag" "public_subnet_cluster" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}
