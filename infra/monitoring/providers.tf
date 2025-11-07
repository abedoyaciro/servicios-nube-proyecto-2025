# infra/monitoring/providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "nexa-cloud-tf-state-111811373821" 
    key            = "monitoring.tfstate"              # Clave ÚNICA para el estado de Monitoreo
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ----------------------------------------------------
# DATOS REMOTOS (Lectura de otros estados)
# ----------------------------------------------------

# Lee el estado del balanceador de carga para obtener su ARN y el de los Target Groups
data "terraform_remote_state" "alb_base" {
  backend = "s3"
  config = {
    bucket = "nexa-cloud-tf-state-111811373821"
    key    = "load-balancer.tfstate" 
    region = "us-east-1"
  }
}

# Lee el estado de la base de datos para obtener su ARN
data "terraform_remote_state" "db_base" {
  backend = "s3"
  config = {
    bucket = "nexa-cloud-tf-state-111811373821"
    key    = "database.tfstate" 
    region = "us-east-1"
  }
}

# Lee el estado del serverless para obtener los nombres de las Lambdas
data "terraform_remote_state" "serverless_base" {
  backend = "s3"
  config = {
    bucket = "nexa-cloud-tf-state-111811373821"
    key    = "serverless.tfstate" 
    region = "us-east-1"
  }
}