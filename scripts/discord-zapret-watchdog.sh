#!/bin/bash
# Арбитр Discord↔zapret:
#   Discord есть      -> nfqws поднят
#   Discord закрыт 60с -> nfqws погашен
ZQ=/home/danze/zapret-discord-youtube-linux
off=0
while true; do
    if pgrep -x Discord >/dev/null 2>&1; then
        off=0
        if ! pgrep -x nfqws >/dev/null 2>&1 && ! pgrep -f 'service.sh daemon' >/dev/null 2>&1; then
            setsid sudo -n bash "$ZQ/service.sh" daemon >/dev/null 2>&1 &
        fi
    else
        off=$((off+1))
        if [ "$off" -ge 3 ] && pgrep -x nfqws >/dev/null 2>&1; then
            sudo -n bash "$ZQ/service.sh" kill >/dev/null 2>&1
        fi
    fi
    sleep 20
done
