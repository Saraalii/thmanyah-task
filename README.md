## How to Run the Project

Below is an end‑to‑end guide you can copy‑paste in a terminal (macOS / Linux / WSL).  
Each block is independent—run it one‑by‑one.

### 0  Prerequisites
* Docker & Docker Compose installed
* Python 3.8+ with:
  ```bash
  pip install psycopg2-binary kafka-python
  ```

### 1  Clone & Start the stack
```bash
git clone <repo‑url>
cd thmanyah-task-fixed
docker compose up -d         # starts ZK, Kafka, Postgres, Flink
```

### 2  Add Flink connectors (one time)
```bash
mkdir -p flink-jars
# Kafka connector & client
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.17.1/flink-connector-kafka-1.17.1.jar
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.4.0/kafka-clients-3.4.0.jar
# JDBC connector & Postgres driver
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.1.2-1.17/flink-connector-jdbc-3.1.2-1.17.jar
wget -P flink-jars https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

# Reload Flink so it picks up the jars
docker compose down
docker compose up -d
```

### 3  Seed the database
```bash
docker exec -it thmanyah-task-fixed-postgres-1   psql -U thmanyah -d thmanyah_db -f /init.sql
```

### 4  Create Flink tables + start the job
```bash
docker compose exec flink-jobmanager ./bin/sql-client.sh
-- execute each statement separately:

-- 1️⃣ Kafka source
CREATE TABLE engagement_events ( ... ) WITH (...);

-- 2️⃣ JDBC lookup (content)
CREATE TABLE content ( ... ) WITH (...);

-- 3️⃣ Upsert sink
CREATE TABLE processed_engagements ( ... ) WITH (...);

-- 4️⃣ Start streaming
INSERT INTO processed_engagements
SELECT … LEFT JOIN content c ON e.content_id = c.id ;
```

> Successful submission prints a **Job ID** (green in Flink UI).

### 5  Send a test event
```bash
echo '{"id":1,"content_id":"11111111-1111-1111-1111-111111111111","user_id":"u-1","event_type":"play","event_ts":"2025-08-10T09:25:00Z","duration_ms":60000,"device":"ios","raw_payload":{}}' |   docker exec -i thmanyah-task-fixed-kafka-1   kafka-console-producer --bootstrap-server kafka:9092 --topic engagements
```

### 6  Verify pipeline output
```bash
docker exec -it thmanyah-task-fixed-kafka-1   kafka-console-consumer --bootstrap-server kafka:9092   --topic processed_engagements --from-beginning
```

Expected JSON (sample):
```json
{
  "content_id": "1111...",
  "user_id": "u-1",
  "event_type": "play",
  "engagement_seconds": 60.0,
  "engagement_pct": 0.033
}
```

### Troubleshooting Quick‑Table

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `relation "content" does not exist` | `init.sql` not executed | Run step 3 |
| `LEADER_NOT_AVAILABLE` in consumer | Sink hasn’t received data yet | Send a test event (step 5) |
| Job missing / failed in Flink UI | Needs tables + INSERT re‑run | Repeat step 4 |
