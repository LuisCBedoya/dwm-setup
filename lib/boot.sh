#!/usr/bin/env bash
# lib/boot.sh — arranque más rápido: GRUB, módulos y timers.
# Todo idempotente y con backup antes de escribir (regla 5).

install_boot_tweaks() {
  section "Ajustes de arranque"

  if dry_run; then
    log "[dry-run] GRUB_TIMEOUT=2 en /etc/default/grub + update-grub"
    log "[dry-run] quitar /etc/modules-load.d/nvidia.conf (nvidia bajo demanda)"
    log "[dry-run] diferir systemd-tmpfiles-clean.timer (OnBootSec=1h)"
    log "[dry-run] desactivar NetworkManager-wait-online.service"
    return 0
  fi

  set_grub_timeout
  drop_nvidia_boot_module
  defer_tmpfiles_clean
  disable_wait_online
}

# Menú de GRUB de 2 s en vez de 5 s.
set_grub_timeout() {
  local grub=/etc/default/grub

  if [[ ! -f "$grub" ]]; then
    warn "Sin $grub: se omite GRUB_TIMEOUT"
    return 0
  fi
  if grep -qx 'GRUB_TIMEOUT=2' "$grub"; then
    info "GRUB_TIMEOUT ya es 2"
    return 0
  fi

  backup_root "$grub"
  run_root sed -i -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' "$grub"
  run_root update-grub >/dev/null 2>&1 \
    || warn "update-grub falló; el cambio se aplicará al regenerar el menú"
  ok "GRUB_TIMEOUT = 2"
}

# nvidia-drm deja de cargarse en el boot: prime-run lo carga bajo demanda.
drop_nvidia_boot_module() {
  local mod=/etc/modules-load.d/nvidia.conf

  if [[ ! -f "$mod" ]]; then
    info "nvidia-drm no se carga en el boot"
    return 0
  fi

  backup_root "$mod"
  run_root rm -f "$mod"
  ok "nvidia-drm fuera del boot (prime-run lo carga al usarlo)"
}

# La limpieza de /tmp no corre en el arranque, sino una hora después.
defer_tmpfiles_clean() {
  local dir=/etc/systemd/system/systemd-tmpfiles-clean.timer.d
  local conf="$dir/10-dwm-setup.conf"
  local tmp

  if [[ -f "$conf" ]] && grep -qx 'OnBootSec=1h' "$conf"; then
    info "systemd-tmpfiles-clean ya está diferido"
    return 0
  fi

  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-setup-tmpfiles.XXXXXX")
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
