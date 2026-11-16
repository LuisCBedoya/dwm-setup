#!/usr/bin/env bash
# lib/bluetooth.sh — Bluetooth apagado por defecto al iniciar sesión.
#
# El servicio bluetooth.service sigue activo para que el módulo polybar
# pueda encender el adaptador con bluetoothctl; lo que se desactiva es el
# autoencendido del controlador (AutoEnable=false).

install_bluetooth_defaults() {
  section "Bluetooth (apagado por defecto)"

  local conf="${DWM_SETUP_BLUETOOTH_CONF:-/etc/bluetooth/main.conf}"
  local tmp

  if dry_run; then
    log "[dry-run] poner AutoEnable=false en $conf"
    log "[dry-run] reiniciar bluetooth.service"
    return 0
  fi

  if [[ ! -f "$conf" ]]; then
    warn "No existe $conf; se omite el apagado por defecto de Bluetooth"
    return 0
  fi

  backup_root "$conf"
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-bluetooth.XXXXXX")
  awk '
    BEGIN { policy = 0; done = 0 }
    /^\[Policy\]/ { policy = 1; print; next }
    /^\[/ { policy = 0; print; next }
    policy && /^[#[:space:]]*AutoEnable[[:space:]]*=/ {
      if (!done) {
        print "AutoEnable=false"
        done = 1
      }
      next
    }
    { print }
    END {
      if (!done)
        print "\n[Policy]\nAutoEnable=false"
    }
  ' "$conf" >"$tmp"

  run_root install -m 0644 -o root -g root "$tmp" "$conf"
  rm -f -- "$tmp"

  run_root systemctl restart bluetooth
  ok "Bluetooth arranca apagado (AutoEnable=false); servicio activo"
}
