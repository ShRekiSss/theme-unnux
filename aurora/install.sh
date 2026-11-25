#!/usr/bin/env bash
# ============================================================================
#   AURORA · универсальный установщик
#   Работает на Debian / Kali / Ubuntu / Fedora / Arch / openSUSE / Alpine.
#   Запуск:  sudo bash ~/aurora-dots/install.sh
# ============================================================================

set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
[[ -z "${SRC:-}" ]] && SRC="/home/studen/aurora-dots"

# Режим: KALI=1 включает починку кривых apt-источников и софтверный EGL в VM
KALI="${KALI:-0}"

say()  { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ── пользователь ────────────────────────────────────────────────────────────
TARGET_USER="${SUDO_USER:-${TARGET_USER:-}}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    TARGET_USER="$(awk -F: '$3 >= 1000 && $7 !~ /(nologin|false)/ {print $1; exit}' /etc/passwd)"
fi
[[ -n "$TARGET_USER" ]] || fail "Не удалось определить пользователя. Запусти: sudo TARGET_USER=имя bash $0"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_HOME="${TARGET_HOME:-/home/$TARGET_USER}"
TARGET_GROUP="$(id -gn "$TARGET_USER" 2>/dev/null || echo "$TARGET_USER")"

[[ $EUID -eq 0 ]] || fail "Нужны права root:  sudo bash $0"

# ── дистрибутив и пакетный менеджер ─────────────────────────────────────────
ID=""; ID_LIKE=""; PRETTY_NAME="Linux"
[[ -f /etc/os-release ]] && . /etc/os-release
ID="${ID:-linux}"; ID_LIKE="${ID_LIKE:-}"; PRETTY_NAME="${PRETTY_NAME:-Linux}"
if [[ "$ID" == "kali" ]]; then KALI=1; fi
(( KALI )) && say "Режим Kali: починка apt + софтверный EGL"

case " $ID $ID_LIKE " in
    *debian*|*ubuntu*|*kali*|*mint*|*pop*|*raspbian*) PM=apt   ;;
    *fedora*|*rhel*|*centos*|*rocky*|*alma*)          PM=dnf   ;;
    *arch*|*manjaro*|*endeavouros*|*cachyos*)         PM=pacman;;
    *opensuse*|*suse*)                                PM=zypper;;
    *alpine*)                                         PM=apk   ;;
    *)
        if   command -v apt-get   >/dev/null; then PM=apt
        elif command -v dnf       >/dev/null; then PM=dnf
        elif command -v pacman    >/dev/null; then PM=pacman
        elif command -v zypper    >/dev/null; then PM=zypper
        elif command -v apk       >/dev/null; then PM=apk
        else fail "Неизвестный пакетный менеджер — установи пакеты вручную"
        fi ;;
esac
say "Система: $PRETTY_NAME  ·  пакеты: $PM  ·  пользователь: $TARGET_USER"

# Важно: НЕ трогаем /etc/os-release, /etc/debian_version, /etc/lsb-release —
# версия дистрибутива остаётся как есть. Меняются только конфиги приложений
# и (при явной поломке) кривые строки репозиториев — с бэкапом.
VIRT="$(command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt 2>/dev/null || true)"
DMI="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
case "$VIRT $DMI" in
    *virtualbox*|*vmware*|*oracle*|*qemu*|*VirtualBox*|*VMware*|*QEMU*) IS_VM=1 ;;
    *) IS_VM=0 ;;
esac
(( IS_VM )) && say "Обнаружена виртуальная машина — включу софтверный EGL"

# ── обёртки над пакетным менеджером ─────────────────────────────────────────
APT_LOG=/tmp/aurora-apt-update.log

pkg_update() {
    case "$PM" in
    apt)
        if apt-get update -o Acquire::Retries=2 >"$APT_LOG" 2>&1; then
            return 0
        fi
        warn "apt update завершился ошибкой (лог: $APT_LOG)"
        # Kali часто имеет ошибочные строки Debian с сюитой kali-rolling.
        if [[ "$KALI" == "1" || "$ID" == "kali" ]]; then
            local bk="/etc/apt/aurora-backup-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$bk/sources.list.d"
            [[ -f /etc/apt/sources.list ]] && cp -a /etc/apt/sources.list "$bk/" 2>/dev/null || true
            cp -a /etc/apt/sources.list.d/. "$bk/sources.list.d/" 2>/dev/null || true
            local f changed=0
            for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
                [[ -f "$f" ]] || continue
                sed -i -E '/^[[:space:]]*#/! { /(deb\.debian\.org|security\.debian\.org)/ { /kali-rolling/ s/^/#AURORA-DISABLED / } }' "$f" || true
                grep -q '^#AURORA-DISABLED' "$f" && changed=1
            done
            if (( changed )); then
                say "Отключены несовместимые Debian-строки с kali-rolling (бэкап: $bk)"
                if apt-get update -o Acquire::Retries=2 >>"$APT_LOG" 2>&1; then
                    ok "репозитории обновлены"
                    return 0
                fi
            fi
        fi
        warn "Продолжаем с кэшированными списками пакетов"
        return 0 ;;
    dnf)    dnf -y makecache                  >/dev/null 2>&1 || true ;;
    pacman) pacman -Syu --noconfirm --needed  >/dev/null 2>&1 || true ;;
    zypper) zypper --non-interactive refresh  >/dev/null 2>&1 || true ;;
    apk)    apk update                        >/dev/null 2>&1 || true ;;
    esac
}

