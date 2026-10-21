#!/usr/bin/env bash
# lib/theme.sh — Carga y gestión de paletas de colores (fase 1b: Nord)

# Paletas disponibles (archivos en templates/colors/palette-<name>.sh)
declare -A AVAILABLE_THEMES=(
  ["nord"]="Nord (vendorizado desde repo Bspwm)"
)

# Tema por defecto
DEFAULT_THEME="nord"

# Tema seleccionado (se establece con load_theme)
THEME_NAME=""
THEME_FILE=""

# Carga una paleta por nombre
# Uso: load_theme "nord"
load_theme() {
  local name="${1:-$DEFAULT_THEME}"
  local palette_file="$PROJECT_ROOT/templates/colors/palette-${name}.sh"

  if [[ ! -f "$palette_file" ]]; then
    die "Tema '$name' no encontrado: $palette_file"
  fi

  # Cargar base primero (define helpers y validate_palette)
  # shellcheck source=/dev/null
  source "$PROJECT_ROOT/templates/colors/base.sh"

  # Cargar paleta (exporta COLOR_* y valida)
  # shellcheck source=/dev/null
  source "$palette_file"

  # Exportar helpers RGBA ahora que las variables COLOR_* están definidas
  export_rgba_helpers

  THEME_NAME="$name"
  THEME_FILE="$palette_file"

  debug "Tema cargado: $name ($palette_file)"
}

# Lista temas disponibles
list_themes() {
  local name desc
  for name in "${!AVAILABLE_THEMES[@]}"; do
    desc="${AVAILABLE_THEMES[$name]}"
    if [[ "$name" == "$DEFAULT_THEME" ]]; then
      printf "  %s (default) — %s\n" "$name" "$desc"
    else
      printf "  %s — %s\n" "$name" "$desc"
    fi
  done
}

# Obtiene el valor de una variable de color
# Uso: theme_var COLOR_ACCENT
theme_var() {
  local var="$1"
  local val="${!var}"
  if [[ -z "$val" ]]; then
    warn "Color $var no definido en tema '$THEME_NAME', usando fallback"
    case "$var" in
      COLOR_BG) val="#2e3440" ;;
      COLOR_BG_ALT) val="#3b4252" ;;
      COLOR_BG_ELEV) val="#434c5e" ;;
      COLOR_BG_HOVER) val="#4c566a" ;;
      COLOR_FG) val="#d8dee9" ;;
      COLOR_FG_MUTED) val="#4c566a" ;;
      COLOR_FG_DIM) val="#434c5e" ;;
      COLOR_BORDER) val="#434c5e" ;;
      COLOR_ACCENT) val="#8fbcbb" ;;
      COLOR_ACCENT_ALT) val="#88c0d0" ;;
      COLOR_GREEN) val="#a3be8c" ;;
      COLOR_YELLOW) val="#ebcb8b" ;;
      COLOR_ORANGE) val="#d08770" ;;
      COLOR_RED) val="#bf616a" ;;
      COLOR_CYAN) val="#88c0d0" ;;
      COLOR_PURPLE) val="#b48ead" ;;
      COLOR_BLUE) val="#81a1c1" ;;
      *) val="#ff00ff" ;;
    esac
  fi
  printf '%s' "$val"
}

# Renderiza un template reemplazando @COLOR_VAR@ y @VAR@ por su valor
# Uso: render_theme_template "input.in" "output" [perms] [HOME=... FONT=... FONT_SIZE=... KEYMAP=... WALLPAPER=... RESOLUTION=...]
render_theme_template() {
  local input="$1"
  local output="$2"
  local perms="${3:-0644}"
  shift 3 || true

  if dry_run; then
    log "[dry-run] render_theme_template $input -> $output"
    return 0
  fi

  [[ -f "$input" ]] || die "Template no encontrado: $input"

  local content
  content=$(cat "$input")

  # Reemplazar todos los @COLOR_*@
  local var
  for var in COLOR_BG COLOR_BG_ALT COLOR_BG_ELEV COLOR_BG_HOVER \
             COLOR_FG COLOR_FG_MUTED COLOR_FG_DIM \
             COLOR_BORDER COLOR_ACCENT COLOR_ACCENT_ALT \
             COLOR_GREEN COLOR_YELLOW COLOR_ORANGE COLOR_RED COLOR_CYAN \
             COLOR_PURPLE COLOR_BLUE \
             COLOR_BG_RGBA_92 COLOR_BG_ALT_RGBA_92 COLOR_BG_ELEV_RGBA_92 \
             COLOR_BG_ELEV_RGBA_85 COLOR_ACCENT_RGBA_30 COLOR_BORDER_RGBA_50; do
    local val
    val=$(theme_var "$var")
    content="${content//@${var}@/$val}"
  done

  # También reemplazar @THEME_NAME@
  content="${content//@THEME_NAME@/$THEME_NAME}"

  # Reemplazar variables de entorno/plantilla extra
  local extra_var extra_val
  for arg in "$@"; do
    extra_var="${arg%%=*}"
    extra_val="${arg#*=}"
    content="${content//@${extra_var}@/$extra_val}"
  done

  run_root install -D -m "$perms" /dev/stdin "$output" <<<"$content"
  ok "Renderizado: $output"
}

