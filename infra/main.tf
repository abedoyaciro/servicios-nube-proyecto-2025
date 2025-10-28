# infra/main.tf

# ----------------------------------------------------
# 1. CONFIGURACIÓN DEL PROVEEDOR
# ----------------------------------------------------
terraform {
  required_providers {
    aws = {
      # El source es el nombre del provider
      source  = "hashicorp/aws"
      # Usaremos una versión reciente que soporta los recursos requeridos
      version = "~> 5.0"
    }
  }
}

# ----------------------------------------------------
# 2. CONFIGURACIÓN DEL PROVEEDOR AWS
# ----------------------------------------------------
# Configuración del proveedor para la región de tu laboratorio
provider "aws" {
  region = "us-east-1"
  # NOTA: Terraform automáticamente buscará las credenciales en el archivo
  # ~/.aws/credentials (donde está el Session Token).
}

# ----------------------------------------------------
# 3. BACKEND (Estado Remoto)
# ----------------------------------------------------
/*
Para que el trabajo en equipo sea robusto y auditable, la MEJOR PRÁCTICA
es almacenar el estado de Terraform (terraform.tfstate) en un bucket de S3.
Esto es necesario para que los demás puedan ver los IDs de los 
recursos que tú creaste (ej. el ID de la VPC).

Sin embargo, para evitar dependencias circulares (el bucket de S3 aún no existe),
por ahora usaremos el backend local.
*/
# terraform {
#   backend "s3" {
#     bucket = "nexa-cloud-tf-state-111811373821" # Reemplazar con el ID de tu cuenta
#     key    = "nexa-cloud-pilot/terraform.tfstate"
#     region = "us-east-1"
#   }
# }