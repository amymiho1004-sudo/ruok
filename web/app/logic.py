import json
from datetime import datetime, timedelta
from typing import Optional

from app.database import connect


MODE_PRIORITY = {
    "vacation": 100,
    "away": 90,
    "pause": 80,
    "maintenance": 70,
}


def parse_dt(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    try:
        if value.endswith("Z"):
            value = value[:-1] + "+00:00"
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is not None:
            dt = dt.astimezone().replace(tzinfo=None)
        return dt
    except Exception:
        pass
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(value, fmt)
        except Exception:
            continue
    return None


def minutes_since(value: Optional[str], now: Optional[datetime] = None) -> Optional[int]:
    dt = parse_dt(value)
    if dt is None:
        return None
    now = now or datetime.now()
    return max(0, int((now - dt).total_seconds() // 60))


def is_sleep_time(device_id: int, now: Optional[datetime] = None) -> bool:
    now = now or datetime.now()
    weekday = now.weekday()
    current = now.strftime("%H:%M")
    with connect() as db:
        row = db.execute(
            "SELECT * FROM sleep_schedules WHERE device_id=? AND enabled=1 ORDER BY id DESC LIMIT 1",
            (device_id,),
        ).fetchone()
    if not row:
        return False

    days = {int(x) for x in str(row["days_of_week"]).split(",") if x.strip().isdigit()}
    if weekday not in days:
        return False

    start = row["start_time"]
    end = row["end_time"]

    if start <= end:
        return start <= current <= end
    return current >= start or current <= end


def active_presence_mode(device_id: int, now: Optional[datetime] = None) -> Optional[dict]:
    now = now or datetime.now()
    with connect() as db:
        rows = db.execute(
            '''
            SELECT * FROM presence_modes
            WHERE device_id=? AND enabled=1
            ORDER BY created_at DESC
            ''',
            (device_id,),
        ).fetchall()

    active = []
    for row in rows:
        start = parse_dt(row["start_at"])
        end = parse_dt(row["end_at"]) if row["end_at"] else None
        if not start:
            continue
        if start <= now and (end is None or now <= end):
            item = dict(row)
            item["_priority"] = MODE_PRIORITY.get(item["mode_type"], 1)
            active.append(item)

    if not active:
        return None
    active.sort(key=lambda x: x["_priority"], reverse=True)
    return active[0]


def get_rules(device_id: int) -> dict:
    with connect() as db:
        row = db.execute("SELECT * FROM alert_rules WHERE device_id=?", (device_id,)).fetchone()
    if not row:
        return {
            "normal_warning_minutes": 180,
            "normal_urgent_minutes": 360,
            "sleep_warning_minutes": 720,
            "sleep_urgent_minutes": 840,
            "offline_minutes": 30,
            "enabled": 1,
        }
    return dict(row)


def latest_reaction_at(device: dict) -> Optional[str]:
    candidates = [device.get("last_motion_at"), device.get("last_voice_at"), device.get("last_button_at")]
    parsed = [(parse_dt(x), x) for x in candidates if x]
    parsed = [(dt, raw) for dt, raw in parsed if dt is not None]
    if not parsed:
        return device.get("created_at")
    parsed.sort(key=lambda x: x[0], reverse=True)
    return parsed[0][1]


def compute_device_status(device_id: int) -> dict:
    now = datetime.now()
    with connect() as db:
        row = db.execute("SELECT * FROM devices WHERE id=?", (device_id,)).fetchone()
    if not row:
        raise ValueError("Device not found")

    device = dict(row)
    rules = get_rules(device_id)
    mode = active_presence_mode(device_id, now)
    sleeping = is_sleep_time(device_id, now)

    last_seen_minutes = minutes_since(device.get("last_seen_at"), now)
    last_reaction_raw = latest_reaction_at(device)
    no_reaction_minutes = minutes_since(last_reaction_raw, now)

    status = "normal"
    severity = "normal"
    reason = "Everything looks normal."

    if not rules.get("enabled", 1):
        status = "monitoring_disabled"
        severity = "info"
        reason = "Alert evaluation is disabled."
    elif last_seen_minutes is None:
        status = "waiting"
        severity = "info"
        reason = "The device has not connected yet."
    elif last_seen_minutes >= int(rules["offline_minutes"]):
        status = "offline"
        severity = "urgent"
        reason = f"The device has not contacted the server for {last_seen_minutes} minutes."
    elif mode and mode["mode_type"] in ("away", "vacation", "pause", "maintenance"):
        status = mode["mode_type"]
        severity = "info"
        reason = f"Currently in {mode['mode_type']} mode. No-motion / no-voice alerts are suspended."
    else:
        warning = int(rules["sleep_warning_minutes"] if sleeping else rules["normal_warning_minutes"])
        urgent = int(rules["sleep_urgent_minutes"] if sleeping else rules["normal_urgent_minutes"])
        if no_reaction_minutes is None:
            status = "waiting"
            severity = "info"
            reason = "No motion or voice has been detected yet."
        elif no_reaction_minutes >= urgent:
            status = "urgent"
            severity = "urgent"
            reason = f"No motion or voice for {no_reaction_minutes} minutes."
        elif no_reaction_minutes >= warning:
            status = "warning"
            severity = "warning"
            reason = f"No motion or voice for {no_reaction_minutes} minutes."
        elif sleeping:
            status = "sleeping"
            severity = "normal"
            reason = "Within the normal range for sleep time."

    return {
        "device_id": device_id,
        "device_uid": device["device_uid"],
        "name": device["name"],
        "location": device["location"],
        "status": status,
        "severity": severity,
        "reason": reason,
        "active_mode": mode["mode_type"] if mode else ("sleep" if sleeping else "home"),
        "is_sleep_time": sleeping,
        "last_seen_at": device.get("last_seen_at"),
        "last_motion_at": device.get("last_motion_at"),
        "last_voice_at": device.get("last_voice_at"),
        "last_button_at": device.get("last_button_at"),
        "last_seen_minutes": last_seen_minutes,
        "no_reaction_minutes": no_reaction_minutes,
        "battery_level": device.get("battery_level"),
        "wifi_strength": device.get("wifi_strength"),
        "checked_at": now.isoformat(timespec="seconds"),
    }


def create_alert_if_needed(device_id: int) -> Optional[dict]:
    status = compute_device_status(device_id)
    if status["severity"] not in ("warning", "urgent"):
        return None

    alert_type = status["status"]
    severity = status["severity"]
    title_map = {
        "offline": "Device offline",
        "warning": "No activity - warning",
        "urgent": "No activity - urgent check needed",
    }
    title = title_map.get(alert_type, "Status check needed")
    message = status["reason"]

    with connect() as db:
        existing = db.execute(
            '''
            SELECT * FROM alerts
            WHERE device_id=? AND alert_type=? AND status IN ('pending', 'sent')
            ORDER BY created_at DESC LIMIT 1
            ''',
            (device_id, alert_type),
        ).fetchone()
        if existing:
            return dict(existing)

        cur = db.execute(
            '''
            INSERT INTO alerts(device_id, alert_type, severity, title, message, status)
            VALUES(?, ?, ?, ?, ?, 'pending')
            ''',
            (device_id, alert_type, severity, title, message),
        )
        db.commit()
        alert_id = cur.lastrowid
        row = db.execute("SELECT * FROM alerts WHERE id=?", (alert_id,)).fetchone()
        return dict(row)


def evaluate_all_devices() -> list[dict]:
    results = []
    with connect() as db:
        devices = db.execute("SELECT id FROM devices").fetchall()
    for row in devices:
        try:
            alert = create_alert_if_needed(row["id"])
            if alert:
                results.append(alert)
        except Exception as exc:
            results.append({"device_id": row["id"], "error": str(exc)})
    return results
