# APP_NAME=FreeLLMAPI - Local AI Gateway
# Official project: https://github.com/tashfeenahmed/freellmapi
# Requires Docker; configuration is stored under ~/freellmapi.

set -Eeuo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required. Installing Ubuntu's Docker engine and Compose plugin..."
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose-v2 openssl git
fi

if ! sudo docker info >/dev/null 2>&1; then
  echo "Attempting to start Docker for this session..."
  sudo service docker start || true
fi

if ! sudo docker info >/dev/null 2>&1; then
  echo "Docker daemon is unavailable in this CloudLab environment."
  echo "FreeLLMAPI cannot run without Docker. No configuration was changed."
  exit 1
fi

if [[ ! -d "$HOME/freellmapi" ]]; then
  git clone --depth 1 https://github.com/tashfeenahmed/freellmapi.git "$HOME/freellmapi"
fi

cd "$HOME/freellmapi"
if [[ ! -f .env ]]; then
  KEY="$(openssl rand -hex 32)"
  umask 077
  printf 'ENCRYPTION_KEY=%s\nPORT=3001\nHOST_BIND=127.0.0.1\n' "$KEY" > .env
  chmod 600 .env
fi

sudo docker compose up -d
echo
echo "FreeLLMAPI started (if the container became healthy)."
echo "Dashboard: http://127.0.0.1:3001"
echo "Add provider API keys in the dashboard. Providers control their own free-tier availability and limits."
echo "CloudLab sessions are temporary; back up ~/freellmapi/.env and data if you need persistence."
