# Python 3.12 - offizielles schlankes Image
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ /app/

EXPOSE 8000
CMD ["python", "app.py"]
