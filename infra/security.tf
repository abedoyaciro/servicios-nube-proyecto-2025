# infra/security.tf
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