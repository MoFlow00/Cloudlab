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
  echo
  echo "PDFCraft installer is not configured yet."
  echo "Add the verified installation steps inside install_pdfcraft() in menu.sh."
  return 2
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
