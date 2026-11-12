#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Simple bash script to check and will try to update your system

# Local Paths
iDIR="$HOME/.config/swaync/images"

# Check for required tools (kitty)
if ! command -v kitty &> /dev/null; then
  notify-send -i "$iDIR/error.png" "Нужен Kitty:" "Нет терминала Kitty. Установи Kitty."
  exit 1
fi

# Detect distribution and update accordingly
if command -v paru &> /dev/null || command -v yay &> /dev/null; then
  # Arch-based
  if command -v paru &> /dev/null; then
    kitty -T update -e paru -Syu
    notify-send -i "$iDIR/ja.png" -u low 'Arch-система' 'обновлена.'
  else
    kitty -T update -e yay -Syu
    notify-send -i "$iDIR/ja.png" -u low 'Arch-система' 'обновлена.'
  fi
elif command -v dnf &> /dev/null; then
  # Fedora-based
  kitty -T update -e sudo dnf update --refresh -y
  notify-send -i "$iDIR/ja.png" -u low 'Fedora-система' 'обновлена.'
elif command -v apt &> /dev/null; then
  # Debian-based (Debian, Ubuntu, etc.)
  kitty -T update -e bash -c "sudo apt update && sudo apt upgrade -y"
  notify-send -i "$iDIR/ja.png" -u low 'Debian/Ubuntu-система' 'обновлена.'
elif command -v zypper &> /dev/null; then
  # openSUSE-based
  kitty -T update -e sudo zypper dup -y
  notify-send -i "$iDIR/ja.png" -u low 'openSUSE-система' 'обновлена.'
else
  # Unsupported distro
  notify-send -i "$iDIR/error.png" -u critical "Не поддерживается" "Твой дистрибутив скрипт не знает."
  exit 1
fi
