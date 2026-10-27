# APP_NAME=Wine - Windows EXE Support
# Installs Wine support for running many Windows desktop apps and some games.
# Compatibility varies; graphics-heavy games may perform poorly in a temporary cloud desktop.

set -Eeuo pipefail

ARCH="$(dpkg --print-architecture)"
if [[ "$ARCH" == "amd64" ]]; then
  sudo dpkg --add-architecture i386
fi

sudo apt-get update
sudo apt-get install -y --no-install-recommends wine wine64 winetricks

if command -v wine >/dev/null 2>&1; then
  WINE_BIN="$(command -v wine)"
elif command -v wine64 >/dev/null 2>&1; then
  WINE_BIN="$(command -v wine64)"
else
  echo "Wine command was not found after installation."
  exit 1
fi

echo
echo "Wine installed: $WINE_BIN"
echo "Try: wine ~/Downloads/installer.exe"
echo "First run initializes a Wine prefix."
echo "Not all Windows apps/games are compatible; DirectX/Vulkan, anti-cheat and DRM are common limitations."
echo "Only run EXE files you trust."
