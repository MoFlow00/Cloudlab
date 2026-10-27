# APP_NAME=REA - Reverse Engineer Anything
# Installs the official rea-agents CLI/MCP server and launches its guided setup.
# Official project: https://github.com/morluto/rea

set -Eeuo pipefail

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "Node.js and npm are required. Installing Ubuntu's Node.js packages..."
  sudo apt-get update
  sudo apt-get install -y nodejs npm
fi

NODE_MAJOR="$(node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || echo 0)"
if (( NODE_MAJOR < 22 )); then
  echo "REA currently requires a recent Node.js runtime (Node 22.23.4+ or newer supported release)."
  echo "The Ubuntu package version is too old. Install a supported Node.js release, then retry."
  exit 1
fi

echo "-> Running the official REA setup wizard..."
npx --yes rea-agents@latest setup

echo
echo "REA setup finished (or the wizard was cancelled)."
echo "Review every proposed agent-config change in the wizard before approving it."
