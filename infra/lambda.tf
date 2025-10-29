
data "aws_iam_role" "labrole" {
  name = "labrole"
}


locals {
  db_env = {
    DB_HOST = "nexa-db-instance.cl1mlfaminhs.us-east-1.rds.amazonaws.com:9876"
    DB_NAME = "estudiante"
    DB_USER = "nexa_admin"
    DB_PASS = "tjaUWyY7c+wXXl6r"
    DB_PORT = "5432"
  }
}

# Reutilizamos el mismo rol y variables para cada lambda
resource "aws_lambda_function" "add_student" {
  filename         = "añadir_estudiante.zip"
  function_name    = "add_student"
  role             = data.aws_iam_role.labrole.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("añadir_estudiante.zip")
  environment {
    variables = local.db_env
  }
}

resource "aws_lambda_function" "list_students" {
  filename         = "listar_estudiantes.zip"
  function_name    = "list_students"
  role             = data.aws_iam_role.labrole.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("listar_estudiantes.zip")
  environment {
    variables = local.db_env
  }
}

resource "aws_lambda_function" "delete_student" {
  filename         = "eliminar_estudiante.zip"
  function_name    = "delete_student"
  role             = data.aws_iam_role.labrole.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("eliminar_estudiante.zip")
  environment {
    variables = local.db_env
  }
}
