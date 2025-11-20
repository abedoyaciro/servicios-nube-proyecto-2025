# infra/images-api/list_images.py
import json
import os
import boto3

# Inicializa el cliente S3 (se usará el rol de IAM adjunto a la Lambda)
s3_client = boto3.client('s3')

# IMPORTANTE: El nombre del bucket debe pasarse como una variable de entorno de Lambda,
# o ser hardcodeado si es estático. Aquí lo pasamos con os.environ.get.
# Lo leeremos del evento de la API Gateway, pero para simplificar, usaremos un nombre de bucket estático.
# En este ejemplo de código, asumiremos que el nombre del bucket se inyecta como una variable de entorno.
# ⚠️ Asegúrate de añadir esta variable de entorno en Terraform después de definir este archivo.

def lambda_handler(event, context):
    """
    Función de Lambda que lista los objetos (imágenes) en un bucket S3.
    """
    try:
        # Extraer el nombre del bucket de una variable de entorno
        # Si no la usas, deberás hardcodear el nombre del bucket aquí o usar el remote state.
        # Por ahora, para que este código funcione, lo hardcodearemos (no es la mejor práctica)
        # ⚠️ Nota: DEBES actualizar esta línea con tu nombre de bucket real si no usas env vars.
        # Asumiendo que el bucket es: nexa-images-[ID_DE_CUENTA]
        # Deberías usar os.environ['S3_BUCKET_NAME'] y configurar la ENV var en main.tf
        
        bucket_name = os.environ.get('S3_BUCKET_NAME')
        
        # Validación
        if not bucket_name:
            return {
                'statusCode': 500,
                'headers': { "Content-Type": "application/json" },
                'body': json.dumps({'error': 'S3_BUCKET_NAME environment variable not set'})
            }

        # Listar objetos del bucket
        response = s3_client.list_objects_v2(Bucket=bucket_name)

        image_keys = []
        if 'Contents' in response:
            for item in response['Contents']:
                # Excluir carpetas (objetos que terminan en /) y el primer archivo, que es el bucket
                if item['Key'] and item['Key'].endswith('/') == False:
                     # El cliente web de NexaCloud debe construir la URL,
                     # por lo que solo necesitamos la clave del archivo (Key).
                    image_keys.append(item['Key'])
        
        # Crear la URL base del bucket. Esto facilita al cliente web construir la URL final.
        region = os.environ.get('AWS_REGION', 'us-east-1')
        base_url = f"https://{bucket_name}.s3.{region}.amazonaws.com/"

        return {
            'statusCode': 200,
            'headers': {
                "Content-Type": "application/json",
                # CORS es fundamental para que el cliente web pueda consumir esta API.
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                "Access-Control-Allow-Methods": "GET,OPTIONS"
            },
            'body': json.dumps({
                'base_url': base_url,
                'image_keys': image_keys
            })
        }
    except Exception as e:
        print(f"Error al listar imágenes: {e}")
        return {
            'statusCode': 500,
            'headers': { "Content-Type": "application/json" },
            'body': json.dumps({'error': str(e)})
        }