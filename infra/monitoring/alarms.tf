# infra/monitoring/alarms.tf

# ----------------------------------------------------
# A. ALARMAS DE BASE DE DATOS (RDS)
# ----------------------------------------------------

# Alarma 1: Alto uso de CPU en el RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "RDS-Critical-CPU-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutos
  statistic           = "Average"
  threshold           = 80 # Mayor o igual al 80% de CPU
  alarm_description   = "CPU del RDS demasiado alta. Puede indicar cuello de botella."
  
  # Dimensiona la alarma al recurso RDS
  dimensions = {
    DBInstanceIdentifier = data.terraform_remote_state.db_base.outputs.db_instance_id # Usamos el ID del RDS
  }
  
  # Asigna el SNS Topic
  alarm_actions = [aws_sns_topic.critical_alarms_topic.arn]
  ok_actions    = [aws_sns_topic.critical_alarms_topic.arn]
}

# ----------------------------------------------------
# B. ALARMAS DE BALANCEADOR DE CARGA (ALB)
# ----------------------------------------------------

# Alarma 2: Errores HTTP 5xx (Server-Side Errors) en el ALB
resource "aws_cloudwatch_metric_alarm" "alb_http_5xx_errors" {
  alarm_name          = "ALB-5XX-Error-Rate-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60 # 1 minuto
  statistic           = "Sum"
  threshold           = 5 # Si hay más de 5 errores 5xx en 1 minuto
  alarm_description   = "Demasiados errores 5xx del Target Group. Los servidores web estan fallando."
  
  # Dimensiona la alarma al recurso ALB y Target Group
  dimensions = {
    LoadBalancer = data.terraform_remote_state.alb_base.outputs.alb_arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.critical_alarms_topic.arn]
  ok_actions    = [aws_sns_topic.critical_alarms_topic.arn]
}

# ----------------------------------------------------
# C. ALARMAS DE FUNCIONES LAMBDA
# ----------------------------------------------------

# Alarma 3: Errores de invocación de Lambda (Para la función Añadir Estudiante)
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "Lambda-Add-Student-Errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60 # 1 minuto
  statistic           = "Sum"
  threshold           = 1 # Si ocurre al menos 1 error en 1 minuto
  alarm_description   = "Errores en la Lambda 'Anadir Estudiante'."
  
  # Dimensiona la alarma a la función de Lambda
  dimensions = {
    FunctionName = "nexa-anadir-estudiantes" # Nombre de la Lambda definida
  }
  
  alarm_actions = [aws_sns_topic.critical_alarms_topic.arn]
  ok_actions    = [aws_sns_topic.critical_alarms_topic.arn]
}