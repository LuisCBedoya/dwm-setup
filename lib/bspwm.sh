#!/usr/bin/env bash
# lib/bspwm.sh — Instalación de bspwm + autostart + xinitrc

install_bspwm() {
  local theme="${1:-nord}"
  local home="$TARGET_HOME"
  
  section "Instalando bspwm"
  
  # Paquetes ya instalados via packages.sh
  
  # Directorios
  make_user_dir "$home/.config/bspwm/scripts"
  make_user_dir "$home/.config/bspwm/scripts/i3lock-fancy"
  
  # bspwmrc
  if [[ -n "${DOTFILES_DIR:-}" && -d "$DOTFILES_DIR/config/.config/bspwm" ]]; then
    log "Usando bspwmrc del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/bspwm" "$home/.config/"
    # Post-procesar colores si es necesario
    post_process_bspwm_config "$home/.config/bspwm/bspwmrc"
  else
    log "Renderizando bspwmrc desde template"
    render_bspwm_template "bspwm/bspwmrc" "$home/.config/bspwm/bspwmrc"
  fi
  
  # Autostart
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/bspwm/scripts/autostart" ]]; then
    log "Usando autostart del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/bspwm/scripts/autostart" "$home/.config/bspwm/scripts/"
    post_process_autostart "$home/.config/bspwm/scripts/autostart"
  else
    log "Renderizando autostart desde template"
    render_bspwm_template "bspwm/autostart" "$home/.config/bspwm/scripts/autostart" 0755
  fi
  
  # Scripts auxiliares
  install_bspwm_scripts "$home"
  
  # .xinitrc
  generate_xinitrc "$home"
  
  ok "bspwm instalado"
}

install_bspwm_scripts() {
  local home="$1"
  local scripts=("bspwm_resize" "low_bat_notifier.sh" "keybindings_rofi.sh" "screenshot.sh")
  
  for script in "${scripts[@]}"; do
    if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/bspwm/scripts/$script" ]]; then
      run_root cp -a "$DOTFILES_DIR/config/.config/bspwm/scripts/$script" "$home/.config/bspwm/scripts/"
    else
      render_theme_template "$PROJECT_ROOT/templates/bspwm/scripts/$script.in" "$home/.config/bspwm/scripts/$script" 0755 \
        "HOME=$TARGET_HOME"
    fi
  done
  
  # i3lock-fancy
  if [[ -n "${DOTFILES_DIR:-}" && -d "$DOTFILES_DIR/config/.config/bspwm/scripts/i3lock-fancy" ]]; then
    run_root cp -a "$DOTFILES_DIR/config/.config/bspwm/scripts/i3lock-fancy" "$home/.config/bspwm/scripts/"
  else
    make_user_dir "$home/.config/bspwm/scripts/i3lock-fancy"
    render_theme_template "$PROJECT_ROOT/templates/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh.in" "$home/.config/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh" 0755 \
      "HOME=$TARGET_HOME"
  fi
  
  # Hacer ejecutables
  run_root chmod +x "$home/.config/bspwm/scripts/"* 2>/dev/null || true
  run_root chmod +x "$home/.config/bspwm/scripts/i3lock-fancy/"* 2>/dev/null || true
}

post_process_bspwm_config() {
  local file="$1"
  # Reemplazar colores hardcodeados comunes por variables Nord si existen
  # Esto es best-effort; si el repo ya usa Nord, no hará nada
  if ! dry_run; then
    sed -i "s/#000000/@COLOR_BG@/g; s/#797979/@COLOR_ACCENT@/g; s/#073642/@COLOR_BG_ELEV@/g" "$file" 2>/dev/null || true
  fi
}

post_process_autostart() {
  local file="$1"
  if ! dry_run; then
    # Reemplazar paths hardcodeados comunes
    sed -i "s|/home/[^/]*/|@HOME@/|g" "$file" 2>/dev/null || true
  fi
}

generate_xinitrc() {
  local home="$1"
  local xinitrc="$home/.xinitrc"
  
  if dry_run; then
    log "[dry-run] Generando $xinitrc"
    return 0
  fi
  
  cat > "$xinitrc" <<'EOF'
#!/bin/sh
# .xinitrc — generado por dwm-setup
# Inicia bspwm con configuración del usuario

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# Configurar teclado
setxkbmap @KEYMAP@ 2>/dev/null || true

# Cursor
xsetroot -cursor_name left_ptr

# Terminal fallback (por si sxhkd falla)
kitty &

# Iniciar bspwm (lee ~/.config/bspwm/bspwmrc que lanza autostart)
exec bspwm
EOF
  
  # Renderizar placeholders
  render_bspwm_template_inline "$xinitrc"
  
  ok "Generado: $xinitrc"
}

render_bspwm_template() {
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
  
  # Detectar hardware para variables específicas de bspwm
  local eth_iface=$(detect_eth_iface)
  local wlan_iface=$(detect_wlan_iface)
  local battery=$(detect_battery)
  
  # Usar render_theme_template de lib/theme.sh (ya cargado)
  render_theme_template "$template" "$output" "$perms" \
    "HOME=$TARGET_HOME" \
    "FONT=$DWM_FONT" \
    "FONT_SIZE=$DWM_FONT_SIZE" \
    "KEYMAP=$DWM_KEYMAP" \
    "WALLPAPER=$TARGET_HOME/.local/share/wallpapers/rocky.jpg" \
    "BAR_HEIGHT=26" \
    "ETH_IFACE=$eth_iface" \
    "WLAN_IFACE=$wlan_iface" \
    "BATTERY=$battery"
}

render_bspwm_template_inline() {
  local file="$1"
  if dry_run; then return 0; fi
  
  local eth_iface=$(detect_eth_iface)
  local wlan_iface=$(detect_wlan_iface)
  local battery=$(detect_battery)
  
  render_theme_template "$file" "$file" 0644 \
    "HOME=$TARGET_HOME" \
    "FONT=$DWM_FONT" \
    "FONT_SIZE=$DWM_FONT_SIZE" \
    "KEYMAP=$DWM_KEYMAP" \
    "WALLPAPER=$TARGET_HOME/.local/share/wallpapers/rocky.jpg" \
    "BAR_HEIGHT=26" \
    "ETH_IFACE=$eth_iface" \
    "WLAN_IFACE=$wlan_iface" \
    "BATTERY=$battery"
}

detect_eth_iface() {
  ip -br link show up 2>/dev/null | awk '/^en/ {print $1; exit}' | head -1
}

detect_wlan_iface() {
  ip -br link show up 2>/dev/null | awk '/^wl/ {print $1; exit}' | head -1
}

detect_battery() {
  for bat in /sys/class/power_supply/BAT*; do
    if [[ -d "$bat" ]]; then
      basename "$bat"
      return
    fi
  done
  echo "BAT0"
}

make_user_dir() {
  run_root install -d -m 0755 "$1"
}