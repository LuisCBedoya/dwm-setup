#!/usr/bin/env bash
# Verificación posterior a la instalación (sin arrancar la sesión gráfica).

verify_install() {
  section "Verificación final"
  local failures=0
  local home="$TARGET_HOME"
  local path module line

  for cmd in bspwm sxhkd polybar dunst rofi feh kitty flameshot i3lock xss-lock \
    brightnessctl xclip thunar udiskie v4l2-ctl ffmpeg pactl wpctl pamixer paplay xwallpaper playerctl nvim \
    zsh lsd ranger zathura vlc ueberzug; do
    if cmd_exists "$cmd"; then
      debug "ok: $cmd"
    else
      error "Falta el comando requerido: $cmd"
      failures=$((failures + 1))
    fi
  done

  if cmd_exists dmenu; then
    debug "ok: dmenu"
  else
    info "dmenu no instalado; services.sh usará rofi -dmenu"
  fi

  if [[ "$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f7)" == "/usr/bin/zsh" ]]; then
    debug "ok: shell zsh para $TARGET_USER"
  else
    error "La shell de $TARGET_USER no es /usr/bin/zsh"
    failures=$((failures + 1))
  fi

  for path in \
    "$home/.config/bspwm/bspwmrc" \
    "$home/.config/bspwm/scripts/autostart" \
    "$home/.config/bspwm/scripts/bspwm_resize" \
    "$home/.config/bspwm/scripts/low_bat_notifier.sh" \
    "$home/.config/bspwm/scripts/keybindings_rofi.sh" \
    "$home/.config/bspwm/scripts/screenshot.sh" \
    "$home/.config/bspwm/scripts/screenshot_region.sh" \
    "$home/.config/bspwm/scripts/screenshot_full.sh" \
    "$home/.config/bspwm/scripts/audio-switch.sh" \
    "$home/.config/bspwm/scripts/audio-watch.sh" \
    "$home/.config/sxhkd/sxhkdrc" \
    "$home/.config/polybar/config.ini" \
    "$home/.config/polybar/launch.sh" \
    "$home/.config/polybar/modules/logo.ini" \
    "$home/.config/polybar/modules/bspwm.ini" \
    "$home/.config/polybar/modules/updates.ini" \
    "$home/.config/polybar/modules/polypomo.ini" \
    "$home/.config/polybar/modules/temp.ini" \
    "$home/.config/polybar/modules/memory.ini" \
    "$home/.config/polybar/modules/cpu.ini" \
    "$home/.config/polybar/modules/network.ini" \
    "$home/.config/polybar/modules/services.ini" \
    "$home/.config/polybar/modules/battery.ini" \
    "$home/.config/polybar/modules/pipewire.ini" \
    "$home/.config/polybar/modules/date.ini" \
    "$home/.config/polybar/scripts/updates-apt.sh" \
    "$home/.config/polybar/scripts/polypomo" \
    "$home/.config/polybar/scripts/network-status.sh" \
    "$home/.config/polybar/scripts/network-menu.sh" \
    "$home/.config/polybar/scripts/services.sh" \
    "$home/.config/polybar/scripts/volume.sh" \
    "$home/.config/polybar/polybar-variant" \
    "$home/.config/polybar/variants/reference/config.ini" \
    "$home/.config/polybar/variants/reference/scripts/network-status.sh" \
    "$home/.config/polybar/variants/reference/scripts/updates-apt.sh" \
    "$home/.config/polybar/variants/reference/scripts/arrow.sh" \
    "$home/.config/polybar/variants/reference/modules/time.ini" \
    "$home/.config/polybar/variants/reference/modules/day.ini" \
    "$home/.config/polybar/variants/reference/modules/sep-dash.ini" \
    "$home/.config/polybar/variants/reference/modules/sep-bar.ini" \
    "$home/.config/polybar/variants/reference/modules/arrow.ini" \
    "$home/.config/polybar/variants/reference/modules/der.ini" \
    "$home/.config/polybar/variants/reference/modules/izq.ini" \
    "$home/.config/polybar/variants/reference/modules/polypomo.ini" \
    "$home/.config/polybar/variants/reference/modules/bspwm.ini" \
    "$home/.config/polybar/variants/reference/modules/battery.ini" \
    "$home/.config/polybar/variants/reference/modules/temp.ini" \
    "$home/.config/polybar/variants/reference/modules/pipewire.ini" \
    "$home/.config/polybar/variants/reference/modules/network.ini" \
    "$home/.config/polybar/variants/reference/modules/services.ini" \
    "$home/.config/polybar/variants/reference/modules/memory.ini" \
    "$home/.config/polybar/variants/reference/modules/cpu.ini" \
    "$home/.config/polybar/variants/reference/modules/xkeyboard.ini" \
    "$home/.config/polybar/variants/reference/modules/fs.ini" \
    "$home/.config/polybar/variants/reference/modules/date.ini" \
    "$home/.config/polybar/variants/reference/modules/updates.ini" \
    "$home/.config/dunst/dunstrc" \
    "$home/.config/rofi/powermenu.rasi" \
    "$home/.config/kitty/kitty.conf" \
    "$home/.zshrc" \
    "$home/.config/lsd/config.yml" \
    "$home/.config/lsd/icons.yaml" \
    "$home/.config/ranger/rc.conf" \
    "$home/.config/ranger/rifle.conf" \
    "$home/.config/ranger/scope.sh" \
    "$home/.config/ranger/epub-cover.sh" \
    "$home/.themes/Windows-10-Dark/index.theme" \
    "$home/.config/gtk-3.0/settings.ini" \
    "$home/.config/gtk-4.0/settings.ini" \
    "$home/.gtkrc-2.0" \
    "$home/.oh-my-zsh/oh-my-zsh.sh" \
    "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
    "$home/.config/dunst/scripts/notification-sound.sh" \
    "/usr/share/icons/Papirus/index.theme" \
    "$home/.xinitrc" \
    "$home/.local/share/wallpapers/rocky.jpg" \
    "$home/.local/share/xorg" \
    "$home/Pictures/Screenshots" \
    "/usr/local/bin/desktop-safe" \
    "/usr/local/bin/desktop-doctor"; do
    if [[ -e "$path" ]]; then
      debug "ok: $path"
    else
      error "Falta el archivo requerido: $path"
      failures=$((failures + 1))
    fi
  done

  # bspwm solo ejecuta bspwmrc si es ejecutable.
  if [[ -x "$home/.config/bspwm/bspwmrc" ]]; then
    debug "ok: bspwmrc ejecutable"
  else
    error "bspwmrc no es ejecutable; bspwm arrancará sin sxhkd ni polybar"
    failures=$((failures + 1))
  fi

  # .xinitrc no debe abrir una terminal en cada arranque.
  if [[ -f "$home/.xinitrc" ]]; then
    if grep -qE '^[[:space:]]*kitty[[:space:]]*&' "$home/.xinitrc"; then
      error "$home/.xinitrc sigue lanzando kitty al arrancar"
      failures=$((failures + 1))
    fi
    if ! grep -qE '^[[:space:]]*exec[[:space:]]+bspwm' "$home/.xinitrc"; then
      error "$home/.xinitrc no termina con 'exec bspwm'"
      failures=$((failures + 1))
    fi
  fi

  # Scripts ejecutables
  for script in "$home/.config/bspwm/scripts/"* "$home/.config/polybar/scripts/"*; do
    if [[ -f "$script" && ! -x "$script" ]]; then
      error "Script no ejecutable: $script"
      failures=$((failures + 1))
    fi
  done
  if [[ ! -x "$home/.config/polybar/polybar-variant" ]]; then
    error "polybar-variant no es ejecutable"
    failures=$((failures + 1))
  fi
  if [[ ! -x "$home/.config/polybar/variants/reference/scripts/network-status.sh" ]]; then
    error "network-status.sh de la variante referencia no es ejecutable"
    failures=$((failures + 1))
  fi
  if [[ ! -x "$home/.config/polybar/variants/reference/scripts/updates-apt.sh" ]]; then
    error "updates-apt.sh de la variante referencia no es ejecutable"
    failures=$((failures + 1))
  fi
  if [[ ! -x "$home/.config/polybar/variants/reference/scripts/arrow.sh" ]]; then
    error "arrow.sh de la variante referencia no es ejecutable"
    failures=$((failures + 1))
  fi
  if [[ -f "$home/.config/dunst/scripts/notification-sound.sh" && ! -x "$home/.config/dunst/scripts/notification-sound.sh" ]]; then
    error "Script no ejecutable: $home/.config/dunst/scripts/notification-sound.sh"
    failures=$((failures + 1))
  fi

  if [[ "${HEADSET_QUIRK_INSTALLED:-0}" -eq 1 ]]; then
    if [[ -f /etc/modprobe.d/alsa-fx504.conf ]]; then
      info "Quirk ALC255 instalado; requiere reiniciar para aplicar el micrófono"
    else
      error "Se esperaba /etc/modprobe.d/alsa-fx504.conf para el quirk ALC255"
      failures=$((failures + 1))
    fi
  fi

  # Módulos de polybar referenciados en la barra
  if [[ -f "$home/.config/polybar/config.ini" ]]; then
    while IFS= read -r line; do
      line="${line#*=}"
      for module in $line; do
        [[ -n "$module" ]] || continue
        if [[ ! -f "$home/.config/polybar/modules/$module.ini" ]]; then
          error "Polybar referencia el módulo '$module' pero falta $home/.config/polybar/modules/$module.ini"
          failures=$((failures + 1))
        fi
      done
    done < <(awk -F'=' '/^modules-(left|right)/ {print $0}' "$home/.config/polybar/config.ini")
    if ! grep -q '^include-directory' "$home/.config/polybar/config.ini"; then
      error "Falta include-directory en polybar/config.ini"
      failures=$((failures + 1))
    fi
  fi

  # Módulos de la variante referencia
  local variant_config="$home/.config/polybar/variants/reference/config.ini"
  if [[ -f "$variant_config" ]]; then
    while IFS= read -r line; do
      line="${line#*=}"
      for module in $line; do
        [[ -n "$module" ]] || continue
        if [[ ! -f "$home/.config/polybar/variants/reference/modules/$module.ini" ]]; then
          error "Variante referencia: falta el módulo '$module.ini'"
          failures=$((failures + 1))
        fi
      done
    done < <(awk -F'=' '/^modules-(left|right|center)/ {print $0}' "$variant_config")
    if ! grep -q '^include-directory' "$variant_config"; then
      error "Falta include-directory en la variante referencia"
      failures=$((failures + 1))
    fi
  fi

  # Placeholders sin renderizar en todas las configuraciones instaladas.
  for path in \
    "$home/.config/bspwm" \
    "$home/.config/sxhkd" \
    "$home/.config/polybar" \
    "$home/.config/dunst" \
    "$home/.config/rofi" \
    "$home/.config/kitty"; do
    [[ -d "$path" ]] || continue
    while IFS= read -r file; do
      if grep -qE '@[A-Z][A-Z0-9_]*@' "$file" 2>/dev/null; then
        error "Placeholders sin renderizar en $file"
        failures=$((failures + 1))
      fi
    done < <(find "$path" -type f 2>/dev/null)
  done
  if [[ -f "$home/.xinitrc" ]] && grep -qE '@[A-Z][A-Z0-9_]*@' "$home/.xinitrc"; then
    error "Placeholders sin renderizar en $home/.xinitrc"
    failures=$((failures + 1))
  fi

  # Propietario correcto de los directorios padre y de lo gestionado.
  for path in \
    "$home/.config" \
    "$home/.local" \
    "$home/.local/share" \
    "$home/.local/state" \
    "$home/.config-backup" \
    "$home/.cache" \
    "$home/.xinitrc" \
    "$home/Pictures/Screenshots"; do
    [[ -e "$path" ]] || continue
    if [[ "$(stat -c '%U' "$path" 2>/dev/null || true)" != "$TARGET_USER" ]]; then
      error "Propietario incorrecto en $path (se espera $TARGET_USER)"
      failures=$((failures + 1))
    fi
  done
  for path in \
    "$home/.config/bspwm" \
    "$home/.config/sxhkd" \
    "$home/.config/polybar" \
    "$home/.config/dunst" \
    "$home/.config/rofi" \
    "$home/.config/kitty" \
    "$home/.local/share/wallpapers" \
    "$home/.local/share/xorg" \
    "$home/.local/state/dwm-setup" \
    "$home/.cache/dwm-setup" \
    "$home/.config-backup/dwm-setup"; do
    [[ -e "$path" ]] || continue
    if [[ -n "$(find "$path" -not -user "$TARGET_USER" -print -quit 2>/dev/null || true)" ]]; then
      error "Hay ficheros que no pertenecen a $TARGET_USER dentro de $path"
      failures=$((failures + 1))
    fi
  done

  # Verificar directorio Xorg
  if [[ -d "$home/.local/share/xorg" ]]; then
    local xorg_owner xorg_mode
    xorg_owner=$(stat -c '%U' "$home/.local/share/xorg" 2>/dev/null || true)
    xorg_mode=$(stat -c '%a' "$home/.local/share/xorg" 2>/dev/null || true)
    if [[ "$xorg_owner" == "$TARGET_USER" && "$xorg_mode" == "700" && -w "$home/.local/share/xorg" ]]; then
      debug "ok: Xorg puede escribir su log en $home/.local/share/xorg"
    else
      error "Permisos incorrectos en $home/.local/share/xorg: $xorg_owner $xorg_mode (se espera $TARGET_USER 700)"
      failures=$((failures + 1))
    fi
  else
    error "Falta el directorio escribible para el log de Xorg: $home/.local/share/xorg"
    failures=$((failures + 1))
  fi

  # Servicios base
  local service_status
  service_status=$(systemctl is-enabled udisks2.service 2>/dev/null || true)
  if [[ "$service_status" == "enabled" || "$service_status" == "static" ]]; then
    debug "ok: udisks2"
  else
    error "udisks2.service no está habilitado"
    failures=$((failures + 1))
  fi
  service_status=$(systemctl is-enabled NetworkManager.service 2>/dev/null || true)
  if [[ "$service_status" == "enabled" || "$service_status" == "static" ]]; then
    debug "ok: NetworkManager"
  else
    error "NetworkManager.service no está habilitado"
    failures=$((failures + 1))
  fi

  # Versiones de los binarios
  local bspwm_version
  bspwm_version=$(bspwm -v 2>&1 || true)
  if [[ "$bspwm_version" =~ ^[0-9] ]]; then
    debug "ok: bspwm $bspwm_version"
  else
    error "bspwm -v falló: $bspwm_version"
    failures=$((failures + 1))
  fi
  if sxhkd -v >/dev/null 2>&1; then
    debug "ok: sxhkd -v"
  else
    error "sxhkd -v falló"
    failures=$((failures + 1))
  fi
  if polybar --version >/dev/null 2>&1; then
    debug "ok: polybar --version"
  else
    error "polybar --version falló"
    failures=$((failures + 1))
  fi

  # Sintaxis de los binarios instalados (POSIX sh)
  if sh -n /usr/local/bin/desktop-safe 2>/dev/null; then
    debug "ok: desktop-safe sh -n"
  else
    error "desktop-safe tiene errores de sintaxis POSIX"
    failures=$((failures + 1))
  fi
  if sh -n /usr/local/bin/desktop-doctor 2>/dev/null; then
    debug "ok: desktop-doctor sh -n"
  else
    error "desktop-doctor tiene errores de sintaxis POSIX"
    failures=$((failures + 1))
  fi

  # Cámara
  if cmd_exists v4l2-ctl; then
    if v4l2-ctl --list-devices >/dev/null 2>&1; then
      debug "ok: v4l2-ctl"
    else
      warn "v4l2-ctl no pudo listar dispositivos"
    fi
  fi

  if [[ ${#CAMERAS[@]} -eq 0 ]]; then
    warn "No se detectó cámara; la prueba real se omite"
  else
    info "Cámara(s) detectada(s): ${CAMERAS[*]}"
    info "Prueba real de captura tras iniciar sesión: desktop-doctor --camera"
  fi

  if ((failures > 0)); then
    error "Verificación con $failures fallo(s). Revisa el log antes de reiniciar."
    return 1
  fi
  ok "Verificación estática correcta"
}
