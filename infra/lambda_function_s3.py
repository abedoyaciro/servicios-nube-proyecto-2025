import json
import boto3
import os

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    bucket = os.environ['BUCKET_NAME']
    try:
        objects = s3.list_objects_v2(Bucket=bucket)
        names = [obj['Key'] for obj in objects.get('Contents', [])]
        return {"statusCode": 200, "body": json.dumps({"files": names})}
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
