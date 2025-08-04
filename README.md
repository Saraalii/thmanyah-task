
# مشروع ثمانية 🧠📊

نظام متكامل لمعالجة بيانات التفاعل (engagement) في الزمن الحقيقي، باستخدام أدوات حديثة مثل Kafka وFlink وPostgreSQL، داخل بيئة Docker.

## ⚙️ المعمارية

```
Kafka → Flink SQL (تحويل وتحليل) → Kafka
           ↑                       ↓
     PostgreSQL (بيانات المحتوى)   (اختياري) Redis / BigQuery
```

| الطبقة            | الوظيفة                            | النسخة                     |
|------------------|-------------------------------------|-----------------------------|
| PostgreSQL       | جدول المحتوى `content`              | `postgres:15`              |
| Kafka            | مواضيع البيانات الخام والمعالجة     | `confluentinc/cp-kafka:7.5.3` |
| Flink SQL        | تنفيذ المعالجة اللحظية              | `flink:1.17.1`             |
| Docker Compose   | تشغيل جميع الخدمات بضغطة واحدة      |                            |

## 🚦 حالة المشروع

- ✅ النظام يعمل بالكامل عبر `docker compose up`
- ✅ PostgreSQL يحتوي على بيانات أولية (content + engagement_events)
- ✅ تم تحميل ملفات الربط لـ Flink (Kafka + JDBC)
- ✅ إنشاء الجداول في Flink بنجاح
- 🟡 عملية `INSERT` قيد التجربة تمت بنجاح ولكن يوجد تحديات بظهورها على ال UI
- ⏩ Redis وBigQuery للمرحلة القادمة

## 🚀 خطوات التشغيل السريع

```bash
# 1. تثبيت Docker
brew install docker

# 2. استنساخ المشروع
git clone https://github.com/Saraalii/thmanyah-task
cd thmanyah-task

# 3. تشغيل الحاويات
docker compose up -d

# 4. تحميل JARs المطلوبة لفلك
mkdir -p flink-jars
# Kafka
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.17.1/flink-connector-kafka-1.17.1.jar
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.4.0/kafka-clients-3.4.0.jar
# JDBC + Postgres
wget -P flink-jars https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.1.2-1.17/flink-connector-jdbc-3.1.2-1.17.jar
wget -P flink-jars https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

# إعادة تشغيل Docker بعد إضافة الـ JARs
docker compose down && docker compose up -d

# 5. تحميل البيانات إلى PostgreSQL
docker exec -it thmanyah-task-postgres-1 psql -U thmanyah -d thmanyah_db -f /Query.sql

# 6. الدخول إلى Flink SQL Client
docker compose exec flink-jobmanager ./bin/sql-client.sh
```

## 🛠️ ملاحظات

- تأكد من أن ملفات الربط `flink-connector-kafka` موجودة داخل `/opt/flink/usrlib` داخل الحاوية.

---

© 2025 - مشروع تدريبي من تنفيذ Sara Bajaba
