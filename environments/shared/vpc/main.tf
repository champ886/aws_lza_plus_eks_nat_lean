# -----------------------------------------------
# SHARED SECURITY VPC
# Deployed once and shared by dev and prod
# Both environments assume role into this account
# for security monitoring and tooling
# -----------------------------------------------
# ── Security VPC — single NAT GW in AZ-a, shared egress for all envs ──────
module "vpc_security" {
  source    = "../../../modules/vpc"
  providers = { aws = aws.security }

  environment          = var.environment
  account_name         = "security"
  vpc_cidr             = var.security_vpc_cidr
  public_subnet_cidrs  = var.security_public_subnet_cidrs
  private_subnet_cidrs = var.security_private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true
}

# -----------------------------------------------
# PUBLIC ROUTE TABLE - PEERING RETURN ROUTES
# NAT gateway sits in the public subnet.
# When dev/prod nodes send traffic:
#   node → peering → security private → NAT → internet
# Return traffic comes back to NAT public IP then:
#   NAT → needs to route 10.0.x.x / 10.2.x.x → peering
# The public route table needs these routes or
# return traffic is dropped and internet fails.
# -----------------------------------------------
data "terraform_remote_state" "peering" {
  backend = "s3"
  config = {
    bucket = "tf-state-landing-zone-champ-001"
    key    = "aws-lza/peering/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

# Dev VPC (10.0.0.0/16) return route on public route table
resource "aws_route" "public_to_dev" {
  provider                  = aws.security
  route_table_id            = module.vpc_security.public_route_table_id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = data.terraform_remote_state.peering.outputs.dev_peering_connection_id
}

# Prod VPC (10.2.0.0/16) return route on public route table
resource "aws_route" "public_to_prod" {
  provider                  = aws.security
  route_table_id            = module.vpc_security.public_route_table_id
  destination_cidr_block    = "10.2.0.0/16"
  vpc_peering_connection_id = data.terraform_remote_state.peering.outputs.prod_peering_connection_id
}
