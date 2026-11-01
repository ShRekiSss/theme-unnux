#!/bin/bash
# Меню питания для панели Waybar
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)}"

choice=$(printf '%s\n' \
    "Выключить" \
    "Перезагрузить" \
    "Заблокировать" \
    "Выйти из сессии" \
    "Спящий режим" \
    | wofi --dmenu --prompt "Питание" --width 340 --height 330 --cache-file /dev/null)

case "$choice" in
    "Выключить")        systemctl poweroff ;;
    "Перезагрузить")    systemctl reboot ;;
    "Заблокировать")    setsid -f hyprlock >/dev/null 2>&1 ;;
    "Выйти из сессии")  hyprctl dispatch exit ;;
    "Спящий режим")     systemctl suspend ;;
esac
