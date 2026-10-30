#!/usr/bin/env bash
# CloudLab menu: programs are loaded automatically from /opt/cloudlab/installers/*.sh
set -u

INSTALL_DIR="/opt/cloudlab/installers"

while true; do
  clear 2>/dev/null || true
  echo "        CloudLab Software Menu"
  echo "----------------------------------------"

  files=()
  names=()
  shopt -s nullglob
  for file in "$INSTALL_DIR"/*.sh; do
    name="$(sed -n 's/^# APP_NAME=//p' "$file" | head -n 1)"
    [[ -n "$name" ]] || name="$(basename "$file" .sh)"
    files+=("$file")
    names+=("$name")
  done

  if (( ${#files[@]} == 0 )); then
    echo "No programs have been added yet."
  else
    for i in "${!files[@]}"; do
      printf " %2d) %s\n" "$((i + 1))" "${names[$i]}"
    done
  fi

  echo "----------------------------------------"
  echo "  0) Exit"
  echo
  read -r -p "Choose a program: " choice

  [[ "$choice" == "0" ]] && exit 0
  if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#files[@]} )); then
    echo "Invalid choice."
    read -r -p "Press Enter to continue..." _
    continue
  fi

  selected="${files[$((choice - 1))]}"
  echo
  echo "Installing: ${names[$((choice - 1))]}"
  echo "----------------------------------------"
  if bash "$selected"; then
    echo
    echo "Installer completed: ${names[$((choice - 1))]}"
  else
    rc=$?
    echo
    echo "INSTALLATION FAILED: ${names[$((choice - 1))]} (exit code $rc)"
    echo "Read the error above, fix the program's script, and try again."
  fi
  echo
  read -r -p "Press Enter to return to menu..." _
done
