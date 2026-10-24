#!/usr/bin/env bash
# lib/picom.sh — Instalación de picom

install_picom() {
  local home="$TARGET_HOME"
  
  section "Instalando picom"
  
  make_user_dir "$home/.config/picom"
  
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/picom/picom.conf" ]]; then
    log "Usando picom.conf del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/picom/picom.conf" "$home/.config/picom/"
  else
    log "Renderizando picom.conf desde template"
    render_picom_template "picom/picom.conf" "$home/.config/picom/picom.conf"
  fi
  
  ok "picom instalado"
}

render_picom_template() {
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