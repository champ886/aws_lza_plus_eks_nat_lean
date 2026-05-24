# ============================================================================
# EKS Cluster Outputs
# ============================================================================
# These match the actual outputs from modules/eks/outputs.tf

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca" {
  description = "Certificate authority data for the cluster"
  value       = module.eks.cluster_ca
  sensitive   = true
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.eks.node_role_arn
}

output "node_sg_id" {
  description = "Security group ID for EKS nodes"
  value       = module.eks.node_sg_id
}

output "alb_sg_id" {
  description = "Security group ID for Application Load Balancer"
  value       = module.eks.alb_sg_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA (IAM Roles for Service Accounts)"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster (without https://)"
  value       = module.eks.cluster_oidc_issuer_url
}