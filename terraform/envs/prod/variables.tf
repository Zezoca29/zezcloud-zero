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
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24"]
}

variable "ec2_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_allowed_cidrs" {
  type      = list(string)
  sensitive = true
}

variable "app_domain" {
  type = string
}

variable "db_name" {
  type    = string
  default = "zezclouddb"
}

variable "db_user" {
  type      = string
  default   = "zezcloud"
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "state_bucket_name" {
  type    = string
  default = "zezcloud-terraform-state"
}

variable "state_lock_table_name" {
  type    = string
  default = "zezcloud-terraform-lock"
}

variable "github_oidc_provider_arn" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "alert_email" {
  description = "Email for prod CloudWatch alerts (strongly recommended)"
  type        = string
  default     = ""
}
