#!/usr/bin/env bash
# lib/cpu.sh — Gobernador de CPU: helper root, sudoers acotado y unidad de arranque.
#
# El módulo polybar "governor" alterna en caliente con sudo -n; el helper
# raíz valida el valor y el fragmento de sudoers solo autoriza ese binario.
# La unidad systemd aplica performance al arrancar (decisión del usuario).

install_cpu_governor() {
  section "Gobernador de CPU"

  local helper_src="$PROJECT_ROOT/bin/dwm-setup-cpu-governor"
  local helper_dst="/usr/local/bin/dwm-setup-cpu-governor"
  local sudoers_src="$PROJECT_ROOT/templates/sudoers/dwm-setup-cpu-governor.in"
  local sudoers_dst="/etc/sudoers.d/dwm-setup-cpu-governor"
  local unit_src="$PROJECT_ROOT/templates/systemd/dwm-setup-cpu-governor.service"
  local unit_dst="/etc/systemd/system/dwm-setup-cpu-governor.service"

  if dry_run; then
    log "[dry-run] instalar helper root $helper_dst (0755)"
    log "[dry-run] instalar sudoers $sudoers_dst (0440) con visudo -cf"
    log "[dry-run] habilitar y arrancar $unit_dst (performance al boot)"
    return 0
  fi

  # Máquinas sin cpufreq: nada que tomar por root.
  if [[ ! -e "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]]; then
    info "cpufreq no disponible; se omite el módulo del gobernador"
    return 0
  fi

  # Helper raíz: valida el gobernador y escribe en todas las CPUs.
  backup_root "$helper_dst"
  run_root install -D -m 0755 "$helper_src" "$helper_dst"

  # Sudoers: fragmento con el usuario real. Se valida con visudo en un
  # archivo provisional (nombre con punto: sudoers.d lo ignora hasta que
  # se mueve a su destino definitivo).
  local tmp pending="/etc/sudoers.d/.dwm-setup-cpu-governor.check"
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-sudoers.XXXXXX")
  sed "s|@USER@|$TARGET_USER|g" "$sudoers_src" >"$tmp"
  run_root install -D -m 0440 "$tmp" "$pending"
  if ! run_root visudo -cf "$pending" >/dev/null 2>&1; then
    run_root rm -f -- "$pending"
    rm -f -- "$tmp"
    die "Fragmento sudoers inválido; no se aplicó nada"
  fi

  backup_root "$sudoers_dst"
  run_root mv -f -- "$pending" "$sudoers_dst"
  rm -f -- "$tmp"
  run_root visudo -cf "$sudoers_dst" >/dev/null 2>&1 ||
    die "sudoers final inválido: $sudoers_dst"
  ok "sudoers del gobernador instalado (NOPASSWD solo para $helper_dst)"

  # Unidad systemd: performance por defecto al arrancar.
  backup_root "$unit_dst"
  run_root install -D -m 0644 "$unit_src" "$unit_dst"
  run_root systemctl daemon-reload
  run_root systemctl enable dwm-setup-cpu-governor.service
  run_root systemctl start dwm-setup-cpu-governor.service
  ok "Unidad dwm-setup-cpu-governor habilitada (performance al boot)"
}
