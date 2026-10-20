#!/bin/sh
set -e

cd /home/luc/dwm-setup/src/chadwm/chadwm
cp -f /home/luc/dwm-setup/config.h ./config.h
make clean >/dev/null 2>&1 || true
make -j"$(nproc)"
mkdir -p "$HOME/.local/bin"
cp -f dwm "$HOME/.local/bin/dwm"
chmod 755 "$HOME/.local/bin/dwm"
"$HOME/.local/bin/dwm" -v
