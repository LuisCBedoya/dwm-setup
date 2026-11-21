# Instalación y sistema

Detalle de instalación, hardware, backups y limitaciones. El
[README](../README.md) tiene el inicio rápido.

## Requisitos

- Debian 13 minimal en x86_64, con systemd.
- `git` instalado para clonar el repositorio.
- Usuario no-root con home real y `sudo`.
- Conexión a Internet durante la primera instalación.
- UEFI o BIOS. Con NVIDIA, Secure Boot `enabled` o no detectable omite el
  driver propietario; con Secure Boot desactivado se instala si hay GPU
  NVIDIA. `--nvidia` permite forzarlo.

## Qué hace el instalador

1. **Detección**: Debian 13 y x86_64 antes de pedir `sudo`; después VM, CPU,
   GPU, Secure Boot, resolución, cámaras, batería, backlight, WiFi, audio y
   sistema de archivos raíz.
2. **Directorios y backups**: crea `~/.config`, `~/.local`,
   `~/.config-backup` como el usuario y guarda la versión anterior de las
   configuraciones **antes** de escribir.
3. **Preflight APT**: lee `main`, `contrib`, `non-free` y
   `non-free-firmware`. Si falta `main`, aborta. Si faltan opcionales, ofrece
   añadirlos con backup, continuar sin ellos o cancelar. `--dry-run` y
   `--yes` no modifican repositorios.
4. **Paquetes**: base, Xorg, cadena de compilación (make, gcc, g++, cmake,
   meson, ninja, autotools), escritorio, audio/códecs, cámara,
   almacenamiento, red, fuentes, firmware, microcódigo y GPU.
5. **Fuente**: descarga JetBrainsMono Nerd Font 3.5.1, verifica SHA-256 y
   ejecuta `fc-cache`. Si falla, usa JetBrains Mono o monospace y avisa.
6. **Configuración**: renderiza bspwm, sxhkd, polybar, dunst, rofi, kitty
   y xsettingsd con la paleta activa (Mocha Black por defecto), el CSS de
   GTK y los defaults de Thunar; instala `.xinitrc`, wallpaper,
   `~/Imágenes/Capturas`, `desktop-safe` y `desktop-doctor`.
7. **Limpieza de restos**: retira restos de la barra anterior (`DesktopLogo`)
   con backup previo.
8. **Verificación**: comprueba binarios, ficheros, módulos de polybar,
   placeholders, permisos, propiedad del home, servicios, versiones y
   sintaxis POSIX de los binarios instalados.
9. **Autoremove**: después de verificar, marca la cadena de compilación como
   manual y ejecuta `apt-get -y autoremove` (sin `--purge`). Si falla, avisa
   y continúa; nunca deja el sistema a medias.

### Backups y logs

- Sistema: `/var/backups/luc-workspace/<timestamp>/`
- Usuario: `~/.config-backup/luc-workspace/<timestamp>/`
- Log: `~/.local/state/luc-workspace/install-<timestamp>.log`
  (fallback a `~/.cache/luc-workspace/`)
- Log de sesión (autostart): `~/.local/state/luc-workspace/session.log`

Los backups de usuario se hacen antes de renderizar. Si algo falla, la
versión anterior está en `~/.config-backup/`.

### Sesión (startx)

No se instala ningún display manager. `~/.xinitrc` configura el teclado y
hace `exec bspwm`; `bspwmrc` lanza sxhkd y el `autostart` interno, que
levanta picom (vsync), polybar, dunst, xwallpaper, udiskie, xss-lock,
lxpolkit y el notificador de batería baja, y desactiva el
salvapantallas/DPMS con `xset s off` y `xset -dpms`. La CPU arranca en
`performance` con la unidad `luc-workspace-cpu-governor.service` y se alterna
desde la barra.

```sh
# desde TTY1
startx
```

Si algo falla, entra por `Ctrl+Alt+F3` y revisa:

```sh
desktop-doctor
less ~/.local/state/luc-workspace/session.log
```

### Almacenamiento extraíble

