# infra/main.tf

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

# ROUTING

# ----------------------------------------------------
# 7. NAT GATEWAY Y ELASTIC IP
# ----------------------------------------------------

# 7a. Elastic IP (EIP) para el NAT Gateway
# Proporciona una dirección IP pública estática al NAT Gateway.
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"

  # Asegura que el Internet Gateway exista antes de crear la EIP
  # y que la VPC esté lista. Aunque Terraform infiere dependencias,
  # a veces es útil ser explícito con dependencias cruzadas.
  depends_on = [
    aws_internet_gateway.nexa_igw, # Asume que IGW está en main.tf
    aws_vpc.nexa_vpc              # Asume que VPC está en main.tf
  ]

  tags = {
    Name = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

# 7b. NAT Gateway
# Permite que los recursos privados inicien conexiones salientes a Internet.
resource "aws_nat_gateway" "nexa_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  # El NAT Gateway DEBE residir en la primera Subred Pública para funcionar.
  subnet_id     = aws_subnet.public_subnet[0].id
  
  tags = {
    Name = "${var.project_name}-nat-gw"
    Environment = var.environment
  }
}

# ----------------------------------------------------
# 8. TABLAS DE RUTAS
# ----------------------------------------------------

# 8a. Tabla de Rutas Públicas
# Dirige el tráfico de las Subredes Públicas al Internet Gateway.
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.nexa_vpc.id

  # Regla: Cualquier destino (0.0.0.0/0) va al Internet Gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nexa_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# 8b. Tabla de Rutas Privadas
# Dirige el tráfico de las Subredes Privadas al NAT Gateway.
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.nexa_vpc.id

  # Regla: Cualquier destino (0.0.0.0/0) va al NAT Gateway.
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nexa_nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# ----------------------------------------------------
# 9. ASOCIACIONES DE SUBREDES
# ----------------------------------------------------

# 9a. Asociar todas las Subredes Públicas a la Tabla Pública
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# 9b. Asociar todas las Subredes Privadas a la Tabla Privada
resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# SECURITY

# ----------------------------------------------------
# 10. GRUPOS DE SEGURIDAD (SECURITY GROUPS - SGs)
# ----------------------------------------------------

# NOTA: Usamos 'ingress' (entrada) y 'egress' (salida) para definir quién puede
# comunicarse con el recurso, usando siempre referencias a otros SGs.

# 10a. Security Group para el Balanceador de Carga (ELB)
# El ELB necesita recibir tráfico de Internet (0.0.0.0/0).
resource "aws_security_group" "nexa_sg_elb" {
  name        = "${var.project_name}-sg-elb"
  description = "Permite trafico HTTP/HTTPS desde Internet al ELB."
  vpc_id      = aws_vpc.nexa_vpc.id

  # INGRESS: Permite HTTP (80) y HTTPS (443) desde cualquier lugar.
  ingress {
    description = "Trafico web HTTP/HTTPS"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # EGRESS: Salida por defecto (Permite todo el tráfico saliente)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 significa todos los protocolos
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-elb"
  }
}

# 10b. Security Group para las Instancias EC2 (Servidores Web/App)
# Los servidores sólo deben recibir tráfico desde el ELB (su SG).
resource "aws_security_group" "nexa_sg_ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "Permite trafico web solo desde el ELB y SSH personalizado para administracion."
  vpc_id      = aws_vpc.nexa_vpc.id

  # INGRESS 1: Permite el tráfico web SÓLO desde el SG del ELB.
  ingress {
    description     = "Trafico web desde ELB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.nexa_sg_elb.id]
  }

  # INGRESS 2: Permite SSH en puerto personalizado (p. ej., 2222)
  ingress {
    description = "Acceso administrativo SSH personalizado" 
    from_port   = 2222 
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = [var.ssh_source_ip] 
  }

  # EGRESS: Permite la salida hacia el SG del RDS (para consultas a la BD).
  # También permite salida a Internet vía NAT Gateway (para actualizaciones).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ec2"
  }
}

# 10c. Security Group para la Base de Datos (RDS)
# La BD sólo debe recibir tráfico desde los servidores de aplicación (SG del EC2).
resource "aws_security_group" "nexa_sg_rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Permite acceso a la BD solo desde los servidores de aplicacion (EC2/Lambda)."
  vpc_id      = aws_vpc.nexa_vpc.id

  # INGRESS: Permite el acceso a la BD SÓLO desde el SG del EC2.
  # Usamos el puerto 9876, según el requisito del proyecto.
  ingress {
    description     = "Acceso a la BD desde EC2/Lambdas"
    from_port       = 9876 # Puerto de BD requerido por NexaCloud
    to_port         = 9876
    protocol        = "tcp"
    security_groups = [aws_security_group.nexa_sg_ec2.id]
    # NOTA: Si usas Lambdas, estas también deben estar incluidas aquí.
  }

  # EGRESS: Restringimos la salida de la BD (es una mejor práctica de seguridad).
  # No necesita conectarse a Internet, solo a la red interna.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.nexa_vpc.cidr_block] # Solo permite salida a la propia VPC
  }

  tags = {
    Name = "${var.project_name}-sg-rds"
  }
}