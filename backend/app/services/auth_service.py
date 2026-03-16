import time
import jwt
import aiosqlite
from passlib.context import CryptContext
from typing import Optional

JWT_SECRET = "dev-secret-change-me"
JWT_ALG = "HS256"
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7  # 7 days

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def init_db(db_path: str = "./users.db") -> None:
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
            """
        )
        await db.commit()


def _issue_token(email: str) -> str:
    now = int(time.time())
    payload = {"sub": email, "iat": now, "exp": now + TOKEN_TTL_SECONDS}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)


def verify_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALG])
        return payload.get("sub")
    except Exception:
        return None


async def create_user(email: str, password: str, db_path: str = "./users.db") -> None:
    await init_db(db_path)
    password_hash = pwd_context.hash(password)
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO users(email, password_hash, created_at) VALUES (?, ?, ?)",
            (email, password_hash, int(time.time())),
        )
        await db.commit()


async def authenticate_user(email: str, password: str, db_path: str = "./users.db") -> bool:
    await init_db(db_path)
    async with aiosqlite.connect(db_path) as db:
        cur = await db.execute("SELECT password_hash FROM users WHERE email = ?", (email,))
        row = await cur.fetchone()
        if not row:
            return False
        password_hash = row[0]
        return pwd_context.verify(password, password_hash)


async def signup_and_issue(email: str, password: str) -> str:
    # Will raise on duplicates; the route catches and returns a clean error
    await create_user(email, password)
    return _issue_token(email)


async def login_and_issue(email: str, password: str) -> Optional[str]:
    ok = await authenticate_user(email, password)
    if not ok:
        return None
    return _issue_token(email)


def dev_issue() -> str:
    # A deterministic-ish dev identity
    return _issue_token("dev@local")