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

# ----------------------------------------------------
# 4. RECURSOS DE RED: VPC
# ----------------------------------------------------

# Crea la Virtual Private Cloud (VPC) principal para NexaCloud
resource "aws_vpc" "nexa_vpc" {
  cidr_block           = var.vpc_cidr       # 10.0.0.0/16 (viene de variables.tf)
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# ----------------------------------------------------
# 5. RECURSOS DE RED: SUBNETS (Usando el metargumento 'count')
# ----------------------------------------------------

# Subredes Públicas (Para ELB, NAT Gateway)
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.nexa_vpc.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true # Las públicas deben asignar IPs automáticamente

  tags = {
    Name        = "${var.project_name}-public-az${count.index + 1}"
    Environment = var.environment
  }
}

# Subredes Privadas (Para RDS, EC2 Backend, Lambdas)
resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.nexa_vpc.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false # Las privadas NO deben asignar IPs automáticamente

  tags = {
    Name        = "${var.project_name}-private-az${count.index + 1}"
    Environment = var.environment
  }
}

# ----------------------------------------------------
# 6. CONECTIVIDAD A INTERNET
# ----------------------------------------------------

# Internet Gateway (Permite la comunicación entre la VPC y el internet)
resource "aws_internet_gateway" "nexa_igw" {
  vpc_id = aws_vpc.nexa_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}