# infra/outputs.tf

# ----------------------------------------------------
# 1. SALIDAS CLAVE DE LA RED (VPC, SUBNETS, IGW)
# ----------------------------------------------------

output "vpc_id" {
  description = "ID de la VPC principal (para adjuntar cualquier recurso AWS)."
  value       = aws_vpc.nexa_vpc.id
}

output "public_subnet_ids" {
  description = "Lista de IDs de las Subredes Públicas (para ELB, NAT GW)."
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "Lista de IDs de las Subredes Privadas (para RDS, EC2 Backend, Lambdas)."
  value       = aws_subnet.private_subnet[*].id
}

output "igw_id" {
  description = "ID del Internet Gateway."
  value       = aws_internet_gateway.nexa_igw.id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway (punto de salida de la red privada)."
  value       = aws_nat_gateway.nexa_nat_gateway.id
}
