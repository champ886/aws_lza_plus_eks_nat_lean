# ============================================================================
# EKS Add-Ons Data Sources
# ============================================================================

data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/dev/eks-cluster/terraform.tfstate"
    region = "ap-southeast-2"
  }
}