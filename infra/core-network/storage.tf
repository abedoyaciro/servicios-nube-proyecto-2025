# infra/core-network/storage.tf

# ----------------------------------------------------
# 11. S3 BUCKET PARA ESTADO REMOTO DE TERRAFORM (LIMPIO)
# ----------------------------------------------------
resource "aws_s3_bucket" "nexa_tf_state" {
  bucket = "nexa-cloud-tf-state-${var.account_id}"

  # ¡BLOQUE DE CIFRADO ELIMINADO DE AQUÍ!

  tags = {
    Name = "nexa-cloud-tf-state"
  }
}

# Nuevo recurso para la Configuración de Cifrado
# Ahora es un recurso de configuración separado que enlaza al bucket.
resource "aws_s3_bucket_server_side_encryption_configuration" "nexa_tf_state_encryption" {
  bucket = aws_s3_bucket.nexa_tf_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # El algoritmo que tenías
    }
  }
}

# Recurso de versionamiento (que corregimos previamente)
resource "aws_s3_bucket_versioning" "nexa_tf_state_versioning" {
  bucket = aws_s3_bucket.nexa_tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ----------------------------------------------------
# 12. S3 BUCKET PARA IMÁGENES DE EMPLEADOS
# ----------------------------------------------------
resource "aws_s3_bucket" "nexa_images" {
  bucket = "${var.project_name}-images-${var.account_id}"

  tags = {
    Name = "${var.project_name}-images-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "nexa_images_security" {
  bucket = aws_s3_bucket.nexa_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nexa_images_encryption" {
  bucket = aws_s3_bucket.nexa_images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}