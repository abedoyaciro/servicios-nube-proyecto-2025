# infra/monitoring/main.tf

# ----------------------------------------------------
# 1. TOPICO SNS PARA ALERTAS (Mecanismo de notificación)
# ----------------------------------------------------

resource "aws_sns_topic" "critical_alarms_topic" {
  name = "NexaCloud-Critical-Alarms"
  # Se deja sin cifrado para simplificar, pero en producción se debería cifrar.
}

# 2. Suscripción por Email (Reemplaza con tu correo real)
# Esta suscripción requiere CONFIRMACIÓN MANUAL por el usuario del correo.
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.critical_alarms_topic.arn
  protocol  = "email"
  endpoint  = "abedoyaci@unal.edu.co"
}