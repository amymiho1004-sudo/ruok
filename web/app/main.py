import asyncio
import json
import secrets
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles

from app.database import connect, init_db
from app.logic import compute_device_status, create_alert_if_needed, evaluate_all_devices
from app.schemas import (
    AlertRulesRequest,
    CreateDeviceRequest,
    DeviceEventRequest,
    LoginRequest,
    PresenceModeRequest,
    RegisterRequest,
    SleepScheduleRequest,
)
from app.security import (
    create_user_token,
    hash_password,
    new_device_token,
    token_hash,
    verify_password,
    verify_user_token,
)


BASE_DIR = Path(__file__).resolve().parent.parent
WEB_DIR = BASE_DIR / "web"

app = FastAPI(title="R U OK? Local Server", version="0.1.0")
app.mount("/web", StaticFiles(directory=str(WEB_DIR)), name="web")


def now_iso() -> str:
    return datetime.now().isoformat(timespec="seconds")


def require_user(authorization: Optional[str] = Header(None)) -> dict:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = verify_user_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    with connect() as db:
        user = db.execute("SELECT * FROM users WHERE id=?", (payload["sub"],)).fetchone()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return dict(user)


def require_device(
    x_device_uid: Optional[str] = Header(None),
    x_device_token: Optional[str] = Header(None),
) -> dict:
    if not x_device_uid or not x_device_token:
        raise HTTPException(status_code=401, detail="Missing device credentials")
    with connect() as db:
        row = db.execute("SELECT * FROM devices WHERE device_uid=?", (x_device_uid,)).fetchone()
    if not row:
        raise HTTPException(status_code=401, detail="Unknown device")
    device = dict(row)
    if token_hash(x_device_token) != device["device_token_hash"]:
        raise HTTPException(status_code=401, detail="Invalid device token")
    return device


def user_can_access_device(user_id: int, device_id: int) -> bool:
    with connect() as db:
        row = db.execute(
            '''
            SELECT d.id
            FROM devices d
            JOIN family_members fm ON fm.family_id = d.family_id
            WHERE d.id=? AND fm.user_id=?
            ''',
            (device_id, user_id),
        ).fetchone()
    return row is not None


def assert_device_access(user: dict, device_id: int) -> None:
    if not user_can_access_device(user["id"], device_id):
        raise HTTPException(status_code=403, detail="No access to this device")


@app.on_event("startup")
async def startup_event() -> None:
    init_db()
    asyncio.create_task(monitor_loop())


async def monitor_loop() -> None:
    while True:
        try:
            evaluate_all_devices()
        except Exception:
            pass
        await asyncio.sleep(60)


@app.get("/", response_class=HTMLResponse)
async def home() -> FileResponse:
    return FileResponse(WEB_DIR / "index.html")


@app.get("/api/health")
async def health() -> dict:
    return {"ok": True, "service": "ruok-local-server", "checked_at": now_iso()}


@app.post("/api/auth/register")
async def register(req: RegisterRequest) -> dict:
    email = req.email.strip().lower()
    with connect() as db:
        existing = db.execute("SELECT id FROM users WHERE email=?", (email,)).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="Email already registered")

        cur = db.execute(
            '''
            INSERT INTO users(name, email, phone, password_hash)
            VALUES(?, ?, ?, ?)
            ''',
            (req.name.strip(), email, req.phone, hash_password(req.password)),
        )
        user_id = cur.lastrowid

        family_name = f"{req.name.strip()} Family"
        fcur = db.execute(
            "INSERT INTO families(name, owner_user_id) VALUES(?, ?)",
            (family_name, user_id),
        )
        family_id = fcur.lastrowid
        db.execute(
            '''
            INSERT INTO family_members(family_id, user_id, relation, permission_level)
            VALUES(?, ?, 'guardian', 'owner')
            ''',
            (family_id, user_id),
        )
        db.commit()

    return {
        "token": create_user_token(user_id, email),
        "user": {"id": user_id, "name": req.name, "email": email},
    }