pkg_install() {
    case "$PM" in
    apt)    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" ;;
    dnf)    dnf -y install "$@" ;;
    pacman) pacman -S --needed --noconfirm "$@" ;;
    zypper) zypper --non-interactive install -y "$@" ;;
    apk)    apk add --no-cache "$@" ;;
    esac
}

# ── 1. пакеты ───────────────────────────────────────────────────────────────
say "Пакеты"
pkg_update

case "$PM" in
apt)
    BASE_PKGS="swaybg sddm"
    QML_PKGS="qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtqml-workerscript"
    QML_FALLBACK="qml-module-qtquick2 qml-module-qtquick-window2 qml-module-qtqml-workerscript"
    HYPR_PKG="hyprland"
    ;;
*)  BASE_PKGS="swaybg sddm"
    QML_PKGS="qt6-qtdeclarative"
    QML_FALLBACK=""
    HYPR_PKG="hyprland"
    ;;
esac

pkg_install $BASE_PKGS || warn "Не удалось установить swaybg/sddm — проверь репозитории"
if ! pkg_install $QML_PKGS; then
    warn "Qt6 QML не установился"
    [[ -n "$QML_FALLBACK" ]] && pkg_install $QML_FALLBACK || true
fi

# ── 2. Hyprland ─────────────────────────────────────────────────────────────
say "Hyprland"
HYPR_BIN="$(command -v Hyprland 2>/dev/null || true)"
if [[ -z "$HYPR_BIN" ]]; then
    HYPR_BIN="$(find /usr/local/bin /usr/bin /opt -maxdepth 3 -type f -name Hyprland -perm -u+x 2>/dev/null | head -1)"
fi
if [[ -z "$HYPR_BIN" ]]; then
    warn "Hyprland не найден — пробую установить из репозитория"
    pkg_install "$HYPR_PKG" || true
    HYPR_BIN="$(command -v Hyprland 2>/dev/null || true)"
fi
if [[ -z "$HYPR_BIN" ]]; then
    warn "Hyprland не установлен. Конфиг и сессия будут готовы, но сам композитор нужно доустановить:"
    warn "  Debian/Kali: sudo apt install hyprland   ·   Arch: sudo pacman -S hyprland"
else
    ok "$HYPR_BIN"
fi

HV="0.0.0"
if [[ -n "$HYPR_BIN" ]]; then
    # Hyprland --version требует XDG_RUNTIME_DIR (под sudo его может не быть)
    VRT="/tmp/aurora-hypr-ver-$$"
    mkdir -p "$VRT" && chmod 700 "$VRT"
    HV="$(XDG_RUNTIME_DIR="$VRT" "$HYPR_BIN" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"
    rmdir "$VRT" 2>/dev/null || true
    if [[ -z "$HV" ]]; then
        HV="$(grep -aoE 'v?0\.[0-9]+\.[0-9]+' "$HYPR_BIN" 2>/dev/null | head -1 | tr -d 'v')"
    fi
    [[ -z "$HV" ]] && HV="0.0.0"
fi
HMAJ="${HV%%.*}"; HREST="${HV#*.}"; HMIN="${HREST%%.*}"; HMIN="${HMIN:-0}"
if (( HMAJ > 0 || HMIN >= 53 )); then
    HYPR_CONF="hyprland.conf"
else
    HYPR_CONF="hyprland-legacy.conf"
fi
say "Версия Hyprland: $HV → конфиг $HYPR_CONF"

# ── 3. Debian-база + Aurora-стиль ──────────────────────────────────────────
say "Конфиги: Debian-база + Aurora style"
BK="$TARGET_HOME/.config/aurora-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
REPO="$(dirname "$SRC")"

