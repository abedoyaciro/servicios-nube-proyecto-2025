# infra/load-balancer/main.tf

# ----------------------------------------------------
# 1. REFERENCIAS DE ESTADO REMOTO
# ----------------------------------------------------

data "terraform_remote_state" "red_base" {
  backend = "s3"
  config = {
    bucket = "nexa-cloud-tf-state-192626564201" # Reemplaza con tu bucket
    key    = "network-base.tfstate"
    region = "us-east-1"
  }
}

# ----------------------------------------------------
# 2. BÚSQUEDA DE AMI (Amazon Linux 2 para Web Server)
# ----------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ----------------------------------------------------
# 3. SECURITY GROUPS (ALB y Servidores Web)
# ----------------------------------------------------

# A. Security Group para el ALB (Abre tráfico HTTP/80 al mundo)
resource "aws_security_group" "alb_sg" {
  name        = "nexa-alb-sg"
  description = "Permite trafico HTTP (80) entrante al ALB"
  vpc_id      = data.terraform_remote_state.red_base.outputs.vpc_id

  # Regla de entrada: HTTP desde cualquier lugar
  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de salida: Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# B. Security Group para las EC2 Backend (Permite tráfico solo desde el ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "nexa-ec2-sg"
  description = "Permite trafico HTTP entrante SOLO desde el ALB"
  vpc_id      = data.terraform_remote_state.red_base.outputs.vpc_id

  # Regla de entrada: HTTP SÓLO desde el Security Group del ALB
  ingress {
    description     = "HTTP desde ALB SG"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # ¡IMPORTANTE! Requisito de seguridad (SSH bloqueado/cambiado)
  # Aquí abrimos SSH en un puerto no estándar (ej: 2222) sólo para tu IP de oficina/hogar
  # Si no tienes IP estática, es mejor dejarlo cerrado
  ingress {
    description = "SSH en puerto no estandar (Bloqueado/Cambiado)"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ¡ADVERTENCIA! Cambiar a tu IP estática o dejar comentado
  }

  # Regla de salida: Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------------------------------
# 4. INSTANCIAS EC2 (Servidores Web, cuenta = 2)
# ----------------------------------------------------

# User Data (Script de configuración que instala Apache e inserta el Hostname)
data "template_file" "user_data_template" {
  template = file("${path.module}/user_data.sh")
}

# Despliegue de dos instancias EC2 (para simular el balanceo)
resource "aws_instance" "web_server" {
  count                  = 2 # Despliega 2 servidores web
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro" # Económico y compatible
  # Se usan las subredes públicas para que puedan ser alcanzadas por el ALB
  subnet_id              = data.terraform_remote_state.red_base.outputs.public_subnet_ids[count.index] 
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = data.template_file.user_data_template.rendered
  associate_public_ip_address = true # Necesario para la instalación del user_data
  
  tags = {
    Name = "NexaCloud-WebServer-${count.index + 1}"
    Environment = "Project"
  }
}

# ----------------------------------------------------
# 5. APPLICATION LOAD BALANCER (ALB)
# ----------------------------------------------------

# A. El Balanceador de Carga
resource "aws_lb" "nexa_alb" {
  name               = "nexa-alb-project"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.terraform_remote_state.red_base.outputs.public_subnet_ids # Debe estar en subredes públicas
}

# B. Target Group (Grupo Objetivo)
resource "aws_lb_target_group" "target_group" {
  name     = "nexa-tg-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.red_base.outputs.vpc_id
  
  health_check {
    path = "/"
    protocol = "HTTP"
  }
}

# C. Listener (Escucha en puerto 80)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.nexa_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# D. Adjuntar las EC2 al Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  count            = length(aws_instance.web_server)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80 # Puerto que escucha el servidor web en la EC2
}

# ----------------------------------------------------
# 6. OUTPUT
# ----------------------------------------------------
output "alb_dns_name" {
  description = "El DNS del Application Load Balancer para acceder a la pagina web"
  value       = aws_lb.nexa_alb.dns_name
}

output "alb_arn_suffix" {
  description = "El ARN Suffix del ALB (ID de CloudWatch)"
  value       = aws_lb.nexa_alb.arn_suffix
}