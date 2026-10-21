#!/usr/bin/env bash
# Instalador de la fase 1: Debian 13 minimal + Xorg + Ly + chadwm + eww.
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
# shellcheck source=lib/dwm.sh
source "$PROJECT_ROOT/lib/dwm.sh"
# shellcheck source=lib/eww.sh
source "$PROJECT_ROOT/lib/eww.sh"
# shellcheck source=lib/ly.sh
source "$PROJECT_ROOT/lib/ly.sh"
# shellcheck source=lib/config.sh
source "$PROJECT_ROOT/lib/config.sh"
# shellcheck source=lib/verify.sh
source "$PROJECT_ROOT/lib/verify.sh"
# shellcheck source=lib/theme.sh
source "$PROJECT_ROOT/lib/theme.sh"

usage() {
  cat <<'EOF'
Instalador de fase 1: escritorio dwm + eww en Debian 13.

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
  --user USUARIO, --home RUTA, --rebuild, --nvidia, --no-nvidia,
  --cuda, --no-cuda,
  --keymap MAPA, --font FUENTE, --font-size N, --resolution WxH, --debug
  --theme TEMA              Tema de colores (monolith, gruvbox)

Temas disponibles:
  monolith (default) — Monocromático con acentos apagados
  gruvbox — Gruvbox Material

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
      --rebuild) FORCE_REBUILD=1 ;;
      --nvidia) INSTALL_NVIDIA="yes" ;;
      --no-nvidia) INSTALL_NVIDIA="no" ;;
      --cuda) INSTALL_CUDA="yes" ;;
      --no-cuda) INSTALL_CUDA="no" ;;
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
      --theme)
        [[ $# -ge 2 ]] || die "--theme requiere un valor"
        DWM_THEME="$2"; shift
        ;;
      --theme=*) DWM_THEME="${1#*=}" ;;
      --debug) DWM_DEBUG=1 ;;
      -h|--help) usage; exit 0 ;;
      --version) printf 'dwm-setup 0.1.0 (fase 1)\n'; exit 0 ;;
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
  # Validar tema
  if [[ -n "${DWM_THEME:-}" ]]; then
    if [[ ! -f "$PROJECT_ROOT/templates/colors/palette-${DWM_THEME}.sh" ]]; then
      die "Tema '$DWM_THEME' no encontrado. Temas disponibles: $(list_themes | awk '{print $1}' | tr '\n' ' ')"
    fi
  fi
}

