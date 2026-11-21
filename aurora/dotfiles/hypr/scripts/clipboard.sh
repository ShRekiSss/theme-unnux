#!/usr/bin/env bash
# ── Aurora · история буфера обмена ─────────────────────────────
# Выбор записи через rofi, вставка в активное окно.

set -euo pipefail

if ! command -v cliphist >/dev/null 2>&1; then
    notify-send -a Aurora "Буфер обмена" "cliphist не установлен"
    exit 1
fi

choice=$(cliphist list | rofi -dmenu -i -p "  Буфер" \
    -theme ~/.config/rofi/aurora.rasi \
    -theme-str 'listview { lines: 10; columns: 1; }' \
    -theme-str 'window { width: 560px; }' || true)

[[ -z "${choice}" ]] && exit 0
cliphist decode <<<"${choice}" | wl-copy
