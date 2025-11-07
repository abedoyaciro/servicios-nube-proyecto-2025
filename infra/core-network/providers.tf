# ----------------------------------------------------
# 1. CONFIGURACIÓN DEL BACKEND (ESTADO DE LA RED)
# ----------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Usar el Bucket de estado definido en storage.tf
    bucket         = "nexa-cloud-tf-state-111811373821" 
    key            = "network-base.tfstate" # Clave ÚNICA para el estado de la red
    region         = "us-east-1"
    encrypt        = true
  }
}

# ----------------------------------------------------
# 2. CONFIGURACIÓN DEL PROVEEDOR AWS
# ----------------------------------------------------
provider "aws" {
  region = "us-east-1"
}