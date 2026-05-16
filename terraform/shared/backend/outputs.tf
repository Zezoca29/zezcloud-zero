output "state_bucket_name" {
  description = "S3 bucket name — use in envs/*/main.tf backend config"
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name — use in envs/*/main.tf backend config"
  value       = aws_dynamodb_table.lock.name
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN — use in security module and GitHub Secrets"
  value       = aws_iam_openid_connect_provider.github.arn
}
