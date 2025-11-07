/*
--------------------------------------------------------------------------------
DOCUMENTACIÓN DE SALIDAS - infra/outputs.tf
--------------------------------------------------------------------------------
Resumen:
Este fichero exporta identificadores clave de la red y de grupos de seguridad
para que otros módulos, pipelines o recursos externos puedan referenciarlos.

Formato y buenas prácticas:
- Confirmar dependencias: los consumidores de estas salidas deben asegurarse de
  que los recursos se han creado (orden de ejecución / dependencias de Terraform).
- Tipos: las listas de subredes se devuelven como arrays; tratarlas acorde al
  lenguaje o herramienta que consuma los outputs.
- Sensibilidad: estas salidas contienen IDs de recursos (no credenciales). Si se
  añadiera información sensible, marcarla como sensitive = true.
- Consumo habitual: module.<name>.<output>, data.terraform_remote_state, variables
  en pipelines CI/CD, o entradas a otros módulos.
--------------------------------------------------------------------------------
*/

# ----------------------------------------------------
# 1. SALIDAS CLAVE DE LA RED (VPC, SUBNETS, IGW, NAT)
# ----------------------------------------------------

# Usos típicos:
# - Adjuntar recursos (EC2, RDS, ENI) a la VPC correcta.
# - Configurar rutas, peering o conexiones VPN hacia la VPC.
output "vpc_id" {
  description = "ID de la VPC principal. Usos: adjuntar recursos, peering, VPN, políticas de ruta y ACL."
  value       = aws_vpc.nexa_vpc.id
}

# Usos típicos:
# - Crear listeners/target groups en ELB/ALB que deben lanzarse en subredes públicas.
# - Asociar Elastic IPs / Gateways para balanceadores.
output "public_subnet_ids" {
  description = "Lista de IDs de las Subredes Públicas. Usos: desplegar ELB/ALB, NAT Gateway redundante y endpoints públicos."
  value       = aws_subnet.public_subnet[*].id
}

# Usos típicos:
# - Lanzamiento de servicios backend (EC2, RDS, Lambdas privadas).
# - Asociar rutas a NAT Gateway y control de acceso por subred.
output "private_subnet_ids" {
  description = "Lista de IDs de las Subredes Privadas. Usos: instancias backend, RDS privados, Lambdas en subred privada y escalado automático."
  value       = aws_subnet.private_subnet[*].id
}

# Usos típicos:
# - Asociar el Internet Gateway a la VPC y configurar rutas públicas.
# - Verificaciones y auditoría de infra.
output "igw_id" {
  description = "ID del Internet Gateway. Usos: rutas públicas para subredes/ELB y comprobaciones de conectividad."
  value       = aws_internet_gateway.nexa_igw.id
}

# Usos típicos:
# - Configurar rutas de salida para subredes privadas.
# - Referenciar en scripts de automatización que gestionan alta disponibilidad de NAT.
output "nat_gateway_id" {
  description = "ID del NAT Gateway. Usos: punto de salida para tráfico saliente desde subredes privadas y referencia para failover/monitoring."
  value       = aws_nat_gateway.nexa_nat_gateway.id
}

# ----------------------------------------------------
# 2. SALIDAS - SECURITY GROUPS
# ----------------------------------------------------

# Usos típicos:
# - Referenciar en otros módulos/recursos que necesiten permitir tráfico hacia/desde balanceadores.
# - Aplicar reglas de referencia (ingress from sg_elb to sg_ec2).
output "sg_elb_id" {
  description = "ID del Security Group para balanceadores (ELB/ALB/NLB). Usos: adjuntar al LB y permitir tráfico entrante público según reglas."
  value       = aws_security_group.nexa_sg_elb.id
}

# Usos típicos:
# - Asociar a instancias EC2 y ASG.
# - Permitir tráfico interno desde sg_elb y controles de puertos de aplicación.
output "sg_ec2_id" {
  description = "ID del Security Group para EC2 (backend). Usos: proteger instancias, reglas de acceso interno y apertura de puertos de aplicación."
  value       = aws_security_group.nexa_sg_ec2.id
}

# Usos típicos:
# - Asociar a instancias RDS.
# - Restringir acceso a RDS únicamente desde sg_ec2 o IPs/peers autorizados.
output "sg_rds_id" {
  description = "ID del Security Group para RDS. Usos: aplicar reglas que permitan acceso solo desde capas de aplicación (p. ej. sg_ec2) y herramientas de gestión."
  value       = aws_security_group.nexa_sg_rds.id
}