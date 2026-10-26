#!/usr/bin/env bash
# lib/gtk.sh — tema GTK Windows-10-Dark e iconos Papirus

install_gtk_theme() {
  local home="$TARGET_HOME"

  section "Instalando tema GTK e iconos"

  if dry_run; then
    log "[dry-run] copiar Windows-10-Dark a $home/.themes/Windows-10-Dark"
    log "[dry-run] instalar settings GTK2/3/4 con Papirus y CSS Mono Slate"
    return 0
  fi

  make_user_dir "$home/.themes"
  make_user_dir "$home/.config/gtk-3.0"
  make_user_dir "$home/.config/gtk-4.0"

  run_root rm -rf "$home/.themes/Windows-10-Dark"
  run_root cp -a "$PROJECT_ROOT/templates/themes/Windows-10-Dark" "$home/.themes/"
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" "$home/.themes/Windows-10-Dark"

  render_theme_template "$PROJECT_ROOT/templates/gtk/gtk-3.0.settings.ini.in" \
    "$home/.config/gtk-3.0/settings.ini" 0644
  render_theme_template "$PROJECT_ROOT/templates/gtk/gtk-4.0.settings.ini.in" \
    "$home/.config/gtk-4.0/settings.ini" 0644
  render_theme_template "$PROJECT_ROOT/templates/gtk/gtkrc-2.0.in" \
    "$home/.gtkrc-2.0" 0644
  render_theme_template "$PROJECT_ROOT/templates/gtk/gtk-3.0.css.in" \
    "$home/.config/gtk-3.0/gtk.css" 0644
  render_theme_template "$PROJECT_ROOT/templates/gtk/gtk-4.0.css.in" \
    "$home/.config/gtk-4.0/gtk.css" 0644

  ok "Tema GTK y Papirus instalados"
}
