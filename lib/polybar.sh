#!/usr/bin/env bash
# lib/polybar.sh — Instalación de polybar (config, modules, scripts, launch)

install_logo_font() {
  local src="$PROJECT_ROOT/assets/desktop-logo.ttf"
  local dest="/usr/local/share/fonts/dwm-setup/desktop-logo.ttf"

  if dry_run; then
    log "[dry-run] Instalando fuente del logo: $dest"
    return 0
  fi

  run_root install -D -m 0644 "$src" "$dest"
  run_root fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || \
    warn "No se pudo actualizar la caché de fuentes"

  if fc-list :charset=e000 2>/dev/null | grep -qi 'DesktopLogo'; then
    debug "Fuente del logo disponible: DesktopLogo"
  else
    warn "DesktopLogo no aparece en fc-list; el logo puede no renderizar"
  fi
}

install_polybar() {
  local home="$TARGET_HOME"

  section "Instalando polybar"

  install_logo_font

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

  # Detectar hardware una sola vez
  # Nota: funciones propias (polybar_detect_*) para no pisar las de lib/bspwm.sh.
  local eth_iface
  local wlan_iface
  local battery
  local ac_adapter
  eth_iface=$(polybar_detect_eth_iface)
  wlan_iface=$(polybar_detect_wlan_iface)
  battery=$(polybar_detect_battery)
  ac_adapter=$(polybar_detect_ac_adapter)

  # Módulo wlan condicional
  local wlan_module=""
  if [[ -n "$wlan_iface" ]]; then
    wlan_module="wlan"
  fi

  # Módulo battery condicional (requiere batería Y adaptador)
  local battery_module=""
  if [[ -n "$battery" && -n "$ac_adapter" && -d "/sys/class/power_supply/$battery" ]]; then
    battery_module="battery"
  fi

  # Configuración común para render_theme_template
  local common_vars=(
    "HOME=$TARGET_HOME"
    "FONT=$DWM_FONT"
    "FONT_SIZE=$DWM_FONT_SIZE"
    "KEYMAP=$DWM_KEYMAP"
    "WALLPAPER=$TARGET_HOME/.local/share/wallpapers/rocky.jpg"
    "THEME_NAME=nord"
    "ETH_IFACE=$eth_iface"
    "WLAN_IFACE=$wlan_iface"
    "BATTERY=$battery"
    "AC_ADAPTER=$ac_adapter"
    "WLAN_MODULE=$wlan_module"
    "BATTERY_MODULE=$battery_module"
  )

  # config.ini principal
  render_theme_template "$PROJECT_ROOT/templates/polybar/config.ini.in" "$home/.config/polybar/config.ini" 0644 "${common_vars[@]}"

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
    "modules/dots.ini"
  )

  for m in "${modules[@]}"; do
    render_theme_template "$PROJECT_ROOT/templates/polybar/$m.in" "$home/.config/polybar/$m" 0644 "${common_vars[@]}"
  done

  # Scripts
  local scripts=("scripts/updates-apt.sh" "scripts/polypomo")
  for s in "${scripts[@]}"; do
    render_theme_template "$PROJECT_ROOT/templates/polybar/$s.in" "$home/.config/polybar/$s" 0755 "${common_vars[@]}"
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

# Detección de hardware propia de polybar.
# Se listan todas las interfaces, no solo las que están UP: así wlo1 (DOWN por
# falta de conexión) sigue teniendo módulo y muestra su estado.
polybar_detect_eth_iface() {
  ip -br link show 2>/dev/null | awk '/^en/ {print $1; exit}'
}

polybar_detect_wlan_iface() {
  ip -br link show 2>/dev/null | awk '/^wl/ {print $1; exit}'
}

polybar_detect_battery() {
  local bat
  for bat in /sys/class/power_supply/BAT*; do
    if [[ -d "$bat" ]]; then
      basename "$bat"
      return
    fi
  done
  echo ""
}

polybar_detect_ac_adapter() {
  local ac
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
