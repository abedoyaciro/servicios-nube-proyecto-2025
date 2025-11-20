# infra/images-api/outputs.tf

# Exporta el URL base del API Gateway desplegado
output "images_api_gateway_url" {
  description = "URL base del API Gateway para listar imágenes (incluye stage /v1)."
  # CORRECCIÓN: Usar aws_api_gateway_stage.images_stage.invoke_url (el stage ya tiene el URL completo)
  value       = aws_api_gateway_stage.images_stage.invoke_url 
}

# Exporta la API Key (necesaria para consumir el servicio, por requisito de la rúbrica)
output "images_api_key_value" {
  description = "Valor de la API Key requerida para invocar el API de imágenes."
  value       = aws_api_gateway_api_key.nexa_api_key.value
  sensitive   = true
}