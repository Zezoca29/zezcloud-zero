output "db_name_ssm_path" {
  description = "SSM parameter path for database name"
  value       = aws_ssm_parameter.db_name.name
}

output "db_user_ssm_path" {
  description = "SSM parameter path for database user"
  value       = aws_ssm_parameter.db_user.name
}

output "db_password_ssm_path" {
  description = "SSM parameter path for database password (SecureString)"
  value       = aws_ssm_parameter.db_password.name
  sensitive   = true
}

output "db_url_ssm_path" {
  description = "SSM parameter path for JDBC database URL"
  value       = aws_ssm_parameter.db_url.name
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_user" {
  description = "Database user"
  value       = var.db_user
}
