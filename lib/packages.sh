#!/usr/bin/env bash
# Grupos de paquetes de la fase 1b. Debian 13 (trixie).

BASE_PKGS=(
  build-essential git curl ca-certificates xz-utils unzip tar file pkg-config
  procps pciutils usbutils dmidecode inxi bash-completion sudo less rsync
  python3
)

XORG_PKGS=(
  xserver-xorg xinit xauth x11-xserver-utils x11-utils x11-xkb-utils
  xserver-xorg-input-libinput libgl1-mesa-dri mesa-utils
  mesa-va-drivers mesa-vdpau-drivers vulkan-tools vainfo vdpauinfo
)

# Paquetes de compilación mínimos (solo para lo que se compila, ya no chadwm/eww/Ly)
BUILD_PKGS=(
  libx11-dev libxft-dev libxinerama-dev libxrender-dev libfontconfig1-dev
  libx11-xcb-dev libxcb1-dev libxcb-randr0-dev libxcb-shape0-dev
  libxcb-xfixes0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev
  libxkbcommon-dev libxkbcommon-x11-dev
  libgtk-3-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev
  libglib2.0-dev libdbus-1-dev libssl-dev zlib1g-dev
)

AUDIO_PKGS=(
  pipewire pipewire-pulse pipewire-alsa wireplumber
  alsa-utils pavucontrol pulseaudio-utils pamixer
  ffmpeg libavcodec-extra ffmpegthumbnailer
  gstreamer1.0-libav gstreamer1.0-plugins-base gstreamer1.0-plugins-good
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-vaapi
  gstreamer1.0-tools
)

CAMERA_PKGS=(v4l-utils libcamera-tools)

STORAGE_PKGS=(
  udisks2 udiskie gvfs gvfs-backends
  exfatprogs ntfs-3g dosfstools e2fsprogs
  lxpolkit libnotify-bin gir1.2-notify-0.7
)

# bspwm + sxhkd + polybar + resto del escritorio
DESKTOP_PKGS=(
  bspwm sxhkd polybar
  picom dunst rofi feh kitty flameshot i3lock xss-lock
  brightnessctl xclip thunar
  xwallpaper playerctl
  bluez redshift
  scrot imagemagick
  lm-sensors upower acpi
)

NETWORK_PKGS=(network-manager network-manager-gnome dbus-user-session dbus-x11)

FONT_PKGS=(
  fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji
  fonts-noto-cjk
  adwaita-icon-theme hicolor-icon-theme desktop-file-utils shared-mime-info
  xdg-utils xdg-user-dirs
)

SENSOR_PKGS=(lm-sensors upower acpi)

FIRMWARE_PKGS=(
  firmware-misc-nonfree firmware-sof-signed firmware-intel-graphics
  firmware-amd-graphics firmware-realtek firmware-iwlwifi
  firmware-atheros firmware-brcm80211 firmware-mediatek
)

NERD_FONT_VERSION="3.5.1"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/JetBrainsMono.tar.xz"
NERD_FONT_SHA256="04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf"

APT_COMPONENTS=()
APT_MISSING_COMPONENTS=()
REPO_MAIN_MISSING=0
REPO_COMPONENTS_UNKNOWN=0
REPO_MODIFIED=0
APT_SOURCES_LIST="${APT_SOURCES_LIST:-/etc/apt/sources.list}"
APT_SOURCES_DIR="${APT_SOURCES_DIR:-/etc/apt/sources.list.d}"
APT_INDEX_UPDATED=0

apt_update() {
  if [[ "$APT_INDEX_UPDATED" == "1" ]]; then
    return 0
  fi
  section "Índices APT"
  if dry_run; then
    print_cmd apt-get update
    APT_INDEX_UPDATED=1
    return 0
  fi
  run_root env DEBIAN_FRONTEND=noninteractive apt-get update
  APT_INDEX_UPDATED=1
}

