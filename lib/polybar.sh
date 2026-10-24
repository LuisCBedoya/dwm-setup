#!/usr/bin/env bash
# lib/polybar.sh — Instalación de polybar (config, modules, scripts, launch)

install_polybar() {
  local home="$TARGET_HOME"

  section "Instalando polybar"

  make_user_dir "$home/.config/polybar/modules"
  make_user_dir "$home/.config/polybar/scripts"

  log "Renderizando polybar desde templates"
  render_polybar_templates "$home"
  render_launch_script "$home"

  ok "polybar instalado"
}

render_polybar_templates() {
  local home="$1"

  local eth_iface
  local wlan_iface
  local battery
  local ac_adapter
  eth_iface=$(polybar_detect_eth_iface)
  wlan_iface=$(polybar_detect_wlan_iface)
  battery=$(polybar_detect_battery)
  ac_adapter=$(polybar_detect_ac_adapter)

  local battery_module=""
  if [[ -n "$battery" && -n "$ac_adapter" && -d "/sys/class/power_supply/$battery" ]]; then
    battery_module="battery"
  fi

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
    "BATTERY_MODULE=$battery_module"
  )

  render_theme_template "$PROJECT_ROOT/templates/polybar/config.ini.in" \
    "$home/.config/polybar/config.ini" 0644 "${common_vars[@]}"

  local modules=(
    "modules/logo.ini"
    "modules/bspwm.ini"
    "modules/updates.ini"
    "modules/polypomo.ini"
    "modules/temp.ini"
    "modules/memory.ini"
    "modules/cpu.ini"
    "modules/network.ini"
    "modules/battery.ini"
    "modules/pipewire.ini"
    "modules/date.ini"
    "modules/dots.ini"
  )

  local m
  for m in "${modules[@]}"; do
    render_theme_template "$PROJECT_ROOT/templates/polybar/$m.in" \
      "$home/.config/polybar/$m" 0644 "${common_vars[@]}"
  done

  local scripts=("scripts/updates-apt.sh" "scripts/polypomo" "scripts/network-status.sh")
  local s
  for s in "${scripts[@]}"; do
    render_theme_template "$PROJECT_ROOT/templates/polybar/$s.in" \
      "$home/.config/polybar/$s" 0755 "${common_vars[@]}"
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

  run_root install -D -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    /dev/stdin "$launch" <<<"$content"
  ok "Generado: $launch"
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
