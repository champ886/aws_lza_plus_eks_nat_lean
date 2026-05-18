# ── Stored in management account state — run once locally ─────────────────
terraform {
  backend "s3" {
    bucket         = "tf-state-landing-zone-champ-001"
    key            = "aws-lza/management/github-oidc/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}