apt_components() {
  local output=""
  if command -v apt-get >/dev/null 2>&1; then
    output=$(apt-get indextargets --format '$(COMPONENT)' 2>/dev/null || true)
  fi
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output" | tr ' ' '\n' | sed '/^$/d' | sort -u
    return 0
  fi

  {
    local file
    for file in "$APT_SOURCES_LIST" "$APT_SOURCES_DIR"/*.list; do
      [[ -r "$file" ]] || continue
      awk '!/^[[:space:]]*#/ && $1 == "deb" { for (i = 2; i <= NF; i++) print $i }' "$file"
    done
    for file in "$APT_SOURCES_DIR"/*.sources; do
      [[ -r "$file" ]] || continue
      awk '
        BEGIN { RS = ""; FS = "\n" }
        {
          enabled = 1
          is_deb = 0
          components = ""
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^Enabled:[[:space:]]*[Nn][Oo]/) enabled = 0
            if ($i ~ /^Types:/ && $i ~ /(^|[[:space:]])deb([[:space:]]|$)/) is_deb = 1
            if ($i ~ /^Components:[[:space:]]*/) {
              sub(/^Components:[[:space:]]*/, "", $i)
              components = $i
            }
          }
          if (enabled && is_deb && components != "") print components
        }' "$file"
    done
  } | grep -Ex 'main|contrib|non-free|non-free-firmware' | sort -u || true
}

apt_component_enabled() {
  local component="$1" current
  for current in "${APT_COMPONENTS[@]}"; do
    [[ "$current" == "$component" ]] && return 0
  done
  return 1
}

add_missing_component() {
  local component="$1" current
  for current in "${APT_MISSING_COMPONENTS[@]}"; do
    [[ "$current" == "$component" ]] && return 0
  done
  APT_MISSING_COMPONENTS+=("$component")
}

nvidia_driver_wanted() {
  [[ "$HAS_NVIDIA" -eq 1 ]] || return 1
  case "${INSTALL_NVIDIA:-auto}" in
    no) return 1 ;;
    yes) return 0 ;;
  esac
  [[ "$SECURE_BOOT" == "enabled" || "$SECURE_BOOT" == "unknown" ]] && return 1
  [[ "$IS_VM" -eq 1 ]] && return 1
  return 0
}

is_debian_13_suite() {
  [[ "$1" =~ ^(trixie|stable)(-updates|-security)?$ ]]
}

is_debian_uri() {
  local uri="$1"
  [[ "$uri" =~ ^(https?|ftp)://([A-Za-z0-9.-]+\.)?debian\.org/ ]] && return 0
  return 1
}

has_component_token() {
  [[ " $1 " == *" $2 "* ]]
}

install_repo_file() {
  local file="$1" tmp="$2" mode owner group
  if cmp -s -- "$file" "$tmp"; then
    rm -f -- "$tmp"
    return 1
  fi
  mode=$(stat -c '%a' "$file")
  owner=$(stat -c '%U' "$file")
  group=$(stat -c '%g' "$file")
  run_root install -m "$mode" -o "$owner" -g "$group" "$tmp" "$file"
  rm -f -- "$tmp"
  info "Actualizado: $file"
  return 0
}

add_components_list_file() {
  local file="$1"
  shift
  local -a add=("$@") tokens=()
  local tmp line idx uri suite component
  [[ -r "$file" ]] || return 1
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-sources.XXXXXX")
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*deb[[:space:]] ]]; then
      tokens=()
      read -r -a tokens <<< "$line"
      idx=1
      if [[ "${tokens[$idx]:-}" == \[* ]]; then
        while ((idx < ${#tokens[@]})) && [[ "${tokens[$idx]}" != *\] ]]; do
          ((idx++))
        done
        ((idx++))
      fi
      uri="${tokens[$idx]:-}"
      suite="${tokens[$((idx + 1))]:-}"
      if is_debian_13_suite "$suite" && is_debian_uri "$uri"; then
        for component in "${add[@]}"; do
          if ! has_component_token "$line" "$component"; then
            line+=" $component"
          fi
        done
      fi
    fi
    printf '%s\n' "$line"
  done <"$file" >"$tmp"
  if install_repo_file "$file" "$tmp"; then
    return 0
  fi
  return 1
}

add_components_sources_file() {
  local file="$1"
  shift
  local -a add=("$@")
  local tmp status
  [[ -r "$file" ]] || return 1
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-sources.XXXXXX")
  status=$(mktemp "${TMPDIR:-/tmp}/dwm-sources-status.XXXXXX")
  awk -v add="${add[*]}" -v status_file="$status" '
    BEGIN { RS = ""; FS = "\n"; n = split(add, wanted, " "); changed = 0 }
    function has_token(s, t) { return index(" " s " ", " " t " ") > 0 }
    function suite_ok(s) {
      return s ~ /(^|[[:space:]])(trixie|stable)(-updates|-security)?([[:space:]]|$)/
    }
    function uri_ok(u) {
      return u ~ /^(https?|ftp):\/\/([A-Za-z0-9.-]+\.)?debian\.org\//
    }
    {
      is_deb = 0
      enabled = 1
      suite = ""
      uri = ""
      comps = ""
      has_comps = 0
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^Enabled:[[:space:]]*[Nn][Oo]/) enabled = 0
        if ($i ~ /^Types:/ && $i ~ /(^|[[:space:]])deb([[:space:]]|$)/) is_deb = 1
        if ($i ~ /^Suites:/) {
          x = $i
          sub(/^Suites:[[:space:]]*/, "", x)
          suite = x
        }
        if ($i ~ /^URIs:/) {
          x = $i
          sub(/^URIs:[[:space:]]*/, "", x)
          uri = x
        }
        if ($i ~ /^Components:/) {
          x = $i
          sub(/^Components:[[:space:]]*/, "", x)
          comps = x
          has_comps = 1
        }
      }
      if (enabled && is_deb && has_comps && suite_ok(suite) && uri_ok(uri)) {
        block_changed = 0
        for (j = 1; j <= n; j++) {
          if (!has_token(comps, wanted[j])) {
            comps = comps " " wanted[j]
            block_changed = 1
          }
        }
        if (block_changed) {
          changed = 1
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^Components:/) $i = "Components: " comps
          }
        }
      }
      for (i = 1; i <= NF; i++) print $i
      print ""
    }
    END { print changed > status_file; close(status_file) }' "$file" >"$tmp"
  if [[ ! -s "$status" || "$(<"$status")" != "1" ]]; then
    rm -f -- "$tmp" "$status"
    return 1
  fi
  rm -f -- "$status"
  if install_repo_file "$file" "$tmp"; then
    return 0
  fi
  return 1
}

