output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "elastic_ip" {
  description = "Public Elastic IP address"
  value       = aws_eip.main.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.main.key_name
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux.id
}
