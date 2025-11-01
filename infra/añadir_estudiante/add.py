import json
import psycopg2
import os

def lambda_handler(event, context):
    conn = None
    try:
        conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            database=os.environ['DB_NAME'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASS'],
            port=os.environ.get('DB_PORT', '9876')  # usa 9876 por defecto
        )
        cursor = conn.cursor()

        body = json.loads(event.get('body', '{}'))

        cursor.execute("""
            INSERT INTO estudiante (nombre, apellido, fecha_nacimiento, direccion, correo_electronico, carrera)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            body.get('nombre'),
            body.get('apellido'),
            body.get('fecha_nacimiento'),
            body.get('direccion'),
            body.get('correo_electronico'),
            body.get('carrera')
        ))

        new_id = cursor.fetchone()[0]
        conn.commit()

        return {
            'statusCode': 200,
            'body': json.dumps({'message': f'Estudiante agregado correctamente con id {new_id}'})
        }

    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

    finally:
        if conn:
            cursor.close()
            conn.close()
