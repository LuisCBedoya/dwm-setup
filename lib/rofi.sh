#!/usr/bin/env bash
# lib/rofi.sh — Instalación de rofi (powermenu)

install_rofi() {
  local home="$TARGET_HOME"
  
  section "Instalando rofi"
  
  make_user_dir "$home/.config/rofi"
  
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/rofi/powermenu/rofi.rasi" ]]; then
    log "Usando rofi.rasi del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/rofi/powermenu/rofi.rasi" "$home/.config/rofi/"
    post_process_rofi "$home/.config/rofi/rofi.rasi"
  else
    log "Renderizando rofi powermenu desde template"
    render_template "rofi/powermenu.rasi" "$home/.config/rofi/powermenu.rasi"
  fi
  
  ok "rofi instalado"
}

post_process_rofi() {
  local file="$1"
  if ! dry_run; then
    sed -i "s/#000000/@COLOR_BG@/g; s/#ffffff/@COLOR_FG@/g" "$file" 2>/dev/null || true
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