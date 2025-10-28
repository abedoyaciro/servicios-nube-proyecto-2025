# infra/outputs.tf

# ----------------------------------------------------
# 1. SALIDAS CLAVE DE LA RED
# ----------------------------------------------------

output "vpc_id" {
  description = "El ID de la VPC principal"
  value       = aws_vpc.nexa_vpc.id
}

output "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas (para RDS y Lambdas)"
  value       = aws_subnet.private_subnet[*].id
}