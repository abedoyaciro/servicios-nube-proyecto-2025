#!/bin/bash
# Script de configuración de las EC2 para el Balanceador de Carga (ALB)

# 1. Instalar un servidor web simple (Amazon Linux usa httpd para Apache)
yum update -y
yum install -y httpd

# 2. Iniciar el servicio Apache
systemctl start httpd
systemctl enable httpd

# 3. Crear el archivo index.html
# Este archivo muestra el hostname (ID único) del servidor web.
# Usamos un poco de HTML/CSS básico para que sea visible.

# Obtenemos el nombre de host de la instancia (será similar a ip-10-0-1-xxx)
HOST_NAME=$(hostname)

# Contenido HTML con el identificador del servidor
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Servidor Web NexaCloud</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            display: flex; 
            flex-direction: column;
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
            margin: 0;
            background-color: #f0f4f8;
            color: #333;
        }
        .container {
            padding: 40px;
            border-radius: 12px;
            background-color: white;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        h1 {
            color: #1a73e8; /* Un azul de NexaCloud */
            font-size: 2em;
            margin-bottom: 10px;
        }
        p {
            font-size: 1.2em;
            color: #555;
        }
        .server-id {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 20px;
            border-radius: 6px;
            background-color: #e6f3ff;
            color: #1a73e8;
            font-weight: bold;
            font-family: monospace;
            font-size: 1.1em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>✅ Balanceador de Carga Activo (Requisito 9)</h1>
        <p>Esta página está siendo servida por:</p>
        <div class="server-id">$HOST_NAME</div>
        <p>Recarga la página para ver el cambio de servidor.</p>
    </div>
</body>
</html>
EOF

# 4. Asegurar que Apache puede escribir en los logs (aunque no es estrictamente necesario aquí)
# chmod -R 755 /var/www/html