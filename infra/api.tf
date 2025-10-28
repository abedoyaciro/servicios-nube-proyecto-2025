# API para la Lambda que lee la base de datos
resource "aws_apigatewayv2_api" "nexa_db_api" {
  name          = "nexa-db-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "nexa_db_integration" {
  api_id           = aws_apigatewayv2_api.nexa_db_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.nexa_db_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "nexa_db_route" {
  api_id    = aws_apigatewayv2_api.nexa_db_api.id
  route_key = "GET /db"
  target    = "integrations/${aws_apigatewayv2_integration.nexa_db_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_db" {
  statement_id  = "AllowExecutionFromAPIGatewayDB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nexa_db_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.nexa_db_api.execution_arn}/*/*"
}

# API para la Lambda que accede al S3
resource "aws_apigatewayv2_api" "nexa_s3_api" {
  name          = "nexa-s3-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "nexa_s3_integration" {
  api_id           = aws_apigatewayv2_api.nexa_s3_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.nexa_s3_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "nexa_s3_route" {
  api_id    = aws_apigatewayv2_api.nexa_s3_api.id
  route_key = "GET /s3"
  target    = "integrations/${aws_apigatewayv2_integration.nexa_s3_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_s3" {
  statement_id  = "AllowExecutionFromAPIGatewayS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nexa_s3_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.nexa_s3_api.execution_arn}/*/*"
}

# Salidas
output "lambda_db_api_endpoint" {
  value = aws_apigatewayv2_api.nexa_db_api.api_endpoint
}

output "lambda_s3_api_endpoint" {
  value = aws_apigatewayv2_api.nexa_s3_api.api_endpoint
}
