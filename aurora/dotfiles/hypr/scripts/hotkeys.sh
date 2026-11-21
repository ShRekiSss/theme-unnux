#!/usr/bin/env bash
# ── Aurora · памятка горячих клавиш ──────────────────────────
cat <<'EOF' | rofi -dmenu -i -p "  Горячие клавиши Aurora" -theme ~/.config/rofi/aurora.rasi -theme-str 'window { width: 760px; } listview { lines: 24; columns: 1; }'
Win           — меню приложений (rofi)
Win + D       — меню приложений
Win + Return  — терминал kitty
Win + B       — браузер
Win + E       — файловый менеджер
Win + Q       — закрыть окно
Ctrl+Alt+Del  — выйти из Hyprland
Win + L / Ctrl+Alt+L — блокировка
Win + Esc / Ctrl+Alt+P — меню выхода
Win + V / Win+Alt+V — буфер обмена
Win + W       — сменить обои
Win + /       — эта памятка
Win + H / Win+Shift+K — памятка

ОКНА
Win + Tab     — следующая группа окон
Win+Shift+Tab — предыдущая группа
Alt + Tab     — следующее окно
Win+Ctrl+S    — переключатель окон (rofi)
Win + G       — группа окон
Win + J / Win+Shift+I — разделить сплит
Win + Space   — плавающее окно
Win + P       — pseudo-tile
Win + F       — fullscreen
Win+Shift+F   — максимальный fullscreen
Win+Ctrl+F    — максимизировать
Win + I       — добавить master
Win+Ctrl+D    — убрать master
Win+Ctrl+Return — поменяться с master
Win + M       — коэффициент сплита 0.3
Win+Ctrl+O    — прозрачность активного окна

ФОКУС И РАЗМЕР
Win + стрелки — фокус
Alt + HJKL    — фокус (vim)
Win+Ctrl + стрелки — переместить окно
Win+Shift + стрелки — изменить размер
Win + LMB/RMB — переместить/изменить размер мышью
Win+Alt + колесо — масштаб курсора

РАБОЧИЕ СТОЛЫ
Win + 1…0     — рабочий стол
Win+Shift + 1…0 — перенести окно
Win+Ctrl + 1…0 — перенести окно молча
Win + Tab     — следующий стол
Win + , / .   — предыдущий/следующий стол
Win + колесо  — листать столы
Win + U       — специальный стол
Win+Shift+U   — перенести на спец. стол
Win + `       — спец. стол magic

СИСТЕМА
Win+Shift+N   — центр уведомлений
Win+Ctrl+Alt+B — скрыть/показать Waybar
Print / Win+Print — скриншот экрана
Shift+Print / Win+Shift+Print — скриншот области
Win + S       — скриншот области
XF86-клавиши  — звук, яркость, медиа
EOF
