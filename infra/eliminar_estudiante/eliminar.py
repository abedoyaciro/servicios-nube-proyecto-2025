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
        student_id = body['id']

        cursor.execute("DELETE FROM estudiante WHERE id = %s RETURNING id;", (student_id,))
        deleted = cursor.fetchone()

        conn.commit()

        if deleted:
            return {'statusCode': 200, 'body': json.dumps({'message': 'Estudiante eliminado'})}
        else:
            return {'statusCode': 404, 'body': json.dumps({'message': 'Estudiante no encontrado'})}

    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

    finally:
        if conn:
            cursor.close()
            conn.close()
