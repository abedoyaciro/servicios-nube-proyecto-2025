
data "aws_iam_role" "labrole" {
  name = "labrole"
}


locals {
  db_env = {
    DB_HOST = "nexa-db-instance.cl1mlfaminhs.us-east-1.rds.amazonaws.com:9876"
    DB_NAME = "estudiante"
    DB_USER = "nexa_admin"
    DB_PASS = "tjaUWyY7c+wXXl6r"
    DB_PORT = "9876"
  }
}

# Reutilizamos el mismo rol y variables para cada lambda
resource "aws_lambda_function" "add_student" {
  filename         = "${path.module}/añadir_estudiante/añadir_estudiante.zip"
  function_name    = "add_student"
  role             = data.aws_iam_role.labrole.arn
  handler          = "add.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/añadir_estudiante/añadir_estudiante.zip")
  environment {
    variables = local.db_env
  }
}

resource "aws_lambda_function" "list_students" {
  filename         = "${path.module}/listar_estudiantes/listar_estudiantes.zip"
  function_name    = "list_students"
  role             = data.aws_iam_role.labrole.arn
  handler          = "list.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/listar_estudiantes/listar_estudiantes.zip")
  environment {
    variables = local.db_env
  }
}

resource "aws_lambda_function" "delete_student" {
  filename         = "${path.module}/eliminar_estudiante/eliminar_estudiante.zip"
  function_name    = "delete_student"
  role             = data.aws_iam_role.labrole.arn
  handler          = "delete.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/eliminar_estudiante/eliminar_estudiante.zip")
  environment {
    variables = local.db_env
  }
}

