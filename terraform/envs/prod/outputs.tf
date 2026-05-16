output "vpc_id" {
  value = module.networking.vpc_id
}

output "ec2_elastic_ip" {
  description = "Production Elastic IP — point Cloudflare A record here"
  value       = module.compute.elastic_ip
}

output "ec2_instance_id" {
  value = module.compute.instance_id
}

output "github_actions_role_arn" {
  description = "ARN to set as AWS_ROLE_ARN in GitHub Secrets"
  value       = module.security.github_actions_role_arn
}

output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${module.monitoring.dashboard_name}"
}

output "ssh_command" {
  value = "ssh -i <your-key.pem> ec2-user@${module.compute.elastic_ip}"
}
