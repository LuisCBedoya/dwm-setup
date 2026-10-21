#!/usr/bin/env bash
# Instalación de configuraciones de usuario y de sesión.

install_user_configs() {
  section "Configuración del escritorio"
  local home="$TARGET_HOME"
  local theme="${DWM_THEME:-monolith}"
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
  make_user_dir "$home/.config/dwm/eww/scripts"

  # Scripts de sesión
  run_root install -D -m 0755 "$PROJECT_ROOT/templates/dwm/run.sh" "$home/.config/dwm/run.sh"
  render_theme_template "$PROJECT_ROOT/templates/dwm/scripts/bar.sh" "$home/.config/dwm/scripts/bar.sh" 0755 \
    THEME_NAME="$theme"
  # Bar theme para el tema actual
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/scripts/bar_themes/$theme" "$home/.config/dwm/scripts/bar_themes/$theme"
  # También instalar gruvchad como fallback
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/scripts/bar_themes/gruvchad" "$home/.config/dwm/scripts/bar_themes/gruvchad"

  # Picom, Dunst, Rofi (renderizados desde templates .in)
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/picom.conf" "$home/.config/dwm/picom.conf"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/dunst/dunstrc" "$home/.config/dwm/dunst/dunstrc"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/rofi/config.rasi" "$home/.config/dwm/rofi/config.rasi"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/rofi/colors.rasi" "$home/.config/dwm/rofi/colors.rasi"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/rofi/fonts.rasi" "$home/.config/dwm/rofi/fonts.rasi"

  # Eww (config renderizada)
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/eww/eww.yuck" "$home/.config/dwm/eww/eww.yuck"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/eww/vars.yuck" "$home/.config/dwm/eww/vars.yuck"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/eww/widgets.yuck" "$home/.config/dwm/eww/widgets.yuck"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/dwm/eww/eww.scss" "$home/.config/dwm/eww/eww.scss"
  for f in "$PROJECT_ROOT/templates/dwm/eww/scripts"/*; do
    run_root install -D -m 0755 "$f" "$home/.config/dwm/eww/scripts/$(basename "$f")"
  done

  # Environment
  install_template_user 0644 "$PROJECT_ROOT/templates/dwm/environment.in" "$home/.config/dwm/environment" \
    KEYMAP "$DWM_KEYMAP" \
    WALLPAPER "$home/.local/share/wallpapers/rocky.jpg" \
    FONT "$DWM_FONT" \
    FONT_SIZE "$DWM_FONT_SIZE" \
    RESOLUTION "$DWM_RESOLUTION" \
    THEME "$theme"

  # Kitty (config base + tema actual)
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/kitty/kitty.conf" "$home/.config/kitty/kitty.conf"
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/kitty/colorshemes/$theme.conf" "$home/.config/kitty/colorshemes/$theme.conf"
  # Fallback gruvbox
  run_root install -D -m 0644 "$PROJECT_ROOT/templates/kitty/colorshemes/gruvbox-material.conf" "$home/.config/kitty/colorshemes/gruvbox-material.conf"

  # Xinitrc y wallpaper
  install_template_user 0755 "$PROJECT_ROOT/templates/dwm/xinitrc" "$home/.xinitrc"
  run_root install -D -m 0644 "$PROJECT_ROOT/assets/wallpaper.jpg" "$home/.local/share/wallpapers/rocky.jpg"

  # Sesión X11 y binarios
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