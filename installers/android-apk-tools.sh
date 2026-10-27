# APP_NAME=Android APK Tools - ADB + APK Analyzer
# Installs ADB, fastboot and APK inspection tools.
# This does not promise an Android emulator: GitHub-hosted runners generally do not expose nested KVM acceleration.

set -Eeuo pipefail

sudo apt-get update
sudo apt-get install -y adb fastboot apksigner aapt apktool

echo
echo "Android SDK command-line tools installed:"
adb version
echo
echo "APK inspection:"
echo "  aapt dump badging your-app.apk"
echo "  apksigner verify --verbose --print-certs your-app.apk"
echo
echo "To RUN an APK, an Android runtime/device is also required."
echo "This workflow does not install Waydroid because it requires Android container support and kernel features unavailable on typical GitHub-hosted runners."
echo "Connect a real Android device with ADB over network, or use an Android emulator on a machine with virtualization support."
