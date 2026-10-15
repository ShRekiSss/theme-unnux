#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запусти от root: sudo $0${NC}"; exit 1
fi

command -v whiptail &>/dev/null || { apt update && apt install -y whiptail; }

CHOICE=$(whiptail --title "DE Installer" --menu \
"Выбери графическую оболочку:" 20 60 10 \
"gnome"    "GNOME (стандарт Debian)" \
"kde"      "KDE Plasma" \
"xfce"     "XFCE (лёгкий)" \
"lxqt"     "LXQt (очень лёгкий)" \
"cinnamon" "Cinnamon (стиль Windows)" \
"mate"     "MATE (классика)" \
"i3"       "i3 (тайловый)" 3>&1 1>&2 2>&3)

[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    gnome)    PKG="task-gnome-desktop"    DM="gdm3"   ;;
    kde)      PKG="task-kde-desktop"      DM="sddm"   ;;
    xfce)     PKG="task-xfce-desktop"     DM="lightdm";;
    lxqt)     PKG="task-lxqt-desktop"     DM="sddm"   ;;
    cinnamon) PKG="task-cinnamon-desktop" DM="lightdm";;
    mate)     PKG="task-mate-desktop"     DM="lightdm";;
    i3)       PKG="i3"                    DM="lightdm";;
esac

whiptail --yesno "Установить: $PKG\nДиспетчер входа: $DM\n\nПродолжить?" 12 60 || exit 0

echo -e "${YELLOW}[1/3] apt update...${NC}"; apt update
echo -e "${YELLOW}[2/3] Установка $PKG...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
echo -e "${YELLOW}[3/3] Настройка $DM...${NC}"
command -v "$DM" &>/dev/null && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}Готово! Перезагрузи: sudo reboot${NC}"
