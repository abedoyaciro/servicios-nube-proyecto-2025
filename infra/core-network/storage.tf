# infra/core-network/storage.tf

# ----------------------------------------------------
# 11. S3 BUCKET PARA ESTADO REMOTO DE TERRAFORM (LIMPIO)
# ----------------------------------------------------
resource "aws_s3_bucket" "nexa_tf_state" {
  bucket = "nexa-cloud-tf-state-${var.account_id}"

  tags = {
    Name = "nexa-cloud-tf-state"
  }
}

# Nuevo recurso para la Configuración de Cifrado
resource "aws_s3_bucket_server_side_encryption_configuration" "nexa_tf_state_encryption" {
  bucket = aws_s3_bucket.nexa_tf_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Recurso de versionamiento
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

resource "aws_s3_bucket_ownership_controls" "nexa_images_ownership" {
  bucket = aws_s3_bucket.nexa_images.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# -> AÑADIDO: ACL para permitir lectura pública
resource "aws_s3_bucket_acl" "nexa_images_acl" {
  bucket = aws_s3_bucket.nexa_images.id
  # 'public-read' permite que cualquier persona lea los objetos.
  acl    = "public-read" 
  # Dependemos de que el Access Block se haya modificado.
  depends_on = [
    aws_s3_bucket_public_access_block.nexa_images_security,
    aws_s3_bucket_ownership_controls.nexa_images_ownership
  ]
}
# <- FIN AÑADIDO

resource "aws_s3_bucket_public_access_block" "nexa_images_security" {
  bucket = aws_s3_bucket.nexa_images.id
  # Deshabilitamos el bloqueo de acceso público
  block_public_acls       = false 
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -> ELIMINADO: La política que causó el error 403.
/*
data "aws_iam_policy_document" "allow_public_read_images" {
  ...
}

resource "aws_s3_bucket_policy" "nexa_images_policy" {
  bucket = aws_s3_bucket.nexa_images.id
  policy = data.aws_iam_policy_document.allow_public_read_images.json
}
*/
# <- FIN ELIMINADO

# El bloque 'terraform_remote_state' que causó el error anterior se mantiene eliminado.