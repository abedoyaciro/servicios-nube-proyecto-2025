# infra/storage.tf

# ----------------------------------------------------
# 11. S3 BUCKET PARA ESTADO REMOTO DE TERRAFORM
# ----------------------------------------------------

# RECURSO PRINCIPAL DEL BUCKET DE ESTADO
resource "aws_s3_bucket" "nexa_tf_state" {
  # Cada compañero debe cambiar la variable account_id en su tfvars o en variables.tf
  bucket = "nexa-cloud-tf-state-${var.account_id}" 
  
  tags = {
    Name = "nexa-cloud-tf-state"
  }
}

# Habilita el control de versiones (Mejor Práctica)
resource "aws_s3_bucket_versioning" "nexa_tf_state_versioning" {
  bucket = aws_s3_bucket.nexa_tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Habilita el cifrado para el estado
resource "aws_s3_bucket_server_side_encryption_configuration" "nexa_tf_state_encryption" {
  bucket = aws_s3_bucket.nexa_tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Tabla DynamoDB para el bloqueo de estado (Evita colisiones)
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "${var.project_name}-terraform-locks"
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ----------------------------------------------------
# 12. S3 BUCKET PARA IMÁGENES DE EMPLEADOS
# ----------------------------------------------------

# RECURSO PRINCIPAL DEL BUCKET DE IMÁGENES
resource "aws_s3_bucket" "nexa_images" {
  bucket = "${var.project_name}-images-${var.account_id}" 
  
  tags = {
    Name = "${var.project_name}-images-bucket"
  }
}

# Bloqueo total de acceso público (REQUISITO DE SEGURIDAD)
# Este es el recurso separado que resuelve el error anterior.
resource "aws_s3_bucket_public_access_block" "nexa_images_security" {
  bucket = aws_s3_bucket.nexa_images.id # Referencia al bucket
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Habilita el cifrado para las imágenes
resource "aws_s3_bucket_server_side_encryption_configuration" "nexa_images_encryption" {
  bucket = aws_s3_bucket.nexa_images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}