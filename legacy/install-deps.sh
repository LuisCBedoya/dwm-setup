#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta este script con sudo:"
  echo "  sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> Actualizando índices de APT..."
apt update

echo "==> Instalando dependencias de compilación y runtime..."
apt install -y \
  build-essential pkg-config \
  libx11-dev libxft-dev libxinerama-dev libxrender-dev libfontconfig1-dev libx11-xcb-dev libimlib2-dev \
  libgtk-3-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev libglib2.0-dev \
  libdbus-1-dev libxcb1-dev libxcb-randr0-dev libxcb-shape0-dev libxcb-xfixes0-dev \
  libxcb-xinerama0-dev libxcb-util-dev libxcb-cursor-dev libxkbcommon-dev \
  libxkbcommon-x11-dev libssl-dev zlib1g-dev \
  rustc cargo \
  picom dunst rofi feh alacritty kitty zathura zathura-pdf-poppler ranger cava playerctl \
  lxpolkit maim xclip i3lock brightnessctl suckless-tools x11-xserver-utils imagemagick \
  libnotify-bin blueman xserver-xephyr x11-utils xdotool keepassxc gpicview \
  mpv xss-lock

echo "==> Instalando la sesión de LightDM..."
install -Dm644 /home/luc/dwm-setup/dwm.desktop /usr/share/xsessions/dwm.desktop
chmod 755 /home/luc/.config/dwm/run.sh /home/luc/.config/dwm/scripts/bar.sh

echo
echo "==> Dependencias instaladas correctamente."
echo "    La sesión 'dwm (Gruvbox)' ya aparece en LightDM."
echo "    Siguiente paso: compilar dwm y eww."

