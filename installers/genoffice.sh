# APP_NAME=GenOffice
# Install the official GenOffice Debian package from the latest GitHub release.
# GenOffice supports Ubuntu/Debian x86_64 with glibc 2.34+ (Ubuntu 22.04+).
# The editor works locally; AI features require provider sign-in or your own API key.

set -Eeuo pipefail

if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
  echo "GenOffice official .deb is currently published for x86_64/amd64 Linux."
  echo "Detected architecture: $(dpkg --print-architecture)"
  exit 1
fi

. /etc/os-release
if [[ "${VERSION_ID:-0}" == "20.04" ]]; then
  echo "GenOffice requires glibc 2.34 or newer (Ubuntu 22.04+)."
  echo "This system appears to be Ubuntu 20.04, so installation is not supported."
  exit 1
fi

echo "-> Checking for the latest official GenOffice release..."
RELEASE_JSON="$(curl -fsSL --retry 5 --retry-all-errors \
  https://api.github.com/repos/genspark-ai/genoffice/releases/latest)"

ASSET_URL="$(printf '%s' "$RELEASE_JSON" | jq -r '
  [.assets[] | select(.name | test("^genoffice_[0-9.]+_amd64\\.deb$")) | .browser_download_url][0] // empty
')"

if [[ -z "$ASSET_URL" ]]; then
  echo "Could not find an official GenOffice amd64 .deb in the latest release."
  echo "Check: https://github.com/genspark-ai/genoffice/releases"
  exit 1
fi

mkdir -p "$HOME/Downloads"
PACKAGE="$HOME/Downloads/$(basename "$ASSET_URL")"

echo "-> Downloading GenOffice package..."
curl -fL --retry 5 --retry-all-errors -o "$PACKAGE.part" "$ASSET_URL"
mv "$PACKAGE.part" "$PACKAGE"

echo "-> Installing GenOffice and resolving dependencies..."
sudo apt-get update
sudo apt-get install -y "$PACKAGE"

echo "-> Verifying installation..."
if ! dpkg-query -W -f='${Status}' genoffice 2>/dev/null | grep -q 'install ok installed'; then
  echo "GenOffice package verification failed."
  exit 1
fi

echo "=== GenOffice installed successfully ==="
echo "Launch it from Applications, or try: genoffice"
echo "AI features need a provider sign-in or your own API key."
