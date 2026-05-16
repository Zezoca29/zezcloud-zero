variable "project" {
  description = "Project name"
  type        = string
  default     = "zezcloud"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24"]
}

variable "ec2_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_cidrs" {
  description = "CIDRs allowed to SSH to EC2 (your IP /32)"
  type        = list(string)
  sensitive   = true
}

variable "app_domain" {
  description = "Application domain (e.g. dev.yourdomain.com)"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "zezclouddb"
}

variable "db_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "zezcloud"
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "zezcloud-terraform-state-136769278205"
}

variable "state_lock_table_name" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "zezcloud-terraform-lock"
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo in owner/repo format"
  type        = string
}

variable "alert_email" {
  description = "Email for CloudWatch alerts (empty = disabled)"
  type        = string
  default     = ""
}
