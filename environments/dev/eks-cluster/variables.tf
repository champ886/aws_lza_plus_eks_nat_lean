variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "workload_account_id" {
  description = "AWS account ID for workload account"
  type        = string
}

variable "cluster_admin_arns" {
  description = "List of IAM ARNs for cluster admin access"
  type        = list(string)
  default     = []
}
