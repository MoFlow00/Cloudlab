# APP_NAME=REA - Reverse Engineer Anything
# Official project: https://github.com/morluto/rea
# Installs the official REA agent/MCP CLI and launches its guided setup.

set -Eeuo pipefail

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "Node.js/npm missing. Installing distro packages..."
  sudo apt-get update
  sudo apt-get install -y nodejs npm
fi

NODE_VERSION="$(node -p 'process.versions.node' 2>/dev/null || echo 0)"
NODE_MAJOR="${NODE_VERSION%%.*}"
if [[ ! "$NODE_MAJOR" =~ ^[0-9]+$ ]] || (( NODE_MAJOR < 23 )); then
  echo "Installed Node.js is $NODE_VERSION; current REA package requires a newer Node.js release."
  echo "Please install a supported Node.js release (see https://github.com/morluto/rea/blob/main/docs/installation.md), then run this option again."
  exit 1
fi

npx --yes rea-agents@latest setup
echo "REA setup command finished. Restart any agent it configured."
