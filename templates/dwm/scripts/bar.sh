#!/bin/sh
# Barra status2d para dwm. Se instala en ~/.config/dwm/scripts/bar.sh.
# Dependencias: xsetroot, pactl, nmcli (opcionales), brightnessctl (no se usa aquí).
set -u
export LC_ALL=C

THEME="${XDG_CONFIG_HOME:-$HOME/.config}/dwm/scripts/bar_themes/gruvchad"
if [ -r "$THEME" ]; then
  . "$THEME"
else
  black="#1e2122"; white="#c7b89d"; grey="#2b2e2f"; blue="#6f8faf"
  green="#89b482"; red="#ec6b64"; orange="#d6b676"; yellow="#d1b171"
  pink="#cc7f94"
fi

interval=2
i=0
prev_total=0
prev_idle=0

cpu() {
  read -r _ user nice system idle iowait irq softirq steal rest < /proc/stat || return 0
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
  printf '^c%s^ ^b%s^ 󰻠 CPU ^c%s^ ^b%s^ %s%% ^b%s^' \
    "$black" "$green" "$white" "$grey" "$usage" "$black"
}

mem() {
  used=$(free -h | awk '/^Mem:/ {print $3}')
  [ -n "$used" ] || used="N/A"
  printf '^c%s^ ^b%s^ 󰍛 RAM ^c%s^ ^b%s^ %s ^b%s^' \
    "$black" "$blue" "$white" "$grey" "$used" "$black"
}

disk() {
  used=$(df -h / | awk 'NR==2 {print $5}')
  [ -n "$used" ] || used="N/A"
  printf '^c%s^ ^b%s^ 󰋊 SSD ^c%s^ ^b%s^ %s ^b%s^' \
    "$black" "$orange" "$white" "$grey" "$used" "$black"
}

vol() {
  if command -v pactl >/dev/null 2>&1; then
    mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
    level=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk 'NR==1 {print $5}')
  else
    mute=""; level=""
  fi
  [ -n "$level" ] || level="N/A"
  if [ "$mute" = "yes" ]; then
    printf '^c%s^ 󰖁 %s ^c%s^' "$red" "$level" "$white"
  else
    printf '^c%s^ 󰕾 %s ^c%s^' "$red" "$level" "$white"
  fi
}

wlan() {
  ssid=""
  if command -v nmcli >/dev/null 2>&1; then
    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1 == "yes" {print $2; exit}')
  fi
  if [ -n "$ssid" ]; then
    printf '^c%s^ 󰤨 %s ' "$blue" "$ssid"
  else
    printf '^c%s^ 󰤭 off ' "$grey"
  fi
}

battery() {
  bat=$(ls /sys/class/power_supply 2>/dev/null | grep -m1 '^BAT')
  if [ -n "$bat" ]; then
    cap=$(cat "/sys/class/power_supply/$bat/capacity" 2>/dev/null)
    [ -n "$cap" ] || cap="?"
    printf '^c%s^ 󰂄 %s%% ' "$green" "$cap"
  else
    printf '^c%s^ 󰚥 AC ' "$green"
  fi
}

updates() {
  n=$(apt list --upgradable 2>/dev/null | grep -c '\[upgradable\]' || true)
  if [ "${n:-0}" -gt 0 ]; then
    printf '^c%s^ 󰚰 %s ' "$yellow" "$n"
  else
    printf '^c%s^ 󰄬 ' "$green"
  fi
}

clock() {
  printf '^c%s^ 󰃭 %s ' "$white" "$(date '+%a %d %b  %H:%M')"
}

upd=$(updates)

while true; do
  if [ $((i % 1800)) -eq 0 ] && [ "$i" -ne 0 ]; then
    upd=$(updates)
  fi
  if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -name "$(cpu) $(mem) $(disk) $(vol) $(wlan) $(battery) $upd $(clock)" 2>/dev/null || true
  fi
  i=$((i + 1))
  sleep "$interval"
done
