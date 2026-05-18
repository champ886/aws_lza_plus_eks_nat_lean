output "nat_gateway_id" {
  description = "NAT Gateway ID (null if not enabled)"
  value       = length(aws_nat_gateway.main) > 0 ? aws_nat_gateway.main[0].id : null
}

output "private_route_table_ids" {
  description = "Per-AZ private route table IDs"
  value       = aws_route_table.private[*].id
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}