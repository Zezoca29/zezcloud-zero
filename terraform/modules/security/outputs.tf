output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "ec2_security_group_arn" {
  description = "ARN of the EC2 security group"
  value       = aws_security_group.ec2.arn
}

output "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 IAM instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role (use as AWS_ROLE_ARN secret)"
  value       = aws_iam_role.github_actions.arn
}