`udiskie -N -a` monta el dispositivo y muestra una notificación. No se abre
ninguna ventana. Thunar se abre manualmente con `Super+Shift+F`.

**Móvil por cable (MTP)**: con `libmtp-runtime` (reglas udev) y el backend MTP
de gvfs, al conectar un Android y elegir *Transferencia de archivos* aparece
en la barra lateral de Thunar como "Dispositivo Android"; se copia en ambos
sentidos sin instalar nada en el teléfono. Si no aparece, reconectar el cable
o comprobarlo con `gio mount -l`.

### Audio y vídeo

PipeWire es el servidor; WirePlumber es el gestor de sesión. `pavucontrol`
sirve para elegir dispositivos. La aceleración VA-API/VDPAU depende de la
GPU y del firmware; `desktop-doctor` muestra el estado.

`audio-watch.sh` arranca desde `autostart` y aplica esta prioridad:

1. **Auriculares de cable** (`analog-output-headphones`).
2. **Audio USB** (auriculares con dongle inalámbrico, DAC o headset).
3. **Bluetooth** (`bluez_output.*`).
4. **HDMI** (`output:hdmi-stereo+input:analog-stereo`).
5. **Altavoces analógicos**.

El micrófono **del jack** queda en el **interno por defecto**
(`JACK_MIC=internal`): el ALC255 no detecta bien el headset y el cambio
de puerto reajusta el HDMI y apaga la pantalla. `JACK_MIC=headset` fuerza
el del headset y `manual` deja elegirlo en pavucontrol. El micro interno
usa `Internal Mic Boost=2` (+20 dB) y el headset `1` (+10 dB). La
grabación aplica `mic_gain=3.0` a la pista del micro. Los micrófonos
USB y Bluetooth siguen cambiando solos; con HDMI se mantiene el perfil
duplex para conservar el micro interno.

El watcher detecta las tarjetas/perfiles/puertos con `pactl`; no hardcodea
nombres. Solo reaplica la política cuando cambia el hardware conectado,
así una elección manual en `pavucontrol` se respeta hasta el siguiente
cambio. Conserva volumen/mute al cambiar de puerto en el mismo sink y
mueve los streams existentes.

Con Bluetooth, la música va en A2DP; cuando una aplicación graba,
WirePlumber cambia a HFP/HSP y vuelve a A2DP al terminar. No se puede
tener A2DP y micrófono a la vez: HFP baja la calidad mientras dura la
grabación.

Comandos manuales:

```sh
~/.config/bspwm/scripts/audio-switch.sh auto
~/.config/bspwm/scripts/audio-switch.sh headphones
~/.config/bspwm/scripts/audio-switch.sh usb
~/.config/bspwm/scripts/audio-switch.sh bluetooth
~/.config/bspwm/scripts/audio-switch.sh hdmi
~/.config/bspwm/scripts/audio-switch.sh analog
```

`yt-play` y `ytwatch` reproducen con mpv en la iGPU Intel: `mpv.conf`
activa `hwdec=vaapi` y salida EGL/Mesa, y el wrapper `~/.local/bin/mpv`
fuerza Mesa/Intel salvo que se lance con `prime-run`; la dGPU NVIDIA
sigue disponible para offload.

Si el jack combo de 3.5 mm no expone el micrófono del headset, el watcher
usa el micrófono interno. En el **ASUS FX504GE con ALC255** el instalador
detecta el modelo y ofrece el fixup `alc255-asus`
(`options snd-hda-intel model=alc255-asus`); en otros PCs no toca el
kernel. El micro del jack se queda en el **interno por defecto**
(`JACK_MIC=internal`) para no reajustar el HDMI; `JACK_MIC=headset` fuerza
el del headset y `manual` lo deja a pavucontrol. Al usar el micro del
jack con `headset`, `audio-switch.sh` deja el `Headset Mic Boost` en 1
y limita el `Capture Volume` a 55. Opciones:
`--headset-quirk` (forzar) y `--no-headset-quirk` (omitir). El quirk
requiere reiniciar.

