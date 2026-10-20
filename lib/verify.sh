#!/usr/bin/env bash
# Verificación posterior a la instalación (sin arrancar la sesión gráfica).

verify_install() {
  section "Verificación final"
  local failures=0
  local home="$TARGET_HOME"
  local cmd

  for cmd in dwm eww picom dunst rofi feh kitty flameshot i3lock xss-lock \
    brightnessctl xclip pcmanfm udiskie v4l2-ctl ffmpeg pactl wpctl; do
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
    "$home/.config/dwm/picom.conf" \
    "$home/.config/dwm/dunst/dunstrc" \
    "$home/.config/dwm/rofi/gruvbox.rasi" \
    "$home/.config/dwm/eww/eww.yuck" \
    "$home/.local/share/wallpapers/rocky.jpg" \
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

  if [[ -x "$home/.config/dwm/run.sh" && -x "$home/.config/dwm/scripts/bar.sh" ]]; then
    debug "ok: scripts ejecutables"
  else
    error "run.sh o bar.sh no son ejecutables"
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
