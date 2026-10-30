#!/usr/bin/env bash
set -euo pipefail
PYTHON="$HOME/.local/share/cloudlab/venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
  notify-send "CloudLab Project Lab" "App environment missing. Restart the CloudLab session." || true
  exit 1
fi
exec "$PYTHON" /opt/cloudlab/app.py
