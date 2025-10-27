# full_test.tf
#######################################################
# 1. Configuración del Proveedor (Provider) de AWS
#######################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Asegúrate de que esta sea la región correcta para tus pruebas
}

# Búsqueda de la AMI (Amazon Linux 2023)
data "aws_ami" "latest_al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-x86_64"] 
  }
}

#######################################################
# 2. VPC y Subred (Redes de Prueba)
#######################################################
# VPC
resource "aws_vpc" "test_vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "test-vpc-terraform"
  }
}

# Subred Pública
resource "aws_subnet" "test_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "172.31.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Para que la EC2 tenga IP pública
  tags = {
    Name = "test-subnet-public"
  }
}

# Internet Gateway (Permite salida a Internet)
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "test-igw"
  }
}

# Tabla de Rutas y Ruta (Conecta la subred al IGW)
resource "aws_route_table" "test_rt" {
  vpc_id = aws_vpc.test_vpc.id
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.test_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.test_igw.id
}

resource "aws_route_table_association" "test_rt_assoc" {
  subnet_id      = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.test_rt.id
}

#######################################################
## 3. Security Group y EC2
#######################################################

# Security Group (Permite SSH para conectarte)
resource "aws_security_group" "test_sg" {
  name        = "test-sg-ssh-only"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.test_vpc.id

  # Regla de entrada: SSH (Puerto 22) abierto a Internet (0.0.0.0/0)
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Regla de salida: Permite todo
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instancia EC2
resource "aws_instance" "test_instance" {
  ami           = data.aws_ami.latest_al2023.id 
  instance_type = "t2.micro" 
  subnet_id     = aws_subnet.test_subnet.id # Asocia a la subred recién creada
  
  vpc_security_group_ids = [
    aws_security_group.test_sg.id # Asocia al SG recién creado
  ]

  # *** Reemplaza con el nombre de tu par de claves SSH para poder acceder ***
  # key_name      = "tu-nombre-de-clave" 

  tags = {
    Name = "test-ec2-terraform"
  }
}

#######################################################
## 4. Resultado (Output)
#######################################################

output "instance_public_ip" {
  description = "IP pública para acceder a la instancia"
  value       = aws_instance.test_instance.public_ip
}
