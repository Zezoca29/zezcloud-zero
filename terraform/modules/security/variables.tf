variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "cloudflare_ip_ranges" {
  description = "Cloudflare IPv4 ranges — allow HTTP/S only from Cloudflare"
  type        = list(string)
  # Source: https://www.cloudflare.com/ips-v4/
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ]
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to connect via SSH (restrict to your IP)"
  type        = list(string)
  sensitive   = true
}

variable "deploy_bucket_name" {
  description = "S3 bucket name for deployment artifacts"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket name used for Terraform remote state"
  type        = string
}

variable "state_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (created once per AWS account)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g. myuser/zezcloud-zero)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
