# infra/routing.tf

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
    aws_vpc.nexa_vpc               # Asume que VPC está en main.tf
  ]

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

# 7b. NAT Gateway
# Permite que los recursos privados inicien conexiones salientes a Internet.
resource "aws_nat_gateway" "nexa_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  # El NAT Gateway DEBE residir en la primera Subred Pública para funcionar.
  subnet_id = aws_subnet.public_subnet[0].id

  tags = {
    Name        = "${var.project_name}-nat-gw"
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