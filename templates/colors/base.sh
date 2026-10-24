#!/usr/bin/env bash
# Base loader para paletas de colores.
# Se sourcea desde install.sh y lib/theme.sh.
# Uso: source /path/to/templates/colors/palette-nord.sh

# Paleta activa (exportada por el archivo de paleta concreto)
# Variables requeridas (todas en formato HEX #rrggbb):
#   COLOR_BG         - Fondo raíz (wallpaper, root window)
#   COLOR_BG_ALT     - Fondo barra, paneles base
#   COLOR_BG_ELEV    - Fondo widgets, tarjetas elevadas
#   COLOR_BG_HOVER   - Hover/selected en UI interactiva
#   COLOR_FG         - Texto principal
#   COLOR_FG_MUTED   - Texto secundario
#   COLOR_FG_DIM     - Texto deshabilitado/placeholder
#   COLOR_BORDER     - Bordes neutros
#   COLOR_ACCENT     - Acento protagonista (foco, cursor, selected)
#   COLOR_ACCENT_ALT - Acento secundario
#   COLOR_GREEN      - OK / bajo
#   COLOR_YELLOW     - Warning / medio
#   COLOR_ORANGE     - Alto / naranja
#   COLOR_RED        - Crítico / error
#   COLOR_CYAN       - Info / cian

# Helper para alpha en formatos que lo necesitan (ej. eww.scss rgba)
# Uso: hex_to_rgba "#1a1b26" 0.92
hex_to_rgba() {
  local hex="${1#\#}"
  local alpha="${2:-1}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf 'rgba(%d, %d, %d, %s)' "$r" "$g" "$b" "$alpha"
}

# Export helpers para plantillas que necesitan rgba (se llaman después de cargar la paleta)
export_rgba_helpers() {
  export COLOR_BG_RGB="${COLOR_BG#\#}"
  export COLOR_BG_ALT_RGB="${COLOR_BG_ALT#\#}"
  export COLOR_BG_ELEV_RGB="${COLOR_BG_ELEV#\#}"
  export COLOR_ACCENT_RGB="${COLOR_ACCENT#\#}"
  export COLOR_BG_RGBA_92="$(hex_to_rgba "$COLOR_BG" 0.92)"
  export COLOR_BG_ALT_RGBA_92="$(hex_to_rgba "$COLOR_BG_ALT" 0.92)"
  export COLOR_BG_ELEV_RGBA_92="$(hex_to_rgba "$COLOR_BG_ELEV" 0.92)"
  export COLOR_BG_ELEV_RGBA_85="$(hex_to_rgba "$COLOR_BG_ELEV" 0.85)"
  export COLOR_ACCENT_RGBA_30="$(hex_to_rgba "$COLOR_ACCENT" 0.30)"
  export COLOR_BORDER_RGBA_50="$(hex_to_rgba "$COLOR_BORDER" 0.50)"
}

# Validación mínima
validate_palette() {
  local var val
  for var in COLOR_BG COLOR_BG_ALT COLOR_BG_ELEV COLOR_BG_HOVER \
             COLOR_FG COLOR_FG_MUTED COLOR_FG_DIM \
             COLOR_BORDER COLOR_ACCENT COLOR_ACCENT_ALT \
             COLOR_GREEN COLOR_YELLOW COLOR_ORANGE COLOR_RED COLOR_CYAN; do
    val="${!var}"
    if [[ -z "$val" ]]; then
      echo "ERROR: Paleta incompleta: falta $var" >&2
      return 1
    fi
    if [[ ! "$val" =~ ^#[0-9a-fA-F]{6}$ ]]; then
      echo "ERROR: $var formato inválido: $val (esperado #rrggbb)" >&2
      return 1
    fi
  done
  return 0
}

# Si se ejecuta directo (no sourceado), validar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  validate_palette && echo "Paleta válida" || exit 1
fi