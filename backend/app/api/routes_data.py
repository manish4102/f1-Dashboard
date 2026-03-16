from __future__ import annotations

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.cache_store import CacheStore
from app.services.fastf1_loader import FastF1Loader

router = APIRouter()

store = CacheStore("./data_cache")
loader = FastF1Loader(store, fastf1_cache_dir="./fastf1_cache")


class LoadSessionRequest(BaseModel):
    season: int
    round: int
    session_name: str


@router.post("/load-session")
def load_session(req: LoadSessionRequest):
    try:
        cache_id = loader.load_and_cache_full(req.season, req.round, req.session_name)
        return {"cache_id": cache_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/session/{cache_id}/full")
def get_full(cache_id: str):
    try:
        payload = store.read_full(cache_id)
        return payload
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Unknown cache_id: {cache_id}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/session/{cache_id}/replay/frames")
def replay_frames(cache_id: str):
    try:
        payload = store.read_full(cache_id)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Unknown cache_id: {cache_id}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    # If your full payload already contains replay frames
    replay = payload.get("replay")

    if replay:
        return {"replay": replay}

    # Otherwise build replay from stored session data
    # (depends on how load_and_cache_full structures payload)

    raise HTTPException(
        status_code=404,
        detail=f"No replay data available in full payload for {cache_id}",
    )