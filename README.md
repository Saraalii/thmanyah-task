# thmanyah‑task

A self‑contained **real‑time data pipeline** that turns raw user‑engagement events into enriched analytics streams, all in Docker.

```
Kafka → Flink SQL (joins + metrics) → Kafka
           ↑                       ↓
     PostgreSQL (content dim)   (optional) Redis / BigQuery
```

* **PostgreSQL 15** — content dimension table (`content`)
* **Kafka 7.5.3**    — raw (`engagements`) & processed (`processed_engagements`) event topics
* **Flink 1.17.1**   — streaming job written in pure Flink SQL
* **Docker Compose** — one‑liner spin‑up on any laptop

---

## 1  Architecture at a glance

| Layer                           | Purpose                             | Image / Tag                   |
| ------------------------------- | ----------------------------------- | ----------------------------- |
| **Postgres**                    | Lookup metadata (content catalogue) | `postgres:15`                 |
| **Kafka**                       | Source + sink event buses           | `confluentinc/cp‑kafka:7.5.3` |
| **Flink**                       | Stateful streaming job              | `flink:1.17.1`                |
| **(Optional) Redis / BigQuery** | Serve dashboards & heavy BI         | *add later*                   |

---

## 2  Where we are now  🚦

| Milestone                              | Status                    | Notes                                                       |
| -------------------------------------- | ------------------------- | ----------------------------------------------------------- |
| Stack boots via `docker compose up -d` | ✅                         | Kafka, Flink, Postgres all healthy                          |
| Postgres seeded (`Query.sql`)          | ✅                         | `content` rows loaded                                       |
| Flink connectors jarred                | ✅                         | Added Kafka & JDBC drivers under `flink-jars/`              |
| Flink tables created                   | ✅                         | `engagement_events`, `content_dim`, `processed_engagements` |
| Main `INSERT` job submitted            | **🟡 Failed / Iterating** | Type‑casting edge‑case (UUID➞STRING) caused *FAILED* state  |
| Extra sinks (Redis / BigQuery)         | ⏩                         | Out‑of‑scope for current sprint                             |

---

## 3  Quick‑start (copy‑paste friendly)

### 3.0  Prerequisites

```bash
# docker + compose
brew install docker
# local helpers
pip install psycopg2‑binary kafka‑python
```

### 3.1  Clone & Launch

```bash
git clone <repo‑url>
cd thmanyah‑task
docker compose up -d    # ~30 sec
```

### 3.2  Add Flink connectors (one‑time)

```bash
mkdir -p flink-jars
# Kafka connector & client
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.17.1/flink-connector-kafka-1.17.1.jar
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.4.0/kafka-clients-3.4.0.jar
# JDBC connector & Postgres driver
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.1.2-1.17/flink-connector-jdbc-3.1.2-1.17.jar
wget -P flink-jars https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

docker compose down && docker compose up -d   # reload JARs
```

### 3.3  Seed Postgres

```bash
# loads both `content` and an initial slice of `engagement_events`
docker exec -it thmanyah-task-postgres-1 psql -U thmanyah -d thmanyah_db -f /Query.sql
```

### 3.4  Create Flink objects & start job

```bash
# open Flink SQL CLI
docker compose exec flink-jobmanager ./bin/sql-client.sh

-- 1️⃣ Kafka source\CREATE TABLE engagement_events (
  id BIGINT,
  content_id STRING,
  user_id STRING,
  event_type STRING,
  event_ts TIMESTAMP_LTZ(3),
  duration_ms INT,
  device STRING,
  raw_payload MAP<STRING,STRING>,
  WATERMARK FOR event_ts AS event_ts - INTERVAL '5' SECOND
) WITH (
  'connector'='kafka',
  'topic'='engagements',
  'properties.bootstrap.servers'='kafka:9092',
  'scan.startup.mode'='earliest-offset',
  'format'='json'
);

-- 2️⃣ JDBC lookup view (content)
CREATE TABLE content_dim (
  id STRING,
  slug STRING,
  title STRING,
  content_type STRING,
  length_seconds INT,
  publish_ts TIMESTAMP(3)
) WITH (
  'connector'='jdbc',
  'url'='jdbc:postgresql://postgres:5432/thmanyah_db',
  'table-name'='content',
  'username'='thmanyah',
  'password'='thmanyah123',
  'driver'='org.postgresql.Driver'
);

-- 3️⃣ Upsert sink for metrics
CREATE TABLE processed_engagements (
  content_id STRING,
  user_id STRING,
  event_type STRING,
  engagement_seconds DOUBLE,
  engagement_pct DOUBLE,
  PRIMARY KEY (content_id, user_id, event_ts) NOT ENFORCED
) WITH (
  'connector'='kafka',
  'topic'='processed_engagements',
  'properties.bootstrap.servers'='kafka:9092',
  'format'='json'
);

-- 4️⃣ ETL query (streaming)
INSERT INTO processed_engagements
SELECT
  e.content_id,
  e.user_id,
  e.event_type,
  e.duration_ms / 1000.0                      AS engagement_seconds,
  CASE
    WHEN c.length_seconds > 0 THEN ROUND((e.duration_ms / 1000.0) / c.length_seconds * 100, 2)
    ELSE NULL
  END AS engagement_pct
FROM engagement_events e
LEFT JOIN content_dim FOR SYSTEM_TIME AS OF e.event_ts AS c
ON e.content_id = c.id;
```

`INSERT` success prints a Job ID—verify on `http://localhost:8081`.

### 3.5  Emit / Verify a test event

---

## 4  Troubleshooting Cheatsheet

| ☠️ Error                                   | Root cause                                 | How to unblock                                                                    |
| ------------------------------------------ | ------------------------------------------ | --------------------------------------------------------------------------------- |
| `relation "content" does not exist`        | DB seed missed                             | Repeat *3.3*                                                                      |
| `java.lang.ClassCastException UUID→String` | Flink JDBC converts UUID → STRING manually | Add a `.cast(BINARY(16))` or store IDs as VARCHAR in Postgres                     |
| Job stuck in **FAILED** & UI empty         | Running in detached session                | `docker compose exec flink-jobmanager flink list -a` then `flink cancel <job-id>` |

---

## 5  Next steps (TODO)

1. Fix UUID type‑mismatch & re‑submit job
2. Add Redis sink for 5‑minute rolling top‑N view
3. Wire BigQuery batch backfill path

---

## 6  Contributing

PRs & issues welcome — this is a hiring take‑home, not production code, so any feedback is gold!

---

© 2025 Thmanyah – Data Engineering Exercise
