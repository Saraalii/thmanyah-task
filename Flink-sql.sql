CREATE TABLE content (
  id             STRING,
  slug           STRING,
  title          STRING,
  content_type   STRING,
  length_seconds INT,
  publish_ts     TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector'  = 'jdbc',
  'url'        = 'jdbc:postgresql://postgres:5432/thmanyah_db',
  'table-name' = 'content',
  'username'   = 'thmanyah',
  'password'   = 'thmanyah123'
);


CREATE TABLE engagement_events (
  id           BIGINT,
  content_id   STRING,
  user_id      STRING,
  event_type   STRING,
  event_ts     TIMESTAMP(3),
  duration_ms  INT,
  device       STRING,
  raw_payload  STRING,
  WATERMARK FOR event_ts AS event_ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka',
  'topic'     = 'engagements',
  'properties.bootstrap.servers' = 'kafka:9092',
  'format'    = 'json',
  'scan.startup.mode' = 'earliest-offset'
);



DROP TABLE IF EXISTS processed_engagements;


CREATE TABLE processed_engagements (
  content_id         STRING,
  user_id            STRING,
  event_type         STRING,
  engagement_seconds DOUBLE,
  engagement_pct     DOUBLE,
  PRIMARY KEY (content_id, user_id, event_type) NOT ENFORCED
) WITH (
  'connector'                    = 'upsert-kafka',
  'topic'                        = 'processed_engagements',
  'properties.bootstrap.servers' = 'kafka:9092',
  'key.format'                   = 'json',
  'value.format'                 = 'json'
);


INSERT INTO processed_engagements
SELECT
    e.content_id,
    e.user_id,
    e.event_type,
    e.duration_ms / 1000.0                                           AS engagement_seconds,
    CASE
        WHEN c.length_seconds IS NULL OR e.duration_ms IS NULL
             THEN NULL
        ELSE (e.duration_ms / 1000.0) / c.length_seconds
    END                                                              AS engagement_pct
FROM engagement_events e
LEFT JOIN content c
ON e.content_id = c.id;
