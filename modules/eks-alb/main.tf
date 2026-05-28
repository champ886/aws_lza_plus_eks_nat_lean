# ─────────────────────────────────────────────────────────────────────────
# IAM Policy for the Load Balancer Controller
# ─────────────────────────────────────────────────────────────────────────
resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/alb-controller-policy.json")

  # If policy already exists import it rather than failing
  lifecycle {
    create_before_destroy = true
  }

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
  name        = "${var.cluster_name}-alb-controller-role"
  description = "IAM role for AWS Load Balancer Controller"

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

  # Prevent destroy/recreate on updates - just update in place
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.cluster_name}-alb-controller-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
