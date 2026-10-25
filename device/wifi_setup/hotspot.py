import subprocess

from system.logger import get_logger

logger = get_logger("ruok-wifi-setup")

HOTSPOT_CON_NAME = "Hotspot"


def _nmcli(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["sudo", "-n", "nmcli", *args], capture_output=True, text=True)


def start_hotspot(ssid: str, password: str) -> bool:
    result = _nmcli("device", "wifi", "hotspot", "ifname", "wlan0", "ssid", ssid, "password", password)
    if result.returncode != 0:
        logger.warning("Failed to start hotspot: %s", result.stderr.strip())
        return False
    logger.info("Hotspot started: ssid=%s", ssid)
    return True


def stop_hotspot() -> None:
    _nmcli("connection", "down", HOTSPOT_CON_NAME)
    logger.info("Hotspot stopped")


def _connection_exists(ssid: str) -> bool:
    result = _nmcli("-t", "-f", "NAME", "connection", "show")
    names = result.stdout.splitlines()
    return ssid in names


def connect_to_wifi(ssid: str, password: str) -> bool:
    if _connection_exists(ssid):
        modify = _nmcli("connection", "modify", ssid, "wifi-sec.psk", password)
        if modify.returncode != 0:
            logger.warning("Failed to update saved network %s: %s", ssid, modify.stderr.strip())
            return False
        up = _nmcli("connection", "up", ssid)
        if up.returncode != 0:
            logger.warning("Failed to bring up saved network %s: %s", ssid, up.stderr.strip())
            return False
        logger.info("Updated and connected to saved network: %s", ssid)
        return True

    add = _nmcli(
        "connection", "add", "type", "wifi", "con-name", ssid, "ifname", "wlan0", "ssid", ssid,
        "--", "wifi-sec.key-mgmt", "wpa-psk", "wifi-sec.psk", password, "connection.autoconnect", "yes",
    )
    if add.returncode != 0:
        logger.warning("Failed to add network %s: %s", ssid, add.stderr.strip())
        return False
    logger.info("Added new network: %s", ssid)
    return True
