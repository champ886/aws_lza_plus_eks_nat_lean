variable "cluster_name"             { type = string }
variable "cluster_version"          { type = string; default = "1.30" }
variable "environment"              { type = string }
variable "vpc_id"                   { type = string }
variable "private_subnet_ids"       { type = list(string) }
variable "public_subnet_ids"        { type = list(string) }
variable "private_route_table_ids"  { type = list(string) }
variable "workload_account_id"      { type = string }
variable "cluster_admin_arns"       { type = list(string); default = [] }