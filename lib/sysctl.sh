#!/usr/bin/env bash
# lib/sysctl.sh — ajustes del kernel persistentes (sysctl.d).

install_sysctl() {
  section "Ajustes del kernel (sysctl)"

  if dry_run; then
    log "[dry-run] instalar /etc/sysctl.d/99-dwm-setup-swappiness.conf (vm.swappiness=10)"
    log "[dry-run] sysctl --system"
    return 0
  fi

  backup_root /etc/sysctl.d/99-dwm-setup-swappiness.conf
  install_template_root 0644 \
    "$PROJECT_ROOT/templates/sysctl/99-dwm-setup-swappiness.conf" \
    /etc/sysctl.d/99-dwm-setup-swappiness.conf
  run_root sysctl --system >/dev/null 2>&1 || warn "sysctl --system falló; se aplicará en el próximo arranque"
  ok "vm.swappiness = $(cat /proc/sys/vm/swappiness 2>/dev/null || printf '?')"
}
