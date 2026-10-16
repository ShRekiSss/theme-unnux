k#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
	#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
/#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep theme-unnux || echo -e "${RED}Хук НЕ создан!${NC}"
#!/bin/bash
#=============================================================#
#  theme-unnux DE Installer v3.0
#  Kali (приоритет) | Debian | Ubuntu — Plasma 5/6
#  Zero-click: тема применяется при ПЕРВОМ графическом входе
#=============================================================#
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SUDO=""
if [ "$EUID" -ne 0 ]; then
    command -v sudo &>/dev/null && SUDO="sudo" || { echo -e "${RED}Нужен root или sudo${NC}"; exit 1; }
fi

DISTRO="unknown"
[ -f /etc/os-release ] && { . /etc/os-release; DISTRO="$ID"; }
echo -e "${CYAN}Дистрибутив: $DISTRO${NC}"

# --- КТО пользователь (главный фикс!) ---
U="${SUDO_USER:-}"
if [ -z "$U" ]; then
    U=$(ls /home 2>/dev/null | grep -vx 'lost+found' | head -1 || true)
fi
if [ -z "$U" ]; then
    U=$(whiptail --inputbox "Введи имя пользователя для настройки темы:" 8 50 "kali" 3>&1 1>&2 2>&3)
fi
HU=$(getent passwd "$U" | cut -d: -f6)
[ -z "$HU" ] && { echo -e "${RED}Пользователь $U не найден${NC}"; exit 1; }
echo -e "${CYAN}Тема настраивается для: $U ($HU)${NC}"

# ================= ОБОИ =================
WALL_DIR="/usr/share/backgrounds/theme-unnux"
WALL_URL="https://raw.githubusercontent.com/ShRekiSss/theme-unnux/main/wallpapers"
WALL_LIST=( "wall1.jpg" "wall2.jpg" "wall3.jpg" "wall4.jpg" "wall5.jpg" )

