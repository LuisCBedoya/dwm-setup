#!/usr/bin/env bash
# Instalación de configuraciones de usuario y de sesión (fase 1b: bspwm+polybar).

install_user_configs() {
  section "Configuración del escritorio"
  local home="$TARGET_HOME"
  local theme="nord"
  
  if dry_run; then
    log "[dry-run] backup en $USER_BACKUP_DIR"
    log "[dry-run] instalar ~/.config/{bspwm,sxhkd,polybar,picom,dunst,rofi,kitty}"
    log "[dry-run] instalar ~/.xinitrc y wallpaper"
    log "[dry-run] preparar ~/.local/share/xorg (0700) para el log de Xorg sin root"
    log "[dry-run] instalar /usr/local/bin/desktop-safe y desktop-doctor"
    return 0
  fi

  # Backups
  backup_root "/usr/local/bin/desktop-safe"
  backup_root "/usr/local/bin/desktop-doctor"
  backup_user_path "$home/.config/bspwm"
  backup_user_path "$home/.config/sxhkd"
  backup_user_path "$home/.config/polybar"
  backup_user_path "$home/.config/picom"
  backup_user_path "$home/.config/dunst"
  backup_user_path "$home/.config/rofi"
  backup_user_path "$home/.config/kitty"
  backup_user_path "$home/.xinitrc"
  backup_user_path "$home/.local/share/wallpapers/rocky.jpg"

  # Directorios
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
  # Xorg log dir (para startx sin root)
  run_root install -d -m 0700 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$home/.local/share/xorg"

  # Wallpaper
  run_root install -D -m 0644 "$PROJECT_ROOT/assets/wallpaper.jpg" "$home/.local/share/wallpapers/rocky.jpg"

  # Binarios
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/desktop-safe" "/usr/local/bin/desktop-safe"
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/desktop-doctor" "/usr/local/bin/desktop-doctor"

  # Las configs (bspwm, sxhkd, polybar, picom, dunst, rofi, kitty) ya se instalaron
  # en sus respectivos módulos (install_bspwm, install_sxhkd, etc.)
  # Aquí solo nos aseguramos de ownership
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" \
    "$home/.config/bspwm" "$home/.config/sxhkd" "$home/.config/polybar" \
    "$home/.config/picom" "$home/.config/dunst" "$home/.config/rofi" \
    "$home/.config/kitty" "$home/.local/share/wallpapers" "$home/.xinitrc" \
    "$home/.local/share/xorg" 2>/dev/null || true
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" \
    "$USER_BACKUP_DIR" 2>/dev/null || true

  ok "Configuración instalada para $TARGET_USER"
  info "Para iniciar: ejecuta 'startx' desde TTY (usa ~/.xinitrc → bspwm)"
  info "Binarios: desktop-safe (lock/suspend/logout/poweroff), desktop-doctor (diagnóstico)"
}