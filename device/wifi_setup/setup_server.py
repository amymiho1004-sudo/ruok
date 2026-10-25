import json
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

from system.config_loader import save_provisioning
from system.logger import get_logger
from wifi_setup.hotspot import connect_to_wifi, stop_hotspot

logger = get_logger("ruok-wifi-setup")

PORT = 8788


def make_handler(device_uid: str, on_connected):
    class Handler(BaseHTTPRequestHandler):
        def _send_json(self, status: int, payload: dict):
            body = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path == "/status":
                self._send_json(200, {"mode": "setup", "device_uid": device_uid})
            else:
                self._send_json(404, {"error": "not found"})

        def do_POST(self):
            if self.path != "/provision":
                self._send_json(404, {"error": "not found"})
                return

            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length) if length else b"{}"
            try:
                data = json.loads(raw)
                ssid = data["ssid"]
                password = data["password"]
            except (json.JSONDecodeError, KeyError):
                self._send_json(400, {"ok": False, "error": "ssid and password are required"})
                return

            # Registration is optional: reconfiguring Wi-Fi on an already-provisioned
            # device sends only ssid/password, since its device_token is never shown again.
            server_url = data.get("server_url")
            new_device_uid = data.get("device_uid")
            device_token = data.get("device_token")
            provisioning = bool(server_url and new_device_uid and device_token)

            ok = connect_to_wifi(ssid, password)
            if ok and provisioning:
                try:
                    save_provisioning(server_url, new_device_uid, device_token)
                    logger.info("Saved device registration: %s", new_device_uid)
                except Exception as exc:
                    logger.warning("Failed to save device registration: %s", exc)
                    ok = False

            self._send_json(200, {"ok": ok})
            if ok:
                threading.Thread(target=on_connected, args=(provisioning,), daemon=True).start()

        def log_message(self, fmt, *args):
            logger.info("setup_server: " + fmt, *args)

    return Handler


def run_setup_server(device_uid: str, timeout_seconds: int = 300) -> None:
    done = threading.Event()

    def on_connected(provisioning: bool):
        time.sleep(2)  # let the HTTP response reach the phone before switching networks
        stop_hotspot()
        done.set()
        if provisioning:
            # Runs after the hotspot is down and Wi-Fi has switched over, so the
            # restarted device service can actually reach the server right away.
            subprocess.run(["sudo", "systemctl", "restart", "ruok-device"], capture_output=True, text=True)

    handler = make_handler(device_uid, on_connected)
    httpd = HTTPServer(("0.0.0.0", PORT), handler)
    httpd.timeout = 1

    deadline = time.time() + timeout_seconds
    logger.info("Wi-Fi setup server listening on port %s", PORT)
    while time.time() < deadline and not done.is_set():
        httpd.handle_request()
    httpd.server_close()

    if not done.is_set():
        logger.info("Wi-Fi setup timed out, tearing down hotspot")
        stop_hotspot()
