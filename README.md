# bspwm + polybar · Debian 13 (fase 1b)

Instalador reproducible de un escritorio mínimo sobre **Debian 13 (trixie)**:
Xorg, bspwm, sxhkd, polybar, dunst, rofi, kitty, xwallpaper,
flameshot, i3lock/xss-lock, PipeWire, cámara UVC y montaje de discos
extraíbles con notificación.

> **Estado:** fase 1b implementada y validada en la sesión viva del
> 2026-10-24 (Debian 13, Intel + NVIDIA, 1920x1080). Falta la validación
> desde cero en una VM Debian 13 minimal y subir el repositorio.
>
> La sesión se inicia **a mano** con `startx` desde TTY. No se instala
> display manager ni auto-login.

## Alcance

Incluido:

- Debian 13 minimal, x86_64.
- Xorg + **startx** (sin display manager).
- **bspwm** + **sxhkd**.
- **polybar** con **13 módulos** (14 con backlight), más la bandeja del
  sistema (XEmbed): logo StumbleUpon, workspaces 1-7, pomodoro, temperatura,
  RAM, CPU, **gobernador de CPU** (clic alterna performance/powersave + notificación),
  red unificada (`󰖩/󰈀 connected`, `󰖩 NoC` sin conexión), servicios
  systemd, volumen, batería, fecha y actualizaciones (calavera + número).
  `font-1` 10 y `font-3` 13; logo en `font-0`.
- **dunst**, **rofi** (y **dmenu** para el módulo de servicios), **kitty**
  (`--single-instance`),
  **flameshot**. Shell **zsh** con Oh My Zsh/cypher, autosuggestions y
  **lsd**. Compositor **picom** (vsync + fade sutil, sin sombras/blur/
  transparencias; ADR-107): mata el rasgado al arrastrar y hacer scroll y
  la barra B se ve translúcida con su fondo transparente.
- **ranger** con **zathura** para PDF/EPUB/DjVu/PS/CB, **VLC** para vídeo,
  **ueberzug** para previsualizar imágenes y carátulas. Texto, código y
  Markdown se abren con **Neovim**. Tema GTK **Catppuccin** (Mocha Black o
  Latte) e iconos **Papirus** con carpetas Catppuccin.
- Bloqueo con **i3lock** + **xss-lock**.
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
  recuperan).
- **fastfetch** con logo propio (`Neofet.png`) y módulos de hardware,
  software y tema.
- Fuente JetBrainsMono Nerd Font, wallpaper oscuro y paleta **Catppuccin**:
  `mocha-black` (oscuro) y `latte` (claro): base `#0d0d14` / `#eff1f5`,
  texto `#cdd6f4` / `#4c4f69`, acento `#89b4fa` / `#1e66f5`.
- **Firefox ESR** con uBlock Origin, SurfingKeys y OpenH264 para WebRTC.
- **yt-play** para audio o vídeo de YouTube/YouTube Music con búsqueda en
  fzf y miniatura; `mpv` + `yt-dlp` oficial en `~/.local/bin`.
- **ytwatch** (opcional, `--no-ytwatch` para saltarlo): buscador TUI de
  YouTube con miniaturas (`ueberzugpp`), filtros, cola y descargas;
  usa el mismo yt-dlp oficial y mpv. Actualizable con `ytwatch-check` /
  `ytwatch-update`.
- Backups, logs, `--dry-run` y diagnóstico con `desktop-doctor`.
- NVIDIA detectada e instalada de forma condicional.

No incluido todavía:

- IDE (VS Code), Brave/Chromium, correo, Teams y reproductores de música
  locales (cmus/mpd). Firefox ESR y el streaming (`yt-play`, `ytwatch`) sí están.
- Bluetooth, htop, ripgrep, nvitop/nvtop, Node/nvm.
- XFCE, LightDM o un entorno de escritorio completo.
- Repositorio de dotfiles externo: las plantillas de este repo son la
  fuente de verdad.

## Requisitos

- Debian 13 minimal en x86_64, con systemd.
- `git` instalado para clonar el repositorio.
- Usuario no-root con home real y `sudo`.
- Conexión a Internet durante la primera instalación.
- UEFI o BIOS. Con NVIDIA, Secure Boot `enabled` o no detectable omite el
  driver propietario; con Secure Boot desactivado se instala si hay GPU
  NVIDIA. `--nvidia` permite forzarlo.

