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
    render_dunst_template "dunst/dunstrc" "$home/.config/dunst/dunstrc"
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

render_dunst_template() {
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
  
  # Usar render_theme_template de lib/theme.sh (ya cargado)
  render_theme_template "$template" "$output" "$perms" \
    "HOME=$TARGET_HOME" \
    "FONT=$DWM_FONT" \
    "FONT_SIZE=$DWM_FONT_SIZE" \
    "KEYMAP=$DWM_KEYMAP" \
    "THEME_NAME=nord"
}

make_user_dir() {
  run_root install -d -m 0755 "$1"
}