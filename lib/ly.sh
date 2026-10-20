#!/usr/bin/env bash
# Compilación e instalación de Ly.
# Ly no está empaquetado en Debian 13: se compila con Zig 0.17.

LY_REPO="https://codeberg.org/fairyglade/ly.git"
LY_COMMIT="4e0f23f08406f20b95146de6ce2e876918d7903d"
LY_VERSION="1.6.0"
LY_CACHE="/var/cache/dwm-setup"
LY_SRC="$LY_CACHE/ly-src"
LY_BIN="/usr/bin/ly"
LY_CONFIG="/etc/ly/config.lua"
LY_SERVICE="/usr/lib/systemd/system/ly@.service"

ZIG_VERSION="0.17.0"
ZIG_DIR="$LY_CACHE/zig-x86_64-linux-${ZIG_VERSION}"
ZIG_BIN="$ZIG_DIR/zig"
ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz"
ZIG_SHA256="1cbe9df9f27e6b78d14ccbca43b6703a404ef79ef1c463de901d7f088d4e2026"

ensure_zig() {
  if [[ -x "$ZIG_BIN" ]] && "$ZIG_BIN" version 2>/dev/null | grep -qx "$ZIG_VERSION"; then
    ok "Zig $ZIG_VERSION disponible"
    return 0
  fi
  info "Instalando Zig $ZIG_VERSION en $LY_CACHE"
  local archive="$LY_CACHE/zig-${ZIG_VERSION}.tar.xz"
  run_root install -d -m 0755 "$LY_CACHE"
  if [[ ! -r "$archive" ]]; then
    if ! run_root curl -fL --retry 3 --connect-timeout 20 -o "$archive" "$ZIG_URL"; then
      die "No se pudo descargar Zig $ZIG_VERSION"
    fi
  fi
  if ! printf '%s  %s\n' "$ZIG_SHA256" "$archive" | sha256sum -c - >/dev/null 2>&1; then
    run_root rm -f "$archive"
    die "Checksum incorrecto para Zig $ZIG_VERSION"
  fi
  run_root rm -rf "$ZIG_DIR"
  run_root tar -xJf "$archive" -C "$LY_CACHE"
  [[ -x "$ZIG_BIN" ]] || die "Zig no quedó en $ZIG_BIN"
  ok "Zig $ZIG_VERSION instalado"
}

build_ly() {
  section "Ly (display manager)"
  if dry_run; then
    log "[dry-run] compilar Ly $LY_VERSION ($LY_COMMIT) con Zig $ZIG_VERSION"
    log "[dry-run] instalar /usr/bin/ly y /etc/ly/config.lua"
    return 0
  fi
  if [[ -x "$LY_BIN" && -r "$LY_CONFIG" && -r "$LY_SERVICE" && "${FORCE_REBUILD:-0}" != "1" ]]; then
    ok "Ly ya está instalado ($LY_BIN); usa --rebuild para recompilar"
    return 0
  fi
  ensure_zig
  if [[ -d "$LY_SRC/.git" ]]; then
    run_root git -C "$LY_SRC" fetch --tags origin
  else
    run_root rm -rf "$LY_SRC"
    if ! run_root git clone "$LY_REPO" "$LY_SRC"; then
      die "No se pudo clonar Ly desde $LY_REPO"
    fi
  fi
  if ! run_root git -C "$LY_SRC" checkout --detach "$LY_COMMIT"; then
    die "No se pudo usar el commit de Ly $LY_COMMIT"
  fi
  backup_root "$LY_BIN"
  backup_root "/etc/ly"
  backup_root "$LY_SERVICE"
  info "Compilando Ly..."
  local -a zig_env=(
    "PATH=$ZIG_DIR:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    "ZIG_GLOBAL_CACHE_DIR=$LY_CACHE/zig-global-cache"
    "ZIG_LOCAL_CACHE_DIR=$LY_CACHE/zig-local-cache"
  )
  if ! run_root env "${zig_env[@]}" sh -c 'cd "$1" && shift && exec "$@"' sh \
    "$LY_SRC" "$ZIG_BIN" build installexe -Dinit_system=systemd; then
    die "Falló la compilación/instalación de Ly. Revisa el log."
  fi
  [[ -x "$LY_BIN" ]] || die "Ly no se instaló en $LY_BIN"
  [[ -r "$LY_CONFIG" ]] || die "Ly no instaló $LY_CONFIG"
  ok "Ly instalado: $LY_BIN"
}

