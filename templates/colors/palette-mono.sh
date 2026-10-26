#!/usr/bin/env bash
# Mono Slate palette — negro, grises y acento azul
# Basada en la paleta exacta de referencia del usuario:
#   BLACK #000000 · SURFACE #0E0E0E · TILE #1A1A1A · LINE #2A2A2A
#   MUTE #4A4A4A · GREY #8C8C8C · WHITE #F2F2F2
# El rojo original #D71921 se sustituye por azul #569CD6.

export MONO_INK_0="#262626"       # SUPERFICIE — barra, terminal, Thunar
export MONO_INK_1="#262626"       # SUPERFICIE — paneles planos
export MONO_INK_2="#3a3a3a"       # ELEVADO — hover / tarjetas
export MONO_INK_3="#3a3a3a"       # HOVER — selección
export MONO_TEXT_0="#f2f2f2"      # WHITE — texto principal
export MONO_TEXT_1="#8c8c8c"      # GREY — texto secundario
export MONO_TEXT_2="#4a4a4a"      # MUTE — deshabilitado
export MONO_BORDER_0="#1a1a1a"    # BORDE — contornos
export MONO_BLUE="#569cd6"        # acento azul
export MONO_CHALK="#d9d9d9"       # gris claro
export MONO_LIGHT="#e9e9e9"
export MONO_SILVER="#b8b8b8"
export MONO_DIM="#6e6e6e"

export COLOR_BG="${MONO_INK_0}"
export COLOR_BG_ALT="${MONO_INK_1}"
export COLOR_BG_ELEV="${MONO_INK_2}"
export COLOR_BG_HOVER="${MONO_INK_3}"
export COLOR_FG="${MONO_TEXT_0}"
export COLOR_FG_MUTED="${MONO_TEXT_1}"
export COLOR_FG_DIM="${MONO_TEXT_2}"
export COLOR_BORDER="${MONO_BORDER_0}"
export COLOR_ACCENT="${MONO_BLUE}"
export COLOR_ACCENT_ALT="${MONO_CHALK}"
export COLOR_GREEN="${MONO_SILVER}"
export COLOR_YELLOW="${MONO_LIGHT}"
export COLOR_ORANGE="${MONO_TEXT_1}"
export COLOR_RED="${MONO_BLUE}"
export COLOR_CYAN="${MONO_DIM}"
export COLOR_PURPLE="${MONO_SILVER}"
export COLOR_BLUE="${MONO_BLUE}"

# Terminal (kitty) — fondo propio y rampa de grises con contraste
export COLOR_TERM_BG="#1c1c1c"
export COLOR_TERM_0="#2a2a2a"
export COLOR_TERM_8="#5f5f5f"
export COLOR_TERM_1="#6e6e6e"
export COLOR_TERM_9="#8c8c8c"
export COLOR_TERM_2="#a8a8a8"
export COLOR_TERM_10="#c0c0c0"
export COLOR_TERM_3="#d0d0d0"
export COLOR_TERM_11="#e0e0e0"
export COLOR_TERM_4="#8c8c8c"
export COLOR_TERM_12="#a8a8a8"
export COLOR_TERM_5="#c0c0c0"
export COLOR_TERM_13="#d9d9d9"
export COLOR_TERM_6="#5f5f5f"
export COLOR_TERM_14="#7a7a7a"
export COLOR_TERM_7="#f2f2f2"
export COLOR_TERM_15="#ffffff"
