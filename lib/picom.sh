#!/usr/bin/env bash
# lib/picom.sh — Instalación de picom

install_picom() {
  local home="$TARGET_HOME"

  section "Instalando picom"

  make_user_dir "$home/.config/picom"
  log "Renderizando picom.conf desde template"
  render_picom_template "picom/picom.conf" "$home/.config/picom/picom.conf"

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

  render_theme_template "$template" "$output" "$perms" \
    "HOME=$TARGET_HOME" \
    "FONT=$DWM_FONT" \
    "FONT_SIZE=$DWM_FONT_SIZE" \
    "KEYMAP=$DWM_KEYMAP" \
    "THEME_NAME=nord"
}
