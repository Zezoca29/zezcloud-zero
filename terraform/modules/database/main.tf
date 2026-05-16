################################################################################
# Database Module — PostgreSQL configuration (containerized on EC2)
# No RDS — cost zero strategy. PostgreSQL runs as a Docker container.
# This module manages configuration and SSM parameters only.
################################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Module      = "database"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  })
}

# ─── SSM Parameter Store — DB credentials ─────────────────────────────────────
# Stored securely; EC2 retrieves at runtime via IAM role.

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.project}/${var.environment}/db/name"
  type  = "String"
  value = var.db_name

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/${var.project}/${var.environment}/db/user"
  type  = "String"
  value = var.db_user

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project}/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = local.common_tags

  lifecycle {
    ignore_changes = [value] # Managed externally after first creation
  }
}

resource "aws_ssm_parameter" "db_url" {
  name  = "/${var.project}/${var.environment}/db/url"
  type  = "SecureString"
  value = "jdbc:postgresql://postgres:5432/${var.db_name}"

  tags = local.common_tags
}
