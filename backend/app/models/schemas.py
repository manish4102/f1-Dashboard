from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List


class SignupRequest(BaseModel):
    email: str = Field(default="")
    password: str = Field(default="")


class LoginRequest(BaseModel):
    email: str = Field(default="")
    password: str = Field(default="")


class AuthResponse(BaseModel):
    token: str
    token_type: str = "bearer"


class LoadSessionRequest(BaseModel):
    season: int
    round: int
    session_name: str


class LoadSessionResponse(BaseModel):
    cache_id: str
    from_cache: bool


class FullSessionResponse(BaseModel):
    # We keep this flexible and future-proof (no rigid schema)
    payload: Dict[str, Any]


class ReplayFramesResponse(BaseModel):
    replay: Dict[str, Any]


class NotEnabledResponse(BaseModel):
    enabled: bool = False
    message: str = "not enabled"