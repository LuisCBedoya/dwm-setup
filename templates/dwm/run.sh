#!/bin/sh
# Arranque de la sesión dwm (fase 1: escritorio)
# Este archivo se instala como ~/.config/dwm/run.sh
set -u

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
DWM_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dwm"
DWM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/dwm"

# Cargar environment (KEYMAP, WALLPAPER, FONT, FONT_SIZE, RESOLUTION, THEME)
if [ -r "$DWM_CONFIG/environment" ]; then
  . "$DWM_CONFIG/environment"
fi

WALLPAPER="${DWM_WALLPAPER:-$HOME/.local/share/wallpapers/rocky.jpg}"
export DWM_WALLPAPER="$WALLPAPER"
mkdir -p "$DWM_CACHE"

# Teclado y ratón. DWM_KEYMAP se puede cambiar en ~/.config/dwm/environment.
KEYMAP="${DWM_KEYMAP:-latam}"
if command -v setxkbmap >/dev/null 2>&1; then
  setxkbmap "$KEYMAP" 2>"$DWM_CACHE/keymap.log" || true
fi
xsetroot -cursor_name left_ptr 2>/dev/null || true
xset r rate 250 40 2>/dev/null || true
# xss-lock reacciona al screensaver de X. Sin un timeout explícito el
# bloqueo por inactividad depende de los valores por defecto del servidor.
xset s 300 5 2>/dev/null || true
xset +dpms 2>/dev/null || true
xset dpms 0 0 600 2>/dev/null || true

# Wallpaper con xwallpaper (fallback feh)
if [ -r "$WALLPAPER" ]; then
  if command -v xwallpaper >/dev/null 2>&1; then
    xwallpaper --zoom "$WALLPAPER" >"$DWM_CACHE/wallpaper.log" 2>&1 || true
  elif command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$WALLPAPER" >"$DWM_CACHE/feh.log" 2>&1 || true
  fi
fi

if command -v picom >/dev/null 2>&1; then
  picom --config "$DWM_CONFIG/picom.conf" -b >"$DWM_CACHE/picom.log" 2>&1 || true
fi

if command -v dunst >/dev/null 2>&1; then
  dunst -config "$DWM_CONFIG/dunst/dunstrc" >"$DWM_CACHE/dunst.log" 2>&1 &
fi

if [ -x "$DWM_CONFIG/scripts/bar.sh" ]; then
  "$DWM_CONFIG/scripts/bar.sh" >"$DWM_CACHE/bar.log" 2>&1 &
fi

if command -v eww >/dev/null 2>&1; then
  eww -c "$DWM_CONFIG/eww" daemon >"$DWM_CACHE/eww.log" 2>&1 &
  # Bajar eww debajo de otras ventanas
  sleep 2 && xdo lower -n eww 2>/dev/null || true
fi

# Almacenamiento extraíble: montar y notificar, nunca abrir una aplicación.
if command -v udiskie >/dev/null 2>&1; then
  udiskie --automount --notify >"$DWM_CACHE/udiskie.log" 2>&1 &
fi

if command -v lxpolkit >/dev/null 2>&1; then
  lxpolkit >"$DWM_CACHE/lxpolkit.log" 2>&1 &
fi

if command -v nm-applet >/dev/null 2>&1; then
  nm-applet >"$DWM_CACHE/nm-applet.log" 2>&1 &
fi

# xss-lock bloquea por inactividad y antes de suspender.
if command -v xss-lock >/dev/null 2>&1 && [ -x /usr/local/bin/dwm-safe ]; then
  xss-lock --transfer-sleep-lock -- /usr/local/bin/dwm-safe lock \
    >"$DWM_CACHE/xss-lock.log" 2>&1 &
fi

if ! command -v dwm >/dev/null 2>&1; then
  command -v notify-send >/dev/null 2>&1 && \
    notify-send -u critical "dwm no está instalado" "Ejecuta el instalador de fase 1."
  exit 1
fi

exec dwm