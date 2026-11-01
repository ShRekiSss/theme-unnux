#!/bin/bash
# ─── Памятка: все горячие клавиши (Win + /) ───
# окно с живым поиском; закрывается по Esc

if pidof rofi >/dev/null; then pkill rofi; fi

memo() {
cat <<'EOF'
📜 ПАМЯТКА — горячие клавиши

────── Основное ──────
Win (кнопка Windows)  → меню программ
Win + 1 … 9           → перейти на рабочий стол №N
Win + Shift + 1…9     → перенести окно на стол №N
Win + Enter           → новый терминал
Win + Shift + Enter   → выпадающий терминал сверху
Win + Q               → закрыть окно
Win + Shift + Q       → выключить программу совсем
Ctrl + Shift          → переключить РУС / АНГЛ
Alt + Tab             → прыгать по окнам

────── Окна ──────
Win + F               → окно на весь экран
Win + Ctrl + F        → растянуть окно (с панелью)
Win + Пробел          → прилепить/отклеить окно
Win + стрелки         → переключение между окнами
Win + ЛКМ (держать)   → таскать окно мышью
Win + ПКМ (держать)   → менять размер окна

────── Приложения ──────
Win + D               → меню программ
Win + E               → файлы (Thunar)
Win + B               → браузер
Win + S               → поиск в интернете
Win + Alt + V         → буфер обмена (что копировал)
Win + Alt + C         → калькулятор
Win + Alt + E         → эмодзи 😸
Win + Shift + M       → музыка онлайн
Win + Shift + N       → центр уведомлений

────── Обои и внешний вид ──────
Win + W               → выбрать обои вручную
Ctrl + Alt + W        → случайные обои
Win + Shift + W       → эффекты обоев (размытие)
Win + T               → перекрасить всё под обои
Win + Shift + A       → меню анимаций
Win + Alt + O         → размытие окон вкл/выкл
Win + Alt + L         → другая раскладка плиток
Win + N               → ночная подсветка (тёплый экран)
Win + Shift + G       → режим игры (без анимаций)
Win + Ctrl + O        → сделать окно непрозрачным

────── Плитки ──────
Win + Shift + I       → делить окно на две плитки
Win + I / Ctrl + D    → добавить / убрать «мастер» окно

────── Панель Power/меню ──────
Win + Ctrl + B        → сменить стиль панели
Win + Ctrl + Alt + B  → показать/спрятать панель
Ctrl + Alt + L        → экран блокировки
Ctrl + Alt + P        → меню выключения (выйти/сон)
Ctrl + Alt + Delete   → выйти из Hyprland

────── Памятки ──────
Win + /               → ЭТА памятка
Win + Shift + K       → ЖИВАЯ памятка: поиск любой комбинации (rofi)

Esc — закрыть выпад
EOF
}

memo | rofi -dmenu -i -p "Памятка" \
    -theme-str 'window {width: 62%; height: 68%; border: 2px; border-color: #8B5CF6; border-radius: 12px;}' \
    -theme-str 'listview {lines: 22; scrollbar: true;}' \
    -theme-str 'inputbar {children: [prompt, entry]; background-color: #2A1F3D; text-color: #E9D5FF;}' \
    -theme-str 'prompt {text-color: #C4B5FD;}' \
    -theme-str 'entry {text-color: #F5F3FF; placeholder: "печатай для поиска…";}' \
    -theme-str 'element {text-color: #DDD6FE;} element selected {background-color: #6D28D9; text-color: #FFFFFF;}' \
    -mesg "Esc — закрыть · печатай, чтобы найти нужную комбинацию" \
    >/dev/null 2>&1
