# ============================================================================
# Provider Configuration
# ============================================================================

provider "aws" {
  alias  = "workload"
  region = var.aws_region

  # Assumes the OrganizationAccountAccessRole in the dev workload account
  # This is how Terraform authenticates into account 435321828725
  # Without this, Terraform uses your default credentials (management account)
  # and can't find the EKS cluster which lives in the workload account
  assume_role {
    role_arn = "arn:aws:iam::${var.workload_account_id}:role/OrganizationAccountAccessRole"
  }
}
