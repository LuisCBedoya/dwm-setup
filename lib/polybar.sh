#!/usr/bin/env bash
# lib/polybar.sh — Instalación de polybar (config, modules, scripts, launch)

install_polybar() {
  local home="$TARGET_HOME"
  
  section "Instalando polybar"
  
  make_user_dir "$home/.config/polybar/modules"
  make_user_dir "$home/.config/polybar/scripts"
  
  # config.ini
  if [[ -n "${DOTFILES_DIR:-}" && -f "$DOTFILES_DIR/config/.config/polybar/config.ini" ]]; then
    log "Usando config.ini del repo dotfiles"
    run_root cp -a "$DOTFILES_DIR/config/.config/polybar/config.ini" "$home/.config/polybar/"
    run_root cp -a "$DOTFILES_DIR/config/.config/polybar/modules" "$home/.config/polybar/" 2>/dev/null || true
    run_root cp -a "$DOTFILES_DIR/config/.config/polybar/scripts" "$home/.config/polybar/" 2>/dev/null || true
    post_process_polybar "$home"
  else
    log "Renderizando polybar desde templates"
    render_polybar_templates "$home"
  fi
  
  # launch.sh (siempre generar el nuestro)
  render_launch_script "$home"
  
  ok "polybar instalado"
}

render_polybar_templates() {
  local home="$1"
  
  # config.ini principal
  render_template "polybar/config.ini" "$home/.config/polybar/config.ini"
  
  # Módulos (orden = modules-left + modules-right del config)
  local modules=(
    "modules/logo.ini"
    "modules/bspwm.ini"
    "modules/updates.ini"
    "modules/polypomo.ini"
    "modules/temp.ini"
    "modules/memory.ini"
    "modules/cpu.ini"
    "modules/xkeyboard.ini"
    "modules/eth.ini"
    "modules/wlan.ini"
    "modules/battery.ini"
    "modules/pipewire.ini"
    "modules/date.ini"
  )
  
  for m in "${modules[@]}"; do
    render_template "polybar/$m" "$home/.config/polybar/$m"
  done
  
  # Scripts
  local scripts=("updates-apt.sh" "polypomo")
  for s in "${scripts[@]}"; do
    render_template "polybar/scripts/$s" "$home/.config/polybar/scripts/$s" 0755
  done
}

render_launch_script() {
  local home="$1"
  local launch="$home/.config/polybar/launch.sh"
  
  if dry_run; then
    log "[dry-run] Generando $launch"
    return 0
  fi
  
  local template="$PROJECT_ROOT/templates/polybar/scripts/launch.sh.in"
  local content
  content=$(cat "$template")
  
  content="${content//@HOME@/$TARGET_HOME}"
  
  run_root install -D -m 0755 /dev/stdin "$launch" <<<"$content"
  ok "Generado: $launch"
}

post_process_polybar() {
  local home="$1"
  # Asegurar launch.sh propio
  render_launch_script "$home"
  
  # Hacer scripts ejecutables
  run_root chmod +x "$home/.config/polybar/scripts/"* 2>/dev/null || true
  run_root chmod +x "$home/.config/polybar/launch.sh" 2>/dev/null || true
}

render_template() {
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
  
  local content
  content=$(cat "$template")
  
  # Variables de color (paleta Nord para compatibilidad, aunque no se usen en config.ini)
  source_theme_vars
  for var in COLOR_BG COLOR_BG_ALT COLOR_BG_ELEV COLOR_BG_HOVER \
             COLOR_FG COLOR_FG_MUTED COLOR_FG_DIM \
             COLOR_BORDER COLOR_ACCENT COLOR_ACCENT_ALT \
             COLOR_GREEN COLOR_YELLOW COLOR_ORANGE COLOR_RED COLOR_CYAN \
             COLOR_PURPLE COLOR_BLUE; do
    content="${content//@${var}@/${!var}}"
  done
  
  # Variables de usuario
  content="${content//@HOME@/$TARGET_HOME}"
  content="${content//@FONT@/$DWM_FONT}"
  content="${content//@FONT_SIZE@/$DWM_FONT_SIZE}"
  content="${content//@KEYMAP@/$DWM_KEYMAP}"
  content="${content//@WALLPAPER@/$TARGET_HOME/.local/share/wallpapers/rocky.jpg}"
  content="${content//@THEME_NAME@/nord}"
  
  # Detectar hardware
  local eth_iface=$(detect_eth_iface)
  local wlan_iface=$(detect_wlan_iface)
  local battery=$(detect_battery)
  local ac_adapter=$(detect_ac_adapter)
  
  content="${content//@ETH_IFACE@/$eth_iface}"
  content="${content//@WLAN_IFACE@/$wlan_iface}"
  content="${content//@BATTERY@/$battery}"
  content="${content//@AC_ADAPTER@/$ac_adapter}"
  
  # Módulo wlan condicional
  if [[ -n "$wlan_iface" ]]; then
    content="${content//@WLAN_MODULE@/wlan}"
  else
    content="${content//@WLAN_MODULE@/}"
  fi
  
  # Módulo battery condicional (requiere batería Y adaptador)
  if [[ -n "$battery" && -n "$ac_adapter" && -d "/sys/class/power_supply/$battery" ]]; then
    content="${content//@BATTERY_MODULE@/battery}"
  else
    content="${content//@BATTERY_MODULE@/}"
  fi
  
  run_root install -D -m "$perms" /dev/stdin "$output" <<<"$content"
  ok "Renderizado: $output"
}

source_theme_vars() {
  if [[ -f "$PROJECT_ROOT/templates/colors/palette-nord.sh" ]]; then
    source "$PROJECT_ROOT/templates/colors/palette-nord.sh"
  fi
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
  echo ""
}

detect_ac_adapter() {
  for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
    if [[ -d "$ac" ]]; then
      basename "$ac"
      return
    fi
  done
  echo ""
}

make_user_dir() {
  run_root install -d -m 0755 "$1"
}