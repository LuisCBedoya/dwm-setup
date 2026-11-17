#!/usr/bin/env bash
# Verificación posterior a la instalación (sin arrancar la sesión gráfica).

verify_install() {
  section "Verificación final"
  local failures=0
  local home="$TARGET_HOME"
  local path module line shot_dir videos_dir
  shot_dir=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" xdg-user-dir PICTURES 2>/dev/null || true)
  case "$shot_dir" in ""|"$home") shot_dir="$home/Imágenes" ;; esac
  videos_dir=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" xdg-user-dir VIDEOS 2>/dev/null || true)
  case "$videos_dir" in ""|"$home") videos_dir="$home/Vídeos" ;; esac

  for cmd in bspwm sxhkd polybar picom xsettingsd ufw bluetoothctl dunst rofi feh kitty flameshot i3lock \
    xss-lock convert brightnessctl xclip xdotool thunar udiskie v4l2-ctl ffmpeg pactl wpctl pamixer paplay amixer \
    xwallpaper playerctl nvim zsh lsd ranger zathura vlc ueberzug fastfetch mpv fzf chafa \
    xdg-user-dir xrandr python3 wmctrl; do
    if cmd_exists "$cmd"; then
      debug "ok: $cmd"
    else
      error "Falta el comando requerido: $cmd"
      failures=$((failures + 1))
    fi
  done

  for pkg in tumbler; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      error "Falta el paquete requerido: $pkg (miniaturas de Thunar)"
      failures=$((failures + 1))
    fi
  done

  # La cadena de compilación se instala explícitamente y se protege del
  # autoremove; si falta, la instalación no está completa.
  for cmd in make gcc g++ patch cmake meson ninja autoconf automake libtool \
    pkg-config git; do
    if cmd_exists "$cmd"; then
      debug "ok: $cmd"
    else
      error "Falta la herramienta de compilación: $cmd"
      failures=$((failures + 1))
    fi
  done

  if cmd_exists dmenu; then
    debug "ok: dmenu"
  else
    info "dmenu no instalado; services.sh usará rofi -dmenu"
  fi

  if ! dpkg-query -W -f='${Status}' libspa-0.2-bluetooth 2>/dev/null |
       grep -q 'install ok installed'; then
    error "Falta libspa-0.2-bluetooth; PipeWire no soportará audio Bluetooth"
    failures=$((failures + 1))
  fi
  if ! dpkg-query -W -f='${Status}' rtkit 2>/dev/null |
       grep -q 'install ok installed'; then
    error "Falta rtkit; WirePlumber no tendrá prioridad de tiempo real"
    failures=$((failures + 1))
  fi

  local wp_audio="$home/.config/wireplumber/wireplumber.conf.d/50-dwm-setup.conf"
  if [[ ! -f "$wp_audio" ]]; then
    error "Falta $wp_audio (autoswitch A2DP/HFP del micrófono Bluetooth)"
    failures=$((failures + 1))
  elif ! grep -q 'bluetooth.autoswitch-to-headset-profile = true' "$wp_audio"; then
    error "WirePlumber no tiene activado el autoswitch de perfil Bluetooth"
    failures=$((failures + 1))
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
    "$home/.config/bspwm/scripts/workspace.sh" \
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
    "$home/.config/polybar/modules/governor.ini" \
    "$home/.config/polybar/modules/fan.ini" \
    "$home/.config/polybar/scripts/cpu-governor.sh" \
    "$home/.config/polybar/scripts/fan-mode.sh" \
    "$home/.config/polybar/scripts/temp-status.sh" \
    "$home/.config/polybar/modules/network.ini" \
    "$home/.config/polybar/modules/bluetooth.ini" \
    "$home/.config/polybar/modules/ufw.ini" \
    "$home/.config/polybar/modules/services.ini" \
    "$home/.config/polybar/modules/battery.ini" \
    "$home/.config/polybar/modules/pipewire.ini" \
    "$home/.config/polybar/modules/date.ini" \
    "$home/.config/polybar/modules/tray.ini" \
    "$home/.config/polybar/scripts/updates-apt.sh" \
    "$home/.config/polybar/scripts/polypomo" \
    "$home/.config/polybar/scripts/network-status.sh" \
    "$home/.config/polybar/scripts/network-menu.sh" \
    "$home/.config/polybar/scripts/bluetooth-status.sh" \
    "$home/.config/polybar/scripts/bluetooth-menu.sh" \
    "$home/.config/polybar/scripts/ufw-status.sh" \
    "$home/.config/polybar/scripts/ufw-menu.sh" \
    "$home/.config/polybar/scripts/services.sh" \
    "$home/.config/polybar/scripts/volume.sh" \
    "$home/.config/polybar/scripts/monocle-count.sh" \
    "$home/.config/polybar/modules/monocle.ini" \
    "$home/.config/polybar/variants/reference/modules/monocle.ini" \
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
    "$home/.config/polybar/variants/reference/modules/bluetooth.ini" \
    "$home/.config/polybar/variants/reference/modules/ufw.ini" \
    "$home/.config/polybar/variants/reference/modules/services.ini" \
    "$home/.config/polybar/variants/reference/modules/memory.ini" \
    "$home/.config/polybar/variants/reference/modules/cpu.ini" \
    "$home/.config/polybar/variants/reference/modules/governor.ini" \
    "$home/.config/polybar/variants/reference/modules/fan.ini" \
    "$home/.config/polybar/variants/reference/modules/xkeyboard.ini" \
    "$home/.config/polybar/variants/reference/modules/fs.ini" \
    "$home/.config/polybar/variants/reference/modules/date.ini" \
    "$home/.config/polybar/variants/reference/modules/updates.ini" \
    "$home/.config/polybar/variants/reference/modules/tray.ini" \
    "$home/.config/dunst/dunstrc" \
    "$home/.config/rofi/powermenu.rasi" \
    "$home/.config/rofi/config.rasi" \
    "$home/.config/kitty/kitty.conf" \
    "$home/.config/kitty/colorshemes/monochromatic.conf" \
    "$home/.zshrc" \
    "$home/.config/lsd/config.yml" \
    "$home/.config/lsd/icons.yaml" \
    "$home/.config/ranger/rc.conf" \
    "$home/.config/ranger/rifle.conf" \
    "$home/.config/ranger/scope.sh" \
    "$home/.config/ranger/epub-cover.sh" \
    "$home/.config/bspwm/scripts/dunst-position.sh" \
    "$home/.config/bspwm/scripts/wallpaper.sh" \
    "$home/.config/bspwm/scripts/display-setup.sh" \
    "$home/.config/bspwm/scripts/monocle.sh" \
    "$home/.config/bspwm/scripts/resize-mode.sh" \
    "$home/.config/sxhkd/resize-mode.sxhkdrc" \
    "$home/.config/polybar/modules/resize.ini" \
    "$home/.config/polybar/variants/reference/modules/resize.ini" \
    "$home/.config/zathura/zathurarc" \
    "/usr/share/themes/catppuccin-mocha-blue/index.theme" \
    "/usr/share/themes/catppuccin-latte-blue/index.theme" \
    "/usr/share/themes/catppuccin-mocha-black/index.theme" \
    "/usr/share/icons/Catppuccin-Mocha/index.theme" \
    "/usr/share/icons/Catppuccin-Latte/index.theme" \
    "/usr/local/bin/theme-mode" \
    "/usr/local/bin/yt-play" \
    "/usr/local/bin/yt-preview" \
    "/usr/local/bin/ytdlp-check" \
    "/usr/local/bin/ytdlp-update" \
    "/usr/local/bin/ytdlp-rollback" \
    "/usr/local/bin/music-ctl" \
    "$home/.config/mpv/mpv.conf" \
    "$home/.local/bin/mpv" \
    "$home/.local/bin/dwm-setup-fan-auto" \
    "$home/.local/bin/dwm-setup-power-auto" \
    "$home/.config/dwm-setup/fan-mode" \
    "$home/.local/bin/ytwatch" \
    "$home/.local/bin/ytwatch-check" \
    "$home/.local/bin/ytwatch-update" \
    "$home/.local/bin/brave-theme" \
    "$home/.local/share/dwm-setup/render.env" \
    "$home/.config/dwm-setup/mode" \
    "$home/.config/dwm-setup/surfingkeys.js" \
    "$home/.config/fastfetch/config.jsonc" \
    "$home/.config/fastfetch/Neofet-dark.png" \
    "$home/.config/fastfetch/Neofet-light.png" \
    "$home/.config/gtk-3.0/settings.ini" \
    "$home/.config/gtk-3.0/gtk.css" \
    "$home/.config/gtk-4.0/gtk.css" \
    "$home/.config/gtk-4.0/settings.ini" \
    "$home/.gtkrc-2.0" \
    "$home/.config/xsettingsd/xsettingsd.conf" \
    "$home/.config/vlc/vlcrc" \
    "$home/.config/dwm-setup/recording.conf" \
    "$home/.oh-my-zsh/oh-my-zsh.sh" \
    "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
    "$home/.config/dunst/scripts/notification-sound.sh" \
    "/usr/share/icons/Papirus/index.theme" \
    "$home/.xinitrc" \
    "$home/.local/share/wallpapers/wallpaper.png" \
    "$home/.local/share/wallpapers/wallpaper-alt.png" \
    "$home/.local/share/xorg" \
    "$shot_dir/Capturas" \
    "$videos_dir/Grabaciones" \
    "/usr/local/bin/desktop-safe" \
    "/usr/local/bin/desktop-doctor" \
    "/usr/local/bin/dwm-setup-ufw" \
    "/etc/sudoers.d/dwm-setup-ufw" \
    "/etc/brave/policies/managed/dwm-setup.json"; do
    if [[ -e "$path" ]]; then
      debug "ok: $path"
    else
      error "Falta el archivo requerido: $path"
      failures=$((failures + 1))
    fi
  done

  # Todos los colores renderizados deben salir de la paleta activa.
  local -a palette_hex=()
  local color_var
  for color_var in COLOR_BG COLOR_BG_DEEP COLOR_BG_DEEPEST COLOR_BG_ALT COLOR_BG_ELEV COLOR_BG_HOVER \
                   COLOR_FG COLOR_FG_MUTED COLOR_FG_DIM COLOR_BORDER COLOR_BORDER_ALT COLOR_SEL_BG \
                   COLOR_ACCENT COLOR_ACCENT_ALT COLOR_ACCENT_STRONG \
                   COLOR_BAR_ACCENT COLOR_FOCUS_BORDER \
                   COLOR_GREEN COLOR_YELLOW \
                   COLOR_ORANGE COLOR_RED COLOR_CYAN COLOR_PURPLE COLOR_BLUE \
                   COLOR_TERM_BG COLOR_TERM_0 COLOR_TERM_1 COLOR_TERM_2 \
                   COLOR_TERM_3 COLOR_TERM_4 COLOR_TERM_5 COLOR_TERM_6 \
                   COLOR_TERM_7 COLOR_TERM_8 COLOR_TERM_9 COLOR_TERM_10 \
                   COLOR_TERM_11 COLOR_TERM_12 COLOR_TERM_13 COLOR_TERM_14 \
                   COLOR_TERM_15; do
    palette_hex+=("$(theme_var "$color_var" | tr 'A-F' 'a-f')")
  done

  local -a themed_files=(
    "$home/.config/polybar/config.ini"
    "$home/.config/polybar/variants/reference/config.ini"
    "$home/.config/kitty/kitty.conf"
    "$home/.config/kitty/colorshemes/monochromatic.conf"
    "$home/.config/dunst/dunstrc"
    "$home/.config/rofi/config.rasi"
    "$home/.config/rofi/powermenu.rasi"
    "$home/.config/bspwm/bspwmrc"
    "$home/.config/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh" \
    "$home/.config/picom/picom.conf" \
    "$home/.config/gtk-3.0/gtk.css" \
    "$home/.config/gtk-4.0/gtk.css"
    "$home/.config/zathura/zathurarc"
    "$home/.config/polybar/scripts/recording-status.sh"
  )

  # Bloqueo: imagen del wallpaper del modo desenfocada, sin captura por bloqueo.
  if [[ ! -x "$home/.config/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh" ]]; then
    error "Falta i3lock-fancy.sh ejecutable (bloqueo con blur)"
    failures=$((failures + 1))
  elif ! grep -q 'i3lock -i' "$home/.config/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh"; then
    error "i3lock-fancy.sh no usa i3lock -i (bloqueo con blur estático)"
    failures=$((failures + 1))
  fi

  for screen_file in "$home/.config/bspwm/scripts/screen-record.sh" \
                     "$home/.config/bspwm/scripts/recording-tray.py" \
                     "$home/.config/polybar/scripts/recording-status.sh"; do
    if [[ ! -x "$screen_file" ]]; then
      error "Falta $screen_file (grabación de pantalla)"
      failures=$((failures + 1))
    fi
  done
  if ! grep -q '^super + shift + g$' "$home/.config/sxhkd/sxhkdrc" 2>/dev/null; then
    error "sxhkd no tiene Super+Shift+G para grabar pantalla"
    failures=$((failures + 1))
  fi
  if ! grep -q 'module_show' "$home/.config/bspwm/scripts/screen-record.sh" 2>/dev/null ||
     ! grep -q 'module_hide' "$home/.config/bspwm/scripts/screen-record.sh" 2>/dev/null; then
    error "screen-record.sh no oculta/muestra el módulo recording de polybar"
    failures=$((failures + 1))
  fi
  if ! grep -q 'get-default-source' "$home/.config/bspwm/scripts/screen-record.sh" 2>/dev/null ||
     ! grep -q 'amix' "$home/.config/bspwm/scripts/screen-record.sh" 2>/dev/null; then
    error "screen-record.sh no mezcla micrófono + sistema (get-default-source/amix)"
    failures=$((failures + 1))
  fi
  if ! grep -q 'dwm-setup/monitors' "$home/.config/bspwm/scripts/screen-record.sh" 2>/dev/null ||
     grep -q 'xrandr --listmonitors' "$home/.config/bspwm/scripts/screen-record.sh" 2>/dev/null; then
    error "screen-record.sh debe leer la caché de monitores y no llamar a xrandr"
    failures=$((failures + 1))
  fi
  if ! grep -q 'write_monitor_cache' "$home/.config/bspwm/scripts/display-setup.sh" 2>/dev/null; then
    error "display-setup.sh no escribe la caché de monitores"
    failures=$((failures + 1))
  fi
  if ! grep -q 'auto)' "$home/.config/bspwm/scripts/display-setup.sh" 2>/dev/null ||
     ! grep -q 'drm_signature' "$home/.config/bspwm/scripts/display-setup.sh" 2>/dev/null; then
    error "display-setup.sh no aplica la política auto (120/60) ni vigila /sys/class/drm"
    failures=$((failures + 1))
  fi
  if ! grep -q 'display-setup.sh watch' "$home/.config/bspwm/scripts/autostart" 2>/dev/null; then
    error "autostart no inicia el watcher de pantalla (hotplug)"
    failures=$((failures + 1))
  fi
  if [[ ! -f "$home/.config/dwm-setup/display.conf" ]]; then
    error "Falta ~/.config/dwm-setup/display.conf"
    failures=$((failures + 1))
  fi
  if ! grep -q '^audio_mode=' "$home/.config/dwm-setup/recording.conf" 2>/dev/null; then
    error "Falta audio_mode en ~/.config/dwm-setup/recording.conf"
    failures=$((failures + 1))
  fi
  if ! grep -q 'format-background = ${colors.module-bg}' \
      "$home/.config/polybar/variants/reference/modules/recording.ini" 2>/dev/null; then
    error "El módulo recording de la variante B no usa el fondo del resto"
    failures=$((failures + 1))
  fi

  if [[ -f "$home/.config/vlc/vlcrc" ]] &&
     ! grep -q '^avcodec-hw=any' "$home/.config/vlc/vlcrc"; then
    error "VLC no tiene avcodec-hw=any (VA-API)"
    failures=$((failures + 1))
  fi
  if [[ -f "$home/.config/vlc/vlcrc" ]] &&
     ! grep -q '^vout=gl' "$home/.config/vlc/vlcrc"; then
    error "VLC no tiene vout=gl (salida compatible con VA-API)"
    failures=$((failures + 1))
  fi

  if ! grep -q '^set preview_images_method ueberzug' \
      "$home/.config/ranger/rc.conf" 2>/dev/null; then
    error "Ranger no usa ueberzug para las miniaturas"
    failures=$((failures + 1))
  fi

  local themed_file raw_hex hex known known_hex
  for themed_file in "${themed_files[@]}"; do
    [[ -f "$themed_file" ]] || continue
    while IFS= read -r raw_hex; do
      [[ -n "$raw_hex" ]] || continue
      hex=$(printf '%s' "$raw_hex" | tr 'A-F' 'a-f')
      case "$hex" in
        '#ff00ff'|'#00000000') continue ;;
      esac
      known=0
      for known_hex in "${palette_hex[@]}"; do
        if [[ "$hex" == "$known_hex" ]]; then
          known=1
          break
        fi
      done
      if (( known == 0 )); then
        error "Color fuera de la paleta ($THEME_NAME) en $themed_file: $raw_hex"
        failures=$((failures + 1))
      fi
    done < <(grep -oE '#[0-9A-Fa-f]{6,8}' "$themed_file" 2>/dev/null || true)
  done

  # El módulo governor va junto al cpu en ambas variantes.
  if [[ -f "$home/.config/polybar/config.ini" ]] &&
     ! grep -qE '^modules-right = .*\bcpu governor\b' "$home/.config/polybar/config.ini"; then
    error "La barra A no alterna el gobernador tras cpu (falta 'governor' en modules-right)"
    failures=$((failures + 1))
  fi
  if [[ -f "$home/.config/polybar/variants/reference/config.ini" ]] &&
     ! grep -qE '^modules-left = .*\bgovernor\b' "$home/.config/polybar/variants/reference/config.ini"; then
    error "La barra B no integra el gobernador en la izquierda (falta 'governor' en modules-left)"
    failures=$((failures + 1))
  fi

  # Módulo de ventilador: presente en A y B, y helper root instalado.
  if [[ -f "$home/.config/polybar/config.ini" ]] &&
     ! grep -qE '^modules-right = .*\bfan\b' "$home/.config/polybar/config.ini"; then
    error "La barra A no incluye el módulo fan"
    failures=$((failures + 1))
  fi
  if [[ -f "$home/.config/polybar/variants/reference/config.ini" ]] &&
     ! grep -qE '^modules-left = .*\bfan\b' "$home/.config/polybar/variants/reference/config.ini"; then
    error "La barra B no incluye el módulo fan"
    failures=$((failures + 1))
  fi
  if [[ -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]] &&
     [[ ! -f /etc/sudoers.d/dwm-setup-power-profile ]]; then
    error "Falta /etc/sudoers.d/dwm-setup-power-profile"
    failures=$((failures + 1))
  fi
  if [[ -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]] &&
     [[ ! -x /usr/local/bin/dwm-setup-power-profile ]]; then
    error "Falta /usr/local/bin/dwm-setup-power-profile"
    failures=$((failures + 1))
  fi
  if [[ ! -x /usr/local/bin/dwm-setup-fan-mode ]]; then
    error "Falta /usr/local/bin/dwm-setup-fan-mode"
    failures=$((failures + 1))
  elif [[ -e /sys/devices/platform/asus-nb-wmi/fan_boost_mode ||
          -e /sys/devices/platform/asus-nb-wmi/throttle_thermal_policy ||
          -r /sys/firmware/acpi/platform_profile ]] &&
       [[ ! -f /etc/sudoers.d/dwm-setup-fan-mode ]]; then
    error "Falta /etc/sudoers.d/dwm-setup-fan-mode con soporte de ventilador"
    failures=$((failures + 1))
  fi

  # La cuenta necesaria para el cliente del módulo.
  local module_script="$home/.config/polybar/scripts/cpu-governor.sh"
  if [[ -f "$module_script" && ! -x "$module_script" ]]; then
    error "cpu-governor.sh no es ejecutable"
    failures=$((failures + 1))
  fi

  # picom: vsync es el núcleo anti-tearing; el resto se leen del conf.
  if [[ -f "$home/.config/picom/picom.conf" ]]; then
    if ! grep -qE '^vsync[[:space:]]*=[[:space:]]*true;' "$home/.config/picom/picom.conf"; then
      error "picom.conf no tiene vsync = true"
      failures=$((failures + 1))
    fi
    if ! grep -qE '^shadow[[:space:]]*=[[:space:]]*true;' "$home/.config/picom/picom.conf"; then
      error "picom.conf no activa las sombras sutiles (ADR-110)"
      failures=$((failures + 1))
    fi
    if ! grep -qE '^shadow-opacity[[:space:]]*=[[:space:]]*0?\.35;' "$home/.config/picom/picom.conf"; then
      error "picom.conf no tiene shadow-opacity = 0.35"
      failures=$((failures + 1))
    fi
    if grep -qE '^blur-background[[:space:]]*=[[:space:]]*true;' "$home/.config/picom/picom.conf"; then
      error "picom.conf activa blur (no permitido: sin blur ni transparencias)"
      failures=$((failures + 1))
    fi
    local rofi_excl
    rofi_excl=$(grep -c "class_g = 'Rofi'" "$home/.config/picom/picom.conf" 2>/dev/null || true)
    if ((rofi_excl < 3)); then
      error "picom.conf no excluye rofi de sombra/redondeo/fade (class_g = 'Rofi')"
      failures=$((failures + 1))
    fi
    if ! grep -q "window_type = 'menu'" "$home/.config/picom/picom.conf"; then
      error "picom.conf no excluye los menús de la sombra (doble recuadro en Brave)"
      failures=$((failures + 1))
    fi
    for rounded_menu in "window_type = 'menu'" "window_type = 'popup_menu'" \
                        "window_type = 'dropdown_menu'" "window_type = 'tooltip'"; do
      if ! grep -q "$rounded_menu" "$home/.config/picom/picom.conf"; then
        error "picom.conf no excluye $rounded_menu del redondeo (doble recuadro en Brave)"
        failures=$((failures + 1))
      fi
    done
  fi

  if ! grep -q '^hwdec=vaapi' "$home/.config/mpv/mpv.conf" 2>/dev/null; then
    error "mpv.conf no activa VA-API (hwdec=vaapi) en la iGPU"
    failures=$((failures + 1))
  fi

  # ytwatch: buscador TUI solo si el bloque está habilitado (--no-ytwatch lo salta).
  if [[ "${INSTALL_YTWATCH:-yes}" == "yes" ]]; then
    for tw_path in "$home/.local/bin/ytwatch" \
      "$home/.config/ytwatch/config.toml" \
      /usr/bin/ueberzugpp; do
      if [[ -e "$tw_path" ]]; then
        debug "ok: $tw_path"
      else
        error "Falta el archivo requerido: $tw_path"
        failures=$((failures + 1))
      fi
    done
    if [[ -x "$home/.local/bin/ytwatch" ]]; then
      debug "ok: ytwatch ejecutable"
    else
      error "ytwatch no es ejecutable"
      failures=$((failures + 1))
    fi
    for tw_unit in "$home/.config/systemd/user/dwm-setup-yt-update-notify.service" \
      "$home/.config/systemd/user/dwm-setup-yt-update-notify.timer" \
      "$home/.config/systemd/user/timers.target.wants/dwm-setup-yt-update-notify.timer" \
      /usr/local/bin/yt-update-notify; do
      if [[ -e "$tw_unit" ]]; then
        debug "ok: $tw_unit"
      else
        error "Falta el aviso de YouTube: $tw_unit"
        failures=$((failures + 1))
      fi
    done
  fi

  # Escritorios dinámicos (ADR-112): arranca con uno, workspace.sh
  # instalado, daemon lanzado desde bspwmrc y sin bloque hjkl viejo.
  if [[ -f "$home/.config/bspwm/bspwmrc" ]]; then
    if grep -q 'bspc monitor -d 1 2 3' "$home/.config/bspwm/bspwmrc"; then
      error "bspwmrc sigue creando escritorios fijos (ADR-112: debe ser -d 1)"
      failures=$((failures + 1))
    elif ! grep -q 'bspc monitor -d 1$' "$home/.config/bspwm/bspwmrc"; then
      error "bspwmrc no arranca con un solo escritorio (bspc monitor -d 1)"
      failures=$((failures + 1))
    fi
    if ! grep -q 'workspace.sh daemon' "$home/.config/bspwm/bspwmrc"; then
      error "bspwmrc no lanza el daemon de escritorios dinámicos"
      failures=$((failures + 1))
    fi
  fi
  if [[ -f "$home/.config/sxhkd/sxhkdrc" ]]; then
    if grep -q 'super + {_,shift + }{h,j,k,l}' "$home/.config/sxhkd/sxhkdrc"; then
      error "sxhkdrc mantiene el bloque Super+h/j/k/l retirado por ADR-112"
      failures=$((failures + 1))
    fi
    if ! grep -q 'workspace.sh next' "$home/.config/sxhkd/sxhkdrc"; then
      error "sxhkdrc no registra Ctrl+Tab de escritorios (workspace.sh next)"
      failures=$((failures + 1))
    fi
  fi

  # prime-run: render offload NVIDIA (ADR-111). Si existe, debe ser
  # ejecutable y activar el offload; si hay driver cargado sin wrapper,
  # es una instalación incompleta.
  if [[ -e /usr/local/bin/prime-run ]]; then
    if [[ -x /usr/local/bin/prime-run ]]; then
      debug "ok: prime-run ejecutable"
    else
      error "prime-run no es ejecutable"
      failures=$((failures + 1))
    fi
    if grep -q '__NV_PRIME_RENDER_OFFLOAD' /usr/local/bin/prime-run; then
      debug "ok: prime-run usa render offload"
    else
      error "prime-run no activa el offload (falta __NV_PRIME_RENDER_OFFLOAD)"
      failures=$((failures + 1))
    fi
  elif [[ "$HAS_NVIDIA" -eq 1 && -d /proc/driver/nvidia ]]; then
    error "Hay driver NVIDIA cargado y falta /usr/local/bin/prime-run"
    failures=$((failures + 1))
  fi

  # sysctl persistente (ADR del ajuste de swap).
  if [[ -f /etc/sysctl.d/99-dwm-setup-swappiness.conf ]]; then
    if [[ "$(cat /proc/sys/vm/swappiness 2>/dev/null || printf '')" == "10" ]]; then
      debug "ok: vm.swappiness = 10"
    else
      warn "vm.swappiness no es 10 todavía (se aplica con sysctl --system o al reiniciar)"
    fi
  else
    error "Falta /etc/sysctl.d/99-dwm-setup-swappiness.conf"
    failures=$((failures + 1))
  fi

  # Gobernador: helper root, sudoers acotado y unidad de arranque.
  for gov_path in /usr/local/bin/dwm-setup-cpu-governor \
    /etc/sudoers.d/dwm-setup-cpu-governor \
    /etc/systemd/system/dwm-setup-cpu-governor.service; do
    if [[ -e "$gov_path" ]]; then
      debug "ok: $gov_path"
    else
      error "Falta el archivo requerido: $gov_path"
      failures=$((failures + 1))
    fi
  done
  if [[ -e /etc/sudoers.d/dwm-setup-cpu-governor ]]; then
    if [[ "$(stat -c '%a' /etc/sudoers.d/dwm-setup-cpu-governor)" != "440" ]]; then
      error "El fragmento de sudoers del gobernador no está 0440"
      failures=$((failures + 1))
    fi
  fi
  if ! grep -q 'NOPASSWD: /usr/local/bin/dwm-setup-cpu-governor' \
    /etc/sudoers.d/dwm-setup-cpu-governor 2>/dev/null; then
    error "El sudoers del gobernador no autoriza exactamente /usr/local/bin/dwm-setup-cpu-governor"
    failures=$((failures + 1))
  fi
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-enabled dwm-setup-cpu-governor.service >/dev/null 2>&1; then
      debug "ok: unidad del gobernador habilitada"
    else
      error "dwm-setup-cpu-governor.service no está habilitada"
      failures=$((failures + 1))
    fi
  fi

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
  if ! grep -q 'set_headset_mic_gain' "$home/.config/bspwm/scripts/audio-switch.sh" 2>/dev/null; then
    error "audio-switch.sh no corrige el boost del micro del jack ALC255"
    failures=$((failures + 1))
  fi

  # El sxhkd hijo del modo resize debe cerrar con Escape.
  if [[ -f "$home/.config/sxhkd/resize-mode.sxhkdrc" ]] &&
     ! grep -q 'resize-mode.sh stop' "$home/.config/sxhkd/resize-mode.sxhkdrc"; then
    error "resize-mode.sxhkdrc no cierra el modo con Escape"
    failures=$((failures + 1))
  fi

  # Brave: navegador del escritorio (ADR-113) con policies de privacidad.
  if ! command -v brave-browser >/dev/null 2>&1; then
    error "Brave no está instalado"
    failures=$((failures + 1))
  fi
  local brave_policy=/etc/brave/policies/managed/dwm-setup.json
  if [[ -f "$brave_policy" ]]; then
    for key in '"BraveP3AEnabled": false' '"BraveStatsPingEnabled": false' \
               '"BraveWebDiscoveryEnabled": false' '"BraveRewardsDisabled": true' \
               '"BookmarkBarEnabled": false' '"NewTabPageLocation"'; do
      if ! grep -q "$key" "$brave_policy"; then
        error "Brave: falta $key en $brave_policy"
        failures=$((failures + 1))
      fi
    done
    if ! grep -q 'gfbliohnnapiefjpjlpjnehglfpaknnc' "$brave_policy"; then
      error "Brave: SurfingKeys no está forzada en las policies"
      failures=$((failures + 1))
    fi
    # Los dos temas Catppuccin quedan instalados pero no forzados: son
    # opcionales, el escritorio usa «Usar GTK» (ADR-115).
    local theme_bad
    theme_bad=$(python3 - "$brave_policy" <<'PYCHK' 2>/dev/null || printf 'policy ilegible\n'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
settings = data.get("ExtensionSettings", {})
for ext_id, name in (
    ("bkkmolkhemgaeaeggcmfbghljjjoofoh", "Mocha"),
    ("jhjnalhegpceacdhbplhnakmkdliaddd", "Latte"),
):
    mode = settings.get(ext_id, {}).get("installation_mode")
    if mode != "normal_installed":
        print(f"{name}: installation_mode={mode!r} (se espera 'normal_installed')")
PYCHK
)
    if [[ -n "$theme_bad" ]]; then
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        error "Brave: tema $line"
        failures=$((failures + 1))
      done <<<"$theme_bad"
    fi
  else
    error "Falta $brave_policy"
    failures=$((failures + 1))
  fi

  # Página de nueva pestaña propia (policy NewTabPageLocation). Vive en el
  # home para que theme-mode la re-renderice sin sudo; /usr/share es un
  # symlink que mantiene la ruta de la policy.
  local newtab_user="$home/.local/share/dwm-setup/newtab.html"
  local newtab_link=/usr/share/dwm-setup/newtab.html
  if [[ ! -f "$newtab_user" ]]; then
    error "Falta la NTP de Brave: $newtab_user"
    failures=$((failures + 1))
  else
    local nt_bg nt_fg
    nt_bg=$(theme_var COLOR_BG)
    nt_fg=$(theme_var COLOR_FG)
    if ! grep -Fq "background: $nt_bg" "$newtab_user"; then
      error "La NTP de Brave no usa el fondo del modo activo ($nt_bg)"
      failures=$((failures + 1))
    fi
    if ! grep -Fq "color: $nt_fg" "$newtab_user"; then
      error "La NTP de Brave no usa el texto del modo activo ($nt_fg)"
      failures=$((failures + 1))
    fi
    if grep -q '@COLOR_' "$newtab_user"; then
      error "La NTP de Brave conserva placeholders @COLOR_*@ sin renderizar"
      failures=$((failures + 1))
    fi
  fi
  if [[ ! -L "$newtab_link" ]]; then
    error "Falta el symlink $newtab_link -> $newtab_user"
    failures=$((failures + 1))
  elif [[ "$(readlink "$newtab_link")" != "$newtab_user" ]]; then
    error "El symlink $newtab_link no apunta a $newtab_user"
    failures=$((failures + 1))
  fi

  # Atajos nativos (solo si el perfil ya existe).
  local brave_prefs="$home/.config/BraveSoftware/Brave-Browser/Default/Preferences"
  if [[ -f "$brave_prefs" ]]; then
    for combo in 'Control+KeyN' 'Control+KeyP' 'Alt+KeyQ' 'Alt+KeyO' 'Alt+KeyK' \
                 'Alt+KeyN' 'Alt+Shift+KeyN' 'Control+Alt+KeyH' 'Control+Alt+KeyL' \
                 'Alt+KeyH' 'Alt+KeyL'; do
      if ! grep -q "$combo" "$brave_prefs"; then
        error "Brave: falta el atajo $combo en Preferences"
        failures=$((failures + 1))
      fi
    done
    # Interfaz minimalista: Brave reescribe Preferences en JSON compacto,
    # así que se comprueban los valores, no el texto.
    local bad
    bad=$(python3 - "$brave_prefs" <<'PYCHK' 2>/dev/null || printf 'Preferences ilegible\n'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
brave = data.get("brave", {})
ntp = brave.get("new_tab_page", {})
tabs = brave.get("tabs", {})
checks = (
    ("show_brave_news", ntp.get("show_brave_news"), False),
    ("show_side_panel_button", brave.get("show_side_panel_button"), False),
    ("always_hide_tab_close_button", tabs.get("always_hide_tab_close_button"), True),
    ("vertical_tabs_show_scrollbar", tabs.get("vertical_tabs_show_scrollbar"), False),
)
for name, got, want in checks:
    if got != want:
        print(f"{name} (valor {got!r}, se espera {want!r})")
PYCHK
)
    if [[ -n "$bad" ]]; then
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        error "Brave: interfaz minimalista sin aplicar: $line"
        failures=$((failures + 1))
      done <<<"$bad"
    fi
  fi

  # Brave usa «Usar GTK» (ADR-115): sin pack de la CWS y con el esquema
  # del sistema. xsettingsd pone el color del modo en caliente.
  if [[ -f "$brave_prefs" ]]; then
    local brave_theme_bad
    brave_theme_bad=$(python3 - "$brave_prefs" <<'PYCHK' 2>/dev/null || printf 'Preferences ilegible\n'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
theme = data.get("browser", {}).get("theme", {})
ext = data.get("extensions", {}).get("theme", {})
checks = (
    ("tema", ext.get("id"), ""),
    ("system_theme", ext.get("system_theme"), 1),
    ("esquema", theme.get("color_scheme2"), 0),
    ("follows_system_colors", theme.get("follows_system_colors"), False),
)
for name, got, want in checks:
    if got != want:
        print(f"{name} (valor {got!r}, se espera {want!r})")
if "pack" in ext:
    print(f"pack presente ({ext['pack']!r}); se espera Usar GTK")
for key in ("user_color2", "color_variant2"):
    if key in theme:
        print(f"{key} presente ({theme[key]!r}); se espera Usar GTK")
PYCHK
)
    if [[ -n "$brave_theme_bad" ]]; then
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        error "Brave: «Usar GTK» sin aplicar: $line"
        failures=$((failures + 1))
      done <<<"$brave_theme_bad"
    fi
  fi

  # VA-API: wrapper con --enable-features (Brave borra el flag de Local State).
  if [[ -f "$home/.local/bin/brave-browser" ]]; then
    if ! grep -q 'VaapiVideoDecoder' "$home/.local/bin/brave-browser"; then
      error "Wrapper de Brave sin --enable-features=VaapiVideoDecoder"
      failures=$((failures + 1))
    fi
    if ! grep -q 'brave-theme' "$home/.local/bin/brave-browser"; then
      error "Wrapper de Brave no aplica el tema (brave-theme)"
      failures=$((failures + 1))
    fi
  else
    error "Falta ~/.local/bin/brave-browser (wrapper de VA-API)"
    failures=$((failures + 1))
  fi
  if [[ -f "$home/.local/share/applications/brave-browser.desktop" ]] &&
     ! grep -q "^Exec=$home/.local/bin/brave-browser" \
       "$home/.local/share/applications/brave-browser.desktop"; then
    error "El .desktop de Brave no usa el wrapper de VA-API"
    failures=$((failures + 1))
  fi

  # Arranque: GRUB, módulos y timers (lib/boot.sh).
  if [[ -f /etc/default/grub ]]; then
    if ! grep -qx 'GRUB_TIMEOUT=0' /etc/default/grub; then
      error "GRUB_TIMEOUT no es 0 en /etc/default/grub"
      failures=$((failures + 1))
    fi
    if ! grep -qx 'GRUB_TIMEOUT_STYLE=hidden' /etc/default/grub; then
      error "GRUB_TIMEOUT_STYLE no es hidden en /etc/default/grub"
      failures=$((failures + 1))
    fi
  fi
  if [[ -f /etc/modules-load.d/nvidia.conf ]]; then
    error "nvidia-drm sigue cargándose en el boot (/etc/modules-load.d/nvidia.conf)"
    failures=$((failures + 1))
  fi
  if ! grep -qs 'OnBootSec=1h' /etc/systemd/system/systemd-tmpfiles-clean.timer.d/10-dwm-setup.conf; then
    error "Falta el drop-in de systemd-tmpfiles-clean.timer (OnBootSec=1h)"
    failures=$((failures + 1))
  fi
  if systemctl is-enabled --quiet NetworkManager-wait-online.service 2>/dev/null; then
    error "NetworkManager-wait-online sigue habilitado"
    failures=$((failures + 1))
  fi
  if [[ "$(systemctl is-enabled apt-daily-upgrade.timer 2>/dev/null || true)" != "masked" ]]; then
    error "apt-daily-upgrade.timer no está enmascarado (actualizaciones manuales)"
    failures=$((failures + 1))
  fi

  # Límite de carga de la batería (solo si el hardware lo expone).
  if compgen -G '/sys/class/power_supply/BAT*/charge_control_end_threshold' >/dev/null; then
    if ! systemctl is-enabled --quiet battery-charge-threshold.service 2>/dev/null; then
      error "battery-charge-threshold.service no está habilitado"
      failures=$((failures + 1))
    fi
    for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
      [[ -e "$f" ]] || continue
      if [[ "$(cat "$f" 2>/dev/null)" != "80" ]]; then
        error "Umbral de carga de $(basename "$(dirname "$f")") no es 80 ($(cat "$f" 2>/dev/null))"
        failures=$((failures + 1))
      fi
    done
  fi

  # kitty debe aceptar control remoto para que theme-mode lo recoloree.
  if [[ -f "$home/.config/kitty/kitty.conf" ]]; then
    if ! grep -qE '^allow_remote_control[[:space:]]+(socket-only|socket|yes)' \
         "$home/.config/kitty/kitty.conf"; then
      error "kitty.conf no permite control remoto; theme-mode no podrá recolorear kitty"
      failures=$((failures + 1))
    fi
    if ! grep -qE '^listen_on[[:space:]]+unix:kitty-\{kitty_pid\}' \
         "$home/.config/kitty/kitty.conf"; then
      error "kitty.conf no fija listen_on unix:kitty-{kitty_pid}"
      failures=$((failures + 1))
    fi
  fi

  # yt-dlp: el binario oficial en ~/.local/bin o, como respaldo, el de APT.
  if [[ -x "$home/.local/bin/yt-dlp" ]]; then
    debug "ok: yt-dlp oficial"
  elif cmd_exists yt-dlp; then
    warn "yt-dlp oficial ausente; yt-play usará el de Debian (puede fallar). Ejecuta: ytdlp-update"
  else
    error "Falta yt-dlp (ni ~/.local/bin/yt-dlp ni el paquete de Debian)"
    failures=$((failures + 1))
  fi

  # Las teclas multimedia deben apuntar a music-ctl.
  if [[ -f "$home/.config/sxhkd/sxhkdrc" ]] &&
     ! grep -q 'music-ctl play-pause' "$home/.config/sxhkd/sxhkdrc"; then
    error "sxhkdrc no tiene XF86AudioPlay -> music-ctl"
    failures=$((failures + 1))
  fi

  # fastfetch debe usar el logo PNG del modo, no el builtin.
  if [[ -f "$home/.config/fastfetch/config.jsonc" ]] &&
     ! grep -qE 'Neofet-(dark|light)\.png' "$home/.config/fastfetch/config.jsonc"; then
    error "fastfetch no apunta al logo Neofet-{dark,light}.png"
    failures=$((failures + 1))
  fi

  # fastfetch: 38;2 debe llevar R;G;B decimal; un hex sin '#' rompe el color.
  if [[ -f "$home/.config/fastfetch/config.jsonc" ]] &&
     grep -Eq '38;2;[0-9a-fA-F]{6}[;}]' "$home/.config/fastfetch/config.jsonc"; then
    error "fastfetch: color hex dentro de SGR 38;2 (debe ser R;G;B decimal)"
    failures=$((failures + 1))
  fi

  # zathura no debe invertir las páginas: rompe cómics e imágenes.
  if [[ -f "$home/.config/zathura/zathurarc" ]] &&
     grep -qE '^set[[:space:]]+recolor[[:space:]]+true' "$home/.config/zathura/zathurarc"; then
    error "zathurarc tiene recolor activo; los cómics se verán invertidos"
    failures=$((failures + 1))
  fi

  # El atajo de cambio de modo debe existir.
  if [[ -f "$home/.config/sxhkd/sxhkdrc" ]] &&
     ! grep -q 'theme-mode toggle' "$home/.config/sxhkd/sxhkdrc"; then
    error "sxhkdrc no tiene el atajo Super+Alt+t para theme-mode"
    failures=$((failures + 1))
  fi

  # Notificaciones de actualización: persistentes y con acción al clic.
  if [[ -f "$home/.config/dunst/dunstrc" ]]; then
    if ! grep -q '^    mouse_left_click = do_action' "$home/.config/dunst/dunstrc"; then
      error "dunstrc: mouse_left_click no es do_action (el toast no se puede pulsar)"
      failures=$((failures + 1))
    fi
    if ! grep -q '\[actualizaciones\]' "$home/.config/dunst/dunstrc"; then
      error "dunstrc: falta la regla [actualizaciones] (timeout = 0)"
      failures=$((failures + 1))
    fi
  fi
  if [[ -f "$home/.config/systemd/user/dwm-setup-yt-update-notify.service" ]] &&
     ! grep -q '^KillMode=process' "$home/.config/systemd/user/dwm-setup-yt-update-notify.service"; then
    error "yt-update-notify.service no tiene KillMode=process (el listener del clic moriría)"
    failures=$((failures + 1))
  fi

  # VLC debe seguir el modo activo (1 en oscuro, 0 en claro).
  local expected_vlc="${THEME_VLC_DARK:-1}"
  if [[ -f "$home/.config/vlc/vlcrc" ]]; then
    if ! grep -qx "qt-dark-palette=$expected_vlc" "$home/.config/vlc/vlcrc"; then
      error "VLC no sigue el modo activo (se espera qt-dark-palette=$expected_vlc)"
      failures=$((failures + 1))
    fi
    if ! grep -qx 'qt-privacy-ask=0' "$home/.config/vlc/vlcrc"; then
      error "vlcrc no desactiva el diálogo de privacidad (qt-privacy-ask=0)"
      failures=$((failures + 1))
    fi
  fi

  # Ranger: previews con el protocolo de kitty (ueberzug no está instalado).
  if [[ -f "$home/.config/ranger/rc.conf" ]] &&
     ! grep -qx 'set preview_images_method kitty' "$home/.config/ranger/rc.conf"; then
    error "ranger no usa preview_images_method kitty (las previews no se ven)"
    failures=$((failures + 1))
  fi

  # Asociaciones de archivos fuera del navegador.
  if cmd_exists xdg-mime; then
    local mime_pair mime want got
    for mime_pair in 'application/pdf:org.pwmt.zathura.desktop' \
                     'image/png:feh.desktop' 'video/mp4:vlc.desktop'; do
      mime="${mime_pair%%:*}"
      want="${mime_pair#*:}"
      got=$(run_user xdg-mime query default "$mime" 2>/dev/null || printf '')
      if [[ "$got" != "$want" ]]; then
        error "Asociación de $mime: se espera $want y hay '${got:-ninguna}'"
        failures=$((failures + 1))
      fi
    done
  fi

  # Tema GTK e iconos del modo activo.
  if [[ -f "$home/.config/gtk-3.0/settings.ini" ]]; then
    if ! grep -qx "gtk-theme-name=$THEME_GTK" "$home/.config/gtk-3.0/settings.ini"; then
      error "GTK3 no usa el tema del modo activo ($THEME_GTK)"
      failures=$((failures + 1))
    fi
    if ! grep -qx "gtk-icon-theme-name=$THEME_ICONS" "$home/.config/gtk-3.0/settings.ini"; then
      error "GTK3 no usa los iconos del modo activo ($THEME_ICONS)"
      failures=$((failures + 1))
    fi
  fi

  # xsettingsd publica el tema del modo por XSETTINGS; sin él, Brave y
  # las apps GTK no cambian en caliente (ADR-115).
  local xsettings_conf="$home/.config/xsettingsd/xsettingsd.conf"
  if [[ -f "$xsettings_conf" ]]; then
    if ! grep -qx "Net/ThemeName \"$THEME_GTK\"" "$xsettings_conf"; then
      error "xsettingsd no publica el tema del modo activo ($THEME_GTK)"
      failures=$((failures + 1))
    fi
    if ! grep -qx "Net/IconThemeName \"$THEME_ICONS\"" "$xsettings_conf"; then
      error "xsettingsd no publica los iconos del modo activo ($THEME_ICONS)"
      failures=$((failures + 1))
    fi
    if ! grep -qx "Gtk/ApplicationPreferDarkTheme $THEME_PREFERS_DARK" "$xsettings_conf"; then
      error "xsettingsd no publica la preferencia dark/light del modo activo"
      failures=$((failures + 1))
    fi
  fi
  if [[ -f "$home/.config/bspwm/scripts/autostart" ]] &&
     ! grep -q 'xsettingsd -c' "$home/.config/bspwm/scripts/autostart"; then
    error "autostart no arranca xsettingsd"
    failures=$((failures + 1))
  fi

  # theme-mode debe ser ejecutable y coherente con el modo guardado.
  if [[ -f "$home/.config/dwm-setup/mode" ]]; then
    local saved_mode
    saved_mode=$(<"$home/.config/dwm-setup/mode")
    if [[ "$saved_mode" == "dark" && "$THEME_NAME" != "mocha-black" ]] ||
       [[ "$saved_mode" == "light" && "$THEME_NAME" != "latte" ]]; then
      error "El modo guardado ($saved_mode) no coincide con la paleta activa ($THEME_NAME)"
      failures=$((failures + 1))
    fi
  fi

  if [[ -f /etc/modprobe.d/dwm-setup-i915.conf ]] &&
     ! grep -q 'enable_sagv=0' /etc/modprobe.d/dwm-setup-i915.conf; then
    error "i915 no tiene enable_sagv=0 (riesgo de apagones del monitor)"
    failures=$((failures + 1))
  fi

  if [[ "${HEADSET_QUIRK_INSTALLED:-0}" -eq 1 ]]; then
    if [[ ! -f /etc/modprobe.d/alsa-fx504.conf ]]; then
      error "Se esperaba /etc/modprobe.d/alsa-fx504.conf para el quirk ALC255"
      failures=$((failures + 1))
    elif ! grep -qx 'options snd-hda-intel model=alc255-asus' \
        /etc/modprobe.d/alsa-fx504.conf; then
      error "El quirk ALC255 debe ser 'options snd-hda-intel model=alc255-asus'"
      failures=$((failures + 1))
    else
      info "Quirk ALC255 instalado; requiere reiniciar para aplicar el micrófono"
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
    if ! grep -qE '^modules-right = .*\btray\b' "$home/.config/polybar/config.ini"; then
      error "La barra A no incluye el módulo tray"
      failures=$((failures + 1))
    fi
    for module in bluetooth ufw; do
      if ! grep -qE "^modules-right = .*\\b$module\\b" "$home/.config/polybar/config.ini"; then
        error "La barra A no incluye el módulo $module"
        failures=$((failures + 1))
      fi
    done
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
    if ! grep -qE '^modules-right = .*\btray\b' "$variant_config"; then
      error "La barra B no incluye el módulo tray"
      failures=$((failures + 1))
    fi
    for module in bluetooth ufw; do
      if ! grep -qE "^modules-right = .*\\b$module\\b" "$variant_config"; then
        error "La barra B no incluye el módulo $module"
        failures=$((failures + 1))
      fi
    done
  fi

  # Bluetooth: servicio activo para que el módulo pueda encenderlo, pero
  # adaptador apagado por defecto (AutoEnable=false).
  if ! grep -qE '^[[:space:]]*AutoEnable=false' /etc/bluetooth/main.conf 2>/dev/null; then
    error "Bluetooth no tiene AutoEnable=false en /etc/bluetooth/main.conf"
    failures=$((failures + 1))
  fi
  if ! systemctl is-enabled --quiet bluetooth 2>/dev/null; then
    error "bluetooth.service no está habilitado al arranque"
    failures=$((failures + 1))
  fi
  if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
    error "bluetooth.service no está activo"
    failures=$((failures + 1))
  fi

  # UFW: helper, sudoers, servicio activo y reglas aplicadas. ufw --force
  # enable puede aplicar reglas sin dejar la unidad activa; se acepta
  # cualquiera de las dos señales como estado real.
  if [[ ! -x /usr/local/bin/dwm-setup-ufw ]]; then
    error "Falta el helper ejecutable /usr/local/bin/dwm-setup-ufw"
    failures=$((failures + 1))
  fi
  local ufw_running=0
  if systemctl is-active --quiet ufw 2>/dev/null; then
    ufw_running=1
  elif run_root env LC_ALL=C /usr/sbin/ufw status 2>/dev/null |
       grep -q '^Status: active'; then
    ufw_running=1
  fi
  if ((ufw_running == 0)); then
    error "UFW no está activo (ni servicio ni reglas)"
    failures=$((failures + 1))
  fi
  if ! systemctl is-enabled --quiet ufw 2>/dev/null; then
    error "UFW no está habilitado al arranque"
    failures=$((failures + 1))
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
    "$shot_dir/Capturas"; do
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
