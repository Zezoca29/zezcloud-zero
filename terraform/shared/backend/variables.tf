variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state (must be globally unique)"
  type        = string
  default     = "zezcloud-terraform-state"
}

variable "state_lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "zezcloud-terraform-lock"
}
