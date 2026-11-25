#!/usr/bin/env bash
# Совместимость: Kali-псевдоним единого установщика
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export KALI=1
exec bash "$SRC/install.sh" "$@"
