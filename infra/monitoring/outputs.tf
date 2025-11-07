# infra/monitoring/outputs.tf

output "sns_topic_arn" {
  description = "ARN del Tópico SNS para suscribir a un correo electrónico"
  value       = aws_sns_topic.critical_alarms_topic.arn
}