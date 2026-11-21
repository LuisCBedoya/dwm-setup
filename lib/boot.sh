#!/usr/bin/env bash
# lib/boot.sh — arranque más rápido: GRUB, módulos y timers.
# Todo idempotente y con backup antes de escribir (regla 5).

install_boot_tweaks() {
  section "Ajustes de arranque"

  if dry_run; then
    log "[dry-run] GRUB_TIMEOUT=0 y GRUB_TIMEOUT_STYLE=hidden en /etc/default/grub + update-grub"
    log "[dry-run] quitar /etc/modules-load.d/nvidia.conf (nvidia bajo demanda)"
    log "[dry-run] diferir systemd-tmpfiles-clean.timer (OnBootSec=1h)"
    log "[dry-run] desactivar NetworkManager-wait-online.service"
    log "[dry-run] enmascarar apt-daily-upgrade.timer (actualizaciones manuales)"
    return 0
  fi

  set_grub_timeout
  drop_nvidia_boot_module
  defer_tmpfiles_clean
  disable_wait_online
  mask_apt_upgrade_timer
}

# Menú de GRUB oculto y sin espera; Shift/Esc lo muestra si hace falta.
set_grub_timeout() {
  local grub=/etc/default/grub

  if [[ ! -f "$grub" ]]; then
    warn "Sin $grub: se omite GRUB_TIMEOUT"
    return 0
  fi
  if grep -qx 'GRUB_TIMEOUT=0' "$grub" &&
     grep -qx 'GRUB_TIMEOUT_STYLE=hidden' "$grub"; then
    info "GRUB ya está en 0 s con menú oculto"
    return 0
  fi

  backup_root "$grub"
  run_root sed -i -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$grub"
  if grep -q '^GRUB_TIMEOUT_STYLE=' "$grub"; then
    run_root sed -i -E 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' "$grub"
  else
    run_root sed -i -E '$a GRUB_TIMEOUT_STYLE=hidden' "$grub"
  fi
  run_root update-grub >/dev/null 2>&1 \
    || warn "update-grub falló; el cambio se aplicará al regenerar el menú"
  ok "GRUB_TIMEOUT = 0 (menú oculto; Shift/Esc para verlo)"
}

# Quita la carga temprana de nvidia vía modules-load.d. El driver también
# puede cargarse por udev; la carga realmente bajo demanda (blacklist +
# helper) está pendiente de validar con modprobe -r/prime-run.
drop_nvidia_boot_module() {
  local mod=/etc/modules-load.d/nvidia.conf

  if [[ ! -f "$mod" ]]; then
    info "nvidia no está en modules-load.d"
    return 0
  fi

  backup_root "$mod"
  run_root rm -f "$mod"
  ok "nvidia fuera de modules-load.d (carga temprana eliminada)"
}

# La limpieza de /tmp no corre en el arranque, sino una hora después.
defer_tmpfiles_clean() {
  local dir=/etc/systemd/system/systemd-tmpfiles-clean.timer.d
  local conf="$dir/10-luc-workspace.conf"
  local tmp

  if [[ -f "$conf" ]] && grep -qx 'OnBootSec=1h' "$conf"; then
    info "systemd-tmpfiles-clean ya está diferido"
    return 0
  fi

  tmp=$(mktemp "${TMPDIR:-/tmp}/luc-workspace-tmpfiles.XXXXXX")
  cat >"$tmp" <<'EOF'
[Timer]
OnBootSec=1h
EOF
  run_root install -d -m 0755 "$dir"
  backup_root "$conf"
  run_root install -D -m 0644 "$tmp" "$conf"
  rm -f -- "$tmp"
  run_root systemctl daemon-reload >/dev/null 2>&1 || true
  ok "systemd-tmpfiles-clean diferido (OnBootSec=1h)"
}

# Quitar la espera de red del arranque.
disable_wait_online() {
  local unit=NetworkManager-wait-online.service

  if ! systemctl is-enabled --quiet "$unit" 2>/dev/null; then
    info "NetworkManager-wait-online ya está desactivado"
    return 0
  fi

  run_root systemctl disable "$unit" >/dev/null 2>&1 \
    || warn "No se pudo desactivar $unit"
  ok "NetworkManager-wait-online desactivado"
}

# Debian instala apt-daily-upgrade.timer para upgrades automáticos. El
# usuario actualiza a mano; se enmascara ese timer, no el de metadatos
# (apt-daily.timer), que mantiene fresca la lista del módulo updates.
# `mask` sobrevive a un `apt upgrade`; `disable` podría reactivarse.
mask_apt_upgrade_timer() {
  local unit=apt-daily-upgrade.timer
  local state

  if ! systemctl cat "$unit" >/dev/null 2>&1; then
    info "Sin $unit; se omite"
    return 0
  fi
  state=$(systemctl is-enabled "$unit" 2>/dev/null || true)
  if [[ "$state" == "masked" ]]; then
    info "$unit ya está enmascarado"
    return 0
  fi

  run_root systemctl mask --now "$unit" >/dev/null 2>&1 \
    || warn "No se pudo enmascarar $unit"
  ok "$unit enmascarado (actualizaciones manuales)"
}
