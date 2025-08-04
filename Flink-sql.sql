
CREATE TABLE engagement_events (
    id            STRING,
    content_id    STRING,
    user_id       STRING,
    event_type    STRING,
    event_ts      TIMESTAMP(3),
    duration_ms   INT,
    device        STRING,
    raw_payload   MAP<STRING, STRING>,
    WATERMARK FOR event_ts AS event_ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'engagements',
  'properties.bootstrap.servers' = 'kafka:9092',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'json'
);


-- جدول PostgreSQL للأبعاد
CREATE TABLE content_dim (
    id             STRING,
    slug           STRING,
    title          STRING,
    content_type   STRING,
    length_seconds INT,
    publish_ts     TIMESTAMP(3)
) WITH (
  'connector' = 'jdbc',
  'url' = 'jdbc:postgresql://postgres:5432/thmanyah_db',
  'table-name' = 'content',
  'username' = 'thmanyah',
  'password' = 'thmanyah123',
  'driver' = 'org.postgresql.Driver'
);


-- جدول Kafka للإخراج التحليلي
INSERT INTO processed_engagements
SELECT
    e.content_id,
    e.user_id,
    e.event_type,
    CAST(e.duration_ms / 1000 AS INT)                      AS engagement_seconds,
    CASE
      WHEN c.length_seconds IS NOT NULL AND c.length_seconds > 0
      THEN ROUND( (e.duration_ms / 1000.0) / c.length_seconds * 100 , 2)
      ELSE NULL
    END                                                    AS engagement_pct
FROM engagement_events e
LEFT JOIN content_dim /* lookup */ FOR SYSTEM_TIME AS OF e.event_ts AS c
ON e.content_id = c.id;

-- استعلام التحليل
INSERT INTO processed_engagements
SELECT
    e.content_id,
    e.user_id,
    e.event_type,
    CAST(e.duration_ms / 1000 AS INT)                      AS engagement_seconds,
    CASE
      WHEN c.length_seconds IS NOT NULL AND c.length_seconds > 0
      THEN ROUND( (e.duration_ms / 1000.0) / c.length_seconds * 100 , 2)
      ELSE NULL
    END                                                    AS engagement_pct
FROM engagement_events e
LEFT JOIN content_dim /* lookup */ FOR SYSTEM_TIME AS OF e.event_ts AS c
ON e.content_id = c.id;
