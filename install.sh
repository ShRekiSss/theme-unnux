#!/usr/bin/env bash
# ═════════════════════════════════════════════════════
#  theme-unnux — установка Dank-риса (Hyprland, KooL-базовый)
#  Репо: https://github.com/ShRekiSss/theme-unnux
# ═════════════════════════════════════════════════════
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🗝 1/5  копирую конфиги → ~/.config"
cp -rT "$DIR/config" "$HOME/.config" || true

echo "⚙️ 2/5  копирую свои скрипты → ~/.local/bin"
cp -rT "$DIR/scripts" "$HOME/.local/bin"
chmod +x "$HOME/.local/bin/"*

echo "🖼 3/5  обои → ~/Обои"
mkdir -p "$HOME/Обои"
cp -rT "$DIR/обои" "$HOME/Обои" || true

echo "🔐 4/5  SDDM тема Alice (нужен sudo)" 
sudo mkdir -p /usr/share/sddm/themes
sudo cp -rT "$DIR/sddm/alice-purple" /usr/share/sddm/themes/alice-purple
sudo tee /etc/sddm.conf >/dev/null <<'CONF'
[Theme]
Current=alice-purple

[General]
InputMethod=
CONF
sudo ln -sf /usr/bin/sddm-greeter-qt6 /usr/bin/sddm-greeter

echo "🔄 5/5  готово! Перезагрузись — рис на месте."
echo "  (стек Hyprland сам собирается через KooL-установщик,
   пресет в файле preset-danze.sh из описания —
   для Debian ещё запустии ./install.sh --tty --preset preset-danze.sh )"
