data "terraform_remote_state" "dev_vpc" {
  backend = "s3"
  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/dev/vpc/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

module "eks_cluster" {
  source    = "../../../modules/eks-cluster"
  providers = { aws = aws.workload }

  cluster_name    = "dev-eks-cluster"
  cluster_version = "1.32"
  environment     = "dev"

  vpc_id             = data.terraform_remote_state.dev_vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.dev_vpc.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.dev_vpc.outputs.public_subnet_ids

  workload_account_id = var.workload_account_id
  cluster_admin_arns  = var.cluster_admin_arns
}