## Inicio rápido

```sh
sudo apt update
sudo apt install -y git

git clone <URL_DEL_REPOSITORIO> dwm-setup
cd dwm-setup
chmod +x install.sh

# 1. Ver el plan sin tocar nada
./install.sh --dry-run

# 2. Instalación real guiada (pide sudo; no guarda la contraseña)
./install.sh

# 3. Reiniciar y entrar en TTY1 con tu usuario
sudo reboot

# 4. Iniciar la sesión
startx
```

El instalador detecta usuario y home. Si se ejecuta como usuario normal,
pide `sudo -v` una vez y usa `sudo` para las operaciones de sistema.
`sudo ./install.sh` también funciona usando `SUDO_USER`.

## Opciones

| Opción | Efecto |
|---|---|
| `./install.sh` | Instalación guiada |
| `./install.sh --dry-run` | Muestra el plan sin modificar nada |
| `./install.sh --yes` | No pide confirmación; no modifica repositorios APT |
| `./install.sh --theme mocha-black` | Catppuccin Mocha Black (por defecto) |
| `./install.sh --theme latte` | Catppuccin Latte (claro) |
| `./install.sh --help` | Ayuda |
| `./install.sh --version` | Versión |

Opciones avanzadas: `--user`, `--home`, `--nvidia`, `--no-nvidia`,
`--cuda`, `--no-cuda`, `--keymap`, `--font`, `--font-size`, `--resolution`
y `--debug`.

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
6. **Configuración**: renderiza bspwm, sxhkd, polybar, dunst, rofi y kitty
   con la paleta activa (Mocha Black por defecto), el CSS de GTK y los
   defaults de Thunar; instala `.xinitrc`, wallpaper,
   `~/Pictures/Screenshots`, `desktop-safe` y `desktop-doctor`.
7. **Limpieza de restos**: retira restos de la barra anterior (`DesktopLogo`)
   con backup previo.
8. **Verificación**: comprueba binarios, ficheros, módulos de polybar,
   placeholders, permisos, propiedad del home, servicios, versiones y
   sintaxis POSIX de los binarios instalados.
9. **Autoremove**: después de verificar, marca la cadena de compilación como
   manual y ejecuta `apt-get -y autoremove` (sin `--purge`). Si falla, avisa
   y continúa; nunca deja el sistema a medias.

### Backups y logs

- Sistema: `/var/backups/dwm-setup/<timestamp>/`
- Usuario: `~/.config-backup/dwm-setup/<timestamp>/`
- Log: `~/.local/state/dwm-setup/install-<timestamp>.log`
  (fallback a `~/.cache/dwm-setup/`)
- Log de sesión (autostart): `~/.local/state/dwm-setup/session.log`

Los backups de usuario se hacen antes de renderizar. Si algo falla, la
versión anterior está en `~/.config-backup/`.

### Sesión (startx)

No se instala ningún display manager. `~/.xinitrc` configura el teclado y
hace `exec bspwm`; `bspwmrc` lanza sxhkd y el `autostart` interno, que
levanta picom (vsync), polybar, dunst, xwallpaper, udiskie, xss-lock,
lxpolkit y el notificador de batería baja, y desactiva el
salvapantallas/DPMS con `xset s off` y `xset -dpms`. La CPU arranca en
`performance` con la unidad `dwm-setup-cpu-governor.service` y se alterna
desde la barra.

```sh
# desde TTY1
startx
```

Si algo falla, entra por `Ctrl+Alt+F3` y revisa:

```sh
desktop-doctor
less ~/.local/state/dwm-setup/session.log
```

### Almacenamiento extraíble

`udiskie -N -a` monta el dispositivo y muestra una notificación. No se abre
ninguna ventana. Thunar se abre manualmente con `Super+Shift+F`.

### Audio y vídeo

PipeWire es el servidor; WirePlumber es el gestor de sesión. `pavucontrol`
sirve para elegir dispositivos. La aceleración VA-API/VDPAU depende de la
GPU y del firmware; `desktop-doctor` muestra el estado.

`audio-watch.sh` arranca desde `autostart` y aplica esta prioridad:

1. **Auriculares de cable** (`analog-output-headphones`).
2. **HDMI** (`output:hdmi-stereo`).
3. **Altavoces analógicos**.

