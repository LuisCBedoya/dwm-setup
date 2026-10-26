#!/usr/bin/env bash
# lib/vlc.sh — VLC con paleta oscura (qt-dark-palette)

install_vlc_config() {
  local home="$TARGET_HOME"
  local vlcrc="$home/.config/vlc/vlcrc"

  section "Configurando VLC"

  if dry_run; then
    log "[dry-run] activar qt-dark-palette=1 en $vlcrc"
    return 0
  fi

  if ! vlc -H --advanced 2>/dev/null | grep -q -- '--qt-dark-palette'; then
    warn "Esta versión de VLC no admite qt-dark-palette; se omite el modo oscuro"
    return 0
  fi

  make_user_dir "$home/.config/vlc"

  if [[ -f "$vlcrc" ]]; then
    if grep -qE '^#?qt-dark-palette=' "$vlcrc"; then
      run_user sed -i 's/^#\{0,1\}qt-dark-palette=.*/qt-dark-palette=1/' "$vlcrc"
    else
      printf '\nqt-dark-palette=1\n' >>"$vlcrc"
    fi
  else
    render_theme_template "$PROJECT_ROOT/templates/vlc/vlcrc.in" "$vlcrc" 0600
  fi

  # VLC reescribe el archivo al salir; asegurar permisos y propiedad.
  if [[ "$EUID" -eq 0 ]]; then
    chown "$TARGET_USER:$TARGET_GROUP" -- "$vlcrc" 2>/dev/null || true
  fi
  chmod 0600 -- "$vlcrc"

  if grep -qx 'qt-dark-palette=1' "$vlcrc"; then
    ok "VLC: paleta oscura activada"
  else
    error "No se pudo activar la paleta oscura de VLC: $vlcrc"
  fi
}
