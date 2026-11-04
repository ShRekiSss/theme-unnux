#!/bin/bash
# ─── «Прилепить/отклеить окно на ВСЕ рабочие столы» (Win + Y) ───
# Работает с активным окном: сейчас не приклеено → отклеивает
# (делает плавающим) и показывает на всех столах.
# Уже приклеено → возвращает обратно в плитку на своём столе.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t /run/user/1000/hypr/ 2>/dev/null | head -1)}"

STATE=$(hyprctl -j activewindow 2>/dev/null | jq -r '"\(.address) \(.pinned)"')
ADDR=$(echo "$STATE" | cut -d' ' -f1)
PINNED=$(echo "$STATE" | cut -d' ' -f2)

# окно должно существовать и не быть полноэкранным
FS=$(hyprctl -j activewindow 2>/dev/null | jq -r '.fullscreen')
if [ "$FS" != "0" ] && [ "$FS" != "null" ]; then
    # на весь экран — сначала снимаем fullscreen
    hyprctl dispatch togglefullscreen >/dev/null
fi

if [ "$PINNED" != "true" ]; then
    # плаваем + приклеиваем на все столы
    hyprctl dispatch togglefloating >/dev/null
    sleep 0.15
    hyprctl dispatch pin >/dev/null
else
    # убрать с «всех столов» и назад в плитку
    hyprctl dispatch pin >/dev/null
    sleep 0.15
    hyprctl dispatch togglefloating >/dev/null
fi

N=$(hyprctl -j activewindow 2>/dev/null | jq -r .pinned)
if [ "$N" = "true" ]; then
    echo "📌 окно приклеено на все столы"
else
    echo "📌 приклейка снята — окно обратно в плитке"
fi
