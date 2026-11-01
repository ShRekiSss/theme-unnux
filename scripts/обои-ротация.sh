#!/bin/bash
# Ротация обоев Xfce каждые 15 минут (нагрузка нуль)
DIR="/home/danze/Обои"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
DISPLAY=${DISPLAY:-:0.0}
while true; do
  f=$(find "$DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
  if [ -n "$f" ]; then
    for m in monitor0 monitor1; do
      xfconf-query -c xfce4-desktop -p "/backdrop/screen0/$m/last-image" -s "$f" 2>/dev/null
      xfconf-query -c xfce4-desktop -p "/backdrop/screen0/$m/image-path" -s "$f" 2>/dev/null
    done
  fi
  sleep 900
done
