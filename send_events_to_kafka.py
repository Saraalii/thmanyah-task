import json 
import time 
import uuid
import os
import psycopg2
from kafka import KafkaProducer

conn = psycopg2.connect(
    host=os.getenv("POSTGRES_HOST"),
    port=int(os.getenv("POSTGRES_PORT")),
    dbname=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD")
)
cursor = conn.cursor()

producer = KafkaProducer(
    bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS").split(','),
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)


cursor.execute("SELECT id, content_id, user_id, event_type, event_ts, duration_ms, device, raw_payload FROM engagement_events")
rows = cursor.fetchall()

for row in rows:
    event = {
        "id": row[0],
        "content_id": str(row[1]),
        "user_id": str(row[2]),
        "event_type": row[3],
        "event_ts": row[4].isoformat(),
        "duration_ms": row[5],
        "device": row[6],
        "raw_payload": row[7]
    }
    producer.send("engagements", value=event)
    print(f"✔️ Sent event ID {row[0]} to Kafka")
    time.sleep(0.5) 

producer.flush()
cursor.close()
conn.close()  
