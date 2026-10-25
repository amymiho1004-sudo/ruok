import subprocess
import threading
from signal import pause

from gpiozero import Button

from system.config_loader import load_config
from system.logger import get_logger
from wifi_setup.hotspot import start_hotspot
from wifi_setup.setup_server import run_setup_server

logger = get_logger("ruok-wifi-setup")

BUTTON_GPIO = 3
WIFI_SETUP_HOLD_SECONDS = 4
SHUTDOWN_HOLD_SECONDS = 10
HOTSPOT_PASSWORD = "ruoksetup123"

_hold_ticks = 0
_wifi_setup_triggered = False
_shutdown_triggered = False


def get_hotspot_ssid() -> str:
    try:
        device_uid = load_config().get("device_uid", "")
    except (FileNotFoundError, ValueError):
        device_uid = ""

    if device_uid:
        return f"RUOK-Setup-{device_uid[-6:]}"
    return "RUOK-Setup"


def get_device_uid() -> str:
    try:
        return load_config().get("device_uid", "unknown")
    except (FileNotFoundError, ValueError):
        return "unknown"


def enter_setup_mode() -> None:
    ssid = get_hotspot_ssid()
    logger.info("Button held %ss, entering Wi-Fi setup mode: %s", WIFI_SETUP_HOLD_SECONDS, ssid)

    if not start_hotspot(ssid, HOTSPOT_PASSWORD):
        logger.warning("Could not start hotspot, aborting setup mode")
        return

    run_setup_server(device_uid=get_device_uid())
    logger.info("Wi-Fi setup mode ended")


def shutdown_device() -> None:
    logger.info("Button held %ss, shutting down", SHUTDOWN_HOLD_SECONDS)
    subprocess.run(["sudo", "-n", "shutdown", "-h", "now"], capture_output=True, text=True)


def _on_held() -> None:
    global _hold_ticks, _wifi_setup_triggered, _shutdown_triggered
    _hold_ticks += 1

    if _hold_ticks == WIFI_SETUP_HOLD_SECONDS and not _wifi_setup_triggered:
        _wifi_setup_triggered = True
        threading.Thread(target=enter_setup_mode, daemon=True).start()

    if _hold_ticks == SHUTDOWN_HOLD_SECONDS and not _shutdown_triggered:
        _shutdown_triggered = True
        threading.Thread(target=shutdown_device, daemon=True).start()


def _on_released() -> None:
    global _hold_ticks, _wifi_setup_triggered, _shutdown_triggered
    _hold_ticks = 0
    _wifi_setup_triggered = False
    _shutdown_triggered = False


def main() -> None:
    # hold_time=1 with hold_repeat fires _on_held once per second while held,
    # so counting ticks doubles as an elapsed-seconds counter for both thresholds.
    button = Button(BUTTON_GPIO, pull_up=True, hold_time=1, hold_repeat=True)
    button.when_held = _on_held
    button.when_released = _on_released
    logger.info(
        "Watching GPIO%s: %ss hold = Wi-Fi setup, %ss hold = shutdown",
        BUTTON_GPIO, WIFI_SETUP_HOLD_SECONDS, SHUTDOWN_HOLD_SECONDS,
    )
    pause()


if __name__ == "__main__":
    main()
