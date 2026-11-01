#!/bin/bash
# ══════════════════════════════════════════════════════════════
#  «Звук ставится на своём рабочем столе»
#  Рабочий стол 1 — играет его звук; перешёл на 2 — играет только
#  то, что открыто на 2. Один стол = один звук.
# ══════════════════════════════════════════════════════════════
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t /run/user/1000/hypr/ 2>/dev/null | head -1)}"

exec 9>/tmp/звук-по-рабочим.lock
flock -n 9 || exit 0
echo $$ > /tmp/звук-по-рабочим.pid   # чтобы легко остановить: kill $(cat ~/.звук-по-рабочим.pid)

PREV_WS=""
PREV_MAP=""

log(){ echo "$(date '+%H:%M:%S') $*" >> /tmp/звук-по-рабочим.log; }

# имя бинарника процесса
binname(){ basename "$(readlink -f "/proc/$1/exe" 2>/dev/null)" 2>/dev/null; }

apply(){
    local ws="$1" s sid spid sbin sapp tws pinned pid cls
    local CLIENTS STREAMS
    CLIENTS=$(hyprctl -j clients 2>/dev/null | tr -d '\000') || return
    [ -z "$CLIENTS" ] && return

    STREAMS=$(pw-dump 2>/dev/null | jq -c '
      [.[] | select(.type=="PipeWire:Interface:Node"
                    and .info.props["media.class"]=="Stream/Input/Audio") ] |
      map({id:.id,
           pid:(.info.props["application.process.id"] // ""),
           app:(.info.props["application.name"] // ""),
           bin:(.info.props["application.process.binary"] // "")}) .[]') || return
    [ -z "$STREAMS" ] && return

    while IFS= read -r s; do
        [ -z "$s" ] && continue
        sid=$(echo "$s" | jq -r .id)
        spid=$(echo "$s" | jq -r .pid)
        sbin=$(echo "$s" | jq -r .bin | tr '[:upper:]' '[:lower:]')
        sapp=$(echo "$s" | jq -r .app | tr '[:upper:]' '[:lower:]')
        tws=""; pinned="false"

        # 1) точное совпадение pid окна и звукового потока
        tws=$(echo "$CLIENTS" | jq -r --argjson p "$spid" \
            '[.[] | select(.pid==$p) | .workspace.id][0] // empty' 2>/dev/null)
        if [ -n "$tws" ]; then
            pinned=$(echo "$CLIENTS" | jq -r --argjson p "$spid" \
                '[.[] | select(.pid==$p) | .pinned][0] // "false"' 2>/dev/null)
        fi

        # 2) совпадение по имени бинарника (например discord.exe ↔ Discord)
        if [ -z "$tws" ] && [ -n "$sbin" ] && [ "$sbin" != "null" ]; then
            for pid in $(echo "$CLIENTS" | jq -r '.[].pid' 2>/dev/null); do
                b=$(binname "$pid" | tr '[:upper:]' '[:lower:]')
                if [ "$b" = "$sbin" ]; then
                    tws=$(echo "$CLIENTS" | jq -r --argjson p "$pid" \
                        '[.[] | select(.pid==$p) | .workspace.id][0] // empty' 2>/dev/null)
                    pinned=$(echo "$CLIENTS" | jq -r --argjson p "$pid" \
                        '[.[] | select(.pid==$p) | .pinned][0] // "false"' 2>/dev/null)
                    break
                fi
            done
        fi

        # 3) грубый запас: имя приложения встречается в классе окна
        if [ -z "$tws" ] && [ -n "$sapp" ] && [ "$sapp" != "null" ]; then
            for pid in $(echo "$CLIENTS" | jq -r '.[].pid' 2>/dev/null); do
                cls=$(echo "$CLIENTS" | jq -r --argjson p "$pid" \
                    '[.[] | select(.pid==$p) | .class][0] // empty' 2>/dev/null | tr '[:upper:]' '[:lower:]')
                case "$cls" in
                    *"$sapp"*|*"$sbin"*)
                        tws=$(echo "$CLIENTS" | jq -r --argjson p "$pid" \
                            '[.[] | select(.pid==$p) | .workspace.id][0] // empty' 2>/dev/null)
                        pinned=$(echo "$CLIENTS" | jq -r --argjson p "$pid" \
                            '[.[] | select(.pid==$p) | .pinned][0] // "false"' 2>/dev/null)
                        break ;;
                esac
            done
        fi

        [ -z "$tws" ] && continue          # не привязываем системный звук

        if [ "$pinned" = "true" ] || [ "$tws" = "$ws" ]; then
            wpctl set-mute "$sid" 0 >/dev/null 2>&1    # этот стол звучит
        else
            wpctl set-mute "$sid" 1 >/dev/null 2>&1    # чужой стол молчит
        fi
    done <<< "$STREAMS"
}

log "старт"
CUR=$(hyprctl -j activeworkspace 2>/dev/null | jq -r .id)
[ "$CUR" = "null" ] && CUR=""
PREV_WS=$CUR
PREV_MAP=$(hyprctl -j clients 2>/dev/null | tr -d '\000' | jq -r 'map(select(.workspace.id > 0)) | map([.pid,.workspace.id,.class,.pinned]) | sort_by(.[0]) | tostring' 2>/dev/null)
apply "$CUR"

while sleep 1; do
    CUR=$(hyprctl -j activeworkspace 2>/dev/null | jq -r .id 2>/dev/null)
    { [ -z "$CUR" ] || [ "$CUR" = "null" ]; } && continue
    NEWMAP=$(hyprctl -j clients 2>/dev/null | tr -d '\000' | jq -r 'map(select(.workspace.id > 0)) | map([.pid,.workspace.id,.class,.pinned]) | sort_by(.[0]) | tostring' 2>/dev/null)
    if [ "$CUR" != "$PREV_WS" ] || [ "$NEWMAP" != "$PREV_MAP" ]; then
        log "смена: $PREV_WS → $CUR"
        PREV_WS="$CUR"
        PREV_MAP="$NEWMAP"
        apply "$CUR"
    fi
done
