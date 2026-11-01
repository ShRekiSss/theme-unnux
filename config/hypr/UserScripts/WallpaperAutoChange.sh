#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# source https://wiki.archlinux.org/title/Hyprland#Using_a_script_to_change_wallpaper_every_X_minutes

# This script will randomly go through the files of a directory, setting it
# up as the wallpaper at regular intervals
#
# NOTE: this script uses bash (not POSIX shell) for the RANDOM variable

wallust_refresh=$HOME/.config/hypr/scripts/RefreshNoWaybar.sh

focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

if [[ $# -lt 1 ]] || [[ ! -d $1   ]]; then
	echo "Usage:
	$0 <dir containing images>"
	exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_TYPE=simple

# This controls (in seconds) when to switch to the next image
INTERVAL=120

# защита от двойного запуска (второй ждал бы flock и ничего не крутил)
exec 9>/tmp/обои-ротатор.lock
flock -n 9 || exit 0

while true; do
	find "$1" -maxdepth 1 -mindepth 1 -type f \
		\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			swww img -o $focused_monitor "$img"
			# Regenerate colors from the exact image path to avoid cache races
			# (таймаут: если модуль зависнет — ротатор не замирает)
			timeout 15s "$HOME/.config/hypr/scripts/WallustSwww.sh" "$img" || true
			timeout 15s "$wallust_refresh" || true
			sleep $INTERVAL
			
		done
done
