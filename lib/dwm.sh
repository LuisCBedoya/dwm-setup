#!/usr/bin/env bash
# Compilación e instalación de chadwm.

DWM_SRC="$PROJECT_ROOT/src/chadwm/chadwm"
DWM_BUILD="/var/cache/dwm-setup/chadwm-build"
DWM_BIN="/usr/local/bin/dwm"

build_dwm() {
  section "chadwm"
  if dry_run; then
    log "[dry-run] compilar chadwm desde $DWM_SRC"
    log "[dry-run] instalar binario en $DWM_BIN"
    return 0
  fi
  if [[ -x "$DWM_BIN" && -r "/usr/share/xsessions/dwm.desktop" && "${FORCE_REBUILD:-0}" != "1" ]]; then
    ok "dwm ya está instalado en $DWM_BIN (usa --rebuild para recompilar)"
    return 0
  fi
  [[ -f "$DWM_SRC/Makefile" ]] || die "No se encontró el código fuente de chadwm en $DWM_SRC"
  backup_root "$DWM_BIN"
  backup_root "/usr/share/xsessions/dwm.desktop"
  run_root rm -rf "$DWM_BUILD"
  run_root install -d -m 0755 "$DWM_BUILD"
  run_root cp -a "$DWM_SRC/." "$DWM_BUILD/"
  if ! run_root make -C "$DWM_BUILD" clean >/dev/null 2>&1; then
    debug "make clean no era necesario"
  fi
  # Generar config.h con tema actual (incluye colores)
  generate_chadwm_config_h "${DWM_THEME:-monolith}"
  info "Compilando chadwm..."
  if ! run_root make -C "$DWM_BUILD" -j"$(nproc)"; then
    die "Falló la compilación de chadwm. Revisa el log."
  fi
  run_root install -D -m 0755 "$DWM_BUILD/dwm" "$DWM_BIN"
  if [[ "$(timeout 10 "$DWM_BIN" -v 2>&1 || true)" != dwm-* ]]; then
    die "dwm se instaló pero no responde a -v"
  fi
  ok "chadwm instalado: $DWM_BIN"
}
