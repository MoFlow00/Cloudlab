# APP_NAME=GridCraft
# تثبيت GridCraft من ملف Debian الرسمي (.deb).
# لو حبيت تغيّر الطريقة، عدّل الأوامر هنا فقط.

set -e

echo "-> Checking system architecture..."
case "$(dpkg --print-architecture)" in
  amd64) ARCH="x86_64" ;;
  arm64) ARCH="aarch64" ;;
  *)
    echo "Unsupported CPU architecture: $(dpkg --print-architecture)"
    exit 1
    ;;
esac

echo "-> Finding the latest GridCraft release..."
API_URL="https://api.github.com/repos/storytold/gridcraft/releases/latest"
RELEASE_JSON="$(curl -fsSL --retry 3 "$API_URL")"

ASSET_URL="$(printf '%s' "$RELEASE_JSON" | jq -r --arg suffix "linux-${ARCH}.deb" '
  [.assets[] | select(.name | endswith($suffix)) | .browser_download_url][0] // empty
')"

if [ -z "$ASSET_URL" ]; then
  echo "Could not find an official GridCraft .deb for Linux ${ARCH}."
  echo "Check the releases page: https://github.com/storytold/gridcraft/releases"
  exit 1
fi

echo "-> Downloading official package..."
PACKAGE="$HOME/Downloads/$(basename "$ASSET_URL")"
mkdir -p "$HOME/Downloads"
curl -fL --retry 3 --retry-all-errors -o "$PACKAGE.part" "$ASSET_URL"
mv "$PACKAGE.part" "$PACKAGE"

echo "-> Installing GridCraft and resolving dependencies..."
sudo apt-get update
sudo apt-get install -y "$PACKAGE"

echo "-> Checking installation..."
if ! dpkg-query -W -f='${Status}' gridcraft 2>/dev/null | grep -q 'install ok installed'; then
  echo "GridCraft package verification failed."
  exit 1
fi

echo "=== GridCraft installed successfully ==="
echo "You can launch it from Applications, or try: gridcraft"
