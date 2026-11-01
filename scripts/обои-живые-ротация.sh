#!/bin/bash
# Ротация живых обоев: раз в 5 минут — случайный другой клип (через ipc mpv)
export XDG_RUNTIME_DIR="/run/user/1000"
echo $$ > /tmp/обои-живые-rotation.pid

INTERVAL=300
SOCK=/tmp/mpvpaper-sock
CUR_FILE=/tmp/обои-живые-текущий
DIR="/home/danze/Обои/анимации"

while true; do
    sleep "$INTERVAL"
    [ -f "$CUR_FILE" ] || continue
    cur=$(cat "$CUR_FILE")
    while :; do
        next=$(find "$DIR" -maxdepth 1 -name '*.mp4' | shuf -n 1)
        [ "$next" != "$cur" ] && break
    done
    printf '{"command":["loadfile","%s"],"sync":true}\n' "$next" \
        | socat - UNIX-CONNECT:"$SOCK" >/dev/null 2>&1 && echo "$next" > "$CUR_FILE"
done
