#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v2.2
#  Kali Linux (приоритет) | Debian | Ubuntu
#  Plasma Overdose + Wallpaper Manager + ZERO-CLICK тема
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &>/dev/null; then SUDO="sudo"; else
        echo -e "${RED}Нужны права root: sudo $0${NC}"; exit 1
    fi
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=(
    "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg"
)

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        if [ -f "$WALL_DIR/$w" ]; then
            present=$((present+1))
        else
            missing+=("$w")
        fi
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    if [ ${#missing[@]} -eq 0 ]; then
        echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0
    fi
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || { $SUDO apt install -y curl; }
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w (нет в репозитории?)${NC}"
    done
    local now=0
    for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && now=$((now+1)); done
    echo -e "${GREEN}Теперь обоев: $now/${#WALL_LIST[@]}${NC}"
}

wall_count() {
    local n=0
    for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done
    echo "$n"
}

# ================= ZERO-CLICK ТЕМА =================
real_user() { echo "${SUDO_USER:-$USER}"; }
HU() { getent passwd "$(real_user)" | cut -d: -f6; }

ku() {  # выполнить команду от имени реального пользователя
    $SUDO -u "$(real_user)" env HOME="$(HU)" XDG_CONFIG_HOME="$(HU)/.config" "$@"
}

apply_theme() {
    local U; U=$(real_user)
    local W; W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
    echo -e "${YELLOW}Применяю тему для $U (zero-click)...${NC}"

    ku kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle Kvantum
    ku kwriteconfig5 --file kdeglobals --group Icons --key Theme Papirus
    ku kwriteconfig5 --file kdeglobals --group General --key ColorScheme BreezeDark
    ku kwriteconfig5 --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0"
    ku plasma-apply-colorscheme BreezeDark 2>/dev/null || true

    ku kvantummanager --set Breeze 2>/dev/null || true

    $SUDO mkdir -p "$(HU)/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$(HU)/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$(HU)/.config/gtk-3.0/settings.ini"

    if [ -n "$W" ]; then
        ku plasma-apply-wallpaperimage "$W" 2>/dev/null || true
        ku kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
            --group Containments --group 1 --group Wallpaper --group org.kde.image --group General \
            --key Image "file://$W" 2>/dev/null || true
    fi

    $SUDO mkdir -p "$(HU)/.config/latte"
    cat <<'LATTE' | $SUDO tee "$(HU)/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
wallpaperplugin=org.kde.image

[Containments][1][Applets][2]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][1][Applets][3]
immutability=1
plugin=org.kde.plasma.taskmanager

[Containments][1][Applets][4]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][1][Applets][5]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][1][General]
appletOrder=2;3;4;5

[LayoutSettings]
color=blue
showInMenu=true
version=2
LATTE
    $SUDO chown "$U:$U" "$(HU)/.config/latte/theme-unnux.layout.latte"

    $SUDO tee /etc/xdg/autostart/latte-dock.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Latte Dock
Exec=sh -c "latte-dock --layout theme-unnux 2>/dev/null || latte-dock"
Type=Application
EOF
    echo -e "${GREEN}Тема применена — первый вход = готовый рабочий стол.${NC}"
}

# ================= ПАКЕТЫ =================
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

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }

WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v2.2 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — тема ставится САМА" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE (лёгкий)" \
"mate"     "MATE" \
"lxde"     "LXDE (супер-лёгкий)" \
"i3"       "i3 (тайловый)" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" 3>&1 1>&2 2>&3)

[ -z "$CHOICE" ] && echo "Отменено." && exit 0

if [ "$CHOICE" = "wall" ]; then
    wall_check
    exit 0
fi

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE установит:\n$PKG + sddm + kvantum + papirus + latte\n+ шрифты + обои + ПОЛНУЮ ТЕМУ (zero-click)\n\nПосле перезагрузки настроек делать НЕ нужно.\n\nПродолжить?" 16 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze qt5-style-kvantum kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        latte-dock konsole dolphin neofetch btop curl || true
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    $SUDO mkdir -p /etc/xdg/Kvantum
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Обои + zero-click тема...${NC}"
    wall_check
    apply_theme
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

