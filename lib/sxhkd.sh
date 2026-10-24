#!/usr/bin/env bash
# lib/sxhkd.sh — Instalación de sxhkdrc

install_sxhkd() {
  local home="$TARGET_HOME"
  
  section "Instalando sxhkd"
  
  make_user_dir "$home/.config/sxhkd"
  
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/sxhkd/sxhkdrc" ]]; then
    log "Usando sxhkdrc del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/sxhkd/sxhkdrc" "$home/.config/sxhkd/"
    post_process_sxhkdrc "$home/.config/sxhkd/sxhkdrc"
  else
    log "Renderizando sxhkdrc desde template"
    render_sxhkd_template "sxhkd/sxhkdrc" "$home/.config/sxhkd/sxhkdrc"
  fi
  
  ok "sxhkd instalado"
}

post_process_sxhkdrc() {
  local file="$1"
  if ! dry_run; then
    # Reemplazar comandos hardcodeados comunes
    sed -i "s|kitty|@TERM@|g; s|rofi -dmenu|@MENU@|g; s|chromium|@BROWSER@|g; s|code|@EDITOR@|g; s|thunar|@FILEMGR@|g" "$file" 2>/dev/null || true
  fi
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
  
  # Usar render_theme_template de lib/theme.sh (ya cargado)
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

make_user_dir() {
  run_root install -d -m 0755 "$1"
}