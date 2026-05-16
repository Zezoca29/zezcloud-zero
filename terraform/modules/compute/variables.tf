variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier: t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "public_key" {
  description = "SSH public key content for the key pair"
  type        = string
  sensitive   = true
}

variable "public_subnet_id" {
  description = "ID of the public subnet to launch EC2 into"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the EC2 instance"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for EC2"
  type        = string
}

variable "root_volume_size" {
  description = "Size (GB) of the root EBS volume"
  type        = number
  default     = 20
}

variable "app_domain" {
  description = "Application domain name (for Nginx and Cloudflare)"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "zezclouddb"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "zezcloud"
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "docker_compose_content" {
  description = "Rendered docker-compose.yml content to write on the instance"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
