#!/usr/bin/env bash
# Verificación posterior a la instalación (sin arrancar la sesión gráfica).

verify_install() {
  section "Verificación final"
  local failures=0
  local home="$TARGET_HOME"

  for cmd in bspwm sxhkd polybar picom dunst rofi feh kitty flameshot i3lock xss-lock \
    brightnessctl xclip thunar udiskie v4l2-ctl ffmpeg pactl wpctl pamixer xwallpaper playerctl; do
    if cmd_exists "$cmd"; then
      debug "ok: $cmd"
    else
      error "Falta el comando requerido: $cmd"
      failures=$((failures + 1))
    fi
  done

  for path in \
    "$home/.config/bspwm/bspwmrc" \
    "$home/.config/bspwm/scripts/autostart" \
    "$home/.config/bspwm/scripts/bspwm_resize" \
    "$home/.config/bspwm/scripts/low_bat_notifier.sh" \
    "$home/.config/bspwm/scripts/keybindings_rofi.sh" \
    "$home/.config/bspwm/scripts/screenshot.sh" \
    "$home/.config/sxhkd/sxhkdrc" \
    "$home/.config/polybar/config.ini" \
    "$home/.config/polybar/launch.sh" \
    "$home/.config/polybar/modules/logo.ini" \
    "$home/.config/polybar/modules/bspwm.ini" \
    "$home/.config/polybar/modules/updates.ini" \
    "$home/.config/polybar/modules/polypomo.ini" \
    "$home/.config/polybar/modules/temp.ini" \
    "$home/.config/polybar/modules/memory.ini" \
    "$home/.config/polybar/modules/cpu.ini" \
    "$home/.config/polybar/modules/xkeyboard.ini" \
    "$home/.config/polybar/modules/eth.ini" \
    "$home/.config/polybar/modules/wlan.ini" \
    "$home/.config/polybar/modules/battery.ini" \
    "$home/.config/polybar/modules/pipewire.ini" \
    "$home/.config/polybar/modules/date.ini" \
    "$home/.config/polybar/modules/dots.ini" \
    "$home/.config/polybar/scripts/updates-apt.sh" \
    "$home/.config/polybar/scripts/polypomo" \
    "$home/.config/picom/picom.conf" \
    "$home/.config/dunst/dunstrc" \
    "$home/.config/rofi/powermenu.rasi" \
    "$home/.config/kitty/kitty.conf" \
    "$home/.xinitrc" \
    "$home/.local/share/wallpapers/rocky.jpg" \
    "$home/.local/share/xorg" \
    "/usr/local/bin/desktop-safe" \
    "/usr/local/bin/desktop-doctor" \
    "/usr/local/share/fonts/dwm-setup/desktop-logo.ttf"; do
    if [[ -e "$path" ]]; then
      debug "ok: $path"
    else
      error "Falta el archivo requerido: $path"
      failures=$((failures + 1))
    fi
  done

  # Verificar la fuente propia del logo (U+E000)
  if fc-list :charset=e000 2>/dev/null | grep -qi 'DesktopLogo'; then
    debug "ok: fuente DesktopLogo"
  else
    error "Falta la fuente DesktopLogo; el logo de la barra no renderizará"
    failures=$((failures + 1))
  fi

  # Verificar scripts ejecutables
  for script in "$home/.config/bspwm/scripts/"* "$home/.config/polybar/scripts/"*; do
    if [[ -f "$script" && ! -x "$script" ]]; then
      error "Script no ejecutable: $script"
      failures=$((failures + 1))
    fi
  done

  # Verificar directorio Xorg
  if [[ -d "$home/.local/share/xorg" ]]; then
    xorg_owner=$(stat -c '%U' "$home/.local/share/xorg" 2>/dev/null || true)
    xorg_mode=$(stat -c '%a' "$home/.local/share/xorg" 2>/dev/null || true)
    if [[ "$xorg_owner" == "$TARGET_USER" && "$xorg_mode" == "700" && -w "$home/.local/share/xorg" ]]; then
      debug "ok: Xorg puede escribir su log en $home/.local/share/xorg"
    else
      error "Permisos incorrectos en $home/.local/share/xorg: $xorg_owner $xorg_mode (se espera $TARGET_USER 700)"
      failures=$((failures + 1))
    fi
  else
    error "Falta el directorio escribible para el log de Xorg: $home/.local/share/xorg"
    failures=$((failures + 1))
  fi

  # Servicios base
  if [[ "$(systemctl is-enabled udisks2.service 2>/dev/null || true)" == "enabled" || "$(systemctl is-enabled udisks2.service 2>/dev/null || true)" == "static" ]]; then
    debug "ok: udisks2"
  else
    error "udisks2.service no está habilitado"
    failures=$((failures + 1))
  fi
  if [[ "$(systemctl is-enabled NetworkManager.service 2>/dev/null || true)" == "enabled" || "$(systemctl is-enabled NetworkManager.service 2>/dev/null || true)" == "static" ]]; then
    debug "ok: NetworkManager"
  else
    error "NetworkManager.service no está habilitado"
    failures=$((failures + 1))
  fi

  # Verificar binarios
  if cmd_exists bspwm; then
    if [[ "$(timeout 5 bspwm -v 2>&1 || true)" == bspwm* ]]; then
      debug "ok: bspwm -v"
    else
      error "bspwm -v falló"
      failures=$((failures + 1))
    fi
  fi
  if cmd_exists sxhkd; then
    if sxhkd -v >/dev/null 2>&1; then
      debug "ok: sxhkd -v"
    else
      error "sxhkd -v falló"
      failures=$((failures + 1))
    fi
  fi
  if cmd_exists polybar; then
    if polybar --version >/dev/null 2>&1; then
      debug "ok: polybar --version"
    else
      error "polybar --version falló"
      failures=$((failures + 1))
    fi
  fi

  # Cámara
  if cmd_exists v4l2-ctl; then
    if v4l2-ctl --list-devices >/dev/null 2>&1; then
      debug "ok: v4l2-ctl"
    else
      warn "v4l2-ctl no pudo listar dispositivos"
    fi
  fi

  # Verificar que no queden placeholders sin renderizar en configs críticos
  for path in \
    "$home/.config/bspwm/bspwmrc" \
    "$home/.config/polybar/config.ini" \
    "$home/.config/picom/picom.conf" \
    "$home/.config/dunst/dunstrc" \
    "$home/.config/rofi/powermenu.rasi" \
    "$home/.config/kitty/kitty.conf" \
    "$home/.xinitrc"; do
    if [[ -f "$path" ]] && grep -q '@COLOR_\|@HOME@\|@FONT@\|@FONT_SIZE@\|@KEYMAP@\|@ETH_IFACE@\|@WLAN_IFACE@\|@BATTERY@\|@AC_ADAPTER@' "$path" 2>/dev/null; then
      error "Placeholders sin renderizar en $path"
      failures=$((failures + 1))
    fi
  done

  if [[ ${#CAMERAS[@]} -eq 0 ]]; then
    warn "No se detectó cámara; la prueba real se omite"
  else
    info "Cámara(s) detectada(s): ${CAMERAS[*]}"
    info "Prueba real de captura tras iniciar sesión: desktop-doctor --camera"
  fi

  if ((failures > 0)); then
    error "Verificación con $failures fallo(s). Revisa el log antes de reiniciar."
    return 1
  fi
  ok "Verificación estática correcta"
}