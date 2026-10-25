import os
import sqlite3
from pathlib import Path
from typing import Iterator


DB_PATH = os.getenv("RUOK_DB", "data/ruok_server.sqlite")


def get_db_path() -> Path:
    return Path(DB_PATH)


def connect() -> sqlite3.Connection:
    path = get_db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db() -> None:
    with connect() as db:
        db.executescript(
            '''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                phone TEXT,
                password_hash TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'guardian',
                status TEXT NOT NULL DEFAULT 'active',
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
            );

            CREATE TABLE IF NOT EXISTS families (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                owner_user_id INTEGER NOT NULL,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(owner_user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS family_members (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                family_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                relation TEXT NOT NULL DEFAULT 'guardian',
                permission_level TEXT NOT NULL DEFAULT 'owner',
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                UNIQUE(family_id, user_id),
                FOREIGN KEY(family_id) REFERENCES families(id) ON DELETE CASCADE,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS devices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                family_id INTEGER NOT NULL,
                device_uid TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL,
                location TEXT,
                device_type TEXT NOT NULL DEFAULT 'raspberry_pi',
                firmware_version TEXT,
                device_token_hash TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'created',
                last_seen_at TEXT,
                last_motion_at TEXT,
                last_voice_at TEXT,
                last_button_at TEXT,
                battery_level REAL,
                wifi_strength REAL,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(family_id) REFERENCES families(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS device_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id INTEGER NOT NULL,
                event_type TEXT NOT NULL,
                detected INTEGER,
                value_text TEXT,
                value_number REAL,
                raw_json TEXT,
                device_timestamp TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS sleep_schedules (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id INTEGER NOT NULL,
                start_time TEXT NOT NULL DEFAULT '22:00',
                end_time TEXT NOT NULL DEFAULT '07:00',
                days_of_week TEXT NOT NULL DEFAULT '0,1,2,3,4,5,6',
                enabled INTEGER NOT NULL DEFAULT 1,
                created_by_user_id INTEGER,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE,
                FOREIGN KEY(created_by_user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS presence_modes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id INTEGER NOT NULL,
                mode_type TEXT NOT NULL,
                start_at TEXT NOT NULL,
                end_at TEXT,
                note TEXT,
                enabled INTEGER NOT NULL DEFAULT 1,
                created_by_user_id INTEGER,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE,
                FOREIGN KEY(created_by_user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS alert_rules (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id INTEGER NOT NULL UNIQUE,
                normal_warning_minutes INTEGER NOT NULL DEFAULT 180,
                normal_urgent_minutes INTEGER NOT NULL DEFAULT 360,
                sleep_warning_minutes INTEGER NOT NULL DEFAULT 720,
                sleep_urgent_minutes INTEGER NOT NULL DEFAULT 840,
                offline_minutes INTEGER NOT NULL DEFAULT 30,
                enabled INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id INTEGER NOT NULL,
                alert_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                title TEXT NOT NULL,
                message TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending',
                triggered_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                acknowledged_at TEXT,
                resolved_at TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS notification_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                alert_id INTEGER,
                channel TEXT NOT NULL,
                target TEXT,
                status TEXT NOT NULL,
                response_text TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                FOREIGN KEY(alert_id) REFERENCES alerts(id) ON DELETE SET NULL
            );

            CREATE INDEX IF NOT EXISTS idx_device_events_device_created
                ON device_events(device_id, created_at DESC);

            CREATE INDEX IF NOT EXISTS idx_alerts_device_status
                ON alerts(device_id, status, created_at DESC);
            '''
        )

