#!/usr/bin/env bash
# lib/gtk.sh — temas GTK Catppuccin, tema derivado Mocha Black e iconos.

GTK_THEME_ROOT="/usr/share/themes"
ICON_THEME_ROOT="/usr/share/icons"

install_gtk_theme() {
  local home="$TARGET_HOME"

  section "Instalando temas GTK e iconos Catppuccin"

  if dry_run; then
    log "[dry-run] copiar catppuccin-mocha-blue y catppuccin-latte-blue a $GTK_THEME_ROOT"
    log "[dry-run] generar catppuccin-mocha-black desde catppuccin-mocha-blue"
    log "[dry-run] crear iconos Catppuccin-Mocha/Catppuccin-Latte en $ICON_THEME_ROOT"
    log "[dry-run] instalar settings GTK2/3/4 con @THEME_GTK@ y @THEME_ICONS@"
    return 0
  fi

  make_user_dir "$home/.config/gtk-3.0"
  make_user_dir "$home/.config/gtk-4.0"

  install_gtk_color_themes
  install_gtk_icon_themes

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

  apply_gtk_gsettings
  ok "Temas GTK e iconos instalados"
}

# Copia los temas vendorizados y genera catppuccin-mocha-black a partir de
# catppuccin-mocha-blue, sustituyendo la rampa de superficies de Mocha por la
# de la paleta mocha-black. Así el tema derivado no se desincroniza.
install_gtk_color_themes() {
  local name src dst

  run_root install -d -m 0755 "$GTK_THEME_ROOT"

  for name in catppuccin-mocha-blue catppuccin-latte-blue; do
    src="$PROJECT_ROOT/templates/themes/$name"
    dst="$GTK_THEME_ROOT/$name"
    backup_root "$dst"
    run_root rm -rf "$dst"
    run_root cp -a "$src" "$dst"
    run_root chown -R root:root "$dst"
    run_root chmod -R a+rX "$dst"
    ok "Tema GTK: $name"
  done

  generate_mocha_black_theme
}

generate_mocha_black_theme() {
  local src="$GTK_THEME_ROOT/catppuccin-mocha-blue"
  local dst="$GTK_THEME_ROOT/catppuccin-mocha-black"
  local values bg bg_deep bg_deepest bg_elev hover border border_alt
  local -a mapping=()
  local pair old new

  values=$(
    PROJECT_ROOT="$PROJECT_ROOT" bash -c '
      # shellcheck source=/dev/null
      source "$PROJECT_ROOT/templates/colors/base.sh"
      # shellcheck source=/dev/null
      source "$PROJECT_ROOT/templates/colors/palette-mocha-black.sh"
      printf "%s %s %s %s %s %s %s\n" \
        "$COLOR_BG" "$COLOR_BG_DEEP" "$COLOR_BG_DEEPEST" "$COLOR_BG_ELEV" \
        "$COLOR_BG_HOVER" "$COLOR_BORDER_ALT"
    ' 2>/dev/null
  )

  read -r bg bg_deep bg_deepest bg_elev hover border_alt <<<"$values"
  if [[ -z "$bg" || -z "$border_alt" ]]; then
    error "No se pudieron leer los colores de palette-mocha-black.sh"
    return 1
  fi

  # Mocha estándar -> Mocha Black
  mapping=(
    "#1e1e2e:$bg"
    "#181825:$bg_deep"
    "#11111b:$bg_deepest"
    "#313244:$bg_elev"
    "#45475a:$hover"
    "#585b70:$border_alt"
  )

  backup_root "$dst"
  run_root rm -rf "$dst"
  run_root cp -a "$src" "$dst"

  run_root bash -c '
    set -Eeuo pipefail
    dst="$1"
    shift
    for pair in "$@"; do
      old="${pair%%:*}"
      new="${pair#*:}"
      find "$dst" -type f \( -name "*.css" -o -name "*.svg" \) -print0 |
        xargs -0 -r sed -i "s/${old}/${new}/g"
    done
  ' _ "$dst" "${mapping[@]}" || die "No se pudo generar catppuccin-mocha-black"

  run_root sed -i 's/^Name=.*/Name=catppuccin-mocha-black/' "$dst/index.theme"
  run_root sed -i 's/^GtkTheme=.*/GtkTheme=catppuccin-mocha-black/' "$dst/index.theme"
  run_root chown -R root:root "$dst"
  run_root chmod -R a+rX "$dst"
  ok "Tema GTK: catppuccin-mocha-black (derivado)"
}

# Crea dos temas de iconos superpuestos sobre Papirus. Papirus-Dark y
# Papirus-Light comparten los directorios de places (symlinks a Papirus), así
# que el color de carpeta no se puede aplicar por separado: cada modo tiene su
# propio tema con solo los places de carpetas.
install_gtk_icon_themes() {
  run_root install -d -m 0755 "$ICON_THEME_ROOT"
  build_icon_theme "Catppuccin-Mocha" "Papirus-Dark" "cat-mocha-blue"
  build_icon_theme "Catppuccin-Latte" "Papirus-Light" "cat-latte-blue"
}

build_icon_theme() {
  local name="$1" base="$2" color="$3"
  local dst="$ICON_THEME_ROOT/$name"
  local src="$PROJECT_ROOT/templates/icons/folders/$color"
  local base_index="$ICON_THEME_ROOT/$base/index.theme"
  local tmp

  [[ -d "$src" ]] || die "Faltan los iconos vendorizados: $src"
  [[ -f "$base_index" ]] || die "Falta el tema base de iconos: $base_index"

  backup_root "$dst"
  run_root rm -rf "$dst"
  run_root install -d -m 0755 "$dst"
  run_root cp -a "$src"/. "$dst"/

  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-index.XXXXXX")
  sed -e "s/^Name=.*/Name=$name/" \
      -e "s/^Inherits=.*/Inherits=$base/" \
      -e "s|^Directories=.*|Directories=22x22/places,24x24/places,32x32/places,48x48/places,64x64/places|" \
      -e "s|^ScaledDirectories=.*|ScaledDirectories=|" \
      "$base_index" >"$tmp"
  run_root install -D -m 0644 "$tmp" "$dst/index.theme"
  rm -f -- "$tmp"

  # papirus-folders crea los symlinks folder*.svg -> folder-<color>*.svg
  run_root env USER_HOME="$TARGET_HOME" \
    XDG_DATA_DIRS="/usr/local/share:/usr/share" \
    "$PROJECT_ROOT/templates/icons/papirus-folders" \
    -o -C "$color" -t "$name" >/dev/null 2>&1 ||
    die "papirus-folders falló para $name"

  run_root gtk-update-icon-cache -f -t "$dst" >/dev/null 2>&1 || true
  run_root chown -R root:root "$dst"
  run_root chmod -R a+rX "$dst"
  ok "Iconos: $name ($color)"
}

apply_gtk_gsettings() {
  run_user gsettings set org.gnome.desktop.interface gtk-theme "$THEME_GTK" 2>/dev/null || true
  run_user gsettings set org.gnome.desktop.interface icon-theme "$THEME_ICONS" 2>/dev/null || true
  run_user gsettings set org.gnome.desktop.interface color-scheme "${THEME_COLOR_SCHEME:-default}" 2>/dev/null || true
}
