# APP_NAME=Wine - Windows EXE Support
# Installs Wine for compatible Windows applications and some games. Compatibility varies.

set -Eeuo pipefail

if [[ "$(dpkg --print-architecture)" == "amd64" ]]; then
  sudo dpkg --add-architecture i386
fi

sudo apt-get update
sudo apt-get install -y --no-install-recommends wine wine64 winetricks

if ! command -v wine >/dev/null 2>&1 && ! command -v wine64 >/dev/null 2>&1; then
  echo "Wine command not found after installation."
  exit 1
fi

echo
echo "Wine installed."
echo "Try: wine ~/Downloads/installer.exe"
echo "Not all programs/games work. Graphics-heavy games, anti-cheat and DRM may fail or perform poorly in a cloud desktop."
echo "Only run EXE files you trust."
