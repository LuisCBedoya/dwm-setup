#!/bin/sh
set -e

cd /home/luc/dwm-setup/src
if [ ! -d eww ]; then
  git clone --depth 1 --branch v0.6.0 https://github.com/elkowar/eww eww
fi
cd eww
cargo build --release --no-default-features --features x11
mkdir -p "$HOME/.local/bin"
cp -f target/release/eww "$HOME/.local/bin/eww"
chmod 755 "$HOME/.local/bin/eww"
"$HOME/.local/bin/eww" --version
