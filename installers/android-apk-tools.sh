# APP_NAME=Android APK Testing - Android Studio Emulator
# Installs ADB/APK tools and offers a best-effort Android Studio emulator setup.
# Emulator execution depends on KVM/nested virtualization, which GitHub-hosted runners may not provide.

set -Eeuo pipefail

sudo apt-get update
sudo apt-get install -y adb fastboot apksigner aapt apktool

echo
echo "APK inspection tools are ready."
echo "Examples:"
echo "  aapt dump badging ~/Downloads/app.apk"
echo "  apksigner verify --verbose --print-certs ~/Downloads/app.apk"
echo
echo "To install and run an APK, you need an Android runtime/device."
echo "This cloud runner does not guarantee KVM or nested virtualization, so an emulator may fail to boot or be too slow."
echo
echo "Recommended reliable path: use ADB to connect to a real Android device on your network, or use a cloud Android testing service."
echo "If you want to test now, keep the APK in Downloads and inspect it with the commands above."
