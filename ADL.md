
---

## `ADL.md`
```md
# Architecture Decision Log (ADL)

## 1. Monorepo structure
**Decision:** Single repo with `backend/` (FastAPI) and `frontend/` (Flutter).
**Rationale:** Fast iteration, easy end-to-end integration.

---

## 2. Auth
**Decision:** Token-based auth with a simple signed token (JWT-like) and SQLite users.
- Endpoints:
  - `POST /auth/signup`
  - `POST /auth/login`
  - `POST /auth/dev-login`
- Token is sent in `Authorization: Bearer <token>` for all other endpoints.

**Rationale:** Real endpoints exist; dev bypass supported in UI and backend.

---

## 3. Load-once, reuse everywhere caching
**Decision:** Backend loads and precomputes a comprehensive dataset once, stores to disk:

`./data_cache/{season}/{round}/{session_name}/full.json`

- Load endpoint:
  - `POST /load-session {season, round, session_name} -> {cache_id}`
- Primary endpoint:
  - `GET /session/{cache_id}/full`

**Rationale:** Frontend expands without backend changes. Also supports offline-ish reuse.

---

## 4. Full payload contract (v1)
`GET /session/{cache_id}/full` returns:

```json
{
  "meta": {
    "cache_id": "2024-1-Race",
    "season": 2024,
    "round": 1,
    "session_name": "Race",
    "event_name": "Bahrain Grand Prix",
    "location": "Bahrain",
    "country": "Bahrain",
    "loaded_at": "ISO-8601",
    "laps_total": 57
  },
  "drivers": [
    {"code":"VER","number":"1","name":"Max Verstappen","color":"#E74C3C"}
  ],
  "overview": {
    "leaderboard": [
      {"pos":1,"code":"VER","gap":"Finished","status":"Finished"}
    ],
    "podium": [{"pos":1,"code":"VER"}, {"pos":2,"code":"PER"}, {"pos":3,"code":"ALO"}],
    "fastest_lap": {"code":"VER","lap":42,"time":"1:32.123","compound":"SOFT","tyre_age":8}
  },
  "lap_charts": {
    "laps": [1,2,3],
    "series": {
      "VER": {"lap_times_s":[92.1,91.9,92.3], "visible_default": true}
    }
  },
  "tyre_strategy": {
    "rows": [
      {
        "code":"VER",
        "stints":[{"compound":"SOFT","start_lap":1,"end_lap":15,"length":15}]
      }
    ]
  },
  "replay": {
    "track_polyline": [{"x":0.1,"y":0.2},{"x":0.12,"y":0.22}],
    "frames": [
      {
        "t_ms": 0,
        "lap": 1,
        "lap_progress": 0.02,
        "order": ["VER","PER","ALO"],
        "cars": {
          "VER": {"x":0.2,"y":0.3,"speed":312,"gear":8,"throttle":98,"drs":1}
        },
        "weather": {"air_temp": 24.1, "track_temp": 33.2, "humidity": 55, "wind_speed": 5.1, "rain": 0}
      }
    ],
    "frame_dt_ms": 200
  },
  "raw": {
    "session_results": [],
    "laps_sample": [],
    "notes": "Extra raw fields for future widgets"
  }
}