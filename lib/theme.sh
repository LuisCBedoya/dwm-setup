#!/usr/bin/env bash
# lib/theme.sh — Carga y gestión de paletas de colores

# Paletas disponibles (archivos en templates/colors/palette-<name>.sh)
declare -A AVAILABLE_THEMES=(
  ["monolith"]="Monolith (monocromática con acentos apagados)"
  ["gruvbox"]="Gruvbox Material"
)

# Tema por defecto
DEFAULT_THEME="monolith"

# Tema seleccionado (se establece con load_theme)
THEME_NAME=""
THEME_FILE=""

# Carga una paleta por nombre
# Uso: load_theme "monolith"
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

# Obtiene el valor de una variable de color (con fallback a monolith)
# Uso: theme_var COLOR_ACCENT
theme_var() {
  local var="$1"
  local val="${!var}"
  if [[ -z "$val" ]]; then
    warn "Color $var no definido en tema '$THEME_NAME', usando fallback"
    # Fallback hardcoded a monolith
    case "$var" in
      COLOR_BG) val="#0d0d0f" ;;
      COLOR_BG_ALT) val="#151518" ;;
      COLOR_BG_ELEV) val="#1d1d22" ;;
      COLOR_BG_HOVER) val="#26262c" ;;
      COLOR_FG) val="#d8d4cc" ;;
      COLOR_FG_MUTED) val="#8a8a92" ;;
      COLOR_FG_DIM) val="#5c5c64" ;;
      COLOR_BORDER) val="#2b2b32" ;;
      COLOR_ACCENT) val="#b4a7d6" ;;
      COLOR_ACCENT_ALT) val="#8fa8c8" ;;
      COLOR_GREEN) val="#9eb88a" ;;
      COLOR_YELLOW) val="#d8c08a" ;;
      COLOR_ORANGE) val="#d09a72" ;;
      COLOR_RED) val="#c97f7f" ;;
      COLOR_CYAN) val="#8fbfc7" ;;
      *) val="#ff00ff" ;; # magenta evidente si falta
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

# Genera bar_theme para status2d
# Uso: generate_bar_theme "monolith"
generate_bar_theme() {
  local theme="${1:-$THEME_NAME}"
  local output_dir="$PROJECT_ROOT/templates/dwm/scripts/bar_themes"
  local output_file="$output_dir/$theme"

  if dry_run; then
    log "[dry-run] generate_bar_theme $theme -> $output_file"
    return 0
  fi

  run_root install -d -m 0755 "$output_dir"

  # Cargar paleta si no está cargada
  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  cat >"$output_file" <<EOF
# Tema barra status2d: $theme (generado automáticamente)
# No editar directamente; modificar templates/colors/palette-${theme}.sh

BG="${COLOR_BG_ALT}"
FG="${COLOR_FG}"
ACCENT="${COLOR_ACCENT}"
ACCENT_ALT="${COLOR_ACCENT_ALT}"
GREEN="${COLOR_GREEN}"
YELLOW="${COLOR_YELLOW}"
ORANGE="${COLOR_ORANGE}"
RED="${COLOR_RED}"
CYAN="${COLOR_CYAN}"
MUTED="${COLOR_FG_MUTED}"
DIM="${COLOR_FG_DIM}"
BORDER="${COLOR_BORDER}"

# Para status2d (^c^b^ formato)
C_BG="^c\${BG}^"
C_FG="^c\${FG}^"
C_ACCENT="^c\${ACCENT}^"
C_ACCENT_ALT="^c\${ACCENT_ALT}^"
C_GREEN="^c\${GREEN}^"
C_YELLOW="^c\${YELLOW}^"
C_ORANGE="^c\${ORANGE}^"
C_RED="^c\${RED}^"
C_CYAN="^c\${CYAN}^"
C_MUTED="^c\${MUTED}^"
C_DIM="^c\${DIM}^"
C_BORDER="^c\${BORDER}^"

B_BG="^b\${BG}^"
B_FG="^b\${FG}^"
B_ACCENT="^b\${ACCENT}^"
EOF

  ok "Bar theme generado: $output_file"
}