check_project_layout() {
  local path
  local -a required=(
    "$PROJECT_ROOT/lib/common.sh"
    "$PROJECT_ROOT/lib/detect.sh"
    "$PROJECT_ROOT/lib/packages.sh"
    "$PROJECT_ROOT/lib/dwm.sh"
    "$PROJECT_ROOT/lib/eww.sh"
    "$PROJECT_ROOT/lib/ly.sh"
    "$PROJECT_ROOT/lib/config.sh"
    "$PROJECT_ROOT/lib/verify.sh"
    "$PROJECT_ROOT/lib/theme.sh"
    "$PROJECT_ROOT/bin/dwm-safe"
    "$PROJECT_ROOT/bin/dwm-doctor"
    "$PROJECT_ROOT/templates/colors/base.sh"
    "$PROJECT_ROOT/templates/colors/palette-monolith.sh"
    "$PROJECT_ROOT/templates/colors/palette-gruvbox.sh"
    "$PROJECT_ROOT/templates/dwm/config.h.in"
    "$PROJECT_ROOT/templates/dwm/run.sh"
    "$PROJECT_ROOT/templates/dwm/environment.in"
    "$PROJECT_ROOT/templates/dwm/dwm.desktop.in"
    "$PROJECT_ROOT/templates/dwm/xinitrc"
    "$PROJECT_ROOT/templates/dwm/picom.conf.in"
    "$PROJECT_ROOT/templates/dwm/dunst/dunstrc.in"
    "$PROJECT_ROOT/templates/dwm/rofi/colors.rasi.in"
    "$PROJECT_ROOT/templates/dwm/rofi/fonts.rasi"
    "$PROJECT_ROOT/templates/dwm/rofi/config.rasi"
    "$PROJECT_ROOT/templates/dwm/scripts/bar.sh"
    "$PROJECT_ROOT/templates/dwm/scripts/bar_themes/gruvchad"
    "$PROJECT_ROOT/templates/dwm/eww/eww.yuck"
    "$PROJECT_ROOT/templates/dwm/eww/vars.yuck.in"
    "$PROJECT_ROOT/templates/dwm/eww/widgets.yuck"
    "$PROJECT_ROOT/templates/dwm/eww/eww.scss.in"
    "$PROJECT_ROOT/templates/dwm/eww/scripts/battery"
    "$PROJECT_ROOT/templates/dwm/eww/scripts/brightness"
    "$PROJECT_ROOT/templates/dwm/eww/scripts/temp"
    "$PROJECT_ROOT/templates/dwm/eww/scripts/updates"
    "$PROJECT_ROOT/templates/dwm/eww/scripts/uptime"
    "$PROJECT_ROOT/templates/dwm/eww/scripts/volume"
    "$PROJECT_ROOT/templates/dwm/eww/scripts/wifi"
    "$PROJECT_ROOT/templates/kitty/kitty.conf"
    "$PROJECT_ROOT/assets/wallpaper.jpg"
    "$PROJECT_ROOT/src/chadwm/chadwm/Makefile"
  )
  for path in "${required[@]}"; do
    [[ -e "$path" ]] || die "Falta un archivo del proyecto: $path"
  done
  if [[ ! -f "$PROJECT_ROOT/src/eww/Cargo.toml" ]]; then
    warn "No existe src/eww; se intentará clonar eww v0.6.0 en /var/cache/dwm-setup."
  fi
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
Fase 1 instalada para: $TARGET_USER
Home:                  $TARGET_HOME
Log:                   $LOG_FILE

Próximo paso:
  1. Reinicia el equipo: sudo reboot
  2. En Ly elige la sesión "dwm" y entra con tu usuario.
  3. Comprueba el escritorio: dwm-doctor
  4. Prueba la cámara real: dwm-doctor --camera
  5. Si algo falla, entra por TTY y usa: startx

Atajos principales:
  Mod+Return      kitty
  Mod+E           pcmanfm
  Mod+Shift+D     rofi
  Mod+Shift+S     flameshot
  Mod+grave       dashboard eww
  Mod+Escape      menú de energía
  Mod+Shift+L     bloquear

Notas:
  - El grupo video/audio/render requiere cerrar sesión y volver a entrar.
  - Los USB se montan solos y solo notifican; no se abre ninguna app.
  - No se instala ningún IDE, navegador ni reproductor de música.
EOF
  if [[ "$REPO_MODIFIED" -eq 1 ]]; then
    printf '  - Componentes APT añadidos; backup de fuentes: %s\n' "$ROOT_BACKUP_DIR"
  fi
}

main() {
  parse_args "$@"

  # Tema por defecto
  DWM_THEME="${DWM_THEME:-monolith}"

  validate_options
  check_project_layout

  # Cargar tema temprano para que dry-run muestre los colores correctos
  load_theme "$DWM_THEME"

  # Debian 13 y x86_64 antes de pedir sudo o resolver el usuario.
  detect_os
  require_debian_13
  detect_arch

  # Si no se ejecuta como root, se pide sudo ahora y no se vuelve a guardar nada.
  check_sudo

  detect_all

  if ! dry_run; then
    LOG_HOME="$TARGET_HOME"
    init_logging
  fi

  show_banner
  print_detection

  # Generar assets de tema (bar_theme, rofi colors, eww scss/vars, dunstrc, picom, kitty)
  generate_all_theme_assets "$DWM_THEME"

  # Los backups deben existir antes del preflight: si el usuario autoriza
  # añadir componentes APT, add_apt_components() guarda sources.list primero.
  local backup_ts
  backup_ts=$(timestamp)
  ROOT_BACKUP_DIR="/var/backups/dwm-setup/$backup_ts"
  USER_BACKUP_DIR="$TARGET_HOME/.config-backup/dwm-setup/$backup_ts"

  # Crear directorio de backup de usuario con propietario correcto ANTES de usarlo.
  # Evita que ~/.config-backup/dwm-setup/<timestamp> quede root:root.
  if ! dry_run; then
    run_root install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "$USER_BACKUP_DIR"
  fi

  preflight_repos

  if ! confirm "¿Aplicar los cambios y continuar con la instalación de la fase 1?"; then
    if [[ "$REPO_MODIFIED" -eq 1 ]]; then
      info "Cancelado. Los componentes APT añadidos se conservan en el backup: $ROOT_BACKUP_DIR"
    else
      info "Cancelado por el usuario. No se modificó el sistema."
    fi
    exit 0
  fi

  install_packages
  build_dwm
  build_eww
  install_user_configs
  install_ly

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
