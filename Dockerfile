FROM python:3.11-slim

WORKDIR /app

COPY backend/ ./backend/
COPY requirements-huggingface.txt ./

RUN pip install -r requirements-huggingface.txt

ENV GEMINI_API_KEY=${GEMINI_API_KEY}

EXPOSE 7860

CMD ["uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "7860"]