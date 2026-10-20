#!/usr/bin/env bash
# Detección de sistema y hardware. Solo lectura.

OS_ID=""
OS_VERSION_ID=""
OS_PRETTY=""
ARCH=""
IS_VM=0
VIRT="none"
CPU_VENDOR="unknown"
CPU_MODEL="unknown"
HAS_INTEL=0
HAS_AMD=0
HAS_NVIDIA=0
GPU_SUMMARY=""
UEFI=0
SECURE_BOOT="unknown"
RESOLUTION="unknown"
CAMERAS=()
CAMERA_NAMES=()
HAS_UVC=0
BATTERY=""
BACKLIGHT=""
HAS_WIFI=0
HAS_AUDIO=0
ROOT_FSTYPE="unknown"
DWM_KEYMAP="${DWM_KEYMAP:-latam}"
DWM_FONT="${DWM_FONT:-JetBrainsMono Nerd Font}"
DWM_FONT_EXPLICIT="${DWM_FONT_EXPLICIT:-0}"
DWM_FONT_SIZE="${DWM_FONT_SIZE:-10}"
DWM_RESOLUTION="${DWM_RESOLUTION:-}"

detect_os() {
  if [[ ! -r /etc/os-release ]]; then
    die "No existe /etc/os-release"
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_VERSION_ID="${VERSION_ID:-unknown}"
  OS_PRETTY="${PRETTY_NAME:-unknown}"
}

require_debian_13() {
  if [[ "$OS_ID" != "debian" || "$OS_VERSION_ID" != "13" ]]; then
    die "Este instalador solo soporta Debian 13 (trixie). Detectado: ${OS_PRETTY}. No se modifica nada."
  fi
}

detect_arch() {
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64|amd64) : ;;
    *) die "Arquitectura no soportada: $ARCH. Se requiere x86_64." ;;
  esac
}

detect_virt() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt 2>/dev/null || true)
    if [[ -n "$VIRT" && "$VIRT" != "none" ]]; then
      IS_VM=1
    fi
  elif [[ -r /sys/hypervisor/type ]]; then
    VIRT=$(cat /sys/hypervisor/type 2>/dev/null || true)
    IS_VM=1
  fi
}

