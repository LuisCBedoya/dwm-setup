#!/usr/bin/env bash
# Grupos de paquetes de la fase 1. Debian 13 (trixie).

BASE_PKGS=(
  build-essential git curl ca-certificates xz-utils unzip tar file pkg-config
  procps pciutils usbutils dmidecode inxi bash-completion sudo less rsync
)

XORG_PKGS=(
  xserver-xorg xinit xauth x11-xserver-utils x11-utils x11-xkb-utils
  xserver-xorg-input-libinput libgl1-mesa-dri mesa-utils
  mesa-va-drivers mesa-vdpau-drivers vulkan-tools vainfo vdpauinfo
)

BUILD_PKGS=(
  libx11-dev libxft-dev libxinerama-dev libxrender-dev libfontconfig1-dev
  libimlib2-dev libx11-xcb-dev libxcb1-dev libxcb-randr0-dev libxcb-shape0-dev
  libxcb-xfixes0-dev libxcb-xinerama0-dev libxcb-util-dev libxcb-cursor-dev
  libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev
  libgtk-3-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev
  libglib2.0-dev libdbus-1-dev libdbusmenu-glib-dev libdbusmenu-gtk3-dev
  libssl-dev zlib1g-dev libpam0g-dev
  rustc cargo
)

AUDIO_PKGS=(
  pipewire pipewire-pulse pipewire-alsa wireplumber
  alsa-utils pavucontrol pulseaudio-utils
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

DESKTOP_PKGS=(
  picom dunst rofi feh kitty flameshot i3lock xss-lock
  brightnessctl xclip pcmanfm
)

NETWORK_PKGS=(network-manager network-manager-gnome dbus-user-session dbus-x11)

FONT_PKGS=(
  fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji
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

apt_update() {
  section "Índices APT"
  if dry_run; then
    print_cmd apt-get update
    return 0
  fi
  run_root env DEBIAN_FRONTEND=noninteractive apt-get update
}

# install_group ETIQUETA required|optional paquete...
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
  install_group "escritorio" required "${DESKTOP_PKGS[@]}"
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
    if [[ "${INSTALL_NVIDIA:-auto}" == "no" ]]; then
      info "NVIDIA detectada; instalación omitida por --no-nvidia"
    elif [[ ( "$SECURE_BOOT" == "enabled" || "$SECURE_BOOT" == "unknown" ) && "${INSTALL_NVIDIA:-auto}" != "yes" ]]; then
      if [[ "$SECURE_BOOT" == "enabled" ]]; then
        warn "NVIDIA detectada con Secure Boot activo; se omite el driver propietario."
      else
        warn "NVIDIA detectada pero no se pudo determinar Secure Boot; se omite por precaución."
      fi
      warn "Usa --nvidia después de configurar MOK o desactiva Secure Boot."
    elif [[ "$IS_VM" -eq 1 && "${INSTALL_NVIDIA:-auto}" != "yes" ]]; then
      warn "NVIDIA detectada en una VM; se omite el driver propietario (usa --nvidia para forzar)."
    else
      gpu_pkgs+=(nvidia-driver nvidia-settings nvidia-vaapi-driver linux-headers-amd64)
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
  warn "Se usará la fuente '$DWM_FONT' en dwm porque la Nerd Font no está disponible."
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
  enable_base_services
  add_user_groups
}
