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

# Most recent GP with full data (2025 Abu Dhabi GP)
CURRENT_SEASON = 2025
CURRENT_ROUND = 24
CURRENT_SESSION = "Race"

def precache_sessions_sync():
    """Pre-cache sessions synchronously (called during startup)."""
    print("Pre-caching sessions...")
    sessions_to_cache = [
        (2025, 24, "Race"),
        (2025, 24, "Qualifying"),
        (2025, 23, "Race"),
        (2025, 1, "Race"),
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
    precache_sessions_sync()
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

# Debug endpoint
@app.get("/debug/schedule")
def debug_schedule(season: int = Query(2025)):
    return {
        "season": season,
        "events": [
            {"round": 1, "event_name": "Bahrain Grand Prix", "country": "Bahrain", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
        ]
    }

# ✅ NEW: schedule endpoint
@app.get("/schedule")
def get_schedule(season: int = Query(..., ge=1950, le=2100)):
    # Return full 2025 calendar directly (FastF1 API is unreliable on HuggingFace)
    return JSONResponse(content={
        "season": season,
        "events": [
            {"round": 1, "event_name": "Bahrain Grand Prix", "country": "Bahrain", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 2, "event_name": "Saudi Arabian Grand Prix", "country": "Saudi Arabia", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 3, "event_name": "Australian Grand Prix", "country": "Australia", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 4, "event_name": "Japanese Grand Prix", "country": "Japan", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 5, "event_name": "Chinese Grand Prix", "country": "China", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 6, "event_name": "Miami Grand Prix", "country": "United States", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 7, "event_name": "Emilia Romagna Grand Prix", "country": "Italy", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 8, "event_name": "Monaco Grand Prix", "country": "Monaco", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 9, "event_name": "Canadian Grand Prix", "country": "Canada", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 10, "event_name": "Spanish Grand Prix", "country": "Spain", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 11, "event_name": "Austrian Grand Prix", "country": "Austria", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 12, "event_name": "British Grand Prix", "country": "United Kingdom", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 13, "event_name": "Belgian Grand Prix", "country": "Belgium", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 14, "event_name": "Hungarian Grand Prix", "country": "Hungary", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 15, "event_name": "Dutch Grand Prix", "country": "Netherlands", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 16, "event_name": "Italian Grand Prix", "country": "Italy", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 17, "event_name": "Azerbaijan Grand Prix", "country": "Azerbaijan", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 18, "event_name": "Singapore Grand Prix", "country": "Singapore", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 19, "event_name": "United States Grand Prix", "country": "United States", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 20, "event_name": "Mexico City Grand Prix", "country": "Mexico", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 21, "event_name": "São Paulo Grand Prix", "country": "Brazil", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 22, "event_name": "Las Vegas Grand Prix", "country": "United States", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 23, "event_name": "Qatar Grand Prix", "country": "Qatar", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
            {"round": 24, "event_name": "Abu Dhabi Grand Prix", "country": "United Arab Emirates", "sessions": [{"name": "Race"}, {"name": "Qualifying"}, {"name": "Practice 1"}, {"name": "Practice 2"}, {"name": "Practice 3"}]},
        ]
    })

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