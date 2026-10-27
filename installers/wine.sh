# APP_NAME=Wine - Windows EXE Support
# Installs Wine and basic helper tools for running many Windows apps.
# Compatibility varies; not all apps/games work, and graphics-heavy games may be slow.

set -Eeuo pipefail

ARCH="$(dpkg --print-architecture)"
if [[ "$ARCH" == "amd64" ]]; then
  echo "-> Enabling 32-bit architecture for older Windows applications..."
  sudo dpkg --add-architecture i386
else
  echo "Detected architecture: $ARCH. Wine support and Windows app compatibility may be limited."
fi

sudo apt-get update
sudo apt-get install -y --install-recommends wine wine64 wine32 winetricks

echo
echo "Wine installed."
echo "Run a Windows installer with: wine ~/Downloads/installer.exe"
echo "First run creates a Wine prefix. For best isolation, test unknown EXE files only in this disposable session."
