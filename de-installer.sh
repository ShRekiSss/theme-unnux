#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v2.0
#  Kali Linux (приоритет) | Debian | Ubuntu
#  Plasma Overdose Edition 🧪
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- Проверка прав ---
SUDO=""
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &>/dev/null; then SUDO="sudo"; else
        echo -e "${RED}Нужны права root: sudo $0${NC}"; exit 1
    fi
fi

# --- Определение дистрибутива ---
DISTRO="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
fi
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- Пакеты по дистрибутивам ---
pkg_de() {
    case "$DISTRO" in
        kali)
            case "$1" in
                plasma)  echo "kali-desktop-kde" ;;
                gnome)   echo "kali-desktop-gnome" ;;
                xfce)    echo "kali-desktop-xfce" ;;
                mate)    echo "kali-desktop-mate" ;;
                lxde)    echo "kali-desktop-lxde" ;;
                i3)      echo "kali-desktop-i3" ;;
            esac ;;
        debian)
            case "$1" in
                plasma)  echo "task-kde-desktop" ;;
                gnome)   echo "task-gnome-desktop" ;;
                xfce)    echo "task-xfce-desktop" ;;
                mate)    echo "task-mate-desktop" ;;
                lxde)    echo "task-lxde-desktop" ;;
                i3)      echo "i3" ;;
            esac ;;
        ubuntu|*)
            case "$1" in
                plasma)  echo "kubuntu-desktop" ;;
                gnome)   echo "ubuntu-desktop" ;;
                xfce)    echo "xubuntu-desktop" ;;
                mate)    echo "ubuntu-mate-desktop" ;;
                lxde)    echo "lubuntu-desktop" ;;
                i3)      echo "i3" ;;
            esac ;;
    esac
}

DM_for() {
    case "$1" in
        plasma) echo "sddm" ;;
        gnome)  echo "gdm3" ;;
        *)      echo "lightdm" ;;
    esac
}

# --- whiptail ---
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }

CHOICE=$(whiptail --title "theme-unnux v2.0 [$DISTRO]" --menu \
"Выбери графическую оболочку:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — максимум кастома" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE (лёгкий)" \
"mate"     "MATE" \
"lxde"     "LXDE (супер-лёгкий)" \
"i3"       "i3 (тайловый)" 3>&1 1>&2 2>&3)

[ -z "$CHOICE" ] && echo "Отменено." && exit 0

# --- Установка ---
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE установит:\n$PKG + sddm + kvantum + papirus + latte + шрифты\n\nПродолжить?" 12 64 || exit 0
    echo -e "${YELLOW}[1/4] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/4] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/4] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze qt5-style-kvantum kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        latte-dock konsole dolphin neofetch btop || true
    echo -e "${YELLOW}[4/4] Применение тем...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    $SUDO mkdir -p /etc/xdg/Kvantum
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    $SUDO tee /etc/xdg/autostart/latte-dock.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Latte Dock
Exec=latte-dock
Type=Application
EOF
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE")
    DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер входа: $DM\n\nПродолжить?" 12 64 || exit 0
    echo -e "${YELLOW}[1/2] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/2] Установка $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

if command -v "$DM" &>/dev/null; then
    echo -e "${YELLOW}Настройка $DM...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true
fi

echo -e "${GREEN}Готово! Перезагрузи: sudo reboot${NC}"
	
