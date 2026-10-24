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
    render_kitty_template "kitty/kitty.conf" "$home/.config/kitty/kitty.conf"
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

render_kitty_template() {
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