#!/bin/bash
# Discord-фикс-прошивка v2:
#  1) гасит зависшие инстансы, чистит кеш
#  2) поднимает zapret, если тот не запущен
#  3) ставит watchdog: как только Discord целиком закрыт — глушит zapret
ZQ=/home/danze/zapret-discord-youtube-linux
D=~/.var/app/com.discordapp.Discord/config/discord

flatpak kill com.discordapp.Discord 2>/dev/null
sleep 1
pkill -x Discord 2>/dev/null

rm -rf "$D/Cache" "$D/Code Cache" "$D/GPUCache" "$D/DawnGraphiteCache" "$D/DawnWebGPUCache" "$D/blob_storage" 2>/dev/null

# watchdog теперь живёт как systemd-юнит discord-zapret-watchdog.service,
# работает в любой сессии и сам поднимает/глушит zapret — тут ничего не нужно

# если запрет злостно спит — будим
if ! sudo -n pgrep -x nfqws >/dev/null 2>&1; then
    ( setsid sudo -n bash "$ZQ/service.sh" daemon >/dev/null 2>&1 & )
    sleep 6
fi

exec flatpak run com.discordapp.Discord "$@"
