# ============================================================================
# EKS CLUSTER DEPLOYMENT
# ============================================================================
# Deploys EKS cluster into the EXISTING dev VPC (already created separately)
# ============================================================================

# ────────────────────────────────────────────────────────────────────────────
# Read existing dev VPC state to get VPC ID and subnet IDs
# ────────────────────────────────────────────────────────────────────────────
data "terraform_remote_state" "dev_vpc" {
  backend = "s3"

  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/dev/vpc/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

# ────────────────────────────────────────────────────────────────────────────
# Deploy EKS cluster into the existing VPC
# ────────────────────────────────────────────────────────────────────────────
module "eks" {
  source    = "../../../modules/eks"
  providers = { aws = aws.workload }

  # Cluster configuration
  cluster_name    = "dev-eks-cluster"
  cluster_version = "1.32"  # Updated to latest stable version
  environment     = var.environment

  # Use VPC and subnets from the existing dev VPC
  vpc_id             = data.terraform_remote_state.dev_vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.dev_vpc.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.dev_vpc.outputs.public_subnet_ids

  # Route tables for VPC endpoints
  private_route_table_ids = data.terraform_remote_state.dev_vpc.outputs.private_route_table_ids

  # IAM and access control
  workload_account_id = var.workload_account_id
  cluster_admin_arns  = var.cluster_admin_arns
}