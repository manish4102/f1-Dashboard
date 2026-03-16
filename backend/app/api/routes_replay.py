from fastapi import APIRouter, HTTPException
from pathlib import Path
import json

router = APIRouter()

@router.get("/session/{cache_id}/replay/frames")
def get_replay_frames(cache_id: str):
    """
    Returns replay data from cached full payload file:
      ./data_cache/{cache_id}.full.json

    If missing, returns 404 instead of silently returning {}.
    """
    cache_path = Path("./data_cache") / f"{cache_id}.full.json"
    if not cache_path.exists():
        # also try the common alternative name you have: "{cache_id}-race.full.json" etc.
        raise HTTPException(
            status_code=404,
            detail=f"Cache file not found for {cache_id}. Expected {cache_path.name}",
        )

    try:
        payload = json.loads(cache_path.read_text())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read cache file: {e}")

    # ✅ Your cached payload probably already contains replay OR enough data to build it.
    # If your loader stored replay frames under a key, return it.
    # Common patterns: payload["replay"], payload["replay_frames"], payload["frames"]
    replay = payload.get("replay") or {}
    if not replay:
        # If your full payload nests things, you can also try:
        # replay = payload.get("data", {}).get("replay", {}) ...
        replay = payload.get("replay_frames") or payload.get("frames") or {}

    if not replay:
        raise HTTPException(
            status_code=404,
            detail=f"No replay data inside cache file for {cache_id}",
        )

    return {"replay": replay}