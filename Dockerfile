FROM python:3.11-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY send_events_to_kafka.py .

# يجعل الطباعة تظهر فورًا في الـ logs
ENV PYTHONUNBUFFERED=1

CMD ["python", "send_events_to_kafka.py"]