add_apt_components() {
  local -a add=("$@")
  local changed=0 file component
  ((${#add[@]} > 0)) || return 0
  for component in "${add[@]}"; do
    [[ "$component" == "main" ]] && die "El componente main no se añade automáticamente."
  done
  [[ -n "${ROOT_BACKUP_DIR:-}" ]] || die "No hay directorio de backup para editar sources.list"
  info "Añadiendo componentes APT: ${add[*]}"
  backup_root "$APT_SOURCES_LIST"
  backup_root "$APT_SOURCES_DIR"

  for file in "$APT_SOURCES_LIST" "$APT_SOURCES_DIR"/*.list; do
    [[ -r "$file" ]] || continue
    if add_components_list_file "$file" "${add[@]}"; then
      changed=1
    fi
  done
  for file in "$APT_SOURCES_DIR"/*.sources; do
    [[ -r "$file" ]] || continue
    if add_components_sources_file "$file" "${add[@]}"; then
      changed=1
    fi
  done

  if ((changed == 0)); then
    warn "No hay componentes nuevos que añadir en las entradas de Debian 13."
    return 1
  fi
  APT_INDEX_UPDATED=0
  return 0
}

detect_repo_problems() {
  APT_COMPONENTS=()
  APT_MISSING_COMPONENTS=()
  REPO_MAIN_MISSING=0
  REPO_COMPONENTS_UNKNOWN=0

  local component_list
  mapfile -t APT_COMPONENTS < <(apt_components)
  if ((${#APT_COMPONENTS[@]} == 0)); then
    REPO_COMPONENTS_UNKNOWN=1
    warn "No se pudieron detectar los componentes APT habilitados."
    warn "Revisa /etc/apt/sources.list y /etc/apt/sources.list.d/ antes de continuar."
    return 0
  fi

  component_list="${APT_COMPONENTS[*]}"
  info "Componentes detectados: $component_list"

  if ! apt_component_enabled main; then
    REPO_MAIN_MISSING=1
    warn "Falta el componente main: los paquetes obligatorios no estarán disponibles."
  fi

  if ! apt_component_enabled non-free-firmware; then
    warn "Falta non-free-firmware: se omitirán firmware de WiFi, audio SOF y GPU."
    if [[ "$HAS_WIFI" -eq 1 ]]; then
      warn "  WiFi detectado: puede quedar sin firmware."
    fi
    if [[ "$HAS_AUDIO" -eq 1 ]]; then
      warn "  Audio detectado: puede faltar firmware SOF."
    fi
    if [[ "$HAS_INTEL" -eq 1 || "$HAS_AMD" -eq 1 || "$HAS_NVIDIA" -eq 1 ]]; then
      warn "  GPU detectada: puede faltar firmware específico."
    fi
    add_missing_component non-free-firmware
  fi

  local need_nonfree=0
  if [[ "$HAS_INTEL" -eq 1 ]] || nvidia_driver_wanted; then
    need_nonfree=1
  fi
  if ((need_nonfree == 1)) && ! apt_component_enabled non-free; then
    warn "Falta non-free: se omitirán drivers propietarios."
    if [[ "$HAS_INTEL" -eq 1 ]]; then
      warn "  Intel: no se instalará intel-media-va-driver-non-free; se usará Mesa."
    fi
    if nvidia_driver_wanted; then
      warn "  NVIDIA: no se instalará nvidia-driver; no habrá driver propietario."
    fi
    add_missing_component non-free
  fi

  if nvidia_driver_wanted && ! apt_component_enabled contrib; then
    warn "Falta contrib: se omitirá nvidia-settings (opcional)."
    warn "  El driver NVIDIA puede instalarse igual; solo falta el panel de configuración."
    add_missing_component contrib
  fi

  return 0
}

resolve_repo_menu() {
  local choice
  while true; do
    if ((${#APT_MISSING_COMPONENTS[@]} == 0)); then
      return 0
    fi
    printf '\n'
    info "Componentes APT que faltan: ${APT_MISSING_COMPONENTS[*]}"
    printf '  1) Añadirlos automáticamente (backup + apt update + comprobar)\n'
    printf '  2) Continuar sin ellos (se omitirán esos paquetes/funciones)\n'
    printf '  3) Cancelar\n'
    choice=""
    if ! read -r -p "Elige [1/2/3] (2): " choice; then
      choice="2"
    fi
    case "$choice" in
      ""|2)
        warn "Se continúa sin: ${APT_MISSING_COMPONENTS[*]}"
        return 0
        ;;
      1)
        if add_apt_components "${APT_MISSING_COMPONENTS[@]}"; then
          REPO_MODIFIED=1
        else
          warn "No se modificó ninguna entrada de Debian 13; se vuelve a comprobar."
        fi
        apt_update
        detect_repo_problems
        if ((${#APT_MISSING_COMPONENTS[@]} == 0)); then
          ok "Componentes APT añadidos y detectados correctamente"
          return 0
        fi
        warn "Siguen faltando componentes: ${APT_MISSING_COMPONENTS[*]}"
        ;;
      3)
        if [[ "$REPO_MODIFIED" -eq 1 ]]; then
          info "Cancelado. Los repositorios ya modificados se conservan en el backup: $ROOT_BACKUP_DIR"
        else
          info "Cancelado por el usuario. No se modificó el sistema."
        fi
        exit 0
        ;;
      *)
        warn "Opción no válida: '$choice'"
        ;;
    esac
  done
}

preflight_repos() {
  section "Repositorios APT"
  detect_repo_problems

  if [[ "$REPO_MAIN_MISSING" -eq 1 ]]; then
    die "Falta el componente main en APT. Revisa sources.list antes de instalar."
  fi
  if [[ "$REPO_COMPONENTS_UNKNOWN" -eq 1 ]]; then
    return 0
  fi
  if ((${#APT_MISSING_COMPONENTS[@]} == 0)); then
    ok "Componentes APT necesarios disponibles"
    return 0
  fi

  if dry_run; then
    info "En una instalación real se ofrecería añadir: ${APT_MISSING_COMPONENTS[*]}"
    return 0
  fi
  if [[ "$ASSUME_YES" == "1" ]]; then
    warn "Modo --yes: no se modifican repositorios; se continúa sin ${APT_MISSING_COMPONENTS[*]}."
    return 0
  fi

  resolve_repo_menu
}

install_group() {
  local label="$1" requirement="$2"
  shift 2
  local -a wanted=("$@") available=() missing=()
  local pkg
  for pkg in "${wanted[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done
  if ((${#missing[@]} > 0)); then
    if [[ "$requirement" == "required" ]]; then
      die "Faltan paquetes obligatorios para $label: ${missing[*]}. Revisa los repositorios de Debian 13."
    fi
    warn "Paquetes no disponibles para $label (se omiten): ${missing[*]}"
  fi
  if ((${#available[@]} == 0)); then
    warn "No hay paquetes instalables para $label"
    return 0
  fi
  info "Instalando $label (${#available[@]} paquetes)"
  if dry_run; then
    print_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
      "${available[@]}"
    return 0
  fi
  if ! run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    "${available[@]}"; then
    if [[ "$requirement" == "required" ]]; then
      die "Falló la instalación del grupo obligatorio: $label"
    fi
    warn "Falló la instalación opcional de $label; se continúa."
    return 0
  fi
}

install_base_packages() {
  section "Paquetes base y Xorg"
  install_group "base" required "${BASE_PKGS[@]}"
  install_group "Xorg" required "${XORG_PKGS[@]}"
  install_group "compilación" required "${BUILD_PKGS[@]}"
}

install_desktop_packages() {
  section "Escritorio, audio, cámara y almacenamiento"
  install_group "escritorio (bspwm+sxhkd+polybar+apps)" required "${DESKTOP_PKGS[@]}"
  install_group "audio y códecs" required "${AUDIO_PKGS[@]}"
  install_group "cámara" optional "${CAMERA_PKGS[@]}"
  install_group "almacenamiento extraíble" required "${STORAGE_PKGS[@]}"
  install_group "red" required "${NETWORK_PKGS[@]}"
  install_group "fuentes e iconos" required "${FONT_PKGS[@]}"
  install_group "sensores y energía" optional "${SENSOR_PKGS[@]}"
  install_group "firmware" optional "${FIRMWARE_PKGS[@]}"

  if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    install_group "microcódigo Intel" optional intel-microcode
  elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    install_group "microcódigo AMD" optional amd64-microcode
  fi
}

install_gpu_packages() {
  local -a gpu_pkgs=()
  if [[ "$HAS_INTEL" -eq 1 ]]; then
    gpu_pkgs+=(intel-media-va-driver-non-free i965-va-driver intel-gpu-tools)
  fi
  if [[ "$HAS_AMD" -eq 1 ]]; then
    gpu_pkgs+=(mesa-va-drivers mesa-vdpau-drivers)
  fi
  if [[ "$HAS_NVIDIA" -eq 1 ]]; then
    if nvidia_driver_wanted; then
      gpu_pkgs+=(nvidia-driver nvidia-settings nvidia-vaapi-driver nvidia-smi linux-headers-amd64)
      if [[ "${INSTALL_CUDA:-auto}" == "yes" ]]; then
        gpu_pkgs+=(nvidia-cuda-toolkit)
      elif [[ "$DRY_RUN" -eq 0 && "$ASSUME_YES" -eq 0 && -t 0 && "${INSTALL_CUDA:-auto}" == "auto" ]]; then
        if ask_cuda_toolkit; then
          gpu_pkgs+=(nvidia-cuda-toolkit)
        fi
      fi
    else
      case "${INSTALL_NVIDIA:-auto}" in
        no)
          info "NVIDIA detectada; instalación omitida por --no-nvidia"
          ;;
        *)
          if [[ "$SECURE_BOOT" == "enabled" || "$SECURE_BOOT" == "unknown" ]]; then
            if [[ "$SECURE_BOOT" == "enabled" ]]; then
              warn "NVIDIA detectada con Secure Boot activo; se omite el driver propietario."
            else
              warn "NVIDIA detectada pero no se pudo determinar Secure Boot; se omite por precaución."
            fi
            warn "Usa --nvidia después de configurar MOK o desactiva Secure Boot."
          elif [[ "$IS_VM" -eq 1 ]]; then
            warn "NVIDIA detectada en una VM; se omite el driver propietario (usa --nvidia para forzar)."
          fi
          ;;
      esac
    fi
  fi
  if ((${#gpu_pkgs[@]} > 0)); then
    install_group "GPU" optional "${gpu_pkgs[@]}" || true
  fi
}

font_fallback() {
  if [[ "${DWM_FONT_EXPLICIT:-0}" == "1" ]]; then
    return 0
  fi
  if fc-list 2>/dev/null | grep -qi 'JetBrains Mono'; then
    DWM_FONT="JetBrains Mono"
  else
    DWM_FONT="monospace"
  fi
  warn "Se usará la fuente '$DWM_FONT' en bspwm porque la Nerd Font no está disponible."
}

install_nerd_font() {
  section "Fuente Nerd Font"
  if dry_run; then
    log "[dry-run] descargar $NERD_FONT_URL"
    log "[dry-run] verificar SHA-256 y extraer en /usr/local/share/fonts/JetBrainsMonoNerd"
    return 0
  fi
  if fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font'; then
    ok "JetBrainsMono Nerd Font ya está instalada"
    return 0
  fi
  local cache="/var/cache/dwm-setup"
  local archive="$cache/JetBrainsMono-${NERD_FONT_VERSION}.tar.xz"
  local target="/usr/local/share/fonts/JetBrainsMonoNerd"
  run_root install -d -m 0755 "$cache"
  if [[ ! -r "$archive" ]]; then
    info "Descargando JetBrainsMono Nerd Font v${NERD_FONT_VERSION}"
    if ! run_root curl -fL --retry 3 --connect-timeout 20 -o "$archive" "$NERD_FONT_URL"; then
      warn "No se pudo descargar la Nerd Font; se usa la fuente JetBrains Mono de Debian."
      font_fallback
      return 0
    fi
  fi
  if ! printf '%s  %s\n' "$NERD_FONT_SHA256" "$archive" | sha256sum -c - >/dev/null 2>&1; then
    warn "Checksum incorrecto para $archive; se elimina el archivo y se usa la fuente de Debian."
    run_root rm -f "$archive"
    font_fallback
    return 0
  fi
  run_root install -d -m 0755 "$target"
  if ! run_root tar -xJf "$archive" -C "$target"; then
    warn "No se pudo extraer la Nerd Font; se usa la fuente de Debian."
    font_fallback
    return 0
  fi
  run_root fc-cache -f >/dev/null 2>&1 || true
  ok "Nerd Font instalada en $target"
}

enable_base_services() {
  section "Servicios base"
  if dry_run; then
    print_cmd systemctl enable udisks2.service
    print_cmd systemctl enable NetworkManager.service
    return 0
  fi
  if systemctl list-unit-files udisks2.service >/dev/null 2>&1; then
    run_root systemctl enable udisks2.service
  fi
  if systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
    run_root systemctl enable NetworkManager.service
  fi
}

add_user_groups() {
  section "Permisos del usuario"
  local group current
  current=$(id -nG "$TARGET_USER" 2>/dev/null || true)
  for group in video audio render plugdev; do
    getent group "$group" >/dev/null 2>&1 || continue
    if printf '%s\n' "$current" | tr ' ' '\n' | grep -qx "$group"; then
      debug "$TARGET_USER ya pertenece a $group"
    else
      if dry_run; then
        print_cmd usermod -aG "$group" "$TARGET_USER"
      else
        run_root usermod -aG "$group" "$TARGET_USER"
        info "Añadido $TARGET_USER al grupo $group (requiere cerrar sesión)"
      fi
    fi
  done
}

install_packages() {
  apt_update
  install_base_packages
  install_desktop_packages
  install_gpu_packages
  install_nerd_font
  # Verificación explícita: paquetes obligatorios DEBEN estar instalados
  if dry_run; then
    return 0
  fi
  local required_pkgs=(
    bspwm sxhkd polybar kitty picom dunst rofi feh xwallpaper
    udiskie brightnessctl xclip thunar playerctl flameshot i3lock xss-lock
    libnotify-bin gir1.2-notify-0.7 lm-sensors upower acpi
    fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji fonts-noto-cjk
    adwaita-icon-theme hicolor-icon-theme desktop-file-utils shared-mime-info
    xdg-utils xdg-user-dirs network-manager network-manager-gnome dbus-user-session dbus-x11
    pipewire pipewire-pulse wireplumber alsa-utils pavucontrol pulseaudio-utils pamixer
    ffmpeg libavcodec-extra gstreamer1.0-plugins-base gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-vaapi
    v4l-utils udisks2 gvfs gvfs-backends exfatprogs ntfs-3g dosfstools e2fsprogs
    lxpolkit
  )
  local missing=()
  for pkg in "${required_pkgs[@]}"; do
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
      missing+=("$pkg")
    fi
  done
  if ((${#missing[@]} > 0)); then
    die "Paquetes obligatorios NO instalados (revisa sudo/apt/locks): ${missing[*]}"
  fi
  ok "Todos los paquetes obligatorios verificados"

  enable_base_services
  add_user_groups
}