El watcher detecta las tarjetas/perfiles/puertos con `pactl`; no hardcodea
nombres. Si el usuario tiene seleccionado un sink/source USB o Bluetooth,
no lo pisa. Conserva volumen/mute y mueve los streams existentes.

Comandos manuales:

```sh
~/.config/bspwm/scripts/audio-switch.sh auto
~/.config/bspwm/scripts/audio-switch.sh headphones
~/.config/bspwm/scripts/audio-switch.sh hdmi
~/.config/bspwm/scripts/audio-switch.sh analog
```

Si el jack combo de 3.5 mm no expone el micrófono del headset, el watcher
usa el micrófono interno. En el **ASUS FX504GE con ALC255** el instalador
detecta el modelo y ofrece el fixup `alc255-asus`; en otros PCs no toca el
kernel. Opciones: `--headset-quirk` (forzar) y `--no-headset-quirk`
(omitir). El quirk requiere reiniciar.

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
3. Revisa `journalctl -b` y `~/.local/state/dwm-setup/`.
4. Comprueba que `~/.config/bspwm/bspwmrc` tiene permiso de ejecución.

## Uso diario

| Atajo | Acción |
|---|---|
| `Super+Return` | kitty |
| `Super+d` | rofi (drun) |
| `Super+Shift+d` | rofi -show run |
| `Super+Shift+s` | scrot: seleccionar región y copiar al portapapeles |
| `Super+Shift+p` | pcmanfm (pendiente de instalar) |
| `Super+Shift+b` | firefox |
| `Super+Shift+v` | codium (pendiente; no está en Debian) |
| `Super+Shift+i` | ristretto (pendiente) |
| `Super+Shift+a` | lxappearance (pendiente) |
| `Super+Shift+f` | Thunar |
| `Super+Shift+l` | bloquear (desktop-safe lock) |
| `Super+Shift+e` | salir (desktop-safe logout) |
| `Super+Shift+c` | recargar sxhkd y bspwm |
| `Super+Shift+r` | reiniciar bspwm |
| `Super+Alt+P` | ciclo A arriba → A abajo → B arriba → B abajo |
| `Super+Alt+W` | alterna wallpaper principal / alternativo |
| `Super+Alt+T` | alterna tema oscuro / claro |
| `Ctrl+Space` | alternar flotante/tiled |
| `Super+Shift+space` | alternar floating |
| `Super+Shift+q` | cerrar ventana |
| `Super+a` | enfocar contenedor padre |
| `Super+b` / `Super+v` | split horizontal / vertical (preselección) |
| `Super+f` | fullscreen |
| `Alt+Tab` / `Alt+Shift+Tab` | siguiente / anterior ventana |
| `Super+Ctrl+Tab` / `Super+Ctrl+Shift+Tab` | siguiente / anterior escritorio |
| `Super+{h,j,k,l}` | foco ventanas |
| `Super+Shift+{h,j,k,l}` | mover/intercambiar ventanas |
| `Super+{1-7}` | ir a escritorio |
| `Super+Shift+{1-7}` | mover ventana a escritorio |
| `Super+r`, luego `h/j/k/l` | modo resize (Escape o 6 s sale) |
| `Super+m` | monocle/tiled |
| `Print` | pantalla completa al portapapeles |
| `Super+Print` | menú de capturas |
| `XF86AudioRaise/Lower/Mute` | volumen |
| `XF86AudioPlay` / `Next` / `Prev` | play-pausa y pista del reproductor activo |
| `XF86MonBrightnessUp/Down` | brillo |

`Ctrl+Tab` queda libre para navegadores y editores. `Super+Ctrl+Tab` y
`Super+Ctrl+Shift+Tab` cambian de escritorio; `Super+Left/Right` y
`Super+1..5` siguen disponibles.

`Super` es la tecla Windows. La barra muestra 13 módulos (14 si hay
backlight): logo StumbleUpon, workspaces 1-7, pomodoro, temperatura, RAM,
CPU, red, servicios, volumen, batería, fecha, actualizaciones y bandeja del
sistema. La red muestra un solo `󰖩 connected` o
`󰈀 connected`; Ethernet tiene prioridad si el cable está conectado. Si no
hay conexión, muestra `󰖩 NoC` y sigue siendo clicable. Al hacer clic en el módulo se abre un menú
WiFi para elegir y conectar una red. Las actualizaciones muestran calavera +
número y se ocultan si N=0. El módulo
de servicios muestra un engranaje y el número de servicios systemd activos;
al hacer clic abre un menú para iniciarlos, detenerlos o reiniciarlos.
El volumen llega como máximo a 120 % y sube/baja de 10 en 10. Las
notificaciones críticas de dunst se cierran solas a los 10 s. El brillo
aparece solo si el equipo tiene backlight y también cambia de 10 en 10.

