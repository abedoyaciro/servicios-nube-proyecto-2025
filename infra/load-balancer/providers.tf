# infra/load-balancer/providers.tf

terraform {
  # Requisito: Versión del proveedor AWS
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configuración del Backend para el estado remoto en S3
  backend "s3" {
    bucket         = "nexa-cloud-tf-state-111811373821"
    key            = "load-balancer.tfstate"           
    region         = "us-east-1"
    encrypt        = true                              
  }
}

# Configuración del proveedor de AWS
provider "aws" {
  region = "us-east-1"
}