if [[ -d "$REPO/config/hypr" ]]; then
    # Родительский репозиторий — копируем проверенную Debian/KooL-базу
    for d in hypr waybar rofi kitty swaync wlogout btop cava fastfetch qt5ct qt6ct swappy; do
        [[ -d "$TARGET_HOME/.config/$d" ]] && cp -a "$TARGET_HOME/.config/$d" "$BK/" 2>/dev/null || true
    done
    cp -a "$REPO/config/." "$TARGET_HOME/.config/"

    mkdir -p "$TARGET_HOME/.local/bin" "$TARGET_HOME/Обои"
    cp -a "$REPO/scripts/." "$TARGET_HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$TARGET_HOME"/.local/bin/* 2>/dev/null || true
    cp -a "$REPO/обои/." "$TARGET_HOME/Обои/" 2>/dev/null || true
    ok "Debian-база: config/, scripts/, обои/"
else
    # Автономныйaurora-dots без родительского репо — старый путь
    deploy() {
        local src="$1" dst="$2" rel="${2#$TARGET_HOME/.config/}"
        [[ -f "$src" ]] || { warn "нет файла $src"; return; }
        mkdir -p "$(dirname "$dst")"
        [[ -f "$dst" ]] && { mkdir -p "$BK/$(dirname "$rel")"; cp -a "$dst" "$BK/$rel" 2>/dev/null || true; }
        install -m 644 "$src" "$dst"
        chown "$TARGET_USER:$TARGET_GROUP" "$dst" 2>/dev/null || true
    }
    deploy "$SRC/$HYPR_CONF"                  "$TARGET_HOME/.config/hypr/hyprland.conf"
    for f in "$SRC"/dotfiles/hypr/scripts/*.sh; do
        deploy "$f" "$TARGET_HOME/.config/hypr/scripts/$(basename "$f")"
        chmod +x "$TARGET_HOME/.config/hypr/scripts/$(basename "$f")" 2>/dev/null || true
    done
    for f in "$SRC"/dotfiles/waybar/* "$SRC"/dotfiles/rofi/*; do
        deploy "$f" "$TARGET_HOME/.config/$(basename "$(dirname "$f")")/$(basename "$f")"
    done
fi

# Aurora-оформление поверх Debian-базы (всегда)
mkdir -p "$TARGET_HOME/.config/hypr/UserConfigs"
install -m 644 "$SRC/style-Aurora.conf" "$TARGET_HOME/.config/hypr/UserConfigs/AuroraStyle.conf"
if ! grep -q 'AuroraStyle.conf' "$TARGET_HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
    printf '\n# Aurora style (последним)\nsource = $UserConfigs/AuroraStyle.conf\n' \
        >> "$TARGET_HOME/.config/hypr/hyprland.conf"
fi
chown -R "$TARGET_USER:$TARGET_GROUP" "$TARGET_HOME/.config/hypr" 2>/dev/null || true
ok "AuroraStyle.conf подключён последним"

# пути под этого пользователя
sed -i "s#/home/[^/]\+#$TARGET_HOME#g" "$TARGET_HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
POLKIT="$(command -v hyprpolkitagent 2>/dev/null || find /usr/libexec /usr/lib -maxdepth 3 -name hyprpolkitagent -type f 2>/dev/null | head -1)"
if [[ -n "$POLKIT" ]]; then
    sed -i "s#/usr/libexec/hyprpolkitagent#$POLKIT#g" "$TARGET_HOME/.config/hypr/hyprland.conf" 2>/dev/null || true
fi
ok "бэкап старых конфигов: $BK"

# ── 4. шрифты, обои, тема SDDM ──────────────────────────────────────────────
say "Шрифты и обои"
FONT_DIR="/usr/local/share/fonts/jetbrains-mono-nerd"
mkdir -p "$FONT_DIR"
install -m 644 "$SRC"/fonts/*.ttf "$FONT_DIR/" 2>/dev/null || true
fc-cache -f >/dev/null 2>&1 || true

WALL_DIR="$TARGET_HOME/.local/share/wallpapers/aurora"
mkdir -p "$WALL_DIR"
install -m 644 "$SRC"/wallpapers/*.png "$WALL_DIR/" 2>/dev/null || true
chown -R "$TARGET_USER:$TARGET_GROUP" "$WALL_DIR" 2>/dev/null || true

say "Тема SDDM «Aurora»"
THEME_DIR=/usr/share/sddm/themes/aurora
mkdir -p "$THEME_DIR"
cp -a "$SRC/sddm/aurora/." "$THEME_DIR/"
find "$THEME_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
find "$THEME_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
# если доступен только Qt5 — адаптируем тему
if [[ "$PM" == "apt" ]] && ! dpkg -l qml6-module-qtquick 2>/dev/null | grep -q '^ii' \
   && dpkg -l qml-module-qtquick2 2>/dev/null | grep -q '^ii'; then
    sed -i 's/^QtVersion=6$/QtVersion=5/' "$THEME_DIR/metadata.desktop" || true
    warn "использована Qt5-версия темы"
fi
ok "$THEME_DIR"

# ── 5. сессия Hyprland в меню входа ─────────────────────────────────────────
STARTER="$(command -v start-hyprland 2>/dev/null || echo "${HYPR_BIN:-/usr/bin/Hyprland}")"
if (( IS_VM || KALI )) && command -v Hyprland >/dev/null 2>&1; then
    # В VM (VirtualBox/VMware) EGL часто падает без софтверного рендера
    cat > /usr/local/bin/hyprland-aurora <<EOF
#!/bin/sh
unset DISPLAY
export XDG_SESSION_TYPE=wayland
export EGL_PLATFORM=gbm
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=swrast
export WLR_NO_HARDWARE_CURSORS=1
exec ${HYPR_BIN:-/usr/local/bin/Hyprland} "\$@"
EOF
    chmod 755 /usr/local/bin/hyprland-aurora
    STARTER=/usr/local/bin/hyprland-aurora
    ok "софтверный EGL: /usr/local/bin/hyprland-aurora"
fi

for d in /usr/share/wayland-sessions /usr/local/share/wayland-sessions; do
    mkdir -p "$d"
    f="$d/hyprland.desktop"
    [[ -f "$f" ]] && cp -a "$f" "$f.aurora-bak" 2>/dev/null || true
    cat > "$f" <<EOF
[Desktop Entry]
Name=Hyprland
Comment=Aurora · dynamic tiling Wayland compositor
Exec=$STARTER
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;aurora;
EOF
    chmod 644 "$f"
    ok "$f → $STARTER"
done
rm -f /usr/local/share/wayland-sessions/hyprland-uwsm.desktop 2>/dev/null || true

# ── 6. конфиг и включение SDDM ──────────────────────────────────────────────
say "SDDM как менеджер входа"
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zz-aurora.conf <<'EOF'
[General]
DisplayServer=x11
Numlock=on

[Theme]
Current=aurora
EOF

# Главный /etc/sddm.conf имеет наивысший приоритет — правим и его (с бэкапом)
if [[ -f /etc/sddm.conf ]]; then
    cp -a /etc/sddm.conf /etc/sddm.conf.aurora-bak 2>/dev/null || true
    if grep -q '^\[Theme\]' /etc/sddm.conf; then
        sed -i '/^\[Theme\]/,/^\[/ s/^Current=.*/Current=aurora/' /etc/sddm.conf
    else
        printf '\n[Theme]\nCurrent=aurora\n' >> /etc/sddm.conf
    fi
