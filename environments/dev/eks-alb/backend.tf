# ============================================================================
# Backend Configuration - with state locking
# ============================================================================

terraform {
  backend "s3" {
    bucket       = "tf-state-landing-zone-champ-001"
    key          = "aws-lza/dev/eks-alb/terraform.tfstate"
    region       = "ap-southeast-2"

    # Prevents two runs writing state at the same time
    # If a run fails mid-way, lock is released automatically
    use_lockfile = true
  }
}
