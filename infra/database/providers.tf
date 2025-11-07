# infra/database/providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = { # Requerido para random_password
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  backend "s3" {
    bucket         = "nexa-cloud-tf-state-111811373821" 
    key            = "database.tfstate"              # Clave ÚNICA para el estado de la DB
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "nexa-cloud-pilot-terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

# ----------------------------------------------------
# LECTURA DEL ESTADO REMOTO DE LA RED (CREADO POR VPC)
# ----------------------------------------------------
data "terraform_remote_state" "red_base" {
  backend = "s3"
  config = {
    bucket         = "nexa-cloud-tf-state-111811373821"
    key            = "network-base.tfstate" # Lee el estado de tu red
    region         = "us-east-1"
    use_lockfile = true
  }
}