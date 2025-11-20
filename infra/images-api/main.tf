# infra/images-api/main.tf

# ----------------------------------------------------
# 1. REFERENCIA A RECURSOS DE INFRAESTRUCTURA (INPUTS)
# ----------------------------------------------------

# Obtener el nombre del Bucket de imágenes
data "terraform_remote_state" "core_network" {
  backend = "s3"
  config = {
    bucket = "nexa-cloud-tf-state-192626564201" # ⚠️ REEMPLAZA CON TU BUCKET REAL
    key    = "network-base.tfstate"
    region = "us-east-1"
  }
}

# Obtener el ARN del Rol de ejecución preexistente para la Lambda (labrole)
data "aws_iam_role" "lab_lambda_role" {
  name = "labrole" 
}

locals {
  images_bucket_name = data.terraform_remote_state.core_network.outputs.nexa_images_bucket_name
}

# ----------------------------------------------------
# 2. FUNCIÓN LAMBDA
# ----------------------------------------------------

# Empaquetar el código de Python de la Lambda en un archivo ZIP
data "archive_file" "images_lambda_zip" {
  type        = "zip"
  source_file = "list_images.py"
  output_path = "list_images.zip"
}

# El recurso de la función Lambda
resource "aws_lambda_function" "get_images_lambda" {
  filename         = data.archive_file.images_lambda_zip.output_path
  function_name    = "nexa-get-images-lambda"
  # Usamos el ARN del rol preexistente
  role             = data.aws_iam_role.lab_lambda_role.arn
  handler          = "list_images.lambda_handler" # Archivo.función
  runtime          = "python3.11"
  source_code_hash = data.archive_file.images_lambda_zip.output_base64sha256
  timeout          = 30 
  
  environment {
    variables = {
      S3_BUCKET_NAME = local.images_bucket_name
      # ¡IMPORTANTE! Eliminamos AWS_REGION ya que es una clave reservada.
    }
  }
}

# ----------------------------------------------------
# 3. API GATEWAY (REST API)
# ----------------------------------------------------

# Crear la REST API
resource "aws_api_gateway_rest_api" "images_api" {
  name        = "NexaCloudImagesAPI"
  description = "API Gateway para obtener la lista de imágenes de empleados."
}

# Crear un recurso (path) bajo el API Gateway: /images
resource "aws_api_gateway_resource" "images_resource" {
  rest_api_id = aws_api_gateway_rest_api.images_api.id
  parent_id   = aws_api_gateway_rest_api.images_api.root_resource_id
  path_part   = "images"
}

# Método GET para el recurso /images
resource "aws_api_gateway_method" "images_method_get" {
  rest_api_id      = aws_api_gateway_rest_api.images_api.id
  resource_id      = aws_api_gateway_resource.images_resource.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

# Integración con la Lambda
resource "aws_api_gateway_integration" "images_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.images_api.id
  resource_id             = aws_api_gateway_resource.images_resource.id
  http_method             = aws_api_gateway_method.images_method_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_images_lambda.invoke_arn
}

# Permiso para que API Gateway pueda invocar la Lambda
resource "aws_lambda_permission" "apigw_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_images_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.images_api.execution_arn}/*/*"
}

# Despliegue de la API (sin stage)
resource "aws_api_gateway_deployment" "images_deployment" {
  depends_on = [
    aws_api_gateway_integration.images_lambda_integration,
    aws_api_gateway_method.images_method_get
  ]
  rest_api_id = aws_api_gateway_rest_api.images_api.id
}

# Stage de la API (Recurso separado - ¡Mejor práctica!)
resource "aws_api_gateway_stage" "images_stage" {
  depends_on    = [aws_api_gateway_deployment.images_deployment]
  deployment_id = aws_api_gateway_deployment.images_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.images_api.id
  stage_name    = "v1"
}


# ----------------------------------------------------
# 4. API KEY
# ----------------------------------------------------

# Creación de la API Key
resource "aws_api_gateway_api_key" "nexa_api_key" {
  name  = "NexaCloudImagesKey"
  value = "NexaCloud-Super-Secret-Key-2025"
}

# Creación del Plan de Uso (Usage Plan)
resource "aws_api_gateway_usage_plan" "images_usage_plan" {
  name        = "NexaImagesUsagePlan"
  description = "Plan de uso para la API de imágenes."

  api_stages {
    api_id = aws_api_gateway_rest_api.images_api.id
    stage  = aws_api_gateway_stage.images_stage.stage_name
  }
}

# Asociar la API Key al Plan de Uso
resource "aws_api_gateway_usage_plan_key" "images_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.nexa_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.images_usage_plan.id
}