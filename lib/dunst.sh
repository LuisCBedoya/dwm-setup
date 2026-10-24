#!/usr/bin/env bash
# lib/dunst.sh — Instalación de dunst

install_dunst() {
  local home="$TARGET_HOME"

  section "Instalando dunst"

  make_user_dir "$home/.config/dunst"
  log "Renderizando dunstrc desde template"
  render_dunst_template "dunst/dunstrc" "$home/.config/dunst/dunstrc"

  ok "dunst instalado"
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

  render_theme_template "$template" "$output" "$perms" \
    "HOME=$TARGET_HOME" \
    "FONT=$DWM_FONT" \
    "FONT_SIZE=$DWM_FONT_SIZE" \
    "KEYMAP=$DWM_KEYMAP" \
    "THEME_NAME=nord"
}
