# infra/variables.tf

# ----------------------------------------------------
# 1. VARIABLES GLOBALES DE CONFIGURACIÓN
# ----------------------------------------------------

# Variable para el nombre del proyecto (usada en tags)
variable "project_name" {
  description = "Nombre del proyecto piloto para NexaCloud"
  type        = string
  default     = "nexa-cloud-pilot"
}

# Variable para la etiqueta de ambiente (usada en tags)
variable "environment" {
  description = "Ambiente de despliegue (ej. Dev, Prod)"
  type        = string
  default     = "Dev"
}

# ----------------------------------------------------
# 2. VARIABLES DE RED (Paquete 1: Tu tarea)
# ----------------------------------------------------

# Bloque CIDR principal para toda la VPC
variable "vpc_cidr" {
  description = "El bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Lista de Zonas de Disponibilidad (AZs) a usar
variable "azs" {
  description = "Lista de Zonas de Disponibilidad a usar en us-east-1"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# CIDRs para las subredes públicas (para ELB, NAT Gateway)
variable "public_subnets" {
  description = "CIDR para las subredes públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# CIDRs para las subredes privadas (para RDS, EC2 Backend, Lambdas)
variable "private_subnets" {
  description = "CIDR para las subredes privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}