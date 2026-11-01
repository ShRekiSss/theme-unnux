#!/bin/bash
# «Показать рабочий стол» как Win+D: прячет все окна на скрытый стол и возвращает обратно.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE="$HOME/.cache/hypr-desktop-hidden"

if [ -s "$STATE" ]; then
    hyprctl dispatch togglespecialworkspace desktop >/dev/null
    while IFS=$'\t' read -r addr ws; do
        [ -n "$addr" ] || continue
        hyprctl dispatch movetoworkspacesilent "$ws,address:$addr" >/dev/null
    done < "$STATE"
    rm -f "$STATE"
else
    mkdir -p "$(dirname "$STATE")"
    hyprctl clients -j \
        | jq -r '.[] | select(.workspace.id >= 0) | [.address, .workspace.id] | @tsv' > "$STATE"

    if [ ! -s "$STATE" ]; then
        rm -f "$STATE"
        exit 0
    fi

    cut -f1 "$STATE" | while read -r a; do
        hyprctl dispatch movetoworkspacesilent "special:desktop,address:$a" >/dev/null
    done
    hyprctl dispatch togglespecialworkspace desktop >/dev/null
fi
