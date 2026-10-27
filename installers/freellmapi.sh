# APP_NAME=FreeLLMAPI - Local AI Gateway
# Official project: https://github.com/tashfeenahmed/freellmapi
# Requires Docker; config and provider keys are stored in ~/freellmapi.

set -Eeuo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Installing Ubuntu's Docker engine and Compose plugin..."
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose-v2 openssl
fi

if ! sudo docker info >/dev/null 2>&1; then
  echo "Docker daemon is unavailable. Attempting to start it for this session..."
  sudo service docker start || true
fi

if ! sudo docker info >/dev/null 2>&1; then
  echo "Docker is not usable in this CloudLab session."
  echo "FreeLLMAPI needs a running Docker daemon; containerized services may not be supported here."
  exit 1
fi

if [[ ! -d "$HOME/freellmapi" ]]; then
  git clone --depth 1 https://github.com/tashfeenahmed/freellmapi.git "$HOME/freellmapi"
else
  echo "Existing $HOME/freellmapi directory found; leaving its configuration intact."
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
echo "FreeLLMAPI startup requested."
echo "Try the dashboard at http://127.0.0.1:3001"
echo "Add provider API keys in the dashboard; free tiers and quotas are controlled by each provider."
echo "NOTE: CloudLab sessions are temporary. Back up ~/freellmapi/.env and its data if you need persistence."
