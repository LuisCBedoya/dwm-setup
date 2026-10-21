#!/bin/sh
# Barra status2d para dwm (tema monolith)
# Se instala en ~/.config/dwm/scripts/bar.sh
# Dependencias: xsetroot, pamixer, nmcli, brightnessctl
# Carga colores desde bar_theme generado por install.sh

set -u
export LC_ALL=C

THEME="${XDG_CONFIG_HOME:-$HOME/.config}/dwm/scripts/bar_themes/@THEME_NAME@"
if [ -r "$THEME" ]; then
  . "$THEME"
else
  # Fallback hardcoded (monolith)
  BG="#151518"; FG="#d8d4cc"; ACCENT="#b4a7d6"; ACCENT_ALT="#8fa8c8"
  GREEN="#9eb88a"; YELLOW="#d8c08a"; ORANGE="#d09a72"; RED="#c97f7f"
  CYAN="#8fbfc7"; MUTED="#8a8a92"; DIM="#5c5c64"; BORDER="#2b2b32"
  C_BG="^c$BG^"; C_FG="^c$FG^"; C_ACCENT="^c$ACCENT^"; C_ACCENT_ALT="^c$ACCENT_ALT^"
  C_GREEN="^c$GREEN^"; C_YELLOW="^c$YELLOW^"; C_ORANGE="^c$ORANGE^"; C_RED="^c$RED^"
  C_CYAN="^c$CYAN^"; C_MUTED="^c$MUTED^"; C_DIM="^c$DIM^"; C_BORDER="^c$BORDER^"
  B_BG="^b$BG^"; B_FG="^b$FG^"; B_ACCENT="^b$ACCENT^"
fi

interval=2
i=0
prev_total=0
prev_idle=0

# Helper: color según umbral (low/med/high/crit)
color_for() {
  val="$1"
  if [ "$val" -lt 30 ]; then echo "$GREEN"
  elif [ "$val" -lt 60 ]; then echo "$YELLOW"
  elif [ "$val" -lt 85 ]; then echo "$ORANGE"
  else echo "$RED"; fi
}

# CPU usage %
cpu() {
  read -r _ user nice system idle iowait irq softirq steal rest < /proc/stat 2>/dev/null || return 0
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  idle_all=$((idle + iowait))
  dt=$((total - prev_total))
  di=$((idle_all - prev_idle))
  prev_total=$total
  prev_idle=$idle_all
  if [ "$dt" -gt 0 ]; then
    usage=$((100 * (dt - di) / dt))
  else
    usage=0
  fi
  color=$(color_for "$usage")
  printf '%s%s 󰻠 CPU %s%s %s%% %s' "$C_BG" "$B_BG" "$C_FG" "$B_BG" "$usage" "$C_BG"
}

# RAM usada (human readable)
mem() {
  used=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')
  [ -n "$used" ] || used="N/A"
  printf '%s%s 󰍛 RAM %s%s %s %s' "$C_BG" "$B_BG" "$C_FG" "$B_BG" "$used" "$C_BG"
}

# Disco raíz %
disk() {
  used=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')
  [ -n "$used" ] || used="N/A"
  # Extraer número para color
  num=$(echo "$used" | tr -d '%')
  [ "$num" -eq "$num" ] 2>/dev/null && color=$(color_for "$num") || color="$ACCENT"
  printf '%s%s 󰋊 SSD %s%s %s %s' "$C_BG" "$B_BG" "$C_FG" "$B_BG" "$used" "$C_BG"
}

# Volumen (pamixer)
vol() {
  if command -v pamixer >/dev/null 2>&1; then
    mute=$(pamixer --get-mute 2>/dev/null)
    level=$(pamixer --get-volume 2>/dev/null)
  else
    mute="false"; level="N/A"
  fi
  [ -n "$level" ] || level="N/A"
  if [ "$mute" = "true" ]; then
    printf '%s 󰖁 %s %s' "$C_RED" "$level" "$C_FG"
  else
    printf '%s 󰕾 %s %s' "$C_ACCENT" "$level" "$C_FG"
  fi
}

# WiFi
wlan() {
  ssid=""
  if command -v nmcli >/dev/null 2>&1; then
    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1 == "yes" {print $2; exit}')
  fi
  if [ -n "$ssid" ]; then
    printf '%s 󰤨 %s %s' "$C_ACCENT_ALT" "$ssid" "$C_FG"
  else
    printf '%s 󰤭 off %s' "$C_MUTED" "$C_FG"
  fi
}

# Batería
battery() {
  bat=$(ls /sys/class/power_supply 2>/dev/null | grep -m1 '^BAT')
  if [ -n "$bat" ]; then
    cap=$(cat "/sys/class/power_supply/$bat/capacity" 2>/dev/null)
    [ -n "$cap" ] || cap="?"
    status=$(cat "/sys/class/power_supply/$bat/status" 2>/dev/null)
    case "$status" in
      Charging) icon="󰂄" ;;
      Full) icon="󰁹" ;;
      *) 
        if [ "$cap" -ge 90 ]; then icon="󰁹"
        elif [ "$cap" -ge 70 ]; then icon="󰂀"
        elif [ "$cap" -ge 50 ]; then icon="󰁿"
        elif [ "$cap" -ge 30 ]; then icon="󰁾"
        elif [ "$cap" -ge 15 ]; then icon="󰁽"
        else icon="󰂃"; fi
        ;;
    esac
    color=$(color_for "$cap")
    printf '%s %s %s%% %s' "$color" "$icon" "$cap" "$C_FG"
  else
    printf '%s 󰚥 AC %s' "$C_GREEN" "$C_FG"
  fi
}

# Actualizaciones pendientes
updates() {
  n=$(apt list --upgradable 2>/dev/null | grep -c '\[upgradable\]' || true)
  if [ "${n:-0}" -gt 0 ]; then
    printf '%s 󰚰 %s %s' "$C_YELLOW" "$n" "$C_FG"
  else
    printf '%s 󰄬 %s' "$C_GREEN" "$C_FG"
  fi
}

# Reloj
clock() {
  printf '%s 󰃭 %s' "$C_FG" "$(date '+%a %d %b  %H:%M')"
}

# Cache de updates (cada 30 min = 1800/2 = 900 iteraciones)
upd=$(updates)

while true; do
  if [ $((i % 900)) -eq 0 ] && [ "$i" -ne 0 ]; then
    upd=$(updates)
  fi
  if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -name "$(cpu) $(mem) $(disk) $(vol) $(wlan) $(battery) $upd $(clock)" 2>/dev/null || true
  fi
  i=$((i + 1))
  sleep "$interval"
done