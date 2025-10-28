###################################
# STORAGE - S3 Bucket (versión estable compatible)
###################################

# Genera un sufijo aleatorio para asegurar nombre único de bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Crea el bucket privado (sin ACLs)
resource "aws_s3_bucket" "nexa_bucket" {
  bucket = "nexa-cloud-storage-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "nexa-cloud-storage"
    Project = "NexaCloud"
  }
}

# Bloquea todo acceso público
resource "aws_s3_bucket_public_access_block" "nexa_block" {
  bucket                  = aws_s3_bucket.nexa_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output para otros módulos o para la aplicación
output "s3_bucket_name" {
  description = "Nombre del bucket S3 NexaCloud"
  value       = aws_s3_bucket.nexa_bucket.bucket
}
