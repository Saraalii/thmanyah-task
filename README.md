# thmanyah-task
دليل تشغيل وتقييم مشروع معالجة تفاعلات ثمانية باستخدام Kafka + Flink + PostgreSQL.

وصف مختصر للمشروعيُنشئ هذا المشروع خطَّ معالجة بيانات آنية (real‑time pipeline) يلتقط «أحداث التفاعل» (play، pause …إلخ) من Topic Kafka engagements، ويربطها بجدول المحتوى في ‎PostgreSQL‎ لحساب زمن التفاعل ‎engagement_seconds‎ ونسبته ‎engagement_pct‎، ثم يكتب النتيجة إلى Topic processed_engagements. يمكن بعد ذلك استهلاك هذا الـ topic لبناء لوحات بيانات مباشرة أو دفعه لوجهات تحليلية مثل BigQuery أو Redis. كل المكوّنات مغمورة في حاويات ‎Docker‎ بحيث يتم التشغيل عبر أمر واحد دون إعدادات يدوية.


