#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#   AURORA · установка для Kali Linux
#   Отдельный файл:он вызывает общий install-debian.sh в Kali-режиме.
#   Запуск: sudo bash ~/aurora-dots/install-kali.sh
# ══════════════════════════════════════════════════════════════
set -uo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export KALI=1
exec bash "$SRC/install-debian.sh" "$@"
