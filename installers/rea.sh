# APP_NAME=REA - Reverse Engineer Anything
# Official project: https://github.com/morluto/rea
# Installs a supported Node.js runtime locally if needed, then launches the official REA setup.

set -Eeuo pipefail

# REA's published engine range is ^22.23.4 || ^24.22.1 || >=26.12.1.
# The runner's bundled Node 22.23.3 is one patch too old, so use a private
# Node 22.23.4 runtime without changing the system-wide Node installation.
NODE_VERSION="$(node -p 'process.versions.node' 2>/dev/null || echo 0)"
if node -e 'const [M,m,p]=process.versions.node.split(".").map(Number); process.exit((M===22 && (m>23 || (m===23 && p>=4))) || (M===24 && (m>22 || (m===22 && p>=1))) || M>=26 && (M>26 || m>12 || (m===12 && p>=1)) ? 0 : 1)' 2>/dev/null; then
  echo "Using installed supported Node.js $NODE_VERSION"
  NODE_BIN="$(dirname "$(command -v node)")"
else
  echo "Installed Node.js is $NODE_VERSION; preparing supported Node.js 22.23.4 locally..."
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64|amd64) NODE_ARCH="x64" ;;
    aarch64|arm64) NODE_ARCH="arm64" ;;
    *) echo "Unsupported CPU architecture for automatic Node.js setup: $ARCH"; exit 1 ;;
  esac

  NODE_VER="22.23.4"
  NODE_HOME="$HOME/.local/opt/node-v$NODE_VER-linux-$NODE_ARCH"
  if [[ ! -x "$NODE_HOME/bin/node" ]]; then
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends curl ca-certificates xz-utils
    mkdir -p "$HOME/.local/opt" /tmp/cloudlab-node
    curl -fL --retry 3 --retry-all-errors \
      "https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-linux-$NODE_ARCH.tar.xz" \
      -o "/tmp/cloudlab-node/node-v$NODE_VER.tar.xz"
    tar -xJf "/tmp/cloudlab-node/node-v$NODE_VER.tar.xz" -C /tmp/cloudlab-node
    mv "/tmp/cloudlab-node/node-v$NODE_VER-linux-$NODE_ARCH" "$NODE_HOME"
    rm -f "/tmp/cloudlab-node/node-v$NODE_VER.tar.xz"
  fi
  NODE_BIN="$NODE_HOME/bin"
fi

export PATH="$NODE_BIN:$PATH"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"

npx --yes rea-agents@latest setup
echo
echo "REA setup command finished. Restart any agent it configured."
