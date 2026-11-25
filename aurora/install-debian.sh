#!/usr/bin/env bash
# Совместимость: Debian-псевдоним единого установщика
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SRC/install.sh" "$@"
