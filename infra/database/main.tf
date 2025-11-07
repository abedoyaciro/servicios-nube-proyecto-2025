###################################
# DATABASE - RDS PostgreSQL (usando VPC existente)
###################################

resource "random_password" "rds_master" {
  length           = 16
  special          = true
  override_special = "!#%&*()_+=-"
}

resource "aws_db_subnet_group" "nexa_subnet_group" {
  name        = "nexa-db-subnet-group"
  # **REFERENCIA DINÁMICA A OUTPUTS**
  subnet_ids  = data.terraform_remote_state.red_base.outputs.private_subnet_ids 
  description = "Subredes privadas para RDS NexaCloud"
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

  # **REFERENCIA DINÁMICA A OUTPUTS**
  # El SG de RDS lo creó la rama VPC, solo necesitamos su ID.
  vpc_security_group_ids  = [data.terraform_remote_state.red_base.outputs.sg_rds_id] 
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

output "db_instance_id" {
  description = "Identificador de la instancia RDS (necesario para monitoreo)"
  value       = aws_db_instance.nexa_db.id
}
