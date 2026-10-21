#!/usr/bin/env bash
# lib/kitty.sh — Instalación de kitty

install_kitty() {
  local home="$TARGET_HOME"
  
  section "Instalando kitty"
  
  make_user_dir "$home/.config/kitty"
  
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/kitty/kitty.conf" ]]; then
    log "Usando kitty.conf del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/kitty/kitty.conf" "$home/.config/kitty/"
    post_process_kitty "$home/.config/kitty/kitty.conf"
  else
    log "Renderizando kitty.conf desde template"
    render_template "kitty/kitty.conf" "$home/.config/kitty/kitty.conf"
  fi
  
  ok "kitty instalado"
}

post_process_kitty() {
  local file="$1"
  if ! dry_run; then
    # Reemplazar colores hardcodeados si los hay
    sed -i "s/background #.*/background @COLOR_BG@/; s/foreground #.*/foreground @COLOR_FG@/" "$file" 2>/dev/null || true
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
  
  for var in COLOR_BG COLOR_BG_ALT COLOR_BG_ELEV COLOR_BG_HOVER \
             COLOR_FG COLOR_FG_MUTED COLOR_FG_DIM \
             COLOR_BORDER COLOR_ACCENT COLOR_ACCENT_ALT \
             COLOR_GREEN COLOR_YELLOW COLOR_ORANGE COLOR_RED COLOR_CYAN \
             COLOR_PURPLE COLOR_BLUE; do
    content="${content//@${var}@/${!var}}"
  done
  
  content="${content//@HOME@/$TARGET_HOME}"
  content="${content//@FONT@/$DWM_FONT}"
  content="${content//@FONT_SIZE@/$DWM_FONT_SIZE}"
  content="${content//@KEYMAP@/$DWM_KEYMAP}"
  content="${content//@THEME_NAME@/nord}"
  
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