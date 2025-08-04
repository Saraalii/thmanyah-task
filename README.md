# مشروع ثمانية - thmanyah-task

نظام متكامل لمعالجة بيانات التفاعل (Engagement Events) في الوقت الحقيقي باستخدام تقنيات حديثة تشمل Kafka وFlink SQL وPostgreSQL، ومبني بالكامل باستخدام Docker لتسهيل التشغيل والنشر.

```
Kafka → Flink SQL (joins + metrics) → Kafka
           ↑                       ↓
     PostgreSQL (content dim)   (optional) Redis / BigQuery
```

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
CREATE TABLE engagement_events (...);

-- جدول PostgreSQL للأبعاد
CREATE TABLE content_dim (...);

-- جدول Kafka للإخراج التحليلي
CREATE TABLE processed_engagements (...);

-- استعلام التحليل
INSERT INTO processed_engagements
SELECT ...
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
