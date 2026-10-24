#!/usr/bin/env bash
# Instalador fase 1b: Debian 13 minimal + Xorg + bspwm + sxhkd + polybar.
#
# Uso normal:
#   ./install.sh
#
# Opcional:
#   ./install.sh --dry-run    Comprobar y mostrar el plan sin modificar nada
#   ./install.sh --yes        Modo no interactivo (no añade repositorios)
#
# El instalador no guarda contraseñas, hace backups y no toca fases futuras.
set -Eeuo pipefail
umask 022
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="$SCRIPT_DIR"
export PROJECT_ROOT

# shellcheck source=lib/common.sh
source "$PROJECT_ROOT/lib/common.sh"
# shellcheck source=lib/detect.sh
source "$PROJECT_ROOT/lib/detect.sh"
# shellcheck source=lib/packages.sh
source "$PROJECT_ROOT/lib/packages.sh"
# shellcheck source=lib/bspwm.sh
source "$PROJECT_ROOT/lib/bspwm.sh"
# shellcheck source=lib/sxhkd.sh
source "$PROJECT_ROOT/lib/sxhkd.sh"
# shellcheck source=lib/polybar.sh
source "$PROJECT_ROOT/lib/polybar.sh"
# shellcheck source=lib/picom.sh
source "$PROJECT_ROOT/lib/picom.sh"
# shellcheck source=lib/dunst.sh
source "$PROJECT_ROOT/lib/dunst.sh"
# shellcheck source=lib/rofi.sh
source "$PROJECT_ROOT/lib/rofi.sh"
# shellcheck source=lib/kitty.sh
source "$PROJECT_ROOT/lib/kitty.sh"
# shellcheck source=lib/config.sh
source "$PROJECT_ROOT/lib/config.sh"
# shellcheck source=lib/verify.sh
source "$PROJECT_ROOT/lib/verify.sh"
# shellcheck source=lib/theme.sh
source "$PROJECT_ROOT/lib/theme.sh"
# shellcheck source=lib/audio.sh
source "$PROJECT_ROOT/lib/audio.sh"

usage() {
  cat <<'EOF'
Instalador de fase 1b: escritorio bspwm + polybar en Debian 13.

Uso normal:
  ./install.sh              Instalación guiada (recomendado)
  ./install.sh --dry-run    Comprobar y mostrar el plan sin modificar
  ./install.sh --yes        Modo no interactivo (no añade repositorios)
  ./install.sh --help
  ./install.sh --version

El instalador detecta usuario, home, GPU, Secure Boot, resolución, cámara,
batería y red. Solo pregunta cuando hay una decisión real, por ejemplo qué
hacer si faltan componentes APT.

Opciones avanzadas (automatización; normalmente no necesarias):
  --user USUARIO, --home RUTA, --nvidia, --no-nvidia,
  --cuda, --no-cuda,
  --headset-quirk, --no-headset-quirk,
  --keymap MAPA, --font FUENTE, --font-size N, --resolution WxH, --debug

Tema: Nord (vendorizado desde tu repo Bspwm)

Sesión: startx manual desde TTY (no se instala display manager).
Fases futuras (IDE, navegadores, música) no se instalan desde aquí.
EOF
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      -y|--yes) ASSUME_YES=1 ;;
      --user)
        [[ $# -ge 2 ]] || die "--user requiere un valor"
        TARGET_USER="$2"; shift
        ;;
      --user=*) TARGET_USER="${1#*=}" ;;
      --home)
        [[ $# -ge 2 ]] || die "--home requiere un valor"
        TARGET_HOME="$2"; shift
        ;;
      --home=*) TARGET_HOME="${1#*=}" ;;
      --nvidia) INSTALL_NVIDIA="yes" ;;
      --no-nvidia) INSTALL_NVIDIA="no" ;;
      --cuda) INSTALL_CUDA="yes" ;;
      --no-cuda) INSTALL_CUDA="no" ;;
      --headset-quirk) HEADSET_QUIRK_MODE="yes" ;;
      --no-headset-quirk) HEADSET_QUIRK_MODE="no" ;;
      --keymap)
        [[ $# -ge 2 ]] || die "--keymap requiere un valor"
        DWM_KEYMAP="$2"; shift
        ;;
      --keymap=*) DWM_KEYMAP="${1#*=}" ;;
      --font)
        [[ $# -ge 2 ]] || die "--font requiere un valor"
        DWM_FONT="$2"; DWM_FONT_EXPLICIT=1; shift
        ;;
      --font=*) DWM_FONT="${1#*=}"; DWM_FONT_EXPLICIT=1 ;;
      --font-size)
        [[ $# -ge 2 ]] || die "--font-size requiere un valor"
        DWM_FONT_SIZE="$2"; shift
        ;;
      --font-size=*) DWM_FONT_SIZE="${1#*=}" ;;
      --resolution)
        [[ $# -ge 2 ]] || die "--resolution requiere un valor"
        DWM_RESOLUTION="$2"; shift
        ;;
      --resolution=*) DWM_RESOLUTION="${1#*=}" ;;
      --debug) DWM_DEBUG=1 ;;
      -h|--help) usage; exit 0 ;;
      --version) printf 'dwm-setup 0.3.0 (fase 1b: bspwm+polybar)\n'; exit 0 ;;
      *) die "Opción desconocida: $1 (usa --help)" ;;
    esac
    shift
  done
}