### Variantes de polybar

Hay dos barras instaladas:

- **actual**: la barra compacta de 13 módulos (14 con backlight): logo,
  workspaces 1-7, updates, servicios, pomodoro, temperatura, RAM, CPU,
  red, volumen, batería, fecha, bandeja del sistema y brillo opcional. En
  monocle añade un contador `[N]` junto a los workspaces.
- **referencia**: variante de 15 módulos (16 con backlight). Workspaces
  como círculos al centro; a la izquierda `date`, `day`, **gobernador**, `updates`,
  pomodoro y `der`; a la derecha `izq`, servicios, temperatura, RAM, CPU, red,
  volumen, batería, bandeja del sistema y brillo opcional. En monocle, `[N]`
  junto a los círculos de workspaces.
  La bandeja usa XEmbed; Telegram/Discord modernos pueden no aparecer hasta
  añadir `snixembed`.
  Barra de 30 px con fondo sólido del modo activo, fuentes 10/13, iconos JBM y
  círculos Font Awesome. Todos los bloques comparten el mismo tono;
  laterales son oscuros y opacos.

Cambiar de variante:

```sh
~/.config/polybar/polybar-variant actual
~/.config/polybar/polybar-variant referencia
~/.config/polybar/polybar-variant toggle
~/.config/polybar/polybar-variant cycle
```

`Super+Alt+P` recorre el ciclo **A arriba → A abajo → B arriba → B
abajo**. La posición se guarda en `~/.config/polybar/position`.

La variante se guarda en `~/.config/polybar/variant` y `launch.sh` arranca
la elegida al iniciar sesión.

Los atajos de apps que aún no están instaladas se dejan puestos para no
cambiar la memoria muscular; no hacen nada hasta instalar la app. `codium`
requiere el repositorio de VSCodium. `Super+s/w/e` de i3 (stacking/tabbed)
no tienen equivalente exacto en bspwm y no se mapean.

## Música y streams

Audio o vídeo de YouTube/YouTube Music sin salir de la terminal:

```sh
yt-play --audio https://music.youtube.com/watch?v=XXXX   # solo audio
yt-play --video https://www.youtube.com/watch?v=XXXX     # vídeo en mpv
yt-play lofi hip hop                                     # busca y elige con fzf
```

`--audio` es el modo por defecto. En la búsqueda, **Enter** reproduce solo
audio y **Ctrl+V** abre el vídeo en una ventana de mpv; con `--video`, Enter
abre el vídeo y Ctrl+V reproduce solo audio. La ventana de vídeo abre al 80%
de la pantalla y se puede dejar flotante con `Ctrl+Space`.

Trae 20 resultados por defecto (una página de YouTube, mismo coste que 10);
se cambia con `YT_PLAY_RESULTS=40 yt-play lofi`.

El menú de fzf muestra los títulos a la izquierda y, a la derecha, el
**título, canal y duración** junto a la **miniatura del vídeo** (chafa en modo
texto, `maxresdefault` con respaldo a `mqdefault`). La lista y las miniaturas
se cachean en `~/.cache/yt-play/{meta,preview}`. `Ctrl+N`/`Ctrl+P` o flechas
para moverse, `Enter`/`Ctrl+V` para reproducir y `Esc` cancela.

`yt-play` usa siempre `~/.local/bin/yt-dlp` aunque esa carpeta no esté en el
PATH (se la pasa a mpv delante), así que el paquete viejo de Debian no
interfiere. El binario oficial se actualiza sin sudo:

```sh
ytdlp-check      # ¿hay versión nueva? solo avisa
ytdlp-update     # actualiza, con copia .bak y rollback automático
ytdlp-rollback   # vuelve a la anterior
```

`yt-play` avisa si YouTube cambia y yt-dlp ya no puede extraer el contenido.

## ytwatch — buscador TUI

Perfil TUI (vim keys, miniaturas junto a cada resultado, filtros de
tipo/duración/fecha, cola multi-select, playlists y live con chat). No
sustituye a `yt-play`: es otra puerta al mismo yt-dlp + mpv.

