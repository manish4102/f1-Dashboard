
---

## `BACKLOG.md`
```md
# Backlog

## ML Predictions (future hook)
- Feature flag gated tab: "Predictions (ML)"
- Backend:
  - `GET /ml/predict/{cache_id}` -> currently returns {"enabled":false,"message":"not enabled"}
- Future tasks:
  - Build feature pipeline from `full.json` raw fields
  - Train offline models (pace, tyre deg, pit stop likelihood)
  - Add versioned model registry and prediction schema
  - Add caching layer for predictions keyed by cache_id + model_version

## AI (RAG) (future hook)
- Feature flag gated tab: "AI (RAG)"
- Backend:
  - `POST /rag/query` -> currently returns {"enabled":false,"message":"not enabled"}
- Future tasks:
  - Ingest historical races + rules + team radio transcripts (where legal)
  - Vector store integration (local first)
  - Prompt templates and toolformer-style retrieval
  - Ensure no breaking changes: extend `full.json.raw.*` for indexed fields

## Replay enhancements
- Improve track polyline from circuit data when available
- Gap to ahead/behind using timing data per frame
- Better interpolation (spline) and camera follow mode
- Multi-driver selection (left panels) with drag/drop

## Data endpoints
- Add (optional) lightweight endpoints:
  - /leaderboard /podium-fastestlap /lapchart /tyrestrategy
  - Mostly for debugging; keep frontend primarily on /full

## UX
- Saved “recent sessions”
- Remember last dropdown selections
- Loading skeletons & error recovery