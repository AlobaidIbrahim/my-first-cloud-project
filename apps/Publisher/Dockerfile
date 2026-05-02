FROM python:3.11.9-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN adduser --disabled-password --gecos "" appuser
USER appuser

EXPOSE 80
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "4", "app:app"]