else
    printf '[Theme]\nCurrent=aurora\n' > /etc/sddm.conf
fi
ok "тема SDDM: aurora"

SDDM_BIN="$(command -v sddm 2>/dev/null || echo /usr/bin/sddm)"
if command -v systemctl >/dev/null 2>&1; then
    for dm in lightdm gdm sddm display-manager; do
        systemctl disable "$dm.service" >/dev/null 2>&1 || true
    done
    systemctl enable sddm.service >/dev/null 2>&1 || true
    systemctl set-default graphical.target >/dev/null 2>&1 || true
    ok "systemd: sddm включён"
elif command -v rc-update >/dev/null 2>&1; then
    rc-update del lightdm default 2>/dev/null || true
    rc-update add sddm default 2>/dev/null || true
    ok "OpenRC: sddm включён"
elif [[ -d /etc/sv/sddm && -d /var/service ]]; then
    ln -sf /etc/sv/sddm /var/service/sddm 2>/dev/null || true
    ok "runit: sddm включён"
elif command -v update-rc.d >/dev/null 2>&1; then
    update-rc.d lightdm disable >/dev/null 2>&1 || true
    update-rc.d sddm defaults >/dev/null 2>&1 || true
    ok "SysV: sddm включён"
else
    warn "Неизвестная init-система — включи sddm вручную"
fi

# Специфичные для дистрибутивов файлы выбора DM (только DM, не версию!)
mkdir -p "$(dirname /etc/X11/default-display-manager)" 2>/dev/null || true
echo "$SDDM_BIN" > /etc/X11/default-display-manager 2>/dev/null || true
if [[ -d /etc/sysconfig ]]; then
    echo "DISPLAYMANAGER=$SDDM_BIN" > /etc/sysconfig/desktop 2>/dev/null || true
    echo 'DISPLAYMANAGER="sddm"' > /etc/sysconfig/displaymanager 2>/dev/null || true
fi

cat <<EOF

────────────────────────────────────────────────────────────
  Aurora готова.

  Перезагрузись:  sudo systemctl reboot   (или просто reboot)

  В меню входа SDDM:
      пользователь  $TARGET_USER
      сессия        Hyprland  (кнопки под полем пароля)

  Запасной вариант — сессия Xfce в том же меню.
  Старые конфиги сохранены в: $BK

  Откат DM:  sudo systemctl enable --now lightdm
  Проверка:  Hyprland --verify-config -c ~/.config/hypr/hyprland.conf
────────────────────────────────────────────────────────────
EOF
