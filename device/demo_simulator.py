"""Keyboard-driven device simulator for recording app demos without real hardware.

Sends the same events as main.py (heartbeat / motion_detected / voice_detected).

Usage:
    python demo_simulator.py --server http://127.0.0.1:8787 --uid RUOK-XXXXXX --token dev_xxxxx
    python demo_simulator.py --config config/config.json

Keys:
    M  send motion event
    V  send voice event
    H  send heartbeat now
    P  pause/resume heartbeats (device goes Offline)
    Q  quit
"""
import argparse
import json
import sys
import threading
import time
from datetime import datetime

from network.api_client import ApiClient


def now_iso():
    return datetime.now().isoformat(timespec="seconds")


def log(msg):
    print(f"[{datetime.now():%H:%M:%S}] {msg}", flush=True)


def send(api, event_type, value=None, meta=None):
    event = {
        "event_type": event_type,
        "detected": True,
        "timestamp": now_iso(),
        "meta": meta or {"sensor": "demo-simulator"},
    }
    if value is not None:
        event["value_number"] = value
    try:
        api.send_event(event)
        log(f"sent {event_type}")
    except Exception as exc:
        log(f"FAILED {event_type}: {exc}")


def read_key():
    if sys.platform == "win32":
        import msvcrt
        return msvcrt.getwch().lower()
    import termios
    import tty
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        return sys.stdin.read(1).lower()
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


def main():
    parser = argparse.ArgumentParser(description="R U OK? demo simulator")
    parser.add_argument("--config", help="device config.json (server_url, device_uid, device_token)")
    parser.add_argument("--server")
    parser.add_argument("--uid")
    parser.add_argument("--token")
    parser.add_argument("--heartbeat", type=int, default=60, help="heartbeat interval in seconds")
    args = parser.parse_args()

    cfg = {}
    if args.config:
        with open(args.config, encoding="utf-8") as f:
            cfg = json.load(f)
    server = args.server or cfg.get("server_url")
    uid = args.uid or cfg.get("device_uid")
    token = args.token or cfg.get("device_token")
    if not (server and uid and token):
        parser.error("server, uid and token are required (via --config or flags)")

    api = ApiClient(server, uid, token)
    try:
        api.health()
    except Exception as exc:
        log(f"server not reachable: {exc}")
        return 1

    state = {"heartbeat_on": True, "running": True}

    def heartbeat_loop():
        last = 0.0
        while state["running"]:
            if state["heartbeat_on"] and time.time() - last >= args.heartbeat:
                last = time.time()
                send(api, "heartbeat", meta={"sensor": "demo-simulator"})
            time.sleep(1)

    threading.Thread(target=heartbeat_loop, daemon=True).start()

    log(f"connected to {server} as {uid}")
    print("  M = motion   V = voice   H = heartbeat   P = pause heartbeats   Q = quit\n", flush=True)

    while True:
        key = read_key()
        if key == "m":
            send(api, "motion_detected", value=120, meta={"sensor": "demo-simulator", "confidence": 0.9})
        elif key == "v":
            send(api, "voice_detected", value=250, meta={"sensor": "demo-simulator"})
        elif key == "h":
            send(api, "heartbeat")
        elif key == "p":
            state["heartbeat_on"] = not state["heartbeat_on"]
            log("heartbeats " + ("ON" if state["heartbeat_on"] else "PAUSED (device will go Offline)"))
        elif key in ("q", "\x03"):
            state["running"] = False
            log("bye")
            return 0


if __name__ == "__main__":
    sys.exit(main())
