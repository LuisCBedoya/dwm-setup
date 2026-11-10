#!/usr/bin/env bash
# Catppuccin Latte — modo claro.
#
# Paleta Latte estándar con acento azul oscurecido (#1e66f5) para que el
# contraste sobre fondo claro sea suficiente.

# Superficies
export COLOR_BG="#eff1f5"          # base
export COLOR_BG_DEEP="#e6e9ef"     # mantle
export COLOR_BG_DEEPEST="#dce0e8"  # crust
export COLOR_BG_ALT="#e6e9ef"      # mantle
export COLOR_BG_ELEV="#ccd0da"     # surface0 — tarjetas
export COLOR_BG_HOVER="#bcc0cc"    # surface1 — selección
export COLOR_BORDER="#bcc0cc"      # surface1 — contornos
export COLOR_BORDER_ALT="#acb0be"  # surface2 — contornos suaves

# Texto
export COLOR_FG="#4c4f69"          # text
export COLOR_FG_MUTED="#6c6f85"    # subtext0
export COLOR_FG_DIM="#9ca0b0"      # overlay0
export COLOR_FG_DIM_RGB="156;160;176" # overlay0 en RGB decimal (SGR 38;2)

# Acentos y estados
export COLOR_ACCENT="#1e66f5"      # blue (oscurecido para contraste)
export COLOR_ACCENT_ALT="#7287fd"  # lavender
export COLOR_ACCENT_RGB="30;102;245"     # blue en RGB decimal (SGR 38;2)
export COLOR_ACCENT_ALT_RGB="114;135;253" # lavender en RGB decimal
export COLOR_GREEN="#40a02b"
export COLOR_YELLOW="#df8e1d"
export COLOR_ORANGE="#fe640b"      # peach
export COLOR_RED="#d20f39"
export COLOR_CYAN="#179299"        # teal
export COLOR_PURPLE="#8839ef"      # mauve
export COLOR_BLUE="#1e66f5"

# Terminal (kitty) — rampa ANSI de Catppuccin Latte
export COLOR_TERM_BG="#eff1f5"
export COLOR_TERM_0="#5c5f77"
export COLOR_TERM_8="#6c6f85"
export COLOR_TERM_1="#d20f39"
export COLOR_TERM_9="#d20f39"
export COLOR_TERM_2="#40a02b"
export COLOR_TERM_10="#40a02b"
export COLOR_TERM_3="#df8e1d"
export COLOR_TERM_11="#df8e1d"
export COLOR_TERM_4="#1e66f5"
export COLOR_TERM_12="#1e66f5"
export COLOR_TERM_5="#ea76cb"
export COLOR_TERM_13="#ea76cb"
export COLOR_TERM_6="#179299"
export COLOR_TERM_14="#179299"
export COLOR_TERM_7="#acb0be"
export COLOR_TERM_15="#bcc0cc"

# Ajustes que no son color pero dependen del modo
export THEME_GTK="catppuccin-latte-blue"
export THEME_ICONS="Catppuccin-Latte"
export THEME_FOLDER_COLOR="cat-latte-blue"
export THEME_VLC_DARK="0"
export THEME_FIREFOX_DARK="false"
export THEME_PREFERS_DARK="0"
export THEME_CONTENT_OVERRIDE="1"   # 1 = claro (se aplica al reiniciar Firefox)
export THEME_COLOR_SCHEME="default"
export THEME_CURSOR="Adwaita"

validate_palette
