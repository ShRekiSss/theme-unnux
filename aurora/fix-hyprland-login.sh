#!/usr/bin/env bash
# ============================================================================
#   AURORA · починка входа в Hyprland в VirtualBox / VMware SVGA
#   Запуск: sudo bash ~/aurora-dots/fix-hyprland-login.sh
# ============================================================================

set -uo pipefail

say()  { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "Нужно: sudo bash $0" >&2; exit 1; }

HYPR="$(command -v Hyprland 2>/dev/null || echo /usr/local/bin/Hyprland)"

# ── 1. обёртка с софтверным EGL ─────────────────────────────────────────────
say "Обёртка запуска Hyprland"
cat > /usr/local/bin/hyprland-aurora <<EOF
#!/bin/sh
# SDDM передаёт DISPLAY от X11-гретера — убираем его, иначе Mesa берёт DRI2
unset DISPLAY
export XDG_SESSION_TYPE=wayland
export EGL_PLATFORM=gbm
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=swrast
export WLR_NO_HARDWARE_CURSORS=1
exec $HYPR "\$@"
EOF
chmod 755 /usr/local/bin/hyprland-aurora
ok "/usr/local/bin/hyprland-aurora → $HYPR"

# ── 2. правим записи сессий ─────────────────────────────────────────────────
say "Сессии Wayland"
for f in /usr/share/wayland-sessions/hyprland.desktop \
         /usr/local/share/wayland-sessions/hyprland.desktop; do
    [[ -f "$f" ]] || continue
    cp -a "$f" "${f}.aurora-bak" 2>/dev/null || true
    sed -i 's#^Exec=.*#Exec=/usr/local/bin/hyprland-aurora#' "$f"
    ok "$f"
done
# uwsm не установлен — такая сессия всё равно упадёт
rm -f /usr/local/share/wayland-sessions/hyprland-uwsm.desktop

# ── 3. тема SDDM (главный конфиг важнее conf.d) ─────────────────────────────
say "Тема SDDM"
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
ok "Current=aurora"

cat <<'EOF'

────────────────────────────────────────────────────────────
  Готово. Перезагрузись:  sudo systemctl reboot

  В SDDM выбирай сессию «Hyprland» (обычную, не uwsm).
  Если снова выкинет — зайди в XFCE и выполни:

      journalctl -u sddm -b --no-pager | tail -40
      ls -t ~/.cache/hyprland/hyprlandCrashReport*.txt | head -1
      cat <последний файл>

  Дополнительно: в настройках VirtualBox включи
  Display → Screen → 3D Acceleration и Video Memory 128 MB.
────────────────────────────────────────────────────────────
EOF