detect_cpu() {
  if command -v lscpu >/dev/null 2>&1; then
    CPU_VENDOR=$(LC_ALL=C lscpu 2>/dev/null | awk -F': +' '/Vendor ID/ {print $2; exit}')
    CPU_MODEL=$(LC_ALL=C lscpu 2>/dev/null | awk -F': +' '/Model name/ {print $2; exit}')
  fi
  # Fallback sin lscpu (instalación mínima antes de instalar util-linux).
  if [[ -z "$CPU_VENDOR" || "$CPU_VENDOR" == "unknown" ]]; then
    CPU_VENDOR=$(awk -F': ' '/^vendor_id/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || true)
  fi
  if [[ -z "$CPU_MODEL" || "$CPU_MODEL" == "unknown" ]]; then
    CPU_MODEL=$(awk -F': ' '/^model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || true)
  fi
  [[ -n "$CPU_VENDOR" ]] || CPU_VENDOR="unknown"
  [[ -n "$CPU_MODEL" ]] || CPU_MODEL="unknown"
  return 0
}

detect_gpu() {
  GPU_SUMMARY=""
  HAS_INTEL=0
  HAS_AMD=0
  HAS_NVIDIA=0
  if command -v lspci >/dev/null 2>&1; then
    GPU_SUMMARY=$(LC_ALL=C lspci -nn 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller' || true)
  fi
  # Fallback sysfs: pciutils puede no estar instalado en Debian minimal.
  local dev class vendor device fallback=""
  for dev in /sys/bus/pci/devices/*; do
    [[ -r "$dev/class" && -r "$dev/vendor" ]] || continue
    class=$(cat "$dev/class" 2>/dev/null || true)
    [[ "$class" == 0x03* ]] || continue
    vendor=$(cat "$dev/vendor" 2>/dev/null || true)
    device=$(cat "$dev/device" 2>/dev/null || true)
    case "$vendor" in
      0x8086) HAS_INTEL=1 ;;
      0x1002) HAS_AMD=1 ;;
      0x10de) HAS_NVIDIA=1 ;;
    esac
    fallback+="${fallback:+$'\n'}${vendor}:${device} [${class}]"
  done
  if [[ -z "$GPU_SUMMARY" && -n "$fallback" ]]; then
    GPU_SUMMARY="$fallback"
  fi
  # Si lspci no dio nombres, los flags de sysfs ya están puestos.
  if printf '%s' "$GPU_SUMMARY" | grep -qi 'Intel'; then HAS_INTEL=1; fi
  if printf '%s' "$GPU_SUMMARY" | grep -Eqi '(^|[^[:alnum:]])(AMD|ATI)([^[:alnum:]]|$)'; then HAS_AMD=1; fi
  if printf '%s' "$GPU_SUMMARY" | grep -qi 'NVIDIA'; then HAS_NVIDIA=1; fi
  return 0
}

detect_secure_boot() {
  if [[ -d /sys/firmware/efi ]]; then
    UEFI=1
    if command -v mokutil >/dev/null 2>&1; then
      local sb
      sb=$(mokutil --sb-state 2>/dev/null || true)
      case "$sb" in
        *"SecureBoot enabled"*) SECURE_BOOT="enabled" ;;
        *"SecureBoot disabled"*) SECURE_BOOT="disabled" ;;
        *) SECURE_BOOT="unknown" ;;
      esac
    else
      local f val
      for f in /sys/firmware/efi/efivars/SecureBoot-*; do
        [[ -e "$f" ]] || continue
        val=$(od -An -t u1 -j4 -N1 "$f" 2>/dev/null | tr -d ' ' || true)
        if [[ "$val" == "1" ]]; then
          SECURE_BOOT="enabled"
        elif [[ "$val" == "0" ]]; then
          SECURE_BOOT="disabled"
        fi
        break
      done
    fi
  else
    UEFI=0
    SECURE_BOOT="not-uefi"
  fi
}

detect_resolution() {
  if [[ -n "$DWM_RESOLUTION" ]]; then
    RESOLUTION="$DWM_RESOLUTION"
    return 0
  fi
  local status modes first
  for status in /sys/class/drm/card*-*/status; do
    [[ -r "$status" ]] || continue
    [[ "$(cat "$status" 2>/dev/null)" == "connected" ]] || continue
    modes="${status%/status}/modes"
    if [[ -r "$modes" ]]; then
      first=$(head -n 1 "$modes" 2>/dev/null || true)
      if [[ -n "$first" ]]; then
        DWM_RESOLUTION="$first"
        RESOLUTION="$first"
        return 0
      fi
    fi
  done
  if command -v xrandr >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    first=$(xrandr --current 2>/dev/null | awk '/ connected/ {getline; print $1; exit}')
    if [[ -n "$first" ]]; then
      DWM_RESOLUTION="$first"
      RESOLUTION="$first"
    fi
  fi
}

detect_camera() {
  CAMERAS=()
  CAMERA_NAMES=()
  local dev name
  for dev in /sys/class/video4linux/video*; do
    [[ -e "$dev" ]] || continue
    name=$(cat "$dev/name" 2>/dev/null || true)
    CAMERAS+=("/dev/${dev##*/}")
    CAMERA_NAMES+=("${name:-V4L2}")
  done
  if [[ -d /sys/bus/usb/drivers/uvcvideo ]] || lsmod 2>/dev/null | grep -q '^uvcvideo'; then
    HAS_UVC=1
  fi
}

detect_power() {
  local p
  for p in /sys/class/power_supply/BAT*; do
    [[ -e "$p" ]] || continue
    BATTERY="${p##*/}"
    break
  done
  for p in /sys/class/backlight/*; do
    [[ -e "$p" ]] || continue
    BACKLIGHT="${p##*/}"
    break
  done
  return 0
}

detect_network() {
  local p
  if command -v lspci >/dev/null 2>&1; then
    if lspci 2>/dev/null | grep -Eqi 'network controller|wireless'; then
      HAS_WIFI=1
    fi
  fi
  if [[ -d /sys/class/net ]]; then
    for p in /sys/class/net/*; do
      [[ "$(basename "$p")" == "lo" ]] && continue
      [[ -d "$p/wireless" ]] && HAS_WIFI=1
    done
  fi
  return 0
}

detect_audio() {
  if [[ -r /proc/asound/cards ]] && grep -q '^ *[0-9]' /proc/asound/cards 2>/dev/null; then
    HAS_AUDIO=1
  fi
}

detect_storage() {
  if command -v findmnt >/dev/null 2>&1; then
    ROOT_FSTYPE=$(findmnt -n -o FSTYPE / 2>/dev/null || true)
    [[ -n "$ROOT_FSTYPE" ]] || ROOT_FSTYPE="unknown"
  fi
}

resolve_target_user() {
  local entry user_home
  if [[ -z "$TARGET_USER" ]]; then
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
      TARGET_USER="$SUDO_USER"
    elif [[ "$EUID" -ne 0 ]]; then
      TARGET_USER=$(id -un)
    elif [[ "$DRY_RUN" != "1" && "$ASSUME_YES" != "1" && -t 0 ]]; then
      read -r -p "Usuario destino (no root): " TARGET_USER
      [[ -n "$TARGET_USER" ]] || die "No hay usuario destino."
    else
      die "No hay usuario destino. Ejecuta como usuario normal o usa --user <usuario>."
    fi
  fi
  if [[ "$TARGET_USER" == "root" ]]; then
    die "El usuario destino no puede ser root."
  fi
  entry=$(getent passwd "$TARGET_USER" || true)
  [[ -n "$entry" ]] || die "El usuario no existe: $TARGET_USER"
  user_home=$(printf '%s\n' "$entry" | cut -d: -f6)
  [[ -n "$user_home" ]] || die "El usuario $TARGET_USER no tiene home en /etc/passwd."
  if [[ -z "$TARGET_HOME" ]]; then
    TARGET_HOME="$user_home"
  fi
  # La sesión usa $HOME (el home real del login). Instalar las configuraciones
  # en otro directorio dejaría la sesión sin eww/dunst/picom/barra.
  if [[ "$(realpath -m -- "$TARGET_HOME")" != "$(realpath -m -- "$user_home")" ]]; then
    die "--home debe coincidir con el home real de $TARGET_USER ($user_home). El instalador no soporta homes alternativos."
  fi
  TARGET_UID=$(printf '%s\n' "$entry" | cut -d: -f3)
  TARGET_GID=$(printf '%s\n' "$entry" | cut -d: -f4)
  TARGET_GROUP=$(id -gn "$TARGET_USER")
  [[ -d "$TARGET_HOME" ]] || die "El home del usuario no existe: $TARGET_HOME"
  if [[ "$EUID" -ne 0 && "$TARGET_USER" != "$(id -un)" ]]; then
    die "Para instalar en otro usuario necesitas ejecutar con sudo/root."
  fi
  return 0
}

check_sudo() {
  if [[ "$EUID" -eq 0 ]] || dry_run; then
    return 0
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    die "No hay sudo. Ejecuta como root o instala sudo."
  fi
  info "Se necesitan permisos de administrador. sudo pedirá tu contraseña (no se almacena)."
  if ! sudo -v; then
    die "No se pudieron obtener permisos con sudo."
  fi
}

print_detection() {
  section "Detección"
  log "Sistema:       $OS_PRETTY"
  log "Arquitectura:  $ARCH"
  log "Virtualización: ${VIRT:-none}"
  log "CPU:           $CPU_MODEL ($CPU_VENDOR)"
  log "GPU:           $(printf '%s' "$GPU_SUMMARY" | tr '\n' ';' | sed 's/; /; /g' | sed 's/;$//')"
  log "Resolución:    ${RESOLUTION:-desconocida}"
  log "UEFI:          $UEFI (Secure Boot: $SECURE_BOOT)"
  log "Cámaras:       ${CAMERAS[*]:-ninguna}"
  log "Batería:       ${BATTERY:-AC}"
  log "Backlight:     ${BACKLIGHT:-no detectado}"
  log "WiFi:          $([[ $HAS_WIFI -eq 1 ]] && echo sí || echo no)"
  log "Audio ALSA:    $([[ $HAS_AUDIO -eq 1 ]] && echo sí || echo no)"
  log "Raíz:          $ROOT_FSTYPE"
  log "Usuario:       $TARGET_USER ($TARGET_HOME)"
}

detect_all() {
  detect_os
  detect_arch
  detect_virt
  detect_cpu
  detect_gpu
  detect_secure_boot
  detect_resolution
  detect_camera
  detect_power
  detect_network
  detect_audio
  detect_storage
  resolve_target_user
}
