from __future__ import annotations

import os
from typing import Optional

from fastapi import Header, HTTPException
import jwt


def _secret() -> str:
    return os.getenv(
        "SECRET_KEY",
        "super_dev_secret_key_change_me_1234567890_abcdef_1234567890",
    )


def require_auth(authorization: Optional[str] = Header(default=None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing token")

    token = authorization.split(" ", 1)[1].strip()
    try:
        payload = jwt.decode(token, _secret(), algorithms=["HS256"])
        return payload
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")