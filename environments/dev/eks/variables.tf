# ============================================================================
# Common Variables
# ============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "workload_account_id" {
  description = "AWS account ID for the workload account"
  type        = string
}

# ============================================================================
# VPC Variables
# ============================================================================

variable "workload_vpc_cidr" {
  description = "CIDR block for the workload VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "workload_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "workload_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnet distribution"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

# ============================================================================
# EKS Variables
# ============================================================================

variable "cluster_admin_arns" {
  description = "List of IAM ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}