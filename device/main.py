import signal
import sys
import time
from datetime import datetime
from pathlib import Path

from network.api_client import ApiClient
from network.offline_queue import OfflineQueue
from sensors.motion_ld2410 import create_motion_sensor
from sensors.voice_detector import VoiceDetector
from system.config_loader import load_config
from system.logger import get_logger


logger = get_logger("ruok-device")
RUNNING = True


def handle_signal(signum, frame):
    global RUNNING
    RUNNING = False
    logger.info("Shutdown signal received")


signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)


def now_iso():
    return datetime.now().isoformat(timespec="seconds")


def send_or_queue(api: ApiClient, queue: OfflineQueue, event: dict):
    try:
        api.send_event(event)
        logger.info("Sent event: %s", event["event_type"])
        queue.flush(api)
    except Exception as exc:
        logger.warning("Send failed, queued event %s: %s", event.get("event_type"), exc)
        queue.add(event)


def main():
    config = load_config()
    api = ApiClient(
        server_url=config["server_url"],
        device_uid=config["device_uid"],
        device_token=config["device_token"],
        timeout_seconds=5,
    )
    queue = OfflineQueue("storage/offline_events.sqlite")

    motion_cfg = config.get("motion", {})
    voice_cfg = config.get("voice", {})

    motion_sensor = create_motion_sensor(motion_cfg) if motion_cfg.get("enabled", True) else None
    voice_detector = VoiceDetector(voice_cfg) if voice_cfg.get("enabled", True) else None

    heartbeat_seconds = int(config.get("heartbeat_seconds", 60))
    offline_flush_seconds = int(config.get("offline_flush_seconds", 20))

    last_heartbeat = 0.0
    last_flush = 0.0
    last_motion_event = 0.0
    last_voice_event = 0.0
    last_voice_check = 0.0
    voice_check_interval = int(voice_cfg.get("interval_seconds", 30))

    logger.info("R U OK? device started. server=%s uid=%s", config["server_url"], config["device_uid"])

    while RUNNING:
        now = time.time()

        if now - last_heartbeat >= heartbeat_seconds:
            last_heartbeat = now
            event = {
                "event_type": "heartbeat",
                "detected": True,
                "timestamp": now_iso(),
                "meta": {
                    "battery_level": config.get("battery_level"),
                    "wifi_strength": config.get("wifi_strength"),
                },
            }
            send_or_queue(api, queue, event)

        if motion_sensor:
            try:
                motion = motion_sensor.read()
                min_interval = int(motion_cfg.get("min_interval_seconds", 30))
                if motion.detected and now - last_motion_event >= min_interval:
                    last_motion_event = now
                    event = {
                        "event_type": "motion_detected",
                        "detected": True,
                        "value_number": motion.distance_cm,
                        "timestamp": now_iso(),
                        "meta": motion.meta,
                    }
                    send_or_queue(api, queue, event)
            except Exception as exc:
                logger.warning("Motion sensor read failed: %s", exc)

        if voice_detector and now - last_voice_check >= voice_check_interval:
            last_voice_check = now
            try:
                min_interval = int(voice_cfg.get("min_interval_seconds", 60))
                voice = voice_detector.detect()
                if voice.detected and now - last_voice_event >= min_interval:
                    last_voice_event = now
                    event = {
                        "event_type": "voice_detected",
                        "detected": True,
                        "value_number": voice.rms,
                        "timestamp": now_iso(),
                        "meta": voice.meta,
                    }
                    send_or_queue(api, queue, event)
            except Exception as exc:
                logger.warning("Voice detection failed: %s", exc)

        if now - last_flush >= offline_flush_seconds:
            last_flush = now
            try:
                queue.flush(api)
            except Exception:
                pass

        time.sleep(1)

    if voice_detector:
        voice_detector.stop()

    logger.info("R U OK? device stopped")


if __name__ == "__main__":
    main()
