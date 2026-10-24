#!/usr/bin/env bash
# lib/sxhkd.sh — Instalación de sxhkdrc

install_sxhkd() {
  local home="$TARGET_HOME"

  section "Instalando sxhkd"

  make_user_dir "$home/.config/sxhkd"
  log "Renderizando sxhkdrc desde template"
  render_sxhkd_template "sxhkd/sxhkdrc" "$home/.config/sxhkd/sxhkdrc"

  ok "sxhkd instalado"
}

render_sxhkd_template() {
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
    "WALLPAPER=$TARGET_HOME/.local/share/wallpapers/rocky.jpg" \
    "TERM=kitty" \
    "MENU=rofi -show drun" \
    "BROWSER=firefox" \
    "EDITOR=code" \
    "FILEMGR=thunar" \
    "LOCK=/usr/local/bin/desktop-safe lock" \
    "SCREENSHOT=$TARGET_HOME/.config/bspwm/scripts/screenshot.sh" \
    "KEYBINDINGS=$TARGET_HOME/.config/bspwm/scripts/keybindings_rofi.sh"
}