validate_options() {
  if ! [[ "$DWM_FONT_SIZE" =~ ^[0-9]+$ ]] || ((DWM_FONT_SIZE < 6 || DWM_FONT_SIZE > 40)); then
    die "--font-size debe ser un entero entre 6 y 40 (recibido: $DWM_FONT_SIZE)"
  fi
  [[ -n "$DWM_FONT" ]] || die "--font no puede estar vacío"
  [[ -n "$DWM_KEYMAP" ]] || die "--keymap no puede estar vacío"
  if [[ -n "$DWM_RESOLUTION" && ! "$DWM_RESOLUTION" =~ ^[0-9]+x[0-9]+$ ]]; then
    die "--resolution debe tener el formato WxH, por ejemplo 1366x768 (recibido: $DWM_RESOLUTION)"
  fi
  if [[ -n "$TARGET_HOME" ]]; then
    [[ "$TARGET_HOME" == /* ]] || die "--home debe ser una ruta absoluta: $TARGET_HOME"
    [[ "$TARGET_HOME" != "/" ]] || die "--home no puede ser /"
  fi
}

check_project_layout() {
  local path
  local -a required=(
    "$PROJECT_ROOT/lib/common.sh"
    "$PROJECT_ROOT/lib/detect.sh"
    "$PROJECT_ROOT/lib/packages.sh"
    "$PROJECT_ROOT/lib/bspwm.sh"
    "$PROJECT_ROOT/lib/sxhkd.sh"
    "$PROJECT_ROOT/lib/polybar.sh"
    "$PROJECT_ROOT/lib/picom.sh"
    "$PROJECT_ROOT/lib/dunst.sh"
    "$PROJECT_ROOT/lib/rofi.sh"
    "$PROJECT_ROOT/lib/kitty.sh"
    "$PROJECT_ROOT/lib/config.sh"
    "$PROJECT_ROOT/lib/verify.sh"
    "$PROJECT_ROOT/lib/theme.sh"
    "$PROJECT_ROOT/lib/audio.sh"
    "$PROJECT_ROOT/bin/desktop-safe"
    "$PROJECT_ROOT/bin/desktop-doctor"
    "$PROJECT_ROOT/templates/colors/base.sh"
    "$PROJECT_ROOT/templates/colors/palette-nord.sh"
    "$PROJECT_ROOT/templates/bspwm/bspwmrc.in"
    "$PROJECT_ROOT/templates/bspwm/autostart.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/bspwm_resize.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/low_bat_notifier.sh.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/keybindings_rofi.sh.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/screenshot.sh.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/screenshot_region.sh.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/screenshot_full.sh.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/audio-switch.sh.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/audio-watch.sh.in"
    "$PROJECT_ROOT/templates/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh.in"
    "$PROJECT_ROOT/templates/sxhkd/sxhkdrc.in"
    "$PROJECT_ROOT/templates/polybar/config.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/logo.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/bspwm.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/updates.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/polypomo.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/temp.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/memory.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/cpu.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/xkeyboard.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/network.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/battery.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/pipewire.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/date.ini.in"
    "$PROJECT_ROOT/templates/polybar/modules/dots.ini.in"
    "$PROJECT_ROOT/templates/polybar/scripts/updates-apt.sh.in"
    "$PROJECT_ROOT/templates/polybar/scripts/polypomo.in"
    "$PROJECT_ROOT/templates/polybar/scripts/network-status.sh.in"
    "$PROJECT_ROOT/templates/polybar/scripts/launch.sh.in"
    "$PROJECT_ROOT/templates/picom/picom.conf.in"
    "$PROJECT_ROOT/templates/dunst/dunstrc.in"
    "$PROJECT_ROOT/templates/dunst/notification-sound.sh.in"
    "$PROJECT_ROOT/templates/rofi/powermenu.rasi.in"
    "$PROJECT_ROOT/templates/kitty/kitty.conf.in"
    "$PROJECT_ROOT/templates/modprobe/alsa-fx504.conf"
    "$PROJECT_ROOT/assets/wallpaper.jpg"
  )
  for path in "${required[@]}"; do
    [[ -e "$path" ]] || die "Falta un archivo del proyecto: $path"
  done
}

print_summary() {
  if dry_run; then
    section "Dry-run completado"
    cat <<EOF
No se modificó el sistema.
Usuario destino: $TARGET_USER
Home:            $TARGET_HOME
Log:             ${LOG_FILE:-sin log en dry-run}

Para ejecutar de verdad:
  ./install.sh
EOF
    return 0
  fi
  section "Instalación completada"
  cat <<EOF
Fase 1b instalada para: $TARGET_USER
Home:                   $TARGET_HOME
Log:                    $LOG_FILE

Próximo paso:
  1. Reinicia el equipo: sudo reboot
  2. En TTY1 entra con tu usuario y ejecuta: startx
  3. Comprueba el escritorio: desktop-doctor
  4. Prueba la cámara real: desktop-doctor --camera
  5. Si algo falla, entra por TTY y usa: startx

Atajos principales:
  Super+Return      kitty
  Super+d           rofi (drun)
  Super+Shift+b     firefox (no instalado en fase 1)
  Super+Shift+e     VS Code (no instalado en fase 1)
  Super+Shift+f     thunar
  Super+Shift+l     bloquear
  Print             pantalla completa al portapapeles
  Super+Print       menú de capturas
  Super+{h,j,k,l}   foco ventanas
  Super+Shift+{h,j,k,l} mover ventanas
  Super+{1-4}       ir a escritorio
  Super+Shift+{1-4} mover ventana a escritorio
  Super+Alt+{h,j,k,l} redimensionar
  Super+m           monocle/tiled
  Super+f           fullscreen
  XF86AudioRaise/Lower/Mute   volumen
  XF86MonBrightnessUp/Down    brillo

Notas:
  - No hay auto-login: la sesión se inicia a mano con startx.
  - El grupo video/audio/render requiere cerrar sesión y volver a entrar.
  - Los USB se montan solos y solo notifican; no se abre ninguna app.
  - No se instala ningún IDE, navegador ni reproductor de música.
EOF
  if [[ "$REPO_MODIFIED" -eq 1 ]]; then
    printf '  - Componentes APT añadidos; backup de fuentes: %s\n' "$ROOT_BACKUP_DIR"
  fi
  if [[ "${REBOOT_REQUIRED:-0}" -eq 1 ]]; then
    printf '  - Quirk ALC255 instalado; reinicia para aplicar el micrófono del jack combo.\n'
  fi
}

main() {
  parse_args "$@"

  validate_options
  check_project_layout

  # Debian 13 y x86_64 antes de pedir sudo o resolver el usuario.
  detect_os
  require_debian_13
  detect_arch

  # Si no se ejecuta como root, se pide sudo ahora y no se vuelve a guardar nada.
  check_sudo

  detect_all

  # Crea ~/.config, ~/.local, ~/.config-backup con el propietario correcto.
  prepare_user_dirs

  if ! dry_run; then
    LOG_HOME="$TARGET_HOME"
    init_logging
  fi

  show_banner
  print_detection

  # Cargar paleta Nord
  load_theme "nord"

  # Los backups deben existir ANTES de cualquier escritura de configuración.
  local backup_ts
  backup_ts=$(timestamp)
  ROOT_BACKUP_DIR="/var/backups/dwm-setup/$backup_ts"
  USER_BACKUP_DIR="$TARGET_HOME/.config-backup/dwm-setup/$backup_ts"

  make_user_dir "$TARGET_HOME/.config-backup"
  make_user_dir "$TARGET_HOME/.config-backup/dwm-setup"
  make_user_dir "$USER_BACKUP_DIR"
  run_root install -d -m 0755 "$ROOT_BACKUP_DIR"
  backup_existing_configs

  preflight_repos

  if ! confirm "¿Aplicar los cambios y continuar con la instalación de la fase 1b?"; then
    if [[ "$REPO_MODIFIED" -eq 1 ]]; then
      info "Cancelado. Los componentes APT añadidos se conservan en el backup: $ROOT_BACKUP_DIR"
    else
      info "Cancelado por el usuario. No se modificó el sistema."
    fi
    exit 0
  fi

  install_packages
  install_headset_quirk
  install_bspwm
  install_sxhkd
  install_polybar
  install_picom
  install_dunst
  install_rofi
  install_kitty
  install_user_configs

  if ! dry_run; then
    if ! verify_install; then
      die "La verificación final falló. Revisa los errores y el log antes de reiniciar."
    fi
  else
    section "Dry-run"
    info "No se modificó el sistema. Las acciones anteriores son el plan completo."
  fi
  print_summary
}

main "$@"