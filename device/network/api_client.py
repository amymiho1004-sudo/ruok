from urllib.parse import urljoin

import requests


class ApiClient:
    def __init__(self, server_url: str, device_uid: str, device_token: str, timeout_seconds: int = 10):
        self.server_url = server_url.rstrip("/") + "/"
        self.device_uid = device_uid
        self.device_token = device_token
        self.timeout_seconds = timeout_seconds

    def send_event(self, event: dict) -> dict:
        url = urljoin(self.server_url, "api/device-events")
        headers = {
            "Content-Type": "application/json",
            "X-Device-UID": self.device_uid,
            "X-Device-Token": self.device_token,
        }
        res = requests.post(url, json=event, headers=headers, timeout=self.timeout_seconds)
        res.raise_for_status()
        return res.json()

    def health(self) -> dict:
        url = urljoin(self.server_url, "api/health")
        res = requests.get(url, timeout=self.timeout_seconds)
        res.raise_for_status()
        return res.json()
