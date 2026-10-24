#!/usr/bin/env bash
# lib/bspwm.sh — Instalación de bspwm + autostart + xinitrc

install_bspwm() {
  local home="$TARGET_HOME"

  section "Instalando bspwm"

  make_user_dir "$home/.config/bspwm/scripts"
  make_user_dir "$home/.config/bspwm/scripts/i3lock-fancy"

  # bspwmrc debe ser ejecutable: bspwm no lo ejecuta si no lo es.
  log "Renderizando bspwmrc desde template"
  render_bspwm_template "bspwm/bspwmrc" "$home/.config/bspwm/bspwmrc" 0755

  log "Renderizando autostart desde template"
  render_bspwm_template "bspwm/autostart" "$home/.config/bspwm/scripts/autostart" 0755

  install_bspwm_scripts "$home"
  generate_xinitrc "$home"

  ok "bspwm instalado"
}

install_bspwm_scripts() {
  local home="$1"
  local battery
  battery=$(detect_battery)
  local scripts=("bspwm_resize" "low_bat_notifier.sh" "keybindings_rofi.sh" "screenshot.sh")

  for script in "${scripts[@]}"; do
    render_theme_template "$PROJECT_ROOT/templates/bspwm/scripts/$script.in" \
      "$home/.config/bspwm/scripts/$script" 0755 \
      "HOME=$TARGET_HOME" \
      "BATTERY=$battery"
  done

  make_user_dir "$home/.config/bspwm/scripts/i3lock-fancy"
  render_theme_template "$PROJECT_ROOT/templates/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh.in" \
    "$home/.config/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh" 0755 \
    "HOME=$TARGET_HOME" \
    "BATTERY=$battery"

  run_root chmod +x "$home/.config/bspwm/scripts/"* 2>/dev/null || true
  run_root chmod +x "$home/.config/bspwm/scripts/i3lock-fancy/"* 2>/dev/null || true
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
# Inicia bspwm con la configuración del usuario.

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# Configurar teclado
setxkbmap @KEYMAP@ 2>/dev/null || true

# Cursor
xsetroot -cursor_name left_ptr

# bspwm lee ~/.config/bspwm/bspwmrc, que lanza sxhkd y el autostart.
exec bspwm
EOF

  render_bspwm_template_inline "$xinitrc" 0755
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

  local eth_iface wlan_iface battery
  eth_iface=$(detect_eth_iface)
  wlan_iface=$(detect_wlan_iface)
  battery=$(detect_battery)

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
  local perms="${2:-0644}"
  if dry_run; then return 0; fi

  local eth_iface wlan_iface battery
  eth_iface=$(detect_eth_iface)
  wlan_iface=$(detect_wlan_iface)
  battery=$(detect_battery)

  render_theme_template "$file" "$file" "$perms" \
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
  ip -br link show 2>/dev/null | awk '/^en/ {print $1; exit}'
}

detect_wlan_iface() {
  ip -br link show 2>/dev/null | awk '/^wl/ {print $1; exit}'
}

detect_battery() {
  local bat
  for bat in /sys/class/power_supply/BAT*; do
    if [[ -d "$bat" ]]; then
      basename "$bat"
      return
    fi
  done
  echo "BAT0"
}
