from __future__ import annotations

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
    """Pre-cache current/latest session on startup if cache is empty."""
    import os
    is_production = os.getenv("RENDER") or os.getenv("PORT")
    
    if is_production:
        # On Render, do light background caching after startup
        await asyncio.sleep(10)
        print("Light background pre-caching...")
        try:
            has_cache = store.find_full(CURRENT_SEASON, CURRENT_ROUND, CURRENT_SESSION)
            if not has_cache:
                print(f"  Loading GP: {CURRENT_SEASON}-{CURRENT_ROUND}-{CURRENT_SESSION}")
                loader.load_and_cache_full(CURRENT_SEASON, CURRENT_ROUND, CURRENT_SESSION)
                print(f"  Background cache done!")
        except Exception as e:
            print(f"  Background cache failed: {e}")
    else:
        print("Checking cache...")
        has_cache = store.find_full(CURRENT_SEASON, CURRENT_ROUND, CURRENT_SESSION)
        if has_cache:
            print(f"  Cache hit: {CURRENT_SEASON}-{CURRENT_ROUND}-{CURRENT_SESSION}")
            return
        print(f"  Cache empty. Loading latest GP: {CURRENT_SEASON}-{CURRENT_ROUND}-{CURRENT_SESSION}...")
        try:
            loader.load_and_cache_full(CURRENT_SEASON, CURRENT_ROUND, CURRENT_SESSION)
            print(f"  Cached: {CURRENT_SEASON}-{CURRENT_ROUND}-{CURRENT_SESSION}")
        except Exception as e:
            print(f"  Failed to cache: {e}")
        print("Pre-caching complete!")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start pre-caching in background (non-blocking)
    try:
        asyncio.create_task(precache_sessions())
    except Exception:
        pass
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
    return JSONResponse(content=loader.get_event_schedule(season))

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