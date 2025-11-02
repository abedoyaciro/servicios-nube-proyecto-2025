###################################
# STORAGE - S3 Bucket (seguro y con cifrado)
###################################

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "nexa_bucket" {
  bucket = "nexa-cloud-storage-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "nexa-cloud-storage"
    Project     = "NexaCloud"
    Environment = "learner-lab"
    Owner       = "Kevin_Ramos"
  }
}

resource "aws_s3_bucket_public_access_block" "nexa_block" {
  bucket                  = aws_s3_bucket.nexa_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.nexa_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 NexaCloud"
  value       = aws_s3_bucket.nexa_bucket.bucket
}
