#!/usr/bin/env bash
# CloudLab software menu
# Add each program as an install_<id>() function and register it in PROGRAM_IDS.
# Keep installation steps explicit and tested. Do not hide errors with "|| true".

set -Eeuo pipefail

PROGRAM_IDS=(pdfcraft gridcraft)

program_name() {
  case "$1" in
    pdfcraft) printf '%s' 'PDFCraft' ;;
    gridcraft) printf '%s' 'GridCraft' ;;
    *) printf '%s' "$1" ;;
  esac
}

install_pdfcraft() {
  local downloads="$HOME/Downloads"
  local package="$downloads/pdfcraft-0.13.0-linux-x86_64.deb"
  local url="https://github.com/storytold/pdfcraft/releases/download/v0.13.0/pdfcraft-0.13.0-linux-x86_64.deb"

  mkdir -p "$downloads"
  sudo apt-get update
  sudo apt-get install -y wget ca-certificates

  if [[ ! -s "$package" ]]; then
    wget -O "$package.part" "$url"
    mv "$package.part" "$package"
  else
    echo "Using existing package: $package"
  fi

  # Install the local DEB and let apt resolve its dependencies.
  sudo apt-get install -y "$package"
  sudo apt-get install -y libxkbcommon-x11-0 libxcb-xkb1

  if ! dpkg-query -W -f='${Status}' pdfcraft 2>/dev/null | grep -q 'install ok installed'; then
    echo "PDFCraft package verification failed."
    return 1
  fi
  echo "PDFCraft package is installed."
}

install_gridcraft() {
  echo
  echo "GridCraft installer is not configured yet."
  echo "Add the verified installation steps inside install_gridcraft() in menu.sh."
  return 2
}

run_installer() {
  local id="$1"
  local fn="install_${id}"
  if ! declare -F "$fn" >/dev/null; then
    echo "Error: installer function '$fn' does not exist."
    return 2
  fi

  echo
  echo "========================================"
  echo "Installing: $(program_name "$id")"
  echo "========================================"

  if "$fn"; then
    echo
    echo "Installer completed: $(program_name "$id")"
  else
    local rc=$?
    echo
    echo "INSTALLATION FAILED: $(program_name "$id") (exit code $rc)"
    echo "Read the error above, fix the installer, then run menu again."
    return "$rc"
  fi
}

while true; do
  clear 2>/dev/null || true
  echo "        CloudLab Software Menu"
  echo "----------------------------------------"
  for i in "${!PROGRAM_IDS[@]}"; do
    printf " %2d) %s\n" "$((i + 1))" "$(program_name "${PROGRAM_IDS[$i]}")"
  done
  echo "----------------------------------------"
  echo "  0) Exit"
  echo
  read -r -p "Choose a program: " choice

  [[ "$choice" == "0" ]] && exit 0
  if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#PROGRAM_IDS[@]} )); then
    echo "Invalid choice."
    read -r -p "Press Enter to continue..." _
    continue
  fi

  id="${PROGRAM_IDS[$((choice - 1))]}"
  run_installer "$id" || true
  echo
  read -r -p "Press Enter to return to menu..." _
done
