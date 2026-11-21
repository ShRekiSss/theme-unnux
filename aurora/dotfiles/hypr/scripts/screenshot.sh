#!/usr/bin/env bash
# ── Aurora · скриншоты ─────────────────────────────────────────
# usage: screenshot.sh [region|full]
# Сохраняет в ~/Изображения/Screenshots и копирует в буфер.

set -euo pipefail

mode="${1:-region}"
dir="${HOME}/Изображения/Screenshots"
mkdir -p "$dir"
file="${dir}/shot-$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
    region)
        geom=$(slurp 2>/dev/null) || exit 0
        grim -g "$geom" "$file"
        ;;
    full)
        grim "$file"
        ;;
    *)
        echo "usage: $0 [region|full]" >&2
        exit 2
        ;;
esac

wl-copy < "$file"
notify-send -a Aurora -i "$file" "Скриншот готов" "$(basename "$file") · скопирован в буфер"
