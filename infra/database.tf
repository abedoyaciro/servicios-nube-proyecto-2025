###################################
# DATABASE - RDS PostgreSQL (usando VPC existente)
###################################

# Generar contraseña aleatoria segura
resource "random_password" "rds_master" {
  length           = 16
  special          = true
  override_special = "!#%&*()_+=-"
}


# Grupo de subredes para RDS (usa las privadas ya creadas)
resource "aws_db_subnet_group" "nexa_subnet_group" {
  name       = "nexa-db-subnet-group"
  subnet_ids = [
    "subnet-0ba127d7c38f549f2",
    "subnet-05d338d9ae527088f"
  ]
  description = "Subredes privadas para RDS NexaCloud"
}

# Security Group para RDS
resource "aws_security_group" "nexa_rds_sg" {
  name        = "nexa-rds-sg"
  description = "Permite acceso al RDS en puerto 9876"
  vpc_id      = "vpc-01e3265cca52090cd"

  ingress {
    description = "Acceso interno al RDS desde la VPC"
    from_port   = 9876
    to_port     = 9876
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nexa-rds-sg"
  }
}

# Instancia RDS PostgreSQL
resource "aws_db_instance" "nexa_db" {
  identifier              = "nexa-db-instance"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  db_name                 = "nexacloud"
  username                = "nexa_admin"
  password                = random_password.rds_master.result
  port                    = 9876
  multi_az                = false
  storage_encrypted       = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.nexa_rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.nexa_subnet_group.name

  tags = {
    Name    = "nexa-rds-instance"
    Project = "NexaCloud"
  }
}

# Output para mostrar el endpoint del RDS
output "rds_endpoint" {
  description = "Endpoint del RDS NexaCloud"
  value       = aws_db_instance.nexa_db.endpoint
}