```sh
ytwatch            # abre con la búsqueda activa
ytwatch lofi jazz  # abre con una búsqueda precargada
```

**Enter** reproduce en audio (config del repo: `audio_only = true`);
`d`/`a`/`Q` descargan (calidad/audio), `V` arma cola, `f` filtra,
`?` muestra la ayuda completa con la tecla que carga el resultado en
vídeo. Las miniaturas van por el protocolo nativo de kitty a través de
`ueberzugpp` (instalado por el instalador como `.deb` del proyecto, sin
añadir repositorios); el fallback es `chafa`. El binario se gestiona solo:

```sh
ytwatch-check        # ¿hay versión nueva de ytwatch o ueberzugpp? avisa por dunst
ytwatch-update       # actualiza el TUI (checksums.txt + .bak)
ytwatch-update --ueberzugpp   # refresca el paquete de miniaturas (sudo)
```

En una instalación sin el bloque: `./install.sh --no-ytwatch`.
No actualiza nada por su cuenta: siempre decides tú con `ytdlp-update`.

## Tema y modo de color

El escritorio usa **Catppuccin** en dos modos:

| Modo | Paleta | Fondo | Acento |
|---|---|---|---|
| `dark` | `mocha-black` | `#0d0d14` | `#89b4fa` |
| `light` | `latte` | `#eff1f5` | `#1e66f5` |

`mocha-black` es Catppuccin Mocha con la rampa de superficies llevada a casi
negro; el resto de la paleta (texto, acentos, estados) se mantiene.

```sh
theme-mode dark        # Mocha Black
theme-mode light       # Latte
theme-mode toggle
theme-mode status
```

`theme-mode` re-renderiza polybar A/B, kitty, dunst, rofi, zathura, bspwm,
GTK, Firefox y VLC desde `~/.local/share/dwm-setup/`, y recarga en caliente
polybar, dunst, los bordes de bspwm y kitty. **No pide sudo**: los temas ya
están instalados. Firefox y VLC necesitan reiniciarse para aplicar el cambio.

kitty se recolorea en caliente con `kitty @ set-colors`, gracias a
`allow_remote_control socket-only` y
`listen_on unix:kitty-{kitty_pid}` en `kitty.conf` (socket en
`/tmp/kitty-<pid>`). Las terminales abiertas antes de activar esto necesitan
un reinicio de kitty.

El atajo es `Super+Alt+t` y muestra una notificación con el modo nuevo.

### Firefox y SurfingKeys

`userChrome.css` aplica Catppuccin al chrome, mantiene la barra compacta y
deja visibles atrás, adelante, recargar, parar, descargas y el menú
hamburguesa. Se instala en el perfil y se regenera con `theme-mode`.

El **contenido web** (Google, YouTube) no cambia en caliente: el esquema de
color del contenido es una preferencia que Firefox lee al arrancar. Tras
`Super+Alt+t`, cierra y abre Firefox. Google Search respeta
`prefers-color-scheme`; YouTube solo si pones *Ajustes → Apariencia → Usar
tema del dispositivo* una vez.

SurfingKeys viene `force_installed` desde `policies.json`. Su configuración
vive en `~/.config/dwm-setup/surfingkeys.js`; se pega **una vez** en
SurfingKeys → Ajustes → Advanced mode → editor → Save. No hay botón de
importar y Firefox no permite que la extensión lea archivos locales sin un
native host. El tema usa `prefers-color-scheme`, así que sigue al modo sin
volver a pegarlo.

Temas GTK instalados:

```text
/usr/share/themes/catppuccin-mocha-blue      vendored
/usr/share/themes/catppuccin-latte-blue      vendored
/usr/share/themes/catppuccin-mocha-black     generado al instalar
/usr/share/icons/Catppuccin-Mocha            overlay sobre Papirus-Dark
/usr/share/icons/Catppuccin-Latte            overlay sobre Papirus-Light
```

