#!/usr/bin/env bash
# lib/sxhkd.sh — Instalación de sxhkdrc

install_sxhkd() {
  local home="$TARGET_HOME"
  
  section "Instalando sxhkd"
  
  make_user_dir "$home/.config/sxhkd"
  
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/sxhkd/sxhkdrc" ]]; then
    log "Usando sxhkdrc del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/sxhkd/sxhkdrc" "$home/.config/sxhkd/"
    post_process_sxhkdrc "$home/.config/sxhkd/sxhkdrc"
  else
    log "Renderizando sxhkdrc desde template"
    render_template "sxhkd/sxhkdrc" "$home/.config/sxhkd/sxhkdrc"
  fi
  
  ok "sxhkd instalado"
}

post_process_sxhkdrc() {
  local file="$1"
  if ! dry_run; then
    # Reemplazar comandos hardcodeados comunes
    sed -i "s|kitty|@TERM@|g; s|rofi -dmenu|@MENU@|g; s|chromium|@BROWSER@|g; s|code|@EDITOR@|g; s|thunar|@FILEMGR@|g" "$file" 2>/dev/null || true
  fi
}

render_template() {
  local template_rel="$1"
  local output="$2"
  local perms="${3:-0644}"
  local template="$PROJECT_ROOT/templates/$template_rel.in"
  
  if [[ ! -f "$template" ]]; then
    die "Template no encontrado: $template"
  fi
  
  if dry_run; then
    log "[dry-run] render $template -> $output"
    return 0
  fi
  
  local content
  content=$(cat "$template")
  
  source_theme_vars
  
  # Variables de color
  for var in COLOR_BG COLOR_BG_ALT COLOR_BG_ELEV COLOR_BG_HOVER \
             COLOR_FG COLOR_FG_MUTED COLOR_FG_DIM \
             COLOR_BORDER COLOR_ACCENT COLOR_ACCENT_ALT \
             COLOR_GREEN COLOR_YELLOW COLOR_ORANGE COLOR_RED COLOR_CYAN \
             COLOR_PURPLE COLOR_BLUE; do
    content="${content//@${var}@/${!var}}"
  done
  
  # Variables de usuario
  content="${content//@HOME@/$TARGET_HOME}"
  content="${content//@FONT@/$DWM_FONT}"
  content="${content//@FONT_SIZE@/$DWM_FONT_SIZE}"
  content="${content//@KEYMAP@/$DWM_KEYMAP}"
  content="${content//@WALLPAPER@/$TARGET_HOME/.local/share/wallpapers/rocky.jpg}"
  content="${content//@THEME_NAME@/nord}"
  
  # Apps configurables
  content="${content//@TERM@/kitty}"
  content="${content//@MENU@/rofi -show drun}"
  content="${content//@BROWSER@/firefox}"
  content="${content//@EDITOR@/code}"
  content="${content//@FILEMGR@/thunar}"
  content="${content//@LOCK@/$TARGET_HOME/.local/bin/desktop-safe lock}"
  content="${content//@SCREENSHOT@/$TARGET_HOME/.config/bspwm/scripts/screenshot.sh}"
  content="${content//@KEYBINDINGS@/$TARGET_HOME/.config/bspwm/scripts/keybindings_rofi.sh}"
  
  run_root install -D -m "$perms" /dev/stdin "$output" <<<"$content"
  ok "Renderizado: $output"
}

source_theme_vars() {
  if [[ -f "$PROJECT_ROOT/templates/colors/palette-nord.sh" ]]; then
    source "$PROJECT_ROOT/templates/colors/palette-nord.sh"
  fi
}

make_user_dir() {
  run_root install -d -m 0755 "$1"
}