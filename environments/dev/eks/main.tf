# Read the existing dev VPC state from S3 so we can reference its outputs
# (vpc_id, subnet IDs) without re-creating or coupling the two stacks.
data "terraform_remote_state" "dev_vpc" {
  backend = "s3"

  config = {
    bucket = "tf-state-landing-zone-champ-001"       # shared state bucket
    key    = "aws-lza/dev/vpc/terraform.tfstate"     # path to the dev VPC state file
    region = "ap-southeast-2"
  }
}

# ── Add a single NAT Gateway to the VPC (AZ-a only, keeps costs low) ──────
module "vpc_nat" {
  source    = "../../../modules/vpc"
  providers = { aws = aws.workload }

  environment          = var.environment
  account_name         = "workload"
  vpc_cidr             = var.workload_vpc_cidr
  public_subnet_cidrs  = var.workload_public_subnet_cidrs
  private_subnet_cidrs = var.workload_private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true
}


# ── Deploy EKS cluster into the existing dev VPC ───────────────────────────
module "eks" {
  source    = "../../../modules/eks"
  providers = { aws = aws.workload }

  cluster_name    = "dev-eks"
  cluster_version = "1.30"
  environment     = var.environment
  vpc_id             = data.terraform_remote_state.dev_vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.dev_vpc.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.dev_vpc.outputs.public_subnet_ids

  # Needed to attach VPC gateway endpoints to the right route tables
  private_route_table_ids = module.vpc_nat.private_route_table_ids

  workload_account_id = var.workload_account_id
  cluster_admin_arns  = var.cluster_admin_arns
}