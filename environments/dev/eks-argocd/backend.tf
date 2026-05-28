# ============================================================================
# Backend Configuration
# ============================================================================

terraform {
  backend "s3" {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/dev/eks-argocd/terraform.tfstate"
    region = "ap-southeast-2"
  }
}
