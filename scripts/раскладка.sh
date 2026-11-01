#!/bin/bash
# Показывает текущую раскладку для Waybar: EN / РУ
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)}"
kb=$(hyprctl -j devices 2>/dev/null | jq -r '.keyboards[] | select(.main==true) | .active_keymap' 2>/dev/null | head -1)
case "$kb" in
    *Russian*|*ru*) echo "РУ" ;;
    *English*|*us*) echo "EN" ;;
    *)             echo "--" ;;
esac