ly_set() {
  local key="$1" value="$2" escaped
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$LY_CONFIG"; then
    escaped=$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')
    run_root sed -i -E "s|^[[:space:]]*${key}[[:space:]]*=.*$|    ${key} = ${escaped},|" "$LY_CONFIG"
  else
    warn "No se encontró $key en $LY_CONFIG; se deja el valor por defecto"
  fi
}

configure_ly() {
  section "Configuración de Ly"
  if dry_run; then
    log "[dry-run] configurar Ly: Gruvbox, español, sin shell/xinitrc, solo sesión dwm"
    return 0
  fi
  [[ -r "$LY_CONFIG" ]] || die "No existe $LY_CONFIG"
  backup_root "$LY_CONFIG"
  local lang="en"
  [[ -r /etc/ly/lang/es.ini ]] && lang="es"
  local battery_value="nil"
  if [[ -n "$BATTERY" ]]; then
    battery_value="\"$BATTERY\""
  fi

  ly_set allow_empty_password "false"
  ly_set animation '"none"'
  ly_set bg "0x001e2122"
  ly_set fg "0x00c7b89d"
  ly_set border_fg "0x00d1b171"
  ly_set error_fg "0x01ec6b64"
  ly_set blank_box "false"
  ly_set box_title '"dwm"'
  ly_set clock '"%H:%M"'
  ly_set initial_info_text '"dwm / Debian 13"'
  ly_set lang "\"$lang\""
  ly_set shell "false"
  ly_set xinitrc "nil"
  ly_set waylandsessions "nil"
  ly_set battery_id "$battery_value"
  ly_set bigclock '"none"'
  ly_set numlock "false"
  ly_set type_username "false"
  ly_set clear_password "true"
  ly_set hide_borders "false"

  run_root chown root:root "$LY_CONFIG"
  run_root chmod 0644 "$LY_CONFIG"
  if run_root sh -c '/usr/bin/ly --help 2>&1 | grep -q -- --validate-config'; then
    if ! run_root timeout 15 /usr/bin/ly --validate-config "$LY_CONFIG"; then
      warn "Ly --validate-config devolvió error; revisa $LY_CONFIG"
    else
      ok "Configuración de Ly validada"
    fi
  else
    debug "Esta versión de Ly no expone --validate-config"
  fi
}

disable_other_display_managers() {
  local dm
  for dm in lightdm gdm3 sddm lxdm xdm; do
    if systemctl list-unit-files "$dm.service" >/dev/null 2>&1; then
      run_root systemctl disable "$dm.service" >/dev/null 2>&1 || true
      info "Display manager alternativo deshabilitado: $dm"
    fi
  done
}

enable_ly() {
  section "Servicio Ly"
  if dry_run; then
    log "[dry-run] deshabilitar getty@tty2 y habilitar ly@tty2.service"
    return 0
  fi
  [[ -r "$LY_SERVICE" ]] || die "No existe $LY_SERVICE"
  [[ -x /usr/sbin/agetty ]] || die "No existe /usr/sbin/agetty (paquete util-linux)"
  disable_other_display_managers
  run_root systemctl daemon-reload
  run_root systemctl disable getty@tty2.service >/dev/null 2>&1 || true
  if ! run_root systemctl enable ly@tty2.service; then
    die "No se pudo habilitar ly@tty2.service"
  fi
  if [[ "$(systemctl is-enabled ly@tty2.service 2>/dev/null || true)" == "enabled" ]]; then
    ok "Ly habilitado en tty2 (arrancará en el próximo reinicio)"
  else
    die "Ly no quedó habilitado en systemd"
  fi
}

install_ly() {
  build_ly
  configure_ly
  enable_ly
}
