# F1 Dashboard + Race Replay (FastAPI + Flutter)

A dark, compact, "F1-style" dashboard with:
- Auth (Login / Signup + dev bypass)
- Session load-once caching (FastF1 cache + disk JSON cache)
- 4 tabs: Overview, Lap Charts, Tyre Strategy, Race Replay
- Replay frames via HTTP + optional WebSocket streamer

---

## HuggingFace Spaces Deployment

This app is deployed on HuggingFace Spaces with the Python API backend.

## Local Development

### 1) Run backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2) Run Flutter

```bash
cd frontend
flutter run -d chrome
```

## Environment Variables

- `GEMINI_API_KEY` - Required for AI chat feature