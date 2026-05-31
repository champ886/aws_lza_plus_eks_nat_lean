# ============================================================================
# Data Sources - Remote State
# ============================================================================

data "terraform_remote_state" "shared_vpc" {
  backend = "s3"
  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/shared/vpc/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

data "terraform_remote_state" "dev_vpc" {
  backend = "s3"
  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/dev/vpc/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

data "terraform_remote_state" "prod_vpc" {
  backend = "s3"
  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/prod/vpc/terraform.tfstate"
    region = "ap-southeast-2"
  }
}
