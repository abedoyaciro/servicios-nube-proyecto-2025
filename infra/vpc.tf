# infra/vpc.tf

# ----------------------------------------------------
# 4. RECURSOS DE RED: VPC
# ----------------------------------------------------

# Crea la Virtual Private Cloud (VPC) principal para NexaCloud
resource "aws_vpc" "nexa_vpc" {
  cidr_block           = var.vpc_cidr # 10.0.0.0/16 (viene de variables.tf)
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