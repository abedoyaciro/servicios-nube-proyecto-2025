# ----------------------------------------------------
# 1. IMPORTAR EL ESTADO EXISTENTE (VPC, RDS, S3)
# ----------------------------------------------------
data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "./terraform.tfstate"
  }
}

# ----------------------------------------------------
# 2. USAR UN ROL IAM EXISTENTE (Learner Lab)
# ----------------------------------------------------
# Reemplaza "LabRole" con el nombre de tu rol permitido si difiere.
# Puedes listar los roles disponibles con:
#   aws iam list-roles --query "Roles[].RoleName"
data "aws_iam_role" "existing_lambda_role" {
  name = "LabRole"
}

# ----------------------------------------------------
# 3. ADJUNTAR POLÍTICAS (si está permitido)
# ----------------------------------------------------
# 


# ----------------------------------------------------
# 4. GRUPO DE SEGURIDAD PARA LAMBDAS
# ----------------------------------------------------
resource "aws_security_group" "nexa_lambda_sg" {
  name        = "nexa-lambda-sg"
  description = "Permite que las Lambdas se comuniquen con el RDS y S3"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc_id

  ingress {
    from_port   = 9876
    to_port     = 9876
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nexa-lambda-sg"
  }
}

# ----------------------------------------------------
# 5. LAMBDA PARA RDS
# ----------------------------------------------------
resource "aws_lambda_function" "nexa_db_lambda" {
  function_name = "nexa-db-lambda"
  role          = data.aws_iam_role.existing_lambda_role.arn
  handler       = "lambda_function_db.lambda_handler"
  runtime       = "python3.9"
  timeout       = 10

  filename         = "${path.module}/lambda_db.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_db.zip")

  environment {
  variables = {
    DB_HOST     = data.terraform_remote_state.infra.outputs.rds_endpoint
    DB_PORT     = "9876"
    DB_USER     = "nexa_admin"
    DB_PASSWORD = "NexaPass123!"
    DB_NAME     = "nexacloud"
  }
}


  vpc_config {
    subnet_ids         = data.terraform_remote_state.infra.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.nexa_lambda_sg.id]
  }

  depends_on = [
    aws_security_group.nexa_lambda_sg
  ]
}

# ----------------------------------------------------
# 6. LAMBDA PARA S3
# ----------------------------------------------------
resource "aws_lambda_function" "nexa_s3_lambda" {
  function_name = "nexa-s3-lambda"
  role          = data.aws_iam_role.existing_lambda_role.arn
  handler       = "lambda_function_s3.lambda_handler"
  runtime       = "python3.9"
  timeout       = 10

  filename         = "${path.module}/lambda_s3.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_s3.zip")

  environment {
  variables = {
    BUCKET_NAME = data.terraform_remote_state.infra.outputs.s3_bucket_name
  }
}


  vpc_config {
    subnet_ids         = data.terraform_remote_state.infra.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.nexa_lambda_sg.id]
  }

  depends_on = [
    aws_security_group.nexa_lambda_sg
  ]
}

