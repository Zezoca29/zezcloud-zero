output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cpu_alarm_arn" {
  description = "ARN of the CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "status_alarm_arn" {
  description = "ARN of the status check alarm"
  value       = aws_cloudwatch_metric_alarm.status_check.arn
}