`catppuccin-mocha-black` se deriva de `catppuccin-mocha-blue` sustituyendo la
rampa `base/mantle/crust/surface0..2` por los valores de
`palette-mocha-black.sh`, así que no se desincroniza. Los temas de iconos son
overlays: Papirus-Dark y Papirus-Light comparten `places/` mediante symlinks,
y solo un tema propio permite colores de carpeta distintos por modo.

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
lib/gtk.sh                 temas GTK Catppuccin, tema derivado e iconos
lib/vlc.sh                 VLC con paleta oscura
lib/config.sh              Configs de usuario, wallpaper y binarios
lib/fastfetch.sh           fastfetch y logo Neofet.png
lib/music.sh               yt-dlp oficial, scripts de streaming y teclas
lib/firefox.sh             Firefox ESR, OpenH264, uBlock y SurfingKeys
lib/verify.sh              Verificación estática final
lib/theme.sh               Paletas (Mocha Black, Latte) y render
lib/audio.sh               Quirk ALC255 condicionado por hardware
bin/desktop-safe           Acciones de sesión
bin/desktop-doctor         Diagnóstico y cámara (POSIX sh)
bin/theme-mode             Cambio dark/light en caliente
bin/yt-play                Audio o vídeo de YouTube (URL o búsqueda con fzf)
bin/yt-preview             Miniatura para el preview de fzf
bin/ytdlp-check            Aviso de versión nueva de yt-dlp
bin/ytdlp-update           Actualización de yt-dlp con .bak y rollback
bin/ytdlp-rollback         Restaura la copia anterior de yt-dlp
bin/music-ctl              Teclas multimedia del reproductor activo
bin/ytwatch-check          Aviso de versión nueva (ytwatch/ueberzugpp, dunst)
bin/ytwatch-update         Actualiza ytwatch o ueberzugpp (--ueberzugpp)
lib/ytwatch.sh             Instalación de ytwatch y ueberzugpp con SHA-256
templates/bspwm/           bspwmrc.in, autostart.in, scripts/
templates/sxhkd/           sxhkdrc.in
templates/polybar/         config.ini.in, modules/, scripts/ y variants/
templates/dunst/           dunstrc.in, notification-sound.sh.in
templates/rofi/            powermenu.rasi.in y config.rasi.in
templates/kitty/           kitty.conf.in y colorshemes/
templates/zsh/             zshrc.in
templates/lsd/             config.yml e icons.yaml
templates/ranger/          rc.conf, rifle.conf y previews
templates/xorg/            configuración Xorg por hardware
templates/gtk/             settings GTK2/3/4 y CSS
templates/vlc/             vlcrc (oscuro o claro según el modo)
templates/zathura/         zathurarc.in
templates/themes/          catppuccin-mocha-blue y catppuccin-latte-blue
templates/fastfetch/       config.jsonc.in
assets/fastfetch/          Neofet.png (logo de fastfetch)
templates/icons/           papirus-folders y carpetas cat-*
templates/modprobe/        i915.conf y nvidia.conf
templates/modprobe/        alsa-fx504.conf (quirk ALC255)
templates/colors/          palette-mocha-black.sh y palette-latte.sh
assets/wallpaper.png       Wallpaper principal
assets/wallpaper-alt.png   Wallpaper alternativo
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
- El instalador no modifica repositorios por defecto. Solo la opción 1 del
  menú añade componentes a entradas oficiales de Debian 13, tras un backup.
- Se instala Firefox ESR como navegador del escritorio; no se instalan IDE,
  cliente de correo ni reproductores de música locales. El streaming de
  YouTube se hace con `yt-play` y, opcionalmente, `ytwatch` (TUI).
- `/etc/firefox-esr/zz-dwm-setup.js` habilita OpenH264 para que Teams pueda
  mostrar H.264 (pantalla compartida). Sin ese ajuste, el vídeo de Teams
  queda en negro en Firefox ESR.
- `/etc/firefox/policies/policies.json` instala uBlock Origin con
  `force_installed`: no se puede desinstalar, pero se puede desactivar por
  sitio desde su popup.
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
- Bluetooth queda fuera de fase 1; se configurará más adelante.

## Documentación

- [`PROGRESS.md`](PROGRESS.md): estado real, pendientes y bloqueos.
- [`AGENTS.md`](AGENTS.md): reglas para futuras sesiones/modelos.
- [`DECISIONS.md`](DECISIONS.md): decisiones de arquitectura.
- [`docs/hardware.md`](docs/hardware.md): hardware de referencia.
- [`docs/testing.md`](docs/testing.md): plan de pruebas y criterios.
- [`PLAN.md`](PLAN.md): plan antiguo, conservado solo como historia.
