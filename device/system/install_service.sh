#!/usr/bin/env bash
set -e

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$APP_DIR/.venv" ]; then
  python3 -m venv "$APP_DIR/.venv"
fi

"$APP_DIR/.venv/bin/pip" install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/requirements.txt"

if id "pi" >/dev/null 2>&1; then
  SERVICE_USER="pi"
else
  SERVICE_USER="$(whoami)"
fi

install_service() {
  local name="$1"
  local exec_start="$2"
  local src="$APP_DIR/system/$name"
  local dst="/etc/systemd/system/$name"

  echo "Installing $name from $APP_DIR"
  sudo cp "$src" "$dst"
  sudo sed -i "s|WorkingDirectory=.*|WorkingDirectory=$APP_DIR|g" "$dst"
  sudo sed -i "s|ExecStart=.*|ExecStart=$exec_start|g" "$dst"
  sudo sed -i "s|User=.*|User=$SERVICE_USER|g" "$dst"
}

install_service "ruok-device.service" "$APP_DIR/.venv/bin/python $APP_DIR/main.py"
install_service "ruok-wifi-setup.service" "$APP_DIR/.venv/bin/python -m wifi_setup.button_watcher"

sudo systemctl daemon-reload

echo "Installed. Start with:"
echo "  sudo systemctl enable ruok-device ruok-wifi-setup"
echo "  sudo systemctl start ruok-device ruok-wifi-setup"
echo "  journalctl -u ruok-device -f"
echo "  journalctl -u ruok-wifi-setup -f"
