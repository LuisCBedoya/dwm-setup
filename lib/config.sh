#!/usr/bin/env bash
# Instalación de configuraciones de usuario y de sesión (fase 1b: bspwm+polybar).

install_user_configs() {
  section "Configuración del escritorio"
  local home="$TARGET_HOME"

  if dry_run; then
    log "[dry-run] instalar ~/.config/{bspwm,sxhkd,polybar,picom,dunst,rofi,kitty}"
    log "[dry-run] instalar ~/.xinitrc, wallpaper y ~/Pictures/Screenshots"
    log "[dry-run] preparar ~/.local/share/xorg (0700) para el log de Xorg sin root"
    log "[dry-run] instalar /usr/local/bin/desktop-safe y desktop-doctor"
    log "[dry-run] corregir propietario de ~/.config, ~/.local y ~/.config-backup"
    return 0
  fi

  # Directorios (make_user_dir crea también los padres como el usuario)
  make_user_dir "$home/.config"
  make_user_dir "$home/.config/bspwm/scripts"
  make_user_dir "$home/.config/bspwm/scripts/i3lock-fancy"
  make_user_dir "$home/.config/sxhkd"
  make_user_dir "$home/.config/polybar/modules"
  make_user_dir "$home/.config/polybar/scripts"
  make_user_dir "$home/.config/picom"
  make_user_dir "$home/.config/dunst"
  make_user_dir "$home/.config/rofi"
  make_user_dir "$home/.config/kitty"
  make_user_dir "$home/.local/share"
  make_user_dir "$home/.local/share/wallpapers"
  make_user_dir "$home/Pictures/Screenshots"
  # Xorg log dir (para startx sin root)
  run_root install -d -m 0700 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$home/.local/share/xorg"

  # Wallpaper
  run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$PROJECT_ROOT/assets/wallpaper.jpg" "$home/.local/share/wallpapers/rocky.jpg"

  # Binarios del sistema
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/desktop-safe" "/usr/local/bin/desktop-safe"
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/desktop-doctor" "/usr/local/bin/desktop-doctor"

  # Restos de la barra anterior: ya no se usan (el backup ya se hizo antes).
  run_root rm -rf "/usr/local/share/fonts/dwm-setup"
  run_root rm -rf "$home/.local/share/fonts/DesktopLogo"
  run_root rm -f "$home/.config/polybar/modules/dots.ini"
  run_user fc-cache -f "$home/.local/share/fonts" >/dev/null 2>&1 || true
  run_root fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true

  # Red de seguridad: todo lo gestionado queda del usuario.
  chown_managed_paths
  run_root chown "$TARGET_USER:$TARGET_GROUP" "$home/.xinitrc" 2>/dev/null || true
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" "$home/Pictures" 2>/dev/null || true

  ok "Configuración instalada para $TARGET_USER"
  info "Para iniciar: ejecuta 'startx' desde TTY (usa ~/.xinitrc → bspwm)"
  info "Binarios: desktop-safe (lock/suspend/logout/poweroff), desktop-doctor (diagnóstico)"
}
