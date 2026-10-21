#!/usr/bin/env bash
# Verificación posterior a la instalación (sin arrancar la sesión gráfica).

verify_install() {
  section "Verificación final"
  local failures=0
  local home="$TARGET_HOME"
  local theme="${DWM_THEME:-monolith}"
  local cmd xorg_owner xorg_mode

  for cmd in dwm eww picom dunst rofi feh kitty flameshot i3lock xss-lock \
    brightnessctl xclip pcmanfm udiskie v4l2-ctl ffmpeg pactl wpctl pamixer xwallpaper playerctl; do
    if cmd_exists "$cmd"; then
      debug "ok: $cmd"
    else
      error "Falta el comando requerido: $cmd"
      failures=$((failures + 1))
    fi
  done

  for path in \
    "$home/.config/dwm/run.sh" \
    "$home/.config/dwm/scripts/bar.sh" \
    "$home/.config/dwm/scripts/bar_themes/$theme" \
    "$home/.config/dwm/scripts/bar_themes/gruvchad" \
    "$home/.config/dwm/picom.conf" \
    "$home/.config/dwm/dunst/dunstrc" \
    "$home/.config/dwm/rofi/config.rasi" \
    "$home/.config/dwm/rofi/colors.rasi" \
    "$home/.config/dwm/rofi/fonts.rasi" \
    "$home/.config/dwm/eww/eww.yuck" \
    "$home/.config/dwm/eww/vars.yuck" \
    "$home/.config/dwm/eww/widgets.yuck" \
    "$home/.config/dwm/eww/eww.scss" \
    "$home/.config/dwm/eww/scripts/volume" \
    "$home/.config/dwm/eww/scripts/brightness" \
    "$home/.config/dwm/eww/scripts/battery" \
    "$home/.config/dwm/eww/scripts/wifi" \
    "$home/.config/dwm/eww/scripts/temp" \
    "$home/.config/dwm/eww/scripts/updates" \
    "$home/.config/dwm/eww/scripts/uptime" \
    "$home/.config/dwm/eww/scripts/music" \
    "$home/.config/dwm/eww/scripts/bluetooth" \
    "$home/.config/dwm/eww/scripts/network" \
    "$home/.config/dwm/eww/scripts/energy" \
    "$home/.config/dwm/eww/scripts/nightlight" \
    "$home/.config/dwm/eww/scripts/cpu" \
    "$home/.config/dwm/eww/scripts/ram" \
    "$home/.config/dwm/eww/scripts/disk" \
    "$home/.local/share/wallpapers/rocky.jpg" \
    "$home/.local/share/xorg" \
    "/usr/share/xsessions/dwm.desktop" \
    "/usr/local/bin/dwm-safe" \
    "/usr/local/bin/dwm-doctor" \
    "/etc/ly/config.lua"; do
    if [[ -e "$path" ]]; then
      debug "ok: $path"
    else
      error "Falta el archivo requerido: $path"
      failures=$((failures + 1))
    fi
  done

  # Detectar anidado accidental scripts/scripts (bug cp -a)
  if [[ -d "$home/.config/dwm/eww/scripts/scripts" ]]; then
    error "Directorio anidado detectado: $home/.config/dwm/eww/scripts/scripts (reinstale para corregir)"
    failures=$((failures + 1))
  fi

  if [[ -x "$home/.config/dwm/run.sh" && -x "$home/.config/dwm/scripts/bar.sh" ]]; then
    debug "ok: scripts ejecutables"
  else
    error "run.sh o bar.sh no son ejecutables"
    failures=$((failures + 1))
  fi

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

  if [[ -r /etc/ly/config.lua ]]; then
    grep -q 'xinitrc = nil' /etc/ly/config.lua || { error "Ly: xinitrc no está oculto"; failures=$((failures + 1)); }
    grep -q 'shell = false' /etc/ly/config.lua || { error "Ly: shell no está oculta"; failures=$((failures + 1)); }
  fi

  if [[ "$(systemctl is-enabled ly@tty2.service 2>/dev/null || true)" == "enabled" ]]; then
    debug "ok: ly@tty2 habilitado"
  else
    error "ly@tty2.service no está habilitado"
    failures=$((failures + 1))
  fi
  if [[ "$(systemctl is-enabled udisks2.service 2>/dev/null || true)" == "enabled" || "$(systemctl is-enabled udisks2.service 2>/dev/null || true)" == "static" ]]; then
    debug "ok: udisks2"
  else
    error "udisks2.service no está habilitado"
    failures=$((failures + 1))
  fi

  if cmd_exists dwm; then
    if [[ "$(timeout 10 dwm -v 2>&1 || true)" == dwm-* ]]; then
      debug "ok: dwm -v"
    else
      error "dwm -v falló"
      failures=$((failures + 1))
    fi
  fi

  if cmd_exists eww; then
    if eww --version >/dev/null 2>&1; then
      debug "ok: eww --version"
    else
      error "eww --version falló"
      failures=$((failures + 1))
    fi
  fi

  if cmd_exists v4l2-ctl; then
    if v4l2-ctl --list-devices >/dev/null 2>&1; then
      debug "ok: v4l2-ctl"
    else
      warn "v4l2-ctl no pudo listar dispositivos"
    fi
  fi

  # Verificar que no queden placeholders sin renderizar en configs
  for path in \
    "$home/.config/dwm/picom.conf" \
    "$home/.config/dwm/dunst/dunstrc" \
    "$home/.config/dwm/rofi/colors.rasi" \
    "$home/.config/dwm/eww/vars.yuck" \
    "$home/.config/dwm/eww/eww.scss"; do
    if [[ -f "$path" ]] && grep -q '@COLOR_' "$path" 2>/dev/null; then
      error "Placeholders @COLOR_*@ sin renderizar en $path"
      failures=$((failures + 1))
    fi
  done

  if [[ ${#CAMERAS[@]} -eq 0 ]]; then
    warn "No se detectó cámara; la prueba real se omite"
  else
    info "Cámara(s) detectada(s): ${CAMERAS[*]}"
    info "Prueba real de captura tras iniciar sesión: dwm-doctor --camera"
  fi

  if ((failures > 0)); then
    error "Verificación con $failures fallo(s). Revisa el log antes de reiniciar."
    return 1
  fi
  ok "Verificación estática correcta"
}