output "security_vpc_id" {
  value = module.vpc_security.vpc_id
}

output "security_vpc_cidr" {
  value = module.vpc_security.vpc_cidr
}

output "security_private_subnet_ids" {
  value = module.vpc_security.private_subnet_ids
}

output "security_private_route_table_ids" {
  value = module.vpc_security.private_route_table_ids
}

output "security_nat_gateway_id" {
  value = module.vpc_security.nat_gateway_id
}