# Genera colors.rasi para rofi
generate_rofi_colors() {
  local theme="${1:-$THEME_NAME}"
  local output="$PROJECT_ROOT/templates/dwm/rofi/colors.rasi"

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

# Genera eww.scss desde template
generate_eww_scss() {
  local theme="${1:-$THEME_NAME}"
  local template="$PROJECT_ROOT/templates/dwm/eww/eww.scss.in"
  local output="$PROJECT_ROOT/templates/dwm/eww/eww.scss"

  if dry_run; then
    log "[dry-run] generate_eww_scss $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  if [[ ! -f "$template" ]]; then
    warn "Template eww.scss.in no existe, saltando"
    return 0
  fi

  render_theme_template "$template" "$output" 0644 \
    HOME="$TARGET_HOME"
}

# Genera vars.yuck para eww
generate_eww_vars() {
  local theme="${1:-$THEME_NAME}"
  local template="$PROJECT_ROOT/templates/dwm/eww/vars.yuck.in"
  local output="$PROJECT_ROOT/templates/dwm/eww/vars.yuck"

  if dry_run; then
    log "[dry-run] generate_eww_vars $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  if [[ ! -f "$template" ]]; then
    warn "Template vars.yuck.in no existe, saltando"
    return 0
  fi

  render_theme_template "$template" "$output" 0644 \
    HOME="$TARGET_HOME"
}

# Genera dunstrc para dunst
generate_dunstrc() {
  local theme="${1:-$THEME_NAME}"
  local template="$PROJECT_ROOT/templates/dwm/dunst/dunstrc.in"
  local output="$PROJECT_ROOT/templates/dwm/dunst/dunstrc"

  if dry_run; then
    log "[dry-run] generate_dunstrc $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  if [[ ! -f "$template" ]]; then
    warn "Template dunstrc.in no existe, saltando"
    return 0
  fi

  render_theme_template "$template" "$output" 0644
}

# Genera picom.conf
generate_picom_conf() {
  local theme="${1:-$THEME_NAME}"
  local template="$PROJECT_ROOT/templates/dwm/picom.conf.in"
  local output="$PROJECT_ROOT/templates/dwm/picom.conf"

  if dry_run; then
    log "[dry-run] generate_picom_conf $theme -> $output"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  if [[ ! -f "$template" ]]; then
    warn "Template picom.conf.in no existe, saltando"
    return 0
  fi

  render_theme_template "$template" "$output" 0644
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
color4 ${COLOR_ACCENT_ALT}
color12 ${COLOR_ACCENT_ALT}

# Magenta
color5 ${COLOR_ACCENT}
color13 ${COLOR_ACCENT}

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

# Genera config.h para chadwm (desde config.h.in)
generate_chadwm_config_h() {
  local theme="${1:-$THEME_NAME}"
  local template="$PROJECT_ROOT/templates/dwm/config.h.in"
  local output_dir="/var/cache/dwm-setup/chadwm-build"
  local output_file="$output_dir/config.h"

  if dry_run; then
    log "[dry-run] generate_chadwm_config_h $theme -> $output_file"
    return 0
  fi

  if [[ "$THEME_NAME" != "$theme" ]]; then
    load_theme "$theme"
  fi

  run_root install -d -m 0755 "$output_dir"

  # El template config.h.in usa @COLOR_*@ para colores
  # y @FONT@, @FONT_SIZE@, @KEYMAP@, @HOME@ para otros
  render_theme_template "$template" "$output_file" 0644 \
    HOME="$TARGET_HOME" \
    FONT="$DWM_FONT" \
    FONT_SIZE="$DWM_FONT_SIZE" \
    KEYMAP="$DWM_KEYMAP" \
    WALLPAPER="$TARGET_HOME/.local/share/wallpapers/rocky.jpg" \
    RESOLUTION="$DWM_RESOLUTION"
}

# Genera TODO lo necesario para un tema
generate_all_theme_assets() {
  local theme="${1:-$THEME_NAME}"
  section "Generando assets para tema: $theme"

  generate_bar_theme "$theme"
  generate_rofi_colors "$theme"
  generate_eww_scss "$theme"
  generate_eww_vars "$theme"
  generate_dunstrc "$theme"
  generate_picom_conf "$theme"
  generate_kitty_theme "$theme"
  # config.h se genera en lib/dwm.sh durante build_dwm

  ok "Assets de tema generados"
}