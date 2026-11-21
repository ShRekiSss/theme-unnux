# ◈ Aurora

Тёмная бирюзово-фиолетовая конфигурация **Hyprland**, панель Waybar, уведомления и тема входа **SDDM**.

```
        teal #5eead4   violet #a78bfa   pink #f472b6
        bg   #070b10   text   #e8f0f7   muted #93a4b5
```

## Установка (любой Linux)

Установщик сам определяет дистрибутив и пакетный менеджер:
**apt** (Debian / Kali / Ubuntu / Mint), **dnf** (Fedora / RHEL), **pacman** (Arch / Manjaro), **zypper** (openSUSE), **apk** (Alpine).

```bash
sudo bash ~/aurora-dots/install.sh
sudo systemctl reboot    # или просто reboot
```

В Kali он также починит типичную проблему с репозиториями: отключит ошибочные строки
`deb.debian.org/... kali-rolling` (предварительно сделав бэкап в `/etc/apt/aurora-backup-*`)
и повторит `apt update`. Если репозитории всё равно недоступны — установка продолжится
из кэша пакетов.

### Что делает установщик

| Шаг | Действие |
|-----|----------|
| 1 | обновляет репозитории (с авто-починкой для Kali), ставит `swaybg`, `sddm`, Qt6 QML |
| 2 | если Hyprland не найден — ставит пакет `hyprland`; определяет версию |
| 3 | кладёт конфиг под версию: `hyprland.conf` (0.53+) или `hyprland-legacy.conf` (старее) |
| 4 | копирует конфиги Waybar / Rofi / kitty / swaync / wlogout / hyprlock / hypridle |
| 5 | ставит шрифты, обои, аватар и тему SDDM в `/usr/share/sddm/themes/aurora` |
| 6 | добавляет сессию Hyprland в `/usr/share/wayland-sessions` и `/usr/local/share/...` |
| 7 | отключает lightdm/gdm, включает SDDM, пишет настройки DM для systemd и SysV |

**Все прежние конфиги сохраняются** в `~/.config/aurora-backup-ДАТА/`.

После перезагрузки в SDDM: пользователь `studen`, сессия **Hyprland**
(кнопки сессий под полем ввода пароля). Запасной вариант — **Xfce** в том же меню.

Откат DM: `sudo systemctl enable --now lightdm`.

---

## Горячие клавиши

| Комбинация | Действие |
|------------|----------|
| `SUPER + Return` | kitty |
| `SUPER + D` | rofi (запуск приложений) |
| `SUPER + B` | firefox |
| `SUPER + E` | thunar |
| `SUPER + Q` | закрыть окно |
| `SUPER + L` | hyprlock |
| `SUPER + V` | история буфера (cliphist) |
| `SUPER + W` | сменить обои |
| `SUPER + S` / `SUPER + Shift + S` | скриншот области / всего экрана |
| `Print` / `Shift + Print` | скриншот всего / области |
| `SUPER + Esc` | wlogout |
| `SUPER + F` / `SUPER + Shift + F` | fullscreen / полный fullscreen |
| `SUPER + Space` | плавающее окно |
| `SUPER + P` | pseudo-tile |
| `SUPER + J` | разделить/объединить сплит |
| `SUPER + Tab` | следующее окно |
| `SUPER + стрелки` | фокус |
| `ALT + HJKL` | фокус (vim) |
| `SUPER + Shift + стрелки` | переместить окно |
| `SUPER + Ctrl + стрелки` | изменить размер |
| `SUPER + 1…0` | рабочий стол 1…10 |
| `SUPER + Shift + 1…0` | перенести окно на стол |
| `SUPER + \`` | special workspace `magic` |
| `Alt + Tab` | переключатель окон rofi |
| `XF86Audio*` / `XF86MonBrightness*` | звук / яркость |

---

## Структура

```
~/aurora-dots/
├── install.sh               универсальный установщик
├── hyprland.conf            конфиг для Hyprland 0.53+
├── hyprland-legacy.conf     конфиг для Hyprland < 0.53
├── dotfiles/                конфиги, которые копируются в ~/.config
│   ├── hypr/                hyprlock, hypridle, avatar, scripts/
│   ├── waybar/              config.jsonc + style.css
│   ├── rofi/                config.rasi + aurora.rasi
│   ├── kitty/               kitty.conf
│   ├── swaync/              config.json + style.css
│   └── wlogout/             layout + style.css
├── sddm/aurora/             QML-тема входа
├── fonts/                   JetBrainsMono Nerd Font (4 начертания)
├── wallpapers/              aurora.png, aurora-4k.png, aurora-blur.png
└── tools/gen_wall.py        генератор обоев (numpy + PIL)
```

---

## Полезное

```bash
hyprctl reload                              # применить правки конфига
hyprctl monitors                            # мониторы
Hyprland --verify-config                    # проверить синтаксис
swaync-client -t -sw                        # центр уведомлений
fc-cache -f && fc-match "JetBrainsMono Nerd Font"
```

### Если Hyprland тормозит в VirtualBox

В конфиге уже отключён аппаратный курсор (`no_hardware_cursors`, `WLR_NO_HARDWARE_CURSORS=1`).
Дополнительно уменьшите блюр:

```ini
decoration {
    blur { size = 4; passes = 1 }
}
```

Включите 3D-ускорение VirtualBox и дайте VM 2+ ядра.