Dunst reproduce `message-new-instant.oga` en cada notificación mediante una
regla con `script`; el sonido sale por el sink activo (HDMI, auriculares o
altavoces). `sound-theme-freedesktop` se instala como dependencia.
`stack_duplicates = false` evita que dos mensajes idénticos se agrupen en
un `(2)`; cada uno se muestra y suena. `gap_size = 6` deja 6 px entre
notificaciones. Los sonidos se serializan con `flock`, así que dos
notificaciones seguidas suenan una tras otra.

### Cámara

Se instala `v4l-utils` y `libcamera-tools` si está disponible. La prueba
real se ejecuta después de entrar en la sesión:

```sh
desktop-doctor --camera
```

Si acabas de ser añadido al grupo `video`, cierra sesión y vuelve a entrar.

## Migración desde `dwm-setup`

Si ya tienes una instalación anterior con el nombre viejo:

```sh
cd luc-workspace
sudo ./bin/luc-workspace-migrate --dry-run
sudo ./bin/luc-workspace-migrate
sudo reboot
```

El script mueve configuraciones, logs, cachés y backups a `luc-workspace`,
conserva los backups antiguos en `luc-workspace/legacy/`, elimina helpers,
units, sudoers, modprobe, sysctl, WirePlumber y policy de Brave con el
nombre viejo, y ejecuta el instalador nuevo. Es idempotente. Cierra Brave
antes de migrar. Después del reinicio, entra con `startx` y comprueba con
`desktop-doctor`.

## Diagnóstico y recuperación

```sh
desktop-doctor              # estado general
desktop-doctor --camera     # prueba real de captura
desktop-safe lock           # bloquear
desktop-safe suspend        # suspender (xss-lock bloquea antes)
desktop-safe logout         # cerrar sesión (bspc quit)
desktop-safe poweroff       # apagar
desktop-safe reboot         # reiniciar

xset q                      # ver salvapantallas y DPMS
```

La pantalla no se apaga por inactividad (`timeout: 0`, `DPMS is Disabled`).
Para revertir el comportamiento: `xset s default && xset +dpms`.

Si algo falla:

1. Entra por una TTY (`Ctrl+Alt+F3`).
2. Ejecuta `startx`.
3. Revisa `journalctl -b` y `~/.local/state/luc-workspace/`.
4. Comprueba que `~/.config/bspwm/bspwmrc` tiene permiso de ejecución.

## Qué incluye

Incluido:

- Debian 13 minimal, x86_64.
- Xorg + **startx** (sin display manager).
- **bspwm** + **sxhkd**.
- **polybar** con **16 módulos** (17 con backlight), más la bandeja del
  sistema (XEmbed): logo StumbleUpon, escritorios dinámicos, pomodoro, temperatura,
  RAM, CPU, **gobernador de CPU** (clic alterna performance/powersave + notificación),
  red unificada (`󰖩/󰈀 connected`, `󰖩 NoC` sin conexión), **Bluetooth**
  (apagado/encendido/conectado), **UFW** (`on`/`off` + reglas), servicios
  systemd, volumen, batería, fecha y actualizaciones (calavera + número).
  `font-1` 10 y `font-3` 13; logo en `font-0`.
- **dunst**, **rofi** (panel lateral izquierdo, también para los menús de la barra), **kitty**
  (`--single-instance`),
  **flameshot**. Shell **zsh** con Oh My Zsh/cypher, autosuggestions y
  **lsd**. Compositor **picom** (vsync + fade sutil + sombras sutiles,
  sin blur ni transparencias; ADR-107/ADR-110): mata el rasgado al
  arrastrar y hacer scroll y la barra B se ve translúcida con su fondo
  transparente. **xsettingsd** publica el tema GTK del modo para que
  Brave y las apps GTK cambien en caliente.
