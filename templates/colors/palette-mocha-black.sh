#!/usr/bin/env bash
# Catppuccin Mocha Black — Mocha con la rampa de fondo llevada a casi negro.
#
# Base Catppuccin Mocha, con estas sustituciones:
#   base     #1e1e2e -> #0d0d14
#   mantle   #181825 -> #08080d
#   crust    #11111b -> #050509
#   surface0 #313244 -> #1a1a24
#   surface1 #45475a -> #26262f
#   surface2 #585b70 -> #35353f
# El resto de la paleta (texto, acentos, estados) es Mocha estándar.

# Superficies
export COLOR_BG="#0d0d14"          # base
export COLOR_BG_DEEP="#08080d"     # mantle
export COLOR_BG_DEEPEST="#050509"  # crust
export COLOR_BG_ALT="#0d0d14"      # superficies planas
export COLOR_BG_ELEV="#1a1a24"     # surface0 — tarjetas, hover de fondo
export COLOR_BG_HOVER="#26262f"    # surface1 — selección
export COLOR_BORDER="#26262f"      # surface1 — contornos
export COLOR_BORDER_ALT="#35353f"  # surface2 — contornos suaves

# Texto
export COLOR_FG="#cdd6f4"          # text
export COLOR_FG_MUTED="#a6adc8"    # subtext0
export COLOR_FG_DIM="#6c7086"      # overlay0

# Acentos y estados
export COLOR_ACCENT="#89b4fa"      # blue
export COLOR_ACCENT_ALT="#b4befe"  # lavender
export COLOR_GREEN="#a6e3a1"
export COLOR_YELLOW="#f9e2af"
export COLOR_ORANGE="#fab387"      # peach
export COLOR_RED="#f38ba8"
export COLOR_CYAN="#94e2d5"        # teal
export COLOR_PURPLE="#cba6f7"      # mauve
export COLOR_BLUE="#89b4fa"

# Terminal (kitty) — rampa ANSI de Catppuccin Mocha
export COLOR_TERM_BG="#0d0d14"
export COLOR_TERM_0="#26262f"
export COLOR_TERM_8="#35353f"
export COLOR_TERM_1="#f38ba8"
export COLOR_TERM_9="#f38ba8"
export COLOR_TERM_2="#a6e3a1"
export COLOR_TERM_10="#a6e3a1"
export COLOR_TERM_3="#f9e2af"
export COLOR_TERM_11="#f9e2af"
export COLOR_TERM_4="#89b4fa"
export COLOR_TERM_12="#89b4fa"
export COLOR_TERM_5="#f5c2e7"
export COLOR_TERM_13="#f5c2e7"
export COLOR_TERM_6="#94e2d5"
export COLOR_TERM_14="#94e2d5"
export COLOR_TERM_7="#bac2de"
export COLOR_TERM_15="#a6adc8"

# Ajustes que no son color pero dependen del modo
export THEME_GTK="catppuccin-mocha-black"
export THEME_ICONS="Catppuccin-Mocha"
export THEME_FOLDER_COLOR="cat-mocha-blue"
export THEME_VLC_DARK="1"
export THEME_FIREFOX_DARK="true"
export THEME_PREFERS_DARK="1"
export THEME_CONTENT_OVERRIDE="0"   # 0 = oscuro (se aplica al reiniciar Firefox)
export THEME_COLOR_SCHEME="prefer-dark"
export THEME_CURSOR="Adwaita"

validate_palette
