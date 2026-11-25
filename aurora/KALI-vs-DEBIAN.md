# Aurora: Kali-билд vs Debian-билд

Этот репозиторий изначально собирался **под Debian** (первый коммит
`15a3ae1 «Скрипт установки DE для Debian»`, затем `v2.0 — Kali/Debian/Ubuntu`).
Папка `aurora/` — отдельный билд, который сейчас доводится primarily под
**Kali Linux в VirtualBox**. Ниже — чем он отличается от «дебиановского» оригинала.

## Общее

Оба билда используют один и тот же стек: Hyprland, Waybar, Rofi, SwayNC,
wlogout, hyprlock, kitty, Firefox, Thunar. Оба ставят SDDM как менеджер входа.

## Ключевые отличия

| | Debian-билд (оригинал репо) | Kali/Aurora-билд (`aurora/`) |
|---|---|---|
| Установщик | `./install.sh`: копирует `config/` → `~/.config`, `scripts/` → `~/.local/bin`, обои → `~/Обои`, тему Alice | `install-debian.sh` + отдельный `install-kali.sh`; `install.sh` — диспетчер по `/etc/os-release` |
| Стиль | Alice / Fran Bow, фиолетовый, панель **снизу**, радикальный rice | Aurora, тёмный teal→violet glass, панель **сверху** + dock-ярлыки, окна «как в Windows» |
| SDDM-тема | `alice-purple` в `/usr/share/sddm/themes` | `aurora` (QML, Qt6), фон и аватар генерируются процедурно |
| Менеджер входа | SDDM, но настраивается KooL-установщиком | SDDM явно: `Current=aurora` и в `/etc/sddm.conf`, и в `conf.d`, отключение lightdm/gdm, поддержка systemd/OpenRC/runit/SysV |
| Репозитории | обычный apt Debian | **починка кривых строк** `deb.debian.org/... kali-rolling` (только комментирование, с бэкапом); версия дистрибутива не меняется |
| Обой | KooL-ротатор + wallust, живые обои (`mpvpaper`) | `swaybg` + `wallpaper.sh` (простой перебор PNG), без wallust и видео-обоев — легче для VM |
| Hyprland layout | dwindle, тайлинг | **floating**, `size = 1200 800`, `center = true`, декорации — окна ведут себя как в Windows |
| Графика | предполагается реальный GPU | VM-aware: при VirtualBox/VMware/QEMU создаётся `hyprland-aurora` с `MESA_LOADER_DRIVER_OVERRIDE=swrast`, `EGL_PLATFORM=gbm`, `LIBGL_ALWAYS_SOFTWARE=1`; на железе — прямой запуск |
| Производительность | полный эффект blur/shadow | для VM уменьшены blur (4/1), shadow (12/2), отключён `noise`; в kitty выключены `cursor_trail` и `dynamic_background_opacity`, урезан scrollback |
| Клавиши | `Ctrl+Shift` — раскладка, `Win` — rofi, `Win+/` — памятка | те же плюс полный порт из `configs/Keybinds.conf`: группы окон, master/dwindle, silent-move, code:10–19, waybar-toggle, скриншоты по Print |
| Панель | Waybar снизу, модули `Modules*` | Waybar сверху, `config.jsonc` + `style.css`, dock-ярлыки Firefox/Thunar/kitty/звук рядом с «Start» |
| Конфиги | 525 файлов в `config/` (btop, cava, kvantum, qt5ct/qt6ct, swappy, wallust…) | 37 компактных файлов: только то, что реально используется в сессии |
| Ярлыки на рабочем столе | `xfdesktop` (X11) | в Wayland нет desktop-icons из коробки; вместо них dock на панели. Для иконок на столе нужен `pcmanfm-qt`/`nautilus` |

## Что намеренно НЕ перенесено

- KooL-скрипты (`OverviewToggle.sh`, `RofiBeats.sh`, `ThemeChanger.sh`, `Wallust`, `KeyHints` и т.д.) — в Kali-билде их нет, рассыпать ссылки на несуществующие файлы было бы хуже.
- Живые обои `mpvpaper` и 25 артов из `обои/` — тяжело для софтверного рендера VirtualBox.
- `alice-purple` и `de-installer.sh` — это оригинальный Debian-рис, он остался в репо как есть.

## Почему два файла установки

Kali требует двух вещей, которых нет в Debian: починку/apt-запасной путь и
софтверный EGL для VM. Поэтому сделаны:

```
aurora/install-debian.sh   # общий установщик (Debian и др. дистрибутивы)
aurora/install-kali.sh     # KALI=1 → apt-fix + принудительный софтверный EGL
aurora/install.sh          # диспетчер, выбирает нужный по /etc/os-release
```

Оба варианта **не меняют версию системы**: `/etc/os-release`,
`/etc/debian_version`, `/etc/lsb-release` не трогаются никогда.