- **Pantallas**: `display-setup.sh` detecta los monitores conectados y usa
  su **resolución preferida (EDID)**; dentro de ella aplica la política
  `auto`: **120 Hz** (o 119.88) si el monitor lo ofrece, si no **60 Hz**
  (o 59.94), y si no la máxima disponible. `~/.config/luc-workspace/display.conf`
  permite fijar `layout=extend|mirror` y `refresh=auto|max|preferred|<Hz>`.
  Un watcher sobre `/sys/class/drm` re-aplica la política al conectar o
  desconectar un monitor (sin sondeo DDC) y refuerza el no-blanqueo. Brave usa **VA-API** para decodificar vídeo
  por GPU cuando el driver está disponible (actívalo en `brave://flags`,
  `VaapiVideoDecoder`).
- **ranger** con **zathura** para PDF/EPUB/DjVu/PS/CB, **VLC** para vídeo y
  previews de imagen con **ueberzug** (X11). Dentro de Herdr, la función
  `ranger` de zsh exporta `WINDOWID` como pista y el wrapper la corrige a
  la kitty real de Herdr; el wrapper `~/.local/bin/ueberzug` deja la
  imagen/PDF dentro del borde de la columna y la etiqueta con su pestaña
  real (`preview_tag.py`);
  `preview-sync` oculta la preview de las pestañas que no están
  enfocadas. VLC usa
  `avcodec-hw=any` y `vout=gl` para decodificar por **VA-API** sin los
  errores de conversión de X11. Texto, código y
  Markdown se abren con **Neovim**. Tema GTK **Catppuccin** (Mocha Black o
  Latte) e iconos **Papirus** con carpetas Catppuccin.
- Asociaciones de archivo: PDF/EPUB/CB → **zathura**, imágenes → **feh**,
  vídeo → **VLC** (`xdg-mime`, sin pasar por el navegador).
- Bloqueo con **i3lock** + **xss-lock**. El bloqueo manual y el de
  suspensión usan el wallpaper del modo (`light`/`dark`) desenfocado
  (`i3lock -i`, `-blur 0x18`) y cacheado; no se captura la pantalla en
  cada bloqueo.
- Directorios XDG (`Descargas`, `Documentos`, `Imágenes`, `Música`,
  `Vídeos`, etc.) creados por el instalador. Capturas en
  `~/Imágenes/Capturas` y grabaciones en `~/Vídeos/Grabaciones`; los
  `Downloads`/`Pictures` antiguos se conservan.
- Grabación de pantalla con **`Super+Shift+G`**: alterna empezar/parar,
  graba el monitor elegido (menú si hay varios) y **mezcla el audio del
  sistema con el micrófono**, usando el sink y el source por defecto
  (misma prioridad que `audio-watch`: jack > USB/BT > HDMI > interno).
  Guarda `grabacion-YYYY-MM-DD_HH-MM-SS.mkv`. El modo se cambia en
  `~/.config/luc-workspace/recording.conf` (`mix`, `system` o `mic`). Muestra
  un `● REC` (punto rojo, texto normal) en el módulo `recording` de
  polybar, que solo aparece mientras grabas.
- Pantalla siempre encendida: sin salvapantallas ni DPMS por inactividad.
  El bloqueo manual (`Super+Shift+L`) y el de suspensión siguen activos.
- Brillo, volumen, portapapeles y agente polkit (`lxpolkit`).
- PipeWire + WirePlumber + ALSA + pavucontrol.
- FFmpeg, `libavcodec-extra`, GStreamer y VA-API/VDPAU.
- Cámara UVC (`uvcvideo`, `v4l-utils`, `libcamera-tools` opcional).
- Almacenamiento extraíble con `udisks2` + `udiskie`: montaje automático y
  **solo notificación**; nunca se abre una aplicación automáticamente.
- Thunar como gestor de archivos puntual (`Super+Shift+F`), con la paleta
  global, sin menú, panel lateral ni barra de estado (Ctrl+M y F9 los
  recuperan) y **miniaturas** de imágenes, PDF y vídeo con `tumbler`.
- **fastfetch** con logo propio (`Neofet-light.png`/`Neofet-dark.png`) y
  módulos de hardware, software y tema.
- Fuente JetBrainsMono Nerd Font, wallpaper oscuro y paleta **Catppuccin**:
  `mocha-black` (oscuro) y `latte` (claro): base `#0d0d14` / `#eff1f5`,
  texto `#cdd6f4` / `#4c4f69`, acento `#89b4fa` / `#1e66f5`.
