###################################
# DATABASE - RDS PostgreSQL (usando VPC existente)
###################################

resource "random_password" "rds_master" {
  length           = 16
  special          = true
  override_special = "!#%&*()_+=-"
}

resource "aws_db_subnet_group" "nexa_subnet_group" {
  name       = "nexa-db-subnet-group"
  subnet_ids = [
    "subnet-06b410ed8346d7a86", # privada 1
    "subnet-0fc351a932d92cf97"  # privada 2
  ]
  description = "Subredes privadas para RDS NexaCloud"
}

resource "aws_security_group" "nexa_rds_sg" {
  name        = "nexa-rds-sg"
  description = "Permite acceso al RDS en puerto 9876"
  vpc_id      = "vpc-0d95bda27a2680ee4"

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
    Project = "NexaCloud"
  }
}

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
  apply_immediately       = true
  deletion_protection     = false
  storage_encrypted       = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.nexa_rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.nexa_subnet_group.name

  tags = {
    Name        = "nexa-db-instance"
    Environment = "learner-lab"
    Project     = "NexaCloud"
    Owner       = "Kevin_Ramos"
  }
}

output "rds_endpoint" {
  description = "Endpoint del RDS NexaCloud"
  value       = aws_db_instance.nexa_db.endpoint
}

output "rds_master_password" {
  description = "Contraseña generada del usuario administrador del RDS"
  value       = random_password.rds_master.result
  sensitive   = true
}
