import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from typing import Optional


SECRET_KEY = os.getenv("RUOK_SECRET_KEY", "local-dev-secret-change-me")


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("utf-8").rstrip("=")


def _unb64(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 160_000)
    return f"pbkdf2_sha256${salt}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        algorithm, salt, expected_hex = stored.split("$", 2)
        if algorithm != "pbkdf2_sha256":
            return False
        digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 160_000)
        return hmac.compare_digest(digest.hex(), expected_hex)
    except Exception:
        return False


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def new_device_token() -> str:
    return "dev_" + secrets.token_urlsafe(32)


def create_user_token(user_id: int, email: str, ttl_seconds: int = 60 * 60 * 24 * 7) -> str:
    payload = {
        "sub": user_id,
        "email": email,
        "type": "user",
        "exp": int(time.time()) + ttl_seconds,
    }
    body = _b64(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    sig = hmac.new(SECRET_KEY.encode("utf-8"), body.encode("utf-8"), hashlib.sha256).digest()
    return f"{body}.{_b64(sig)}"


def verify_user_token(token: str) -> Optional[dict]:
    try:
        body, sig = token.split(".", 1)
        expected = hmac.new(SECRET_KEY.encode("utf-8"), body.encode("utf-8"), hashlib.sha256).digest()
        if not hmac.compare_digest(_b64(expected), sig):
            return None
        payload = json.loads(_unb64(body))
        if payload.get("type") != "user":
            return None
        if int(payload.get("exp", 0)) < int(time.time()):
            return None
        return payload
    except Exception:
        return None