- **Brave** con Shields, SurfingKeys y **«Usar GTK»**: sigue el tema
  Catppuccin del modo en caliente (xsettingsd), sin packs de la CWS ni
  reinicio, y con atajos nativos de pestañas.
- **yt-play** para audio o vídeo de YouTube/YouTube Music con búsqueda en
  fzf y miniatura; `mpv` + `yt-dlp` oficial en `~/.local/bin`.
- **ytwatch** (opcional, `--no-ytwatch` para saltarlo): buscador TUI de
  YouTube con miniaturas (`ueberzugpp`), filtros, cola y descargas;
  usa el mismo yt-dlp oficial y mpv. Actualizable con `ytwatch-check` /
  `ytwatch-update`.
- **Herdr** (TUI de terminal): se instala en `~/.local/bin`; se abre
  escribiendo `herdr` en kitty. Pestañas y panes con `herdr-close`
  (Alt+Q cierra pane → pestaña); ranger y ytwatch muestran sus previews
  reales dentro de sus panes.
- **Avisos de YouTube por dunst**: timer de usuario
  (`luc-workspace-yt-update-notify.timer`, 13:00 diario; si el PC estaba
  apagado, corre al encender) que
  avisa con un solo toast si yt-dlp, ytwatch o ueberzugpp están viejos.
  No toca APT ni el módulo `updates` de la barra.
- `vm.swappiness = 10` por `/etc/sysctl.d/99-luc-workspace-swappiness.conf`
  (23 GB de RAM: menos swap y SSD más tranquilo).
- Arranque más corto (`lib/boot.sh`): `GRUB_TIMEOUT=0` +
  `GRUB_TIMEOUT_STYLE=hidden` (Shift/Esc muestra el menú), nvidia fuera
  de `modules-load.d`, limpieza de `/tmp` diferida 1 h,
  `NetworkManager-wait-online` desactivado y `apt-daily-upgrade.timer`
  enmascarado (actualizaciones manuales; `apt-daily.timer` sigue para
  los metadatos del módulo `updates`). El instalador ejecuta
  `apt-get clean` al final para no dejar GB en `/var/cache/apt`.
- Límite de carga de la batería al **80 %** (`lib/power.sh`): unidad
  `battery-charge-threshold.service` + helper
  `luc-workspace-battery-limit`; solo se instala si el hardware expone
  `charge_control_end_threshold` (ASUS/TUF y similares).
  `desktop-doctor` avisa si la salud de la batería baja del 60 %.
- La barra usa `COLOR_BAR_ACCENT` (mocha `#89b4fa`, latte lavanda
  `#7287fd`): el acento de la barra puede ser más suave que el acento
  general del modo. El borde de la ventana enfocada usa
  `COLOR_FOCUS_BORDER` (mocha `#89b4fa`, latte lavanda suave `#8b9cf7`). Fondos
  personales: `~/.local/share/wallpapers/local-dark.png` y
  `local-light.png` (el instalador no los toca).
- Modo del ventilador con un clic en la barra (`fan`, tras `governor`):
  ASUS `fan_boost_mode`/`throttle_thermal_policy` (normal/overboost/silent)
  o `platform_profile` genérico (quiet/balanced/performance). Se oculta en
  equipos sin soporte y usa un sudoers acotado para el helper. El clic
  cicla `auto → normal → overboost → silent → auto`; en `auto` el daemon
  `luc-workspace-fan-auto` sube a overboost a 80 °C/80 % (10 s) y baja a
  normal a 70 °C/<40 % (30 s).
- Perfil de energía automático (`luc-workspace-power-auto`): con cargador
  `performance` + EPP performance; con batería `powersave` + EPP
  `balance_performance` + suelo de 1.2 GHz (sin la lentitud del powersave
  puro). El clic del módulo `governor` aplica el mismo perfil completo.
- Backups, logs, `--dry-run` y diagnóstico con `desktop-doctor`.
- NVIDIA detectada e instalada de forma condicional; con driver
  propietario deja `prime-run` para render offload por app a la dGPU y
  el ICD de Vulkan (ADR-111). La Intel sigue siendo la GPU primaria.

