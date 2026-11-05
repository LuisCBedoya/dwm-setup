#!/usr/bin/env bash
# lib/yt-notify.sh — timer de usuario que avisa por dunst si yt-dlp o
# ytwatch están desactualizados. No toca APT ni el módulo `updates` de
# polybar (esa calavera sigue siendo el indicador visual de paquetes).

install_yt_update_notify() {
  if [[ "$INSTALL_YTWATCH" != "yes" ]]; then
    section "Omitiendo avisos de YouTube (--no-ytwatch)"
    return 0
  fi

  if dry_run; then
    section "Avisos de YouTube (timer de usuario)"
    log "[dry-run] instalar /usr/local/bin/yt-update-notify (0755)"
    log "[dry-run] render ~/.config/systemd/user/dwm-setup-yt-update-notify.{service,timer}"
    log "[dry-run] habilitar el timer (symlink en timers.target.wants) y arrancarlo"
    return 0
  fi

  section "Avisos de YouTube (timer de usuario)"
  local home="$TARGET_HOME"
  local unit_dir="$home/.config/systemd/user"

  run_root install -D -m 0755 "$PROJECT_ROOT/bin/yt-update-notify" /usr/local/bin/yt-update-notify

  make_user_dir "$unit_dir"
  install_template_user 0644 \
    "$PROJECT_ROOT/templates/systemd/dwm-setup-yt-update-notify.service" \
    "$unit_dir/dwm-setup-yt-update-notify.service" HOME "$home"
  install_template_user 0644 \
    "$PROJECT_ROOT/templates/systemd/dwm-setup-yt-update-notify.timer" \
    "$unit_dir/dwm-setup-yt-update-notify.timer" HOME "$home"

  # Habilitación a nivel de sistema de archivos: funciona aunque el
  # instalador corra sin sesión gráfica (el timer arranca al primer login).
  run_user mkdir -p "$unit_dir/timers.target.wants"
  run_user ln -sfn ../dwm-setup-yt-update-notify.timer \
    "$unit_dir/timers.target.wants/dwm-setup-yt-update-notify.timer"

  # Si la sesión del usuario está disponible, recargar y arrancar ya.
  if [[ -d "/run/user/$TARGET_UID" ]]; then
    run_user env XDG_RUNTIME_DIR="/run/user/$TARGET_UID" \
      systemctl --user daemon-reload >/dev/null 2>&1 || true
    run_user env XDG_RUNTIME_DIR="/run/user/$TARGET_UID" \
      systemctl --user start dwm-setup-yt-update-notify.timer >/dev/null 2>&1 || true
    info "Timer activo: systemctl --user list-timers · dwm-setup-yt-update-notify"
  else
    info "Timer habilitado; arrancará al iniciar sesión (120 s + 09:00 diario)"
  fi
  ok "Avisos por dunst: yt-dlp / ytwatch (sin tocar APT ni la barra)"
}