# Genera colors.rasi para rofi
generate_rofi_colors() {
  local theme="${1:-$THEME_NAME}"
  local output="$PROJECT_ROOT/templates/rofi/colors.rasi"

  if dry_run; then
    log "[dry-run] generate_rofi_colors $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  cat >"$output" <<EOF
/* Rofi colors: $theme (generado automáticamente) */
/* No editar directamente; modificar templates/colors/palette-${theme}.sh */

* {
    /* Colores base */
    background:     ${COLOR_BG_ELEV};
    foreground:     ${COLOR_FG};
    selected:       ${COLOR_BG_HOVER};
    accent:         ${COLOR_ACCENT};
    border:         ${COLOR_BORDER};

    /* Estados */
    urgent:         ${COLOR_RED};
    active:         ${COLOR_ACCENT};
    normal:         ${COLOR_FG_MUTED};

    /* Transparencias */
    background-alpha: 0.95;
}
EOF

  ok "Rofi colors generado: $output"
}

# Genera dunstrc para dunst
generate_dunstrc() {
  local theme="${1:-$THEME_NAME}"
  local output="$PROJECT_ROOT/templates/dunst/dunstrc"

  if dry_run; then
    log "[dry-run] generate_dunstrc $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  render_theme_template "$PROJECT_ROOT/templates/dunst/dunstrc.in" "$output" 0644
}

# Genera picom.conf
generate_picom_conf() {
  local theme="${1:-$THEME_NAME}"
  local output="$PROJECT_ROOT/templates/picom/picom.conf"

  if dry_run; then
    log "[dry-run] generate_picom_conf $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  render_theme_template "$PROJECT_ROOT/templates/picom/picom.conf.in" "$output" 0644
}

# Genera kitty theme
generate_kitty_theme() {
  local theme="${1:-$THEME_NAME}"
  local output="$PROJECT_ROOT/templates/kitty/colorshemes/${theme}.conf"

  if dry_run; then
    log "[dry-run] generate_kitty_theme $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  run_root install -d -m 0755 "$(dirname "$output")"

  cat >"$output" <<EOF
# Kitty theme: $theme (generado automáticamente)
# No editar directamente; modificar templates/colors/palette-${theme}.sh

background ${COLOR_BG}
foreground ${COLOR_FG}
cursor     ${COLOR_ACCENT}
selection_foreground ${COLOR_BG}
selection_background ${COLOR_ACCENT}

# Black
color0 ${COLOR_BG_ELEV}
color8 ${COLOR_FG_DIM}

# Red
color1 ${COLOR_RED}
color9 ${COLOR_RED}

# Green
color2 ${COLOR_GREEN}
color10 ${COLOR_GREEN}

# Yellow
color3 ${COLOR_YELLOW}
color11 ${COLOR_YELLOW}

# Blue
color4 ${COLOR_BLUE}
color12 ${COLOR_BLUE}

# Magenta
color5 ${COLOR_PURPLE}
color13 ${COLOR_PURPLE}

# Cyan
color6 ${COLOR_CYAN}
color14 ${COLOR_CYAN}

# White
color7 ${COLOR_FG}
color15 #ffffff

# Colores extendidos (kitty 0.26+)
cursor_text_color ${COLOR_BG}
url_color ${COLOR_ACCENT_ALT}
EOF

  ok "Kitty theme generado: $output"
}

# Genera TODO lo necesario para el stack bspwm+polybar
generate_all_desktop_assets() {
  local theme="${1:-$THEME_NAME}"
  section "Generando assets para tema: $theme"

  generate_rofi_colors "$theme"
  generate_dunstrc "$theme"
  generate_picom_conf "$theme"
  generate_kitty_theme "$theme"

  ok "Assets de tema generados"
}