# APP_NAME=Android APK Testing - ADB and APK Inspector
# Installs Android debugging and APK inspection utilities.
# Running an APK needs a real Android device or a working emulator; nested virtualization is not guaranteed in CloudLab.

set -Eeuo pipefail

sudo apt-get update
sudo apt-get install -y --no-install-recommends adb fastboot apksigner aapt apktool

echo
echo "Android APK inspection tools are ready."
echo "Inspect an APK:"
echo "  aapt dump badging ~/Downloads/app.apk"
echo "  apksigner verify --verbose --print-certs ~/Downloads/app.apk"
echo
echo "To run an APK, connect a real Android device with ADB or use an emulator that supports hardware virtualization."
echo "This GitHub-hosted CloudLab runner may not be able to boot an Android emulator. APK install/run is not claimed as verified here."
