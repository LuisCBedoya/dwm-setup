#!/usr/bin/env bash
# Instalación de configuraciones de usuario y de sesión.

install_user_configs() {
  section "Configuración del escritorio"
  local home="$TARGET_HOME"
  if dry_run; then
    log "[dry-run] backup en $USER_BACKUP_DIR"
    log "[dry-run] instalar ~/.config/dwm, ~/.config/kitty, ~/.xinitrc y wallpaper"
    log "[dry-run] preparar ~/.local/share/xorg (0700) para el log de Xorg sin root"
    log "[dry-run] instalar /usr/share/xsessions/dwm.desktop"
    log "[dry-run] instalar /usr/local/bin/dwm-safe y dwm-doctor"
    return 0
  fi

  backup_root "/usr/share/xsessions/dwm.desktop"
  backup_root "/usr/local/bin/dwm-safe"
  backup_root "/usr/local/bin/dwm-doctor"
  backup_user_path "$home/.config/dwm"
  backup_user_path "$home/.config/kitty"
  backup_user_path "$home/.xinitrc"
  backup_user_path "$home/.local/share/wallpapers/rocky.jpg"

  make_user_dir "$home/.config/dwm"
  make_user_dir "$home/.config/dwm/scripts/bar_themes"
  make_user_dir "$home/.config/dwm/dunst"
  make_user_dir "$home/.config/dwm/rofi"
  make_user_dir "$home/.config/kitty/colorshemes"
  make_user_dir "$home/.local/share"
  make_user_dir "$home/.local/share/wallpapers"
  # Xorg lanzado por Ly corre como el usuario y escribe aquí su log.
  # Sin este directorio, Xorg aborta con "Cannot open log file".
  run_root install -d -m 0700 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$home/.local/share/xorg"

  # Reemplazar solo las piezas que gestiona el instalador.
  run_root rm -rf "$home/.config/dwm/scripts" "$home/.config/dwm/dunst" \
    "$home/.config/dwm/rofi" "$home/.config/dwm/eww"
  make_user_dir "$home/.config/dwm/scripts/bar_themes"
  make_user_dir "$home/.config/dwm/dunst"
  make_user_dir "$home/.config/dwm/rofi"

  run_root install -D -m 0755 "$PROJECT_ROOT/templates/dwm/run.sh" "$home/.config/dwm/run.sh"
  run_root install -D -m 0755 "$PROJECT_ROOT/templates/dwm/scripts/bar.sh" "$home/.config/dwm/scripts/bar.sh"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/scripts/bar_themes/gruvchad" "$home/.config/dwm/scripts/bar_themes/gruvchad"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/picom.conf" "$home/.config/dwm/picom.conf"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/dunst/dunstrc" "$home/.config/dwm/dunst/dunstrc"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/rofi/gruvbox.rasi" "$home/.config/dwm/rofi/gruvbox.rasi"

  run_root cp -a "$PROJECT_ROOT/templates/dwm/eww" "$home/.config/dwm/eww"
  run_root chmod 0755 "$home/.config/dwm/eww/scripts/"* 2>/dev/null || true

  install_template_user 0644 "$PROJECT_ROOT/templates/dwm/environment.in" "$home/.config/dwm/environment" \
    KEYMAP "$DWM_KEYMAP" \
    WALLPAPER "$home/.local/share/wallpapers/rocky.jpg" \
    FONT "$DWM_FONT" \
    FONT_SIZE "$DWM_FONT_SIZE" \
    RESOLUTION "$DWM_RESOLUTION"

  run_root install -D -m 0644 "$PROJECT_ROOT/templates/kitty/kitty.conf" "$home/.config/kitty/kitty.conf"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/kitty/colorshemes/gruvbox-material.conf" \
    "$home/.config/kitty/colorshemes/gruvbox-material.conf"
  install_template_user 0755 "$PROJECT_ROOT/templates/dwm/xinitrc" "$home/.xinitrc"
  run_root install -D -m 0644 "$PROJECT_ROOT/assets/wallpaper.jpg" "$home/.local/share/wallpapers/rocky.jpg"

  install_template_root 0644 "$PROJECT_ROOT/templates/dwm/dwm.desktop.in" "/usr/share/xsessions/dwm.desktop" \
    HOME "$home"
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/dwm-safe" "/usr/local/bin/dwm-safe"
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/dwm-doctor" "/usr/local/bin/dwm-doctor"

  run_root chown -R "$TARGET_USER:$TARGET_GROUP" \
    "$home/.config/dwm" "$home/.config/kitty" "$home/.local/share/wallpapers" "$home/.xinitrc"
  # Defensa en profundidad: asegurar ownership de directorios que se crean/copian como root
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" \
    "$home/.local/share/xorg" 2>/dev/null || true
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" \
    "$USER_BACKUP_DIR" 2>/dev/null || true
  run_root chmod 0755 "$home/.config/dwm/run.sh" "$home/.config/dwm/scripts/bar.sh"

  ok "Configuración instalada para $TARGET_USER"
  info "Sesión X11: /usr/share/xsessions/dwm.desktop"
  info "Fallback manual: startx (usa ~/.xinitrc)"
}
