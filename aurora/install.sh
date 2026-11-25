#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#   AURORA · универсальный диспетчер
#   Выбирает install-kali.sh или install-debian.sh по /etc/os-release.
# ══════════════════════════════════════════════════════════════
set -uo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ID=""
[[ -f /etc/os-release ]] && . /etc/os-release
case "${ID:-linux}" in
    kali) exec bash "$SRC/install-kali.sh" "$@" ;;
    *)    exec bash "$SRC/install-debian.sh" "$@" ;;
esac
