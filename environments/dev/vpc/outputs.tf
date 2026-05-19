output "vpc_id" {
  value = module.vpc_dev.vpc_id
}

output "vpc_cidr" {
  value = module.vpc_dev.vpc_cidr
}

output "private_subnet_ids" {
  value = module.vpc_dev.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.vpc_dev.public_subnet_ids
}

output "private_route_table_ids" {
  value = module.vpc_dev.private_route_table_ids
}