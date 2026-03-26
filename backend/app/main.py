from __future__ import annotations

import sys
from pathlib import Path

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastf1 import Cache
from contextlib import asynccontextmanager

from app.api.routes_auth import router as auth_router
from app.api.routes_data import router as data_router
from app.api.routes_chat import router as chat_router

# ✅ import your loader + store (adjust these imports to your project)
from app.services.fastf1_loader import FastF1Loader
from app.services.cache_store import CacheStore# <-- rename if your store class/module differs
import re
from fastapi import HTTPException
import asyncio

# Ensure required directories exist
Path("./fastf1_cache").mkdir(parents=True, exist_ok=True)
Path("./data_cache").mkdir(parents=True, exist_ok=True)

# Enable FastF1 cache
Cache.enable_cache("./fastf1_cache")

# ✅ Create store + loader
store = CacheStore("./data_cache")
loader = FastF1Loader(store=store, fastf1_cache_dir="./fastf1_cache")

# Most recent GP with full data
CURRENT_SEASON = 2026
CURRENT_ROUND = 1
CURRENT_SESSION = "Race"

async def precache_sessions():
    """Pre-cache current/latest session on startup."""
    print("Pre-caching sessions...")
    sessions_to_cache = [
        (CURRENT_SEASON, CURRENT_ROUND, CURRENT_SESSION),
        (CURRENT_SEASON, 1, "Qualifying"),
        (CURRENT_SEASON, 1, "Practice 3"),
        (CURRENT_SEASON, 1, "Practice 2"),
        (CURRENT_SEASON, 1, "Practice 1"),
    ]
    for season, round_no, session in sessions_to_cache:
        try:
            cache_id = store.find_full(season, round_no, session)
            if not cache_id:
                print(f"  Pre-caching {season} R{round_no} {session}...")
                loader.load_and_cache_full(season, round_no, session)
                print(f"  Done: {season} R{round_no} {session}")
        except Exception as e:
            print(f"  Skipped {season} R{round_no} {session}: {e}")
    print("Pre-caching complete!")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Skip pre-caching on HuggingFace
    # Data will be loaded on-demand when users request it
    yield

# Create app
app = FastAPI(title="F1 Dash API", version="0.1.0", lifespan=lifespan)

# CORS (dev-friendly)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth_router)
app.include_router(data_router)
app.include_router(chat_router)

@app.get("/")
def root():
    return {"name": "F1 Dash API", "ok": True}

@app.get("/health")
def health():
    return {"ok": True}

# ✅ NEW: schedule endpoint
@app.get("/schedule")
def get_schedule(season: int = Query(..., ge=1950, le=2100)):
    try:
        return JSONResponse(content=loader.get_event_schedule(season))
    except Exception as e:
        print(f"[ERROR] Schedule failed: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        fallback = {
            "season": season,
            "events": [
                {"round": 1, "event_name": "Bahrain Grand Prix", "country": "Bahrain", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
                {"round": 2, "event_name": "Saudi Arabian Grand Prix", "country": "Saudi Arabia", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            ]
        }
        return JSONResponse(content=fallback)

# Get current/latest session
@app.get("/api/current")
def get_current_session():
    """Returns the current/most recent session to load by default."""
    return {
        "season": CURRENT_SEASON,
        "round": CURRENT_ROUND,
        "session": CURRENT_SESSION,
    }

@app.get("/api/cache_id")
def api_cache_id(
    season: int = Query(..., ge=1950, le=2100),
    round: int = Query(..., ge=1, le=99),
    session: str = Query("R"),
):
    """
    Returns cache_id like: 2025-24-r
    Usage:
      /api/cache_id?season=2025&round=24&session=R
    """
    s = (session or "R").strip().lower()
    s = re.sub(r"[^a-z0-9]+", "", s)
    if not s:
        s = "r"
    cache_id = f"{season}-{round}-{s}"
    return {"cache_id": cache_id}

@app.post("/api/session/load")
def load_session(
    season: int = Query(..., ge=1950, le=2100),
    round: int = Query(..., ge=1, le=99),
    session: str = Query("R"),
):
    """
    Loads session data via FastF1Loader.load_and_cache_full(...) and returns cache_id.
    """
    cache_id = f"{season}-{round}-{(session or 'R').strip().lower()}"

    try:
        # This should download/build everything and cache it in your CacheStore
        # (based on the method name you have)
        loader.load_and_cache_full(season=season, round=round, session=session)
    except TypeError:
        # In case your signature is positional or uses different param names
        try:
            loader.load_and_cache_full(season, round, session)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"load_and_cache_full failed: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"load_and_cache_full failed: {e}")

    return {"ok": True, "cache_id": cache_id}

@app.get("/api/store/keys")
def store_keys():
    # adjust based on your CacheStore API
    if hasattr(store, "keys"):
        return {"keys": store.keys()}
    return {"detail": "CacheStore has no keys() method"}

@app.post("/api/warmup")
def warmup(season: int = Query(2026), round: int = Query(1), session: str = Query("R")):
    """Pre-load a specific session into cache."""
    cache_id = f"{season}-{round}-{session.strip().lower()}"
    try:
        existing = store.find_full(season, round, session)
        if existing:
            return {"ok": True, "cache_id": existing, "cached": True}
        loader.load_and_cache_full(season, round, session)
        return {"ok": True, "cache_id": cache_id, "cached": False}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))