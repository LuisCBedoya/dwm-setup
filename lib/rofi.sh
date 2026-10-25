#!/usr/bin/env bash
# lib/rofi.sh — Instalación de rofi (powermenu)

install_rofi() {
  local home="$TARGET_HOME"

  section "Instalando rofi"

  make_user_dir "$home/.config/rofi"
  log "Renderizando rofi powermenu desde template"
  render_rofi_template "rofi/powermenu.rasi" "$home/.config/rofi/powermenu.rasi"

  ok "rofi instalado"
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

  render_theme_template "$template" "$output" "$perms" \
    "HOME=$TARGET_HOME" \
    "FONT=$DWM_FONT" \
    "FONT_SIZE=$DWM_FONT_SIZE" \
    "KEYMAP=$DWM_KEYMAP" \
    "THEME_NAME=warm"
}
