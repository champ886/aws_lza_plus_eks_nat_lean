variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "environment" {
  type = string
}

variable "peering_name" {
  type = string
}

variable "requester_vpc_id" {
  type = string
}

variable "requester_vpc_cidr" {
  type = string
}

variable "requester_route_table_az_a_id" {
  type = string
}

variable "requester_route_table_az_b_id" {
  type = string
}

variable "accepter_account_id" {
  type = string
}

variable "accepter_vpc_id" {
  type = string
}

variable "accepter_vpc_cidr" {
  type = string
}

variable "accepter_route_table_az_a_id" {
  type = string
}

variable "accepter_route_table_az_b_id" {
  type = string
}

variable "route_internet_via_accepter" {
  description = "Route 0.0.0.0/0 from requester through accepter NAT GW"
  type        = bool
  default     = false
}