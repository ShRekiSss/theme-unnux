#!/usr/bin/env bash
# ── Aurora · обои ─────────────────────────────────────────────
# usage: wallpaper.sh [init|next]
#   init — применить текущие обои при старте сессии
#   next — переключить на следующие
# Использует swaybg: простой и стабильный слой под Wayland.

set -euo pipefail

dir="${HOME}/.local/share/wallpapers/aurora"
state="${HOME}/.config/hypr/.wallpaper"
mode="${1:-next}"

mapfile -t walls < <(find "$dir" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    ! -name '*-blur.*' 2>/dev/null | sort)

if (( ${#walls[@]} == 0 )); then
    notify-send -a Aurora "Обои" "В $dir нет изображений" 2>/dev/null || true
    exit 1
fi

current=""
[[ -f "$state" ]] && current="$(<"$state")"

wall="$current"
if [[ "$mode" == "next" ]]; then
    idx=0
    for i in "${!walls[@]}"; do
        [[ "${walls[$i]}" == "$current" ]] && idx=$(( (i + 1) % ${#walls[@]} ))
    done
    wall="${walls[$idx]}"
fi

if [[ -z "$wall" || ! -f "$wall" ]]; then
    wall="${walls[0]}"
fi

pkill -x swaybg 2>/dev/null || true
swaybg -i "$wall" -m fill >/dev/null 2>&1 &
disown 2>/dev/null || true

printf '%s\n' "$wall" > "$state"

if [[ "$mode" != "init" ]]; then
    notify-send -a Aurora "Обои" "$(basename "$wall")" 2>/dev/null || true
fi
