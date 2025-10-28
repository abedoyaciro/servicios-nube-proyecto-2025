import json
import psycopg2
import os

def lambda_handler(event, context):
    try:
        conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            port=os.environ['DB_PORT'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            dbname=os.environ['DB_NAME']
        )
        cur = conn.cursor()
        cur.execute("SELECT 'NexaCloud' AS company_name;")
        result = cur.fetchone()[0]
        cur.close()
        conn.close()
        return {"statusCode": 200, "body": json.dumps({"name": result})}
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
