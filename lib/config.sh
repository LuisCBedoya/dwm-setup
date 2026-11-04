#!/usr/bin/env bash
# Instalación de configuraciones de usuario y de sesión (fase 1b: bspwm+polybar).

install_user_configs() {
  section "Configuración del escritorio"
  local home="$TARGET_HOME"

  if dry_run; then
    log "[dry-run] instalar ~/.config/{bspwm,sxhkd,polybar,dunst,rofi,kitty}"
    log "[dry-run] instalar ~/.xinitrc, wallpaper y ~/Pictures/Screenshots"
    log "[dry-run] preparar ~/.local/share/xorg (0700) para el log de Xorg sin root"
    log "[dry-run] instalar /usr/local/bin/desktop-safe, desktop-doctor y theme-mode"
    log "[dry-run] instalar plantillas y paletas en ~/.local/share/dwm-setup"
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
  make_user_dir "$home/.config/dunst"
  make_user_dir "$home/.config/rofi"
  make_user_dir "$home/.config/kitty"
  make_user_dir "$home/.local/share"
  make_user_dir "$home/.local/share/wallpapers"
  make_user_dir "$home/Pictures/Screenshots"
  # Xorg log dir (para startx sin root)
  run_root install -d -m 0700 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$home/.local/share/xorg"

  # Wallpaper principal y alternativo
  run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$PROJECT_ROOT/assets/wallpaper.png" "$home/.local/share/wallpapers/wallpaper.png"
  run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$PROJECT_ROOT/assets/wallpaper-alt.png" "$home/.local/share/wallpapers/wallpaper-alt.png"

  # Binarios del sistema
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/desktop-safe" "/usr/local/bin/desktop-safe"
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/desktop-doctor" "/usr/local/bin/desktop-doctor"
  run_root install -D -m 0755 "$PROJECT_ROOT/bin/theme-mode" "/usr/local/bin/theme-mode"

  # Plantillas y paletas para theme-mode (cambio de modo sin sudo)
  install_theme_store

  # Restos de la barra anterior: ya no se usan (el backup ya se hizo antes).
  run_root rm -rf "/usr/local/share/fonts/dwm-setup"
  run_root rm -rf "$home/.local/share/fonts/DesktopLogo"
  run_user fc-cache -f "$home/.local/share/fonts" >/dev/null 2>&1 || true
  run_root fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true

  # Red de seguridad: todo lo gestionado queda del usuario.
  chown_managed_paths
  run_root chown "$TARGET_USER:$TARGET_GROUP" "$home/.xinitrc" 2>/dev/null || true
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" "$home/Pictures" 2>/dev/null || true

  ok "Configuración instalada para $TARGET_USER"
  info "Para iniciar: ejecuta 'startx' desde TTY (usa ~/.xinitrc → bspwm)"
  info "Binarios: desktop-safe, desktop-doctor y theme-mode dark|light|toggle|status"
}

# Escribe un archivo del usuario desde una cadena.
write_user_file() {
  local content="$1" dst="$2" perms="${3:-0644}"
  local tmp

  if dry_run; then
    log "[dry-run] escribir $dst"
    return 0
  fi

  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-write.XXXXXX")
  printf '%s\n' "$content" >"$tmp"
  run_root install -D -m "$perms" -o "$TARGET_USER" -g "$TARGET_GROUP" "$tmp" "$dst"
  rm -f -- "$tmp"
}

# Instala en ~/.local/share/dwm-setup lo que necesita theme-mode para
# re-renderizar sin acceso al repo ni a sudo.
install_theme_store() {
  local home="$TARGET_HOME"
  local store="$home/.local/share/dwm-setup"
  local rel profile
  local -a template_files=(
    "templates/polybar/config.ini.in"
    "templates/polybar/variants/reference/config.ini.in"
    "templates/polybar/scripts/cpu-governor.sh.in"
    "templates/kitty/kitty.conf.in"
    "templates/kitty/colorshemes/monochromatic.conf.in"
    "templates/dunst/dunstrc.in"
    "templates/rofi/config.rasi.in"
    "templates/rofi/powermenu.rasi.in"
    "templates/zathura/zathurarc.in"
    "templates/bspwm/bspwmrc.in"
    "templates/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh.in"
    "templates/gtk/gtk-3.0.settings.ini.in"
    "templates/gtk/gtk-3.0.css.in"
    "templates/gtk/gtk-4.0.settings.ini.in"
    "templates/gtk/gtk-4.0.css.in"
    "templates/gtk/gtkrc-2.0.in"
    "templates/vlc/vlcrc.in"
    "templates/firefox/userChrome.css.in"
    "templates/firefox/user.js.in"
  )

  make_user_dir "$store"
  make_user_dir "$store/colors"
  make_user_dir "$store/templates"

  for rel in "${template_files[@]}"; do
    run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
      "$PROJECT_ROOT/$rel" "$store/$rel"
  done

  for rel in base.sh palette-mocha-black.sh palette-latte.sh; do
    run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
      "$PROJECT_ROOT/templates/colors/$rel" "$store/colors/$rel"
  done

  profile=$(detect_firefox_profile "$home" 2>/dev/null || true)

  local mode="dark" tmp
  [[ "$THEME_NAME" == "latte" ]] && mode="light"

  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-render-env.XXXXXX")
  {
    polybar_common_vars
    printf 'FIREFOX_PROFILE=%s\n' "$profile"
  } >"$tmp"
  run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$tmp" "$store/render.env"
  rm -f -- "$tmp"

  make_user_dir "$home/.config/dwm-setup"
  write_user_file "$mode" "$home/.config/dwm-setup/mode" 0644
  write_user_file "$(
    printf 'GTK_THEME=%s\n' "$THEME_GTK"
    printf 'ICON_THEME=%s\n' "$THEME_ICONS"
    printf 'MODE=%s\n' "$mode"
    printf 'THEME=%s\n' "$THEME_NAME"
  )" "$home/.config/dwm-setup/gtk.env" 0644

  run_root chown -R "$TARGET_USER:$TARGET_GROUP" "$store"
  ok "theme-mode: plantillas y paletas en $store"
}
