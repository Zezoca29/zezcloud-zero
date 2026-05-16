variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | prod)"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications (leave empty to disable)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
