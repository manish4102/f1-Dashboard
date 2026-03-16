from __future__ import annotations

from typing import Optional, Dict

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["auth"])

# Simple in-memory user store (dev-friendly)
_USERS: Dict[str, Dict[str, str]] = {}  # email -> {"pw": password}


class SignupRequest(BaseModel):
    email: str = ""
    password: str = ""
    confirm_password: Optional[str] = None  # optional, frontend may send it


class LoginRequest(BaseModel):
    email: str = ""
    password: str = ""


class AuthResponse(BaseModel):
    # Keep token field because frontend expects it.
    # We DO NOT enforce it anywhere.
    token: str


@router.post("/dev-login", response_model=AuthResponse)
def dev_login():
    return AuthResponse(token="dev")


@router.post("/signup", response_model=AuthResponse)
def signup(req: SignupRequest):
    email = (req.email or "").strip().lower()
    password = req.password or ""

    # Dev bypass: empty fields => proceed
    if not email or not password:
        return AuthResponse(token="dev")

    # Create if not exists; if exists, still OK
    _USERS.setdefault(email, {"pw": password})
    return AuthResponse(token="dev")


@router.post("/login", response_model=AuthResponse)
def login(req: LoginRequest):
    email = (req.email or "").strip().lower()
    password = req.password or ""

    # Dev bypass: empty fields => proceed
    if not email or not password:
        return AuthResponse(token="dev")

    # Dev-friendly behavior: auto-create if missing
    if email not in _USERS:
        _USERS[email] = {"pw": password}
        return AuthResponse(token="dev")

    # If exists, do not block on password mismatch (dev-friendly)
    return AuthResponse(token="dev")


# --------------------------------------------------------------------
# IMPORTANT: routes_data imports this; we keep it as a NO-OP.
# --------------------------------------------------------------------
def require_auth():
    return {"user": "dev"}
