import json
import psycopg2
import os

def lambda_handler(event, context):
    try:
        conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASS'],
            port=os.environ['DB_PORT']
        )
        cursor = conn.cursor()

        body = json.loads(event['body'])

        cursor.execute("""
            INSERT INTO estudiante (nombre, apellido, fecha_nacimiento, direccion, correo_electronico, carrera)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            body['nombre'],
            body['apellido'],
            body['fecha_nacimiento'],
            body['direccion'],
            body['correo_electronico'],
            body['carrera']
        ))

        new_id = cursor.fetchone()[0]
        conn.commit()

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Estudiante agregado correctamente', 'id': new_id})
        }

    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

    finally:
        if conn:
            cursor.close()
            conn.close()
