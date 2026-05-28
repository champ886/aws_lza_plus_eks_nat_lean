variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "pgadmin_email" {
  description = "pgAdmin login email"
  type        = string
  sensitive   = true
}

variable "pgadmin_password" {
  description = "pgAdmin login password"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  type = string
}