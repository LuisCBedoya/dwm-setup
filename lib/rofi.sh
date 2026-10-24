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
    render_rofi_template "rofi/powermenu.rasi" "$home/.config/rofi/powermenu.rasi"
  fi
  
  ok "rofi instalado"
}

post_process_rofi() {
  local file="$1"
  if ! dry_run; then
    sed -i "s/#000000/@COLOR_BG@/g; s/#ffffff/@COLOR_FG@/g" "$file" 2>/dev/null || true
  fi
}

render_rofi_template() {
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