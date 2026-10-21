#!/usr/bin/env bash
# lib/dunst.sh — Instalación de dunst

install_dunst() {
  local home="$TARGET_HOME"
  
  section "Instalando dunst"
  
  make_user_dir "$home/.config/dunst"
  
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/dunst/dunstrc" ]]; then
    log "Usando dunstrc del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/dunst/dunstrc" "$home/.config/dunst/"
    post_process_dunstrc "$home/.config/dunst/dunstrc"
  else
    log "Renderizando dunstrc desde template"
    render_template "dunst/dunstrc" "$home/.config/dunst/dunstrc"
  fi
  
  ok "dunst instalado"
}

post_process_dunstrc() {
  local file="$1"
  if ! dry_run; then
    # Reemplazar colores hardcodeados comunes
    sed -i "s/#000000/@COLOR_BG@/g; s/#ffffff/@COLOR_FG@/g; s/#ff0000/@COLOR_RED@/g; s/#00ff00/@COLOR_GREEN@/g" "$file" 2>/dev/null || true
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