wall_check() {
    $SUDO mkdir -p "$WALL_DIR"
    local present=0 missing=()
    for w in "${WALL_LIST[@]}"; do
        [ -f "$WALL_DIR/$w" ] && present=$((present+1)) || missing+=("$w")
    done
    echo -e "${CYAN}Обои: $present/${#WALL_LIST[@]}${NC}"
    [ ${#missing[@]} -eq 0 ] && { echo -e "${GREEN}Все обои на месте ✔${NC}"; return 0; }
    echo -e "${YELLOW}Недостаёт: ${missing[*]}${NC}"
    command -v curl &>/dev/null || $SUDO apt install -y curl
    for w in "${missing[@]}"; do
        echo "  Качаю $w..."
        curl -sfL "$WALL_URL/$w" -o "/tmp/$w" && $SUDO mv "/tmp/$w" "$WALL_DIR/$w" \
            || echo -e "${RED}  Не скачался: $w${NC}"
    done
}

wall_count() { local n=0; for w in "${WALL_LIST[@]}"; do [ -f "$WALL_DIR/$w" ] && n=$((n+1)); done; echo "$n"; }

# ================= ZERO-CLICK (предзапись конфигов) =================
ku() { $SUDO -u "$U" env HOME="$HU" XDG_CONFIG_HOME="$HU/.config" "$@"; }

apply_theme() {
    echo -e "${YELLOW}Предзаписываю конфиги для $U...${NC}"
    local KWC; KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
    if [ -n "$KWC" ]; then
        ku "$KWC" --file kdeglobals --group KDE --key widgetStyle Kvantum     || true
        ku "$KWC" --file kdeglobals --group Icons --key Theme Papirus         || true
        ku "$KWC" --file kdeglobals --group General --key ColorScheme BreezeDark || true
        ku "$KWC" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    else
        echo -e "${YELLOW}kwriteconfig не найден — применит хук входа${NC}"
    fi

    $SUDO mkdir -p "$HU/.config/gtk-3.0"
    printf '[Settings]\ngtk-theme-name=Breeze\ngtk-icon-theme-name=Papirus\ngtk-font-name=Noto Sans 10\n' \
        | $SUDO tee "$HU/.config/gtk-3.0/settings.ini" >/dev/null
    $SUDO chown "$U:$U" "$HU/.config/gtk-3.0/settings.ini"

    if command -v latte-dock &>/dev/null; then
        $SUDO mkdir -p "$HU/.config/latte"
        cat <<'LATTE' | $SUDO tee "$HU/.config/latte/theme-unnux.layout.latte" >/dev/null
[Containments][1]
formfactor=2
immutability=1
location=4
plugin=org.kde.latte.containment
visibility=2
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
        $SUDO chown "$U:$U" "$HU/.config/latte/theme-unnux.layout.latte"
    fi
}

# ================= ХУК ПЕРВОГО ВХОДА =================
first_login_hook() {
    echo -e "${YELLOW}Ставлю хук первого входа...${NC}"
    $SUDO mkdir -p "$HU/.config/autostart" "$HU/.local/bin"

    cat > /tmp/tu-firstlogin.sh <<'EOS'
#!/bin/bash
for i in $(seq 1 60); do pgrep -x plasmashell >/dev/null && break; sleep 2; done
sleep 5
WALL_DIR=/usr/share/backgrounds/theme-unnux
W=$(ls "$WALL_DIR"/* 2>/dev/null | shuf -n 1 || true)
[ -n "$W" ] && plasma-apply-wallpaperimage "$W" 2>/dev/null
plasma-apply-colorscheme BreezeDark 2>/dev/null
kvantummanager --set Breeze 2>/dev/null
command -v latte-dock >/dev/null && { latte-dock --layout theme-unnux 2>/dev/null || latte-dock 2>/dev/null & }
notify-send "theme-unnux" "Тема применена" 2>/dev/null
rm -f "$HOME/.config/autostart/theme-unnux-firstlogin.desktop"
EOS
    $SUDO mv /tmp/tu-firstlogin.sh "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chmod +x "$HU/.local/bin/theme-unnux-firstlogin.sh"
    $SUDO chown "$U:$U" "$HU/.local/bin/theme-unnux-firstlogin.sh"

    cat > /tmp/tu-firstlogin.desktop <<EOF
[Desktop Entry]
Name=theme-unnux setup
Exec=$HU/.local/bin/theme-unnux-firstlogin.sh
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    $SUDO mv /tmp/tu-firstlogin.desktop "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
    $SUDO chown "$U:$U" "$HU/.config/autostart/theme-unnux-firstlogin.desktop"
}

# ================= ПАКЕТЫ =================
pkg_de() {
    case "$DISTRO" in
        kali) case "$1" in
                plasma) echo "kali-desktop-kde";; gnome) echo "kali-desktop-gnome";;
                xfce) echo "kali-desktop-xfce";; mate) echo "kali-desktop-mate";;
                lxde) echo "kali-desktop-lxde";; i3) echo "kali-desktop-i3";; esac;;
        debian) case "$1" in
                plasma) echo "task-kde-desktop";; gnome) echo "task-gnome-desktop";;
                xfce) echo "task-xfce-desktop";; mate) echo "task-mate-desktop";;
                lxde) echo "task-lxde-desktop";; i3) echo "i3";; esac;;
        *) case "$1" in
                plasma) echo "kubuntu-desktop";; gnome) echo "ubuntu-desktop";;
                xfce) echo "xubuntu-desktop";; mate) echo "ubuntu-mate-desktop";;
                lxde) echo "lubuntu-desktop";; i3) echo "i3";; esac;;
    esac
}
DM_for() { case "$1" in plasma) echo "sddm";; gnome) echo "gdm3";; *) echo "lightdm";; esac; }

# ================= МЕНЮ =================
command -v whiptail &>/dev/null || { $SUDO apt update; $SUDO apt install -y whiptail; }
WC=$(wall_count)
CHOICE=$(whiptail --title "theme-unnux v3.0 [$DISTRO]" --menu \
"Выбери действие:" 22 64 11 \
"overdose" "PLASMA OVERDOSE — zero-click" \
"plasma"   "KDE Plasma (чистая)" \
"gnome"    "GNOME" \
"xfce"     "XFCE" \
"mate"     "MATE" \
"lxde"     "LXDE" \
"i3"       "i3" \
"wall"     "Обои: проверить/докачать ($WC/${#WALL_LIST[@]})" \
"reapply"  "Переустановить тему (хук первого входа)" 3>&1 1>&2 2>&3)
[ -z "$CHOICE" ] && echo "Отменено." && exit 0

case "$CHOICE" in
    wall) wall_check; exit 0 ;;
    reapply) apply_theme; first_login_hook
        echo -e "${GREEN}Готово. Перелогинься.${NC}"; exit 0 ;;
esac

# ================= УСТАНОВКА =================
if [ "$CHOICE" = "overdose" ]; then
    PKG=$(pkg_de plasma)
    whiptail --yesno "PLASMA OVERDOSE:\n$PKG + sddm + kvantum + papirus\n+ шрифты + обои + zero-click тема\n\nТема применится при ПЕРВОМ входе.\nПродолжить?" 14 64 || exit 0
    echo -e "${YELLOW}[1/5] apt update...${NC}"; $SUDO apt update
    echo -e "${YELLOW}[2/5] База: $PKG...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
    echo -e "${YELLOW}[3/5] Овердоз-пакеты...${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
        sddm sddm-theme-breeze kvantum qt6-style-kvantum \
        papirus-icon-theme fonts-noto fonts-firacode \
        konsole dolphin neofetch btop curl || true
    $SUDO apt install -y latte-dock 2>/dev/null || echo -e "${YELLOW}Latte недоступен (Plasma 6)${NC}"
    echo -e "${YELLOW}[4/5] Системные конфиги...${NC}"
    $SUDO mkdir -p /etc/sddm.conf.d /etc/xdg/Kvantum
    echo -e "[Theme]\nCurrent=breeze" | $SUDO tee /etc/sddm.conf.d/theme.conf >/dev/null
    echo -e "[General]\ntheme=Breeze" | $SUDO tee /etc/xdg/Kvantum/kvantum.kvconfig >/dev/null
    echo -e "${YELLOW}[5/5] Тема + хук первого входа...${NC}"
    wall_check
    apply_theme
    first_login_hook
    DM="sddm"
else
    PKG=$(pkg_de "$CHOICE"); DM=$(DM_for "$CHOICE")
    whiptail --yesno "Установить: $PKG\nДиспетчер: $DM" 10 60 || exit 0
    $SUDO apt update
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y "$PKG"
fi

command -v "$DM" &>/dev/null && $SUDO DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$DM" || true

echo -e "${GREEN}=== Готово! Перезагрузка: sudo reboot ===${NC}"
ls -la "$HU/.config/autostart/" 2>/dev/null | grep