@app.post("/api/auth/login")
async def login(req: LoginRequest) -> dict:
    email = req.email.strip().lower()
    with connect() as db:
        user = db.execute("SELECT * FROM users WHERE email=?", (email,)).fetchone()
    if not user or not verify_password(req.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return {
        "token": create_user_token(user["id"], email),
        "user": {"id": user["id"], "name": user["name"], "email": user["email"]},
    }


@app.get("/api/me")
async def me(user: dict = Depends(require_user)) -> dict:
    return {"user": {"id": user["id"], "name": user["name"], "email": user["email"], "phone": user["phone"]}}


@app.post("/api/devices")
async def create_device(req: CreateDeviceRequest, user: dict = Depends(require_user)) -> dict:
    device_uid = "RUOK-" + secrets.token_hex(3).upper()
    token = new_device_token()

    with connect() as db:
        family = db.execute(
            '''
            SELECT f.*
            FROM families f
            JOIN family_members fm ON fm.family_id = f.id
            WHERE fm.user_id=?
            ORDER BY f.id ASC LIMIT 1
            ''',
            (user["id"],),
        ).fetchone()

        if not family:
            fcur = db.execute(
                "INSERT INTO families(name, owner_user_id) VALUES(?, ?)",
                (req.family_name, user["id"]),
            )
            family_id = fcur.lastrowid
            db.execute(
                '''
                INSERT INTO family_members(family_id, user_id, relation, permission_level)
                VALUES(?, ?, 'guardian', 'owner')
                ''',
                (family_id, user["id"]),
            )
        else:
            family_id = family["id"]

        cur = db.execute(
            '''
            INSERT INTO devices(family_id, device_uid, name, location, device_token_hash)
            VALUES(?, ?, ?, ?, ?)
            ''',
            (family_id, device_uid, req.name, req.location, token_hash(token)),
        )
        device_id = cur.lastrowid
        db.execute(
            '''
            INSERT INTO alert_rules(device_id)
            VALUES(?)
            ''',
            (device_id,),
        )
        db.execute(
            '''
            INSERT INTO sleep_schedules(device_id, created_by_user_id)
            VALUES(?, ?)
            ''',
            (device_id, user["id"]),
        )
        db.commit()

    return {
        "device": {
            "id": device_id,
            "device_uid": device_uid,
            "name": req.name,
            "location": req.location,
        },
        "device_token": token,
        "message": "Save this token into the Raspberry Pi config/config.json file. It is shown only in this response.",
    }


@app.get("/api/devices")
async def list_devices(user: dict = Depends(require_user)) -> dict:
    with connect() as db:
        rows = db.execute(
            '''
            SELECT d.*
            FROM devices d
            JOIN family_members fm ON fm.family_id = d.family_id
            WHERE fm.user_id=?
            ORDER BY d.created_at DESC
            ''',
            (user["id"],),
        ).fetchall()
    devices = []
    for row in rows:
        item = dict(row)
        try:
            item["computed"] = compute_device_status(item["id"])
        except Exception:
            item["computed"] = None
        devices.append(item)
    return {"devices": devices}


@app.delete("/api/devices/{device_id}")
async def delete_device(device_id: int, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    with connect() as db:
        db.execute("DELETE FROM devices WHERE id=?", (device_id,))
        db.commit()
    return {"ok": True}


@app.get("/api/devices/{device_id}/status")
async def device_status(device_id: int, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    return compute_device_status(device_id)


@app.get("/api/devices/{device_id}/events")
async def device_events(device_id: int, limit: int = 100, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    with connect() as db:
        rows = db.execute(
            '''
            SELECT * FROM device_events
            WHERE device_id=?
            ORDER BY created_at DESC
            LIMIT ?
            ''',
            (device_id, max(1, min(limit, 500))),
        ).fetchall()
    return {"events": [dict(r) for r in rows]}


@app.post("/api/device-events")
async def receive_device_event(req: DeviceEventRequest, device: dict = Depends(require_device)) -> dict:
    raw = req.model_dump()
    event_type = req.event_type
    detected = None if req.detected is None else int(req.detected)
    device_ts = req.timestamp

    with connect() as db:
        db.execute(
            '''
            INSERT INTO device_events(device_id, event_type, detected, value_text, value_number, raw_json, device_timestamp)
            VALUES(?, ?, ?, ?, ?, ?, ?)
            ''',
            (
                device["id"],
                event_type,
                detected,
                req.value_text,
                req.value_number,
                json.dumps(raw, ensure_ascii=False),
                device_ts,
            ),
        )

        updates = ["last_seen_at=datetime('now','localtime')", "status='online'", "updated_at=datetime('now','localtime')"]
        params = []

        if event_type == "motion_detected" and req.detected:
            updates.append("last_motion_at=datetime('now','localtime')")
        if event_type == "voice_detected" and req.detected:
            updates.append("last_voice_at=datetime('now','localtime')")
        if event_type == "button_pressed":
            updates.append("last_button_at=datetime('now','localtime')")
        if event_type == "heartbeat" and req.meta:
            battery_level = req.meta.get("battery_level")
            wifi_strength = req.meta.get("wifi_strength")

            if battery_level is not None:
                updates.append("battery_level=?")
                params.append(float(battery_level))

            if wifi_strength is not None:
                updates.append("wifi_strength=?")
                params.append(float(wifi_strength))

        params.append(device["id"])
        db.execute(f"UPDATE devices SET {', '.join(updates)} WHERE id=?", params)
        db.commit()

    alert = create_alert_if_needed(device["id"])
    return {"ok": True, "alert": alert}


@app.get("/api/devices/{device_id}/sleep-schedule")
async def get_sleep_schedule(device_id: int, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    with connect() as db:
        row = db.execute(
            "SELECT * FROM sleep_schedules WHERE device_id=? ORDER BY id DESC LIMIT 1",
            (device_id,),
        ).fetchone()
    return {"sleep_schedule": dict(row) if row else None}


@app.post("/api/devices/{device_id}/sleep-schedule")
async def set_sleep_schedule(device_id: int, req: SleepScheduleRequest, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    with connect() as db:
        db.execute(
            '''
            INSERT INTO sleep_schedules(device_id, start_time, end_time, days_of_week, enabled, created_by_user_id)
            VALUES(?, ?, ?, ?, ?, ?)
            ''',
            (device_id, req.start_time, req.end_time, req.days_of_week, int(req.enabled), user["id"]),
        )
        db.commit()
    return {"ok": True}


@app.get("/api/devices/{device_id}/presence-modes")
async def get_presence_modes(device_id: int, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    with connect() as db:
        rows = db.execute(
            '''
            SELECT * FROM presence_modes
            WHERE device_id=?
            ORDER BY created_at DESC
            LIMIT 50
            ''',
            (device_id,),
        ).fetchall()
    return {"presence_modes": [dict(r) for r in rows]}


@app.post("/api/devices/{device_id}/presence-mode")
async def set_presence_mode(device_id: int, req: PresenceModeRequest, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    allowed = {"home", "away", "vacation", "pause", "maintenance"}
    if req.mode_type not in allowed:
        raise HTTPException(status_code=400, detail=f"mode_type must be one of {sorted(allowed)}")
    with connect() as db:
        if req.mode_type == "home":
            db.execute(
                "UPDATE presence_modes SET enabled=0 WHERE device_id=? AND enabled=1",
                (device_id,),
            )
        else:
            db.execute(
                '''
                INSERT INTO presence_modes(device_id, mode_type, start_at, end_at, note, enabled, created_by_user_id)
                VALUES(?, ?, ?, ?, ?, ?, ?)
                ''',
                (device_id, req.mode_type, req.start_at, req.end_at, req.note, int(req.enabled), user["id"]),
            )
        db.commit()
    return {"ok": True}


@app.get("/api/devices/{device_id}/alert-rules")
async def get_alert_rules(device_id: int, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    with connect() as db:
        row = db.execute("SELECT * FROM alert_rules WHERE device_id=?", (device_id,)).fetchone()
    return {"alert_rules": dict(row) if row else None}


@app.post("/api/devices/{device_id}/alert-rules")
async def set_alert_rules(device_id: int, req: AlertRulesRequest, user: dict = Depends(require_user)) -> dict:
    assert_device_access(user, device_id)
    with connect() as db:
        db.execute(
            '''
            INSERT INTO alert_rules(
                device_id, normal_warning_minutes, normal_urgent_minutes,
                sleep_warning_minutes, sleep_urgent_minutes, offline_minutes, enabled
            )
            VALUES(?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(device_id) DO UPDATE SET
                normal_warning_minutes=excluded.normal_warning_minutes,
                normal_urgent_minutes=excluded.normal_urgent_minutes,
                sleep_warning_minutes=excluded.sleep_warning_minutes,
                sleep_urgent_minutes=excluded.sleep_urgent_minutes,
                offline_minutes=excluded.offline_minutes,
                enabled=excluded.enabled,
                updated_at=datetime('now','localtime')
            ''',
            (
                device_id,
                req.normal_warning_minutes,
                req.normal_urgent_minutes,
                req.sleep_warning_minutes,
                req.sleep_urgent_minutes,
                req.offline_minutes,
                int(req.enabled),
            ),
        )
        db.commit()
    return {"ok": True}


@app.get("/api/alerts")
async def list_alerts(user: dict = Depends(require_user)) -> dict:
    with connect() as db:
        rows = db.execute(
            '''
            SELECT a.*, d.name AS device_name, d.device_uid
            FROM alerts a
            JOIN devices d ON d.id = a.device_id
            JOIN family_members fm ON fm.family_id = d.family_id
            WHERE fm.user_id=?
            ORDER BY a.created_at DESC
            LIMIT 200
            ''',
            (user["id"],),
        ).fetchall()
    return {"alerts": [dict(r) for r in rows]}


@app.post("/api/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(alert_id: int, user: dict = Depends(require_user)) -> dict:
    with connect() as db:
        row = db.execute(
            '''
            SELECT a.*
            FROM alerts a
            JOIN devices d ON d.id = a.device_id
            JOIN family_members fm ON fm.family_id = d.family_id
            WHERE a.id=? AND fm.user_id=?
            ''',
            (alert_id, user["id"]),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Alert not found")

        db.execute(
            "UPDATE alerts SET status='acknowledged', acknowledged_at=datetime('now','localtime') WHERE id=?",
            (alert_id,),
        )
        db.commit()
    return {"ok": True}


@app.post("/api/admin/evaluate-alerts")
async def evaluate_alerts(user: dict = Depends(require_user)) -> dict:
    return {"results": evaluate_all_devices()}

