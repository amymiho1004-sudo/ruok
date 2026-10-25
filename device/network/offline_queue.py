import json
import sqlite3
from pathlib import Path
from typing import Optional


class OfflineQueue:
    def __init__(self, db_path: str):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _connect(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self._connect() as db:
            db.execute(
                '''
                CREATE TABLE IF NOT EXISTS offline_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    payload_json TEXT NOT NULL,
                    retry_count INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL DEFAULT (datetime('now')),
                    sent_at TEXT
                )
                '''
            )

    def add(self, event: dict):
        with self._connect() as db:
            db.execute(
                "INSERT INTO offline_events(payload_json) VALUES(?)",
                (json.dumps(event, ensure_ascii=False),),
            )
            db.commit()

    def flush(self, api_client, limit: int = 50) -> int:
        sent = 0
        with self._connect() as db:
            rows = db.execute(
                "SELECT * FROM offline_events WHERE sent_at IS NULL ORDER BY id ASC LIMIT ?",
                (limit,),
            ).fetchall()

        for row in rows:
            event = json.loads(row["payload_json"])
            try:
                api_client.send_event(event)
                with self._connect() as db:
                    db.execute("UPDATE offline_events SET sent_at=datetime('now') WHERE id=?", (row["id"],))
                    db.commit()
                sent += 1
            except Exception:
                with self._connect() as db:
                    db.execute(
                        "UPDATE offline_events SET retry_count=retry_count+1 WHERE id=?",
                        (row["id"],),
                    )
                    db.commit()
                break

        return sent
