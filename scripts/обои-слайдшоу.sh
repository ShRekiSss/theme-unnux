#!/bin/bash
# Слайдшоу обоев Hyprland: статичные картинки из ~/Обои,
# случайная смена каждые 15 минут через swww (плавное растворение)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)}"

# защита от повторного запуска (exec-once иногда дублируется)
exec 9>/tmp/обои-слайдшоу.lock
flock -n 9 || exit 0

DIR="/home/danze/Обои"
LAST="/tmp/обои-слайдшоу-текущий"
INTERVAL="${INTERVAL:-300}"   # 300 секунд = 5 минут

pgrep -x swww-daemon >/dev/null || setsid -f swww-daemon >/dev/null 2>&1
sleep 1

pick() {
    find "$DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1
}

# первая случайная картинка
f="$(pick)"
[ -n "$f" ] && swww img "$f" --transition-type fade --transition-duration 1 >/dev/null 2>&1
echo "$f" > "$LAST"

# дальше просто ждём и меняем (fd 9 не отдаём детям, иначе lock зависает)
while true; do
    sleep "$INTERVAL" 9>&-
    while :; do
        f="$(pick)"
        [ "$f" != "$(cat "$LAST" 2>/dev/null)" ] && break
    done
    swww img "$f" --transition-type fade --transition-duration 2 9>&- >/dev/null 2>&1
    echo "$f" > "$LAST"
done
