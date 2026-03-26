FROM python:3.11-slim

WORKDIR /app

# Force rebuild timestamp: 2026-03-26
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./backend/
COPY app.py ./

ENV PYTHONUNBUFFERED=1
ENV GEMINI_API_KEY=${GEMINI_API_KEY}

EXPOSE 7860

CMD ["python", "app.py"]