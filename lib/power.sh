#!/usr/bin/env bash
# lib/power.sh — límite de carga de la batería (umbral del EC vía sysfs).

DWM_BATTERY_THRESHOLD="${DWM_BATTERY_THRESHOLD:-80}"

install_battery_threshold() {
  section "Límite de carga de la batería"

  if dry_run; then
    log "[dry-run] instalar /usr/local/bin/dwm-setup-battery-limit"
    log "[dry-run] habilitar battery-charge-threshold.service (${DWM_BATTERY_THRESHOLD}%) si el hardware lo soporta"
    return 0
  fi

  local file supported=0
  for file in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
    [[ -e "$file" ]] && supported=1
  done
  if ((supported == 0)); then
    info "Este equipo no expone charge_control_end_threshold; se omite el límite de carga"
    return 0
  fi

  run_root install -D -m 0755 "$PROJECT_ROOT/bin/dwm-setup-battery-limit" \
    /usr/local/bin/dwm-setup-battery-limit

  render_theme_template \
    "$PROJECT_ROOT/templates/systemd/battery-charge-threshold.service.in" \
    /etc/systemd/system/battery-charge-threshold.service 0644 \
    "THRESHOLD=$DWM_BATTERY_THRESHOLD"

  run_root systemctl daemon-reload >/dev/null 2>&1 || true
  if run_root systemctl enable --now battery-charge-threshold.service >/dev/null 2>&1; then
    ok "Batería: carga limitada al ${DWM_BATTERY_THRESHOLD}%"
  else
    warn "No se pudo activar el límite de carga; se reintentará en el próximo arranque"
  fi
}

# Perfil de energía automático: performance con cargador, powersave+1.2 GHz
# con batería. Helper root con sudoers acotado + daemon de usuario.
install_power_profile() {
  section "Perfil de energía automático"

  local helper_src="$PROJECT_ROOT/bin/dwm-setup-power-profile"
  local helper_dst="/usr/local/bin/dwm-setup-power-profile"
  local sudoers_src="$PROJECT_ROOT/templates/sudoers/dwm-setup-power-profile.in"
  local sudoers_dst="/etc/sudoers.d/dwm-setup-power-profile"

  if dry_run; then
    log "[dry-run] instalar helper root $helper_dst (0755)"
    log "[dry-run] sudoers $sudoers_dst (NOPASSWD, visudo -cf)"
    log "[dry-run] instalar ~/.local/bin/dwm-setup-power-auto (usuario)"
    return 0
  fi

  if [[ ! -e "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]]; then
    info "cpufreq no disponible; se omite el perfil de energía"
    return 0
  fi

  backup_root "$helper_dst"
  run_root install -D -m 0755 "$helper_src" "$helper_dst"

  local tmp pending="/etc/sudoers.d/.dwm-setup-power-profile.check"
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-sudoers-power.XXXXXX")
  sed "s|@USER@|$TARGET_USER|g" "$sudoers_src" >"$tmp"
  run_root install -D -m 0440 "$tmp" "$pending"
  if ! run_root visudo -cf "$pending" >/dev/null 2>&1; then
    run_root rm -f -- "$pending"
    rm -f -- "$tmp"
    die "Fragmento sudoers del perfil de energía inválido"
  fi
  backup_root "$sudoers_dst"
  run_root mv -f -- "$pending" "$sudoers_dst"
  rm -f -- "$tmp"
  run_root visudo -cf "$sudoers_dst" >/dev/null 2>&1 ||
    die "sudoers final del perfil de energía inválido: $sudoers_dst"

  make_user_dir "$TARGET_HOME/.local/bin"
  run_user install -m 0755 "$PROJECT_ROOT/bin/dwm-setup-power-auto" \
    "$TARGET_HOME/.local/bin/dwm-setup-power-auto"
  ok "Energía: performance en AC y powersave+1.2 GHz en batería"
}
