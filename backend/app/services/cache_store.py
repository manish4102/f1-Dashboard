from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Optional, Dict
from functools import lru_cache


class CacheStore:
    """
    File-based cache for full session payloads with in-memory LRU cache.
    Ensures payloads are JSON-compliant (no NaN/Infinity).
    """

    def __init__(self, base_dir: str = "./data_cache"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self._memory_cache: Dict[str, Any] = {}
        self._max_memory_items = 20

    def _full_path(self, season: int, round_no: int, session_name: str) -> Path:
        key = f"{int(season)}-{int(round_no)}-{str(session_name).strip().lower()}"
        return self.base_dir / f"{key}.full.json"

    def find_full(self, season: int, round_no: int, session_name: str) -> Optional[str]:
        p = self._full_path(season, round_no, session_name)
        if p.exists():
            return f"{int(season)}-{int(round_no)}-{str(session_name).strip().lower()}"
        return None

    def write_full(self, season: int, round_no: int, session_name: str, payload: Any) -> str:
        cache_id = f"{int(season)}-{int(round_no)}-{str(session_name).strip().lower()}"
        p = self._full_path(season, round_no, session_name)

        # Ensure JSON-compliant: replace NaN/Inf with null
        payload = _sanitize_nan_inf(payload)

        # Write strict JSON (this will raise if something sneaks through)
        text = json.dumps(payload, ensure_ascii=False, allow_nan=False)
        p.write_text(text, encoding="utf-8")

        # Also cache in memory
        if len(self._memory_cache) >= self._max_memory_items:
            self._memory_cache.pop(next(iter(self._memory_cache)))
        self._memory_cache[cache_id] = payload

        return cache_id

    def read_full(self, cache_id: str) -> Any:
        """
        Reads a cached payload from memory or disk.
        Also fixes older cache files that contain NaN/Infinity tokens.
        """
        if cache_id in self._memory_cache:
            return self._memory_cache[cache_id]

        p = self.base_dir / f"{cache_id}.full.json"
        if not p.exists():
            raise FileNotFoundError(f"Cache not found: {cache_id}")

        raw = p.read_text(encoding="utf-8")

        # Old files might contain bare NaN/Infinity tokens (not valid JSON).
        # Convert them to null before parsing.
        raw = _replace_non_json_numbers(raw)

        data = json.loads(raw)

        # Sanitize and cache in memory
        data = _sanitize_nan_inf(data)

        if len(self._memory_cache) >= self._max_memory_items:
            self._memory_cache.pop(next(iter(self._memory_cache)))
        self._memory_cache[cache_id] = data

        return data

    def keys(self):
        return [p.stem.replace(".full", "") for p in self.base_dir.glob("*.full.json")]


_NON_JSON_NUMBER_RE = re.compile(r'(?<!")\b(NaN|Infinity|-Infinity)\b(?!")')


def _replace_non_json_numbers(s: str) -> str:
    return _NON_JSON_NUMBER_RE.sub("null", s)


def _sanitize_nan_inf(obj: Any) -> Any:
    """
    Walk any nested dict/list and replace float NaN/Inf with None.
    """
    try:
        import math

        if isinstance(obj, float):
            if math.isnan(obj) or math.isinf(obj):
                return None
            return obj
    except Exception:
        pass

    # dict
    if isinstance(obj, dict):
        return {str(k): _sanitize_nan_inf(v) for k, v in obj.items()}

    # list/tuple
    if isinstance(obj, (list, tuple)):
        return [_sanitize_nan_inf(v) for v in obj]

    return obj