No incluido todavía:

- IDE (VS Code), Firefox ESR, correo, Teams y reproductores de música
  locales (cmus/mpd). Brave y el streaming (`yt-play`, `ytwatch`) sí están.
- htop, ripgrep, nvitop/nvtop, Node/nvm.
- XFCE, LightDM o un entorno de escritorio completo.
- Repositorio de dotfiles externo: las plantillas de este repo son la
  fuente de verdad.

## Estructura del repositorio

```text
install.sh                 Entrada principal
lib/common.sh              Logs, sudo, ownership, backups, render
lib/detect.sh              Detección de sistema/hardware
lib/packages.sh            Grupos de paquetes, compilación, Nerd Font y autoremove
lib/bspwm.sh               bspwm, bspwmrc, autostart y .xinitrc
lib/sxhkd.sh               sxhkdrc
lib/polybar.sh             polybar config/modules/scripts/launch
lib/dunst.sh               dunstrc
lib/rofi.sh                rofi powermenu
lib/kitty.sh               kitty.conf y paleta del terminal
lib/zsh.sh                 zsh, Oh My Zsh y lsd
lib/ranger.sh              ranger, zathura y VLC
lib/gpu.sh                 configuración Intel/NVIDIA
lib/gtk.sh                 temas GTK Catppuccin, iconos y xsettingsd.conf
lib/vlc.sh                 VLC con paleta oscura
lib/config.sh              Configs de usuario, wallpaper y binarios
lib/fastfetch.sh           fastfetch y logos Neofet-{light,dark}.png
lib/music.sh               yt-dlp oficial, scripts de streaming y teclas
lib/brave.sh               Brave: repo APT, policies, atajos, temas y SurfingKeys
lib/ufw.sh                 Firewall UFW: helper root, sudoers y reglas base
lib/verify.sh              Verificación estática final
lib/theme.sh               Paletas (Mocha Black, Latte) y render
lib/audio.sh               Quirk ALC255 condicionado por hardware
bin/desktop-safe           Acciones de sesión
bin/desktop-doctor         Diagnóstico y cámara (POSIX sh)
bin/luc-workspace-ufw      Helper root acotado del módulo UFW
bin/luc-workspace-migrate  Migración de dwm-setup a luc-workspace
bin/theme-mode             Cambio dark/light en caliente
bin/brave-theme            Asegura «Usar GTK» en Brave (sin sudo)
bin/yt-play                Audio o vídeo de YouTube (URL o búsqueda con fzf)
bin/yt-preview             Miniatura para el preview de fzf
bin/ytdlp-check            Aviso de versión nueva de yt-dlp
bin/ytdlp-update           Actualización de yt-dlp con .bak y rollback
bin/ytdlp-rollback         Restaura la copia anterior de yt-dlp
bin/music-ctl              Teclas multimedia del reproductor activo
bin/ytwatch-check          Aviso de versión nueva (ytwatch/ueberzugpp, dunst)
bin/ytwatch-update         Actualiza ytwatch o ueberzugpp (--ueberzugpp)
lib/ytwatch.sh             Instalación de ytwatch y ueberzugpp con SHA-256
lib/herdr.sh               Instalación de Herdr con SHA-256, config y preview_tag
templates/bspwm/           bspwmrc.in, autostart.in, scripts/
templates/sxhkd/           sxhkdrc.in
templates/polybar/         config.ini.in, modules/, scripts/ y variants/
templates/dunst/           dunstrc.in, notification-sound.sh.in
templates/rofi/            powermenu.rasi.in y config.rasi.in
templates/kitty/           kitty.conf.in y colorshemes/
templates/zsh/             zshrc.in
templates/lsd/             config.yml e icons.yaml
templates/ranger/          rc.conf, rifle.conf y previews
templates/herdr/           config.toml.in (atajos y tema) y preview_tag.py
templates/xorg/            configuración Xorg por hardware
templates/gtk/             settings GTK2/3/4 y CSS
templates/xsettingsd/      xsettingsd.conf.in (tema GTK del modo)
templates/vlc/             vlcrc (oscuro o claro según el modo)
templates/zathura/         zathurarc.in
templates/themes/          catppuccin-mocha-blue y catppuccin-latte-blue
templates/fastfetch/       config.jsonc.in
templates/opencode/        mocha-black.json (tema Catppuccin con #0d0d14)
assets/fastfetch/          Neofet-{light,dark}.png (logos de fastfetch)
templates/icons/           papirus-folders y carpetas cat-*
templates/modprobe/        i915.conf y nvidia.conf
templates/modprobe/        alsa-fx504.conf (quirk ALC255)
templates/recording/       recording.conf (modo de audio de la grabación)
templates/display/         display.conf (layout y refresh de pantalla)
templates/colors/          palette-mocha-black.sh y palette-latte.sh
assets/wallpaper.png       Wallpaper por defecto de dark
assets/wallpaper-alt.png   Wallpaper por defecto de light
docs/                      Hardware y testing
```

