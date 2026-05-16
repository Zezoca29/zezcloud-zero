output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "ec2_elastic_ip" {
  description = "EC2 public Elastic IP — point Cloudflare A record here"
  value       = module.compute.elastic_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "github_actions_role_arn" {
  description = "ARN to set as AWS_ROLE_ARN in GitHub Secrets"
  value       = module.security.github_actions_role_arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${module.monitoring.dashboard_name}"
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i <your-key.pem> ec2-user@${module.compute.elastic_ip}"
}
