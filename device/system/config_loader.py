import json
from pathlib import Path


def save_provisioning(server_url: str, device_uid: str, device_token: str) -> None:
    """Writes server_url/device_uid/device_token into config/config.json,
    preserving any existing sensor settings. Falls back to config.example.json
    as a base when config.json doesn't exist yet (first-time setup)."""
    path = Path("config/config.json")
    if path.exists():
        with path.open("r", encoding="utf-8") as f:
            config = json.load(f)
    else:
        example = Path("config/config.example.json")
        with example.open("r", encoding="utf-8") as f:
            config = json.load(f)

    config["server_url"] = server_url
    config["device_uid"] = device_uid
    config["device_token"] = device_token

    with path.open("w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)


def load_config() -> dict:
    path = Path("config/config.json")
    if not path.exists():
        example = Path("config/config.example.json")
        raise FileNotFoundError(
            f"Missing {path}. Copy {example} to {path} and fill server_url, device_uid, device_token."
        )

    with path.open("r", encoding="utf-8") as f:
        config = json.load(f)

    required = ["server_url", "device_uid", "device_token"]
    missing = [key for key in required if not config.get(key)]
    if missing:
        raise ValueError(f"Missing config values: {', '.join(missing)}")

    return config
