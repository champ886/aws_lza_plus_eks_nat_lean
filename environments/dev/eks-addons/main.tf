# ============================================================================
# Dev Environment - EKS Add-ons
# ============================================================================

data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/dev/eks-cluster/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

module "eks_addons" {
  source    = "../../../modules/eks-addons"
  providers = { aws = aws.workload }

  cluster_name = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  environment  = var.environment

  # Optional: Override default versions
  # addon_version_vpc_cni    = "v1.18.1-eksbuild.1"
  # addon_version_coredns    = "v1.11.1-eksbuild.5"
  # addon_version_kube_proxy = "v1.29.1-eksbuild.2"

  # Optional: Disable specific add-ons
  # enable_pod_identity = false
}