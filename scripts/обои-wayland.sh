#!/bin/bash
# Обои для Hyprland через swww. Без аргумента — случайные из ~/Обои,
# с аргументом-путём — конкретный файл.
set -u

DIR="$HOME/Обои"
CUR="$HOME/.cache/current-wallpaper"
mkdir -p "$(dirname "$CUR")"

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
    swww-daemon >/dev/null 2>&1 &
    for _ in $(seq 1 50); do
        swww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

pick() {
    if [ -n "${1:-}" ] && [ -f "$1" ]; then
        echo "$1"
        return
    fi
    find "$DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | shuf -n 1
}

f=$(pick "${1:-}")
if [ -z "$f" ]; then
    echo "нет обоев в $DIR"
    exit 1
fi

ln -sfn "$f" "$CUR"

swww img "$f" \
    --resize crop \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-duration 1.2 \
    --transition-fps 60

echo "обои: $f"
