# مشروع ثمانية - thmanyah-task

نظام متكامل لمعالجة بيانات التفاعل (Engagement Events) في الوقت الحقيقي باستخدام تقنيات حديثة تشمل Kafka وFlink SQL وPostgreSQL، ومبني بالكامل باستخدام Docker لتسهيل التشغيل والنشر.

الفكرة باختصار
نُنشئ خطّ معالجة بيانات لحظي (Real-Time Pipeline) يلتقط أحداث تفاعل المستخدمين من Kafka، ويُثريها بمعلومات المحتوى من PostgreSQL عبر Flink SQL، ثم يحسب :

| الوصف      | الحقل         | 
|--------------|--------------------|
| ‎duration_ms / 1000‎ → عدد الثواني الفعليّة للتفاعل   | engagement_seconds   | 
| ‎engagement_seconds / length_seconds * 100‎ (بدقّة منزلتين)        | engagement_pct	           |

وتُكتب النتيجة في موضوع Kafka آخر اسمه processed_engagements.
جميع الخدمات (Kafka + Zookeeper + Postgres + Flink) تُشغَّل في Docker Compose.

## مخطّط المكوّنات

```text
┌────────────┐      raw events       ┌───────────┐   enriched stream   ┌────────────────┐
│  Producer  │  ───────────────────> │  Kafka     │ ──────────────────> │  Flink Job     │
│  (Python)  │   topic: engagements  │  Broker    │  topic: processed_ │  (SQL pipeline)│
└────────────┘                       └───────────┘     engagements     └──┬──────────────┘
                                        ▲                                │lookup
                                        │                                │
                               ┌────────┴──────┐                         │
                               │ PostgreSQL    │  content dimension     │
                               │  table:       │<───────────────────────┘
                               │   content     │
                               └───────────────┘

```

تم تنفيذ المشروع بدءًا من إعداد PostgreSQL ومرورًا بـ Flink وPython ,Kafka حتى تم بناء الجدول النهائي عبر Flink SQL.
واجهت تحديًا في متابعة مهام Flink داخل الواجهة الرسومية (Flink UI)، وبسبب ضيق الوقت لم أتمكن من حل هذه النقطة حتى الآن.
لكني أواصل العمل على فهمها؛ لأن الهدف الأساسي من المشروع هو التعلم العميق، وليس فقط إنجاز المهمة.
شرف المحاولة يكفي بالنسبه لي 💪.


```
Kafka → Flink SQL (joins + metrics) → Kafka
           ↑                       ↓
     PostgreSQL (content dim)   (optional) Redis / BigQuery
```
| Service      | URL / Port         | Notes                                |
|--------------|--------------------|--------------------------------------|
| PostgreSQL   | `localhost:5432`   | User: `thmanyah`, Password: `thmanyah123` |
| Kafka        | `localhost:9092`   | Kafka broker                         |
| Flink UI     | http://localhost:8081 | Flink SQL Client Dashboard         |

---
## نظرة عامة على البنية

| الطبقة                  | الغرض                            | الصورة/الإصدار                  |
|------------------------|----------------------------------|---------------------------------|
| **PostgreSQL 15**      | تخزين جدول الأبعاد `content`     | `postgres:15`                  |
| **Kafka 7.5.3**        | استقبال وإرسال الأحداث           | `confluentinc/cp-kafka:7.5.3`  |
| **Flink 1.17.1**       | تشغيل الاستعلامات التحليلية     | `flink:1.17.1`                 |
| **Docker Compose**     | إدارة جميع الخدمات               |                                 |

## ما الذي يقدمه المشروع؟

- **استخراج البيانات**: يتم أخذ بيانات التفاعل من قاعدة PostgreSQL.
- **معالجة البيانات**: استخدام Flink SQL لتحليل البيانات، احتساب مدة التفاعل ونسبة التفاعل.
- **نشر البيانات**: إرسال النتائج إلى Kafka لمزيد من الاستخدام أو التخزين الخارجي.

## المراحل المنفذة ✅

- تشغيل الخدمات باستخدام `docker compose`
- تحميل البيانات الأولية في PostgreSQL (جدولي `content` و`engagement_events`)
- إضافة الـ Connectors الخاصة بـ Kafka وPostgres إلى Flink
- تعريف الجداول داخل Flink: مصادر Kafka، جداول الأبعاد، ومخارج Kafka
- تشغيل استعلام Flink الرئيسي لإنتاج بيانات تحليلية جاهزة

## خطوات البدء

1. **تثبيت المتطلبات**
```bash
brew install docker
pip install psycopg2-binary kafka-python
```

2. **تشغيل المشروع**
```bash
git clone https://github.com/Saraalii/thmanyah-task.git
cd thmanyah-task
docker compose up -d
```

3. **إضافة مكتبات الربط (Connectors) لـ Flink**
```bash
mkdir -p flink-jars
# Kafka
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.17.1/flink-connector-kafka-1.17.1.jar
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.4.0/kafka-clients-3.4.0.jar
# JDBC + Postgres
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.1.2-1.17/flink-connector-jdbc-3.1.2-1.17.jar
wget -P flink-jars https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

docker compose down && docker compose up -d
```

4. **تحميل البيانات في PostgreSQL**
```bash
docker exec -it thmanyah-task-postgres-1 psql -U thmanyah -d thmanyah_db -f /Query.sql
```

5. **فتح Flink SQL Client**
```bash
docker compose exec flink-jobmanager ./bin/sql-client.sh
```

6. **إنشاء الجداول داخل Flink**
```sql
-- جدول Kafka للقراءة
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


-- ستظهر رسالة INSERT INTO ... submitted successfully, JobID: XXXXX

```

**7. تجربة حدث**
```

echo '{"id":"1",
       "content_id":"11111111-1111-1111-1111-111111111111",
       "user_id":"u-1",
       "event_type":"play",
       "event_ts":"2025-08-10T09:25:00Z",
       "duration_ms":60000,
       "device":"ios",
       "raw_payload":{}}' | \
docker exec -i thmanyah-task-kafka-1 \
kafka-console-producer --bootstrap-server kafka:9092 --topic engagements
```

**8. التحقق**
```
-- التحقق من المخرجات

docker exec -it thmanyah-task-kafka-1 \
kafka-console-consumer --bootstrap-server kafka:9092 \
--topic processed_engagements --from-beginning
 --المفترض ترى مثل هذا
{"content_id":"1111…","user_id":"u-1","event_type":"play",
 "engagement_seconds":60,"engagement_pct":33.33}


```




## الأخطاء الشائعة وطريقة حلها

| الخطأ                                      | السبب المحتمل                             | الحل                             |
|-------------------------------------------|--------------------------------------------|----------------------------------|
| Flink لا يتعرف على Kafka                  | لم يتم إضافة JARs إلى `/opt/flink/lib`    | تحقق من مجلد `flink-jars/`      |
| فشل إنشاء الجداول أو التنفيذ              | اختلاف في أنواع البيانات أو الأسماء       | راجع تعاريف الجداول والاستعلامات |
| "relation does not exist" في PostgreSQL    | لم يتم تحميل البيانات بعد                 | نفّذ `docker exec ... /Query.sql` |

## المهام المستقبلية (TODO)

- إصلاح مشكلة UUID وتحويله لنوع متوافق مع Flink
- إضافة Redis لتوفير نتائج سريعة لـ Dashboards
- دمج BigQuery لتحليلات أكثر تعمقًا

---

© 2025 Thmanyah – مشروع تدريبي في هندسة البيانات
