# infra/images-api/providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configuración del Backend para el estado remoto en S3
  backend "s3" {
    bucket         = "nexa-cloud-tf-state-192626564201" 
    key            = "images-api.tfstate"               
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}