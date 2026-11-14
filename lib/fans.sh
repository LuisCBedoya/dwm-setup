#!/usr/bin/env bash
# lib/fans.sh — modo del ventilador: helper root y sudoers acotado.
#
# El módulo polybar "fan" se instala siempre y se oculta con `exec-if`
# cuando el equipo no expone ningún backend. Solo entonces no se escribe
# sudoers (el helper existiría pero no puede hacer nada).

install_fan_control() {
  section "Modo del ventilador"

  local helper_src="$PROJECT_ROOT/bin/dwm-setup-fan-mode"
  local helper_dst="/usr/local/bin/dwm-setup-fan-mode"
  local sudoers_src="$PROJECT_ROOT/templates/sudoers/dwm-setup-fan-mode.in"
  local sudoers_dst="/etc/sudoers.d/dwm-setup-fan-mode"
  local asus_dir=/sys/devices/platform/asus-nb-wmi

  if dry_run; then
    log "[dry-run] instalar helper root $helper_dst (0755)"
    log "[dry-run] sudoers $sudoers_dst (NOPASSWD) solo si hay backend de ventilador"
    return 0
  fi

  backup_root "$helper_dst"
  run_root install -D -m 0755 "$helper_src" "$helper_dst"

  # Daemon del ventilador automático y estado por defecto (auto).
  make_user_dir "$TARGET_HOME/.local/bin"
  make_user_dir "$TARGET_HOME/.config/dwm-setup"
  run_user install -m 0755 "$PROJECT_ROOT/bin/dwm-setup-fan-auto" \
    "$TARGET_HOME/.local/bin/dwm-setup-fan-auto"
  if [[ ! -f "$TARGET_HOME/.config/dwm-setup/fan-mode" ]]; then
    printf 'auto\n' | run_user tee "$TARGET_HOME/.config/dwm-setup/fan-mode" >/dev/null
  fi

  if [[ ! -e "$asus_dir/fan_boost_mode" &&
        ! -e "$asus_dir/throttle_thermal_policy" ]] &&
     [[ ! -r /sys/firmware/acpi/platform_profile ||
        ! -r /sys/firmware/acpi/platform_profile_choices ]]; then
    info "Sin control de ventilador en este equipo; el módulo de la barra queda oculto"
    return 0
  fi

  local tmp pending="/etc/sudoers.d/.dwm-setup-fan-mode.check"
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-sudoers-fan.XXXXXX")
  sed "s|@USER@|$TARGET_USER|g" "$sudoers_src" >"$tmp"
  run_root install -D -m 0440 "$tmp" "$pending"
  if ! run_root visudo -cf "$pending" >/dev/null 2>&1; then
    run_root rm -f -- "$pending"
    rm -f -- "$tmp"
    die "Fragmento sudoers del ventilador inválido; no se aplicó nada"
  fi

  backup_root "$sudoers_dst"
  run_root mv -f -- "$pending" "$sudoers_dst"
  rm -f -- "$tmp"
  run_root visudo -cf "$sudoers_dst" >/dev/null 2>&1 ||
    die "sudoers final del ventilador inválido: $sudoers_dst"

  ok "Ventilador: modos disponibles con clic en la barra"
}
