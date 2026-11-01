# 🌙 theme-unnux
Фиолетовый «creepy-cute» рис для **Hyprland** на Debian (forky/sid):
Alice: Madness Returns / Fran Bow, SDDM-тема Alice, панель снизу
со значком Windows и кнопкой питания, слайдшоу обоев, памятка `Win+/`.

## 🧩 Из чего состоит
| Папка | Что это |
|---|---|
| `config/` | конфиги Hyprland, Waybar, Rofi, SwayNC, Wallust, Kitty и др. |
| `scripts/` | свои скрипты: обои вкл/выкл, памятка, меню питания, раскладка |
| `обои/` | 22 статичных арта + 4 видео-обоя (Alice + Чеширский кот) |
| `sddm/` | SDDM-тема `alice-purple` |
| `install.sh` | переносит всё на места (конфиги, скрипты, обои, SDDM) |
| `de-installer.sh` | удалить основу (лежал в репо изначально) |

## ⚡ Установка (вкратце)
```bash
git clone https://github.com/ShRekiSss/theme-unnux
cd theme-unnux
./install.sh       # скопирует конфиги/скрипты/обои и настроит SDDM
```
Требуется уже установленный Hyprland-стек (быстро — через
[KooL Debian-Hyprland](https://github.com/LinuxBeginnings/Debian-Hyprland)
с файлом `preset-danze.sh` (в репо!):

## 🗝 Горячие клавиши (главное)
- `Ctrl+Shift` — РУС/АНГЛ
- `Win` (одна) — меню программ (rofi)
- `Win+1..9` — рабочие столы, `Win+F` — окно на весь экран
- `Win+/` — памятка по всем комбинациям (rofi, на русском)
- `Ctrl+Alt+P` — меню выключения (wlogout)
- обои меняются случайно каждые 2 минуты (KooL-ротатор)
