#!/usr/bin/env bash
# lib/vlc.sh — VLC con paleta Qt oscura o clara según el modo activo.

install_vlc_config() {
  local home="$TARGET_HOME"
  local vlcrc="$home/.config/vlc/vlcrc"
  local dark="${THEME_VLC_DARK:-1}"

  section "Configurando VLC"

  if dry_run; then
    log "[dry-run] dejar qt-dark-palette=$dark en $vlcrc"
    return 0
  fi

  # VLC se niega a arrancar como root ("not supposed to be run as root"), así
  # que la sonda se ejecuta como el usuario destino. Si no hay salida, se
  # continúa: VLC ignora las claves desconocidas de vlcrc.
  local vlc_help=""
  if cmd_exists vlc; then
    vlc_help=$(run_user vlc -H --advanced 2>/dev/null || true)
  fi

  if [[ -n "$vlc_help" ]] && ! grep -q -- '--qt-dark-palette' <<<"$vlc_help"; then
    warn "Esta versión de VLC no admite qt-dark-palette; se omite el modo de color"
    return 0
  fi

  make_user_dir "$home/.config/vlc"

  if [[ -f "$vlcrc" ]]; then
    if grep -qE '^#?qt-dark-palette=' "$vlcrc"; then
      run_user sed -i "s/^#\\{0,1\\}qt-dark-palette=.*/qt-dark-palette=$dark/" "$vlcrc"
    else
      printf '\nqt-dark-palette=%s\n' "$dark" >>"$vlcrc"
    fi
  else
    render_theme_template "$PROJECT_ROOT/templates/vlc/vlcrc.in" "$vlcrc" 0600
  fi

  # VLC reescribe el archivo al salir; asegurar permisos y propiedad.
  if [[ "$EUID" -eq 0 ]]; then
    chown "$TARGET_USER:$TARGET_GROUP" -- "$vlcrc" 2>/dev/null || true
  fi
  chmod 0600 -- "$vlcrc"

  if grep -qx "qt-dark-palette=$dark" "$vlcrc"; then
    ok "VLC: paleta Qt $([[ "$dark" == "1" ]] && echo oscura || echo clara)"
  else
    error "No se pudo ajustar la paleta de VLC: $vlcrc"
  fi
}
