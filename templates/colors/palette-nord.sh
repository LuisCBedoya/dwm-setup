#!/usr/bin/env bash
# Nord color palette — vendorizado desde /home/luc/Documentos/Bspwm/config/nord.conf
# No editar directamente; modificar este archivo y regenerar assets.

# Colores base Nord
export NORD_POLAR_NIGHT_0="#2e3440"   # color0  bg principal
export NORD_POLAR_NIGHT_1="#3b4252"   # color1  bg alt
export NORD_POLAR_NIGHT_2="#434c5e"   # color2  bg elev
export NORD_POLAR_NIGHT_3="#4c566a"   # color3  bg hover/comentarios

export NORD_SNOW_STORM_4="#d8dee9"    # color4  fg principal
export NORD_SNOW_STORM_5="#e5e9f0"    # color5  fg alt
export NORD_SNOW_STORM_6="#eceff4"    # color6  fg bright

export NORD_FROST_7="#8fbcbb"         # color7  accent principal (teal)
export NORD_FROST_8="#88c0d0"         # color8  accent alt (cyan)
export NORD_FROST_9="#81a1c1"         # color9  accent azul
export NORD_FROST_10="#5e81ac"        # color10 accent azul oscuro

export NORD_AURORA_11="#bf616a"       # color11 red
export NORD_AURORA_12="#d08770"       # color12 orange
export NORD_AURORA_13="#ebcb8b"       # color13 yellow
export NORD_AURORA_14="#a3be8c"       # color14 green
export NORD_AURORA_15="#b48ead"       # color15 purple

# Alias semánticos para templates
export COLOR_BG="${NORD_POLAR_NIGHT_0}"
export COLOR_BG_ALT="${NORD_POLAR_NIGHT_1}"
export COLOR_BG_ELEV="${NORD_POLAR_NIGHT_2}"
export COLOR_BG_HOVER="${NORD_POLAR_NIGHT_3}"
export COLOR_FG="${NORD_SNOW_STORM_4}"
export COLOR_FG_MUTED="${NORD_POLAR_NIGHT_3}"
export COLOR_FG_DIM="${NORD_POLAR_NIGHT_2}"
export COLOR_BORDER="${NORD_POLAR_NIGHT_2}"
export COLOR_ACCENT="${NORD_FROST_7}"
export COLOR_ACCENT_ALT="${NORD_FROST_8}"
export COLOR_GREEN="${NORD_AURORA_14}"
export COLOR_YELLOW="${NORD_AURORA_13}"
export COLOR_ORANGE="${NORD_AURORA_12}"
export COLOR_RED="${NORD_AURORA_11}"
export COLOR_CYAN="${NORD_FROST_8}"
export COLOR_PURPLE="${NORD_AURORA_15}"
export COLOR_BLUE="${NORD_FROST_9}"

# Helpers RGBA (para transparencias en polybar/kitty/dunst)
# Calculados en lib/theme.sh por export_rgba_helpers

# Terminal (kitty)
export COLOR_TERM_BG="#2e3440"
export COLOR_TERM_0="#3b4252"
export COLOR_TERM_8="#4c566a"
export COLOR_TERM_1="#bf616a"
export COLOR_TERM_9="#bf616a"
export COLOR_TERM_2="#a3be8c"
export COLOR_TERM_10="#a3be8c"
export COLOR_TERM_3="#ebcb8b"
export COLOR_TERM_11="#ebcb8b"
export COLOR_TERM_4="#81a1c1"
export COLOR_TERM_12="#81a1c1"
export COLOR_TERM_5="#b48ead"
export COLOR_TERM_13="#b48ead"
export COLOR_TERM_6="#88c0d0"
export COLOR_TERM_14="#88c0d0"
export COLOR_TERM_7="#d8dee9"
export COLOR_TERM_15="#eceff4"