## Limitaciones conocidas

- No hay validación desde cero en VM Debian 13 todavía; la sesión viva se
  validó el 2026-10-24.
- La cámara, el montaje USB, el audio/códecs y NVIDIA/PRIME necesitan
  hardware real o pass-through de VM.
- NVIDIA propietario y Secure Boot requiere MOK; si Secure Boot no está
  desactivado, el driver se omite y se avisa.
- `libcamera-tools`, firmware y drivers propietarios son opcionales.
- El instalador añade el repo APT oficial de Brave (ADR-113, autorizado por
  el usuario) y con él instala el navegador. Fuera de eso no modifica otros
  repositorios: solo la opción 1 del menú añade componentes a entradas
  oficiales de Debian 13, tras un backup.
- Se instala Brave como navegador del escritorio; no se instalan IDE,
  cliente de correo ni reproductores de música locales. El streaming de
  YouTube se hace con `yt-play` y, opcionalmente, `ytwatch` (TUI).
- `/etc/brave/policies/managed/luc-workspace.json` apaga la telemetría de Brave y
  fuerza SurfingKeys; los temas Catppuccin Mocha y Latte quedan instalados
  (`normal_installed`) como opcionales. Brave usa «Usar GTK» y sigue el
  tema del modo por `xsettingsd`.
- Firefox, OpenH264 y sus policies/autoconfig se retiran en la migración.
- Los atajos `Super+Shift+p/v/i/a` existen en `sxhkdrc` pero las apps
  (`pcmanfm`, `codium`, `ristretto`, `lxappearance`) no se
  instalan en esta fase. `codium` requiere el repositorio de VSCodium.
  `Super+Shift+e` es logout; el editor se movió a `Super+Shift+v`.
- `Super+Shift+s` usa `scrot`: selecciona región y copia al portapapeles, sin
  dejar archivo. La línea de selección es magenta (`#FF00FF`), 2 px y opacidad
  total para verse sobre fondo blanco; se usa `--line mode=edge` y un
  `xrefresh` posterior para borrar el rectángulo residual. `--freeze` se
  descartó porque en pruebas capturaba la pantalla completa. La notificación
  muestra una miniatura del recorte (64 px) desde
  `~/.cache/dunst/last-screenshot.png`. No tiene anotaciones; flameshot
  sigue instalado para eso.
- `Print` captura toda la pantalla y la copia al portapapeles, también con
  miniatura en la notificación y sin dejar archivo. `Super+Print` mantiene el
  menú de capturas.
- El watcher de audio solo puede activar una salida a la vez (auriculares,
  HDMI o altavoces). Si el usuario elige un headset USB/Bluetooth, no lo
  pisa.
- El quirk `alc255-asus` está condicionado a ASUS FX504GE/ALC255; en otros
  PCs no se aplica. Requiere reinicio y está pendiente de validación en
  hardware real.
- Bluetooth está incluido como módulo de polybar y menú de dispositivos.
  El pareo con PIN puede requerir `bluetoothctl` en terminal; los
  auriculares suelen usar Just Works.
