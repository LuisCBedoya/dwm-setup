# bspwm + polybar · Debian 13 (fase 1b)

Instalador reproducible de un escritorio mínimo sobre **Debian 13 (trixie)**:
Xorg, bspwm, sxhkd, polybar, picom, dunst, rofi, kitty, xwallpaper,
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
- **polybar** con **12 módulos**: logo StumbleUpon, workspaces 1-5,
  pomodoro, temperatura, RAM, CPU, red unificada
  (`󰖩/󰈀 connected`, sin `NoC`), servicios systemd, volumen, batería, fecha
  y actualizaciones (calavera + número). `font-1` 10 y `font-3` 13; logo en
  `font-0`.
- **picom**, **dunst**, **rofi** (y **dmenu** para el módulo de servicios),
  **kitty**, **flameshot**.
- Bloqueo con **i3lock** + **xss-lock**.
- Brillo, volumen, portapapeles y agente polkit (`lxpolkit`).
- PipeWire + WirePlumber + ALSA + pavucontrol.
- FFmpeg, `libavcodec-extra`, GStreamer y VA-API/VDPAU.
- Cámara UVC (`uvcvideo`, `v4l-utils`, `libcamera-tools` opcional).
- Almacenamiento extraíble con `udisks2` + `udiskie`: montaje automático y
  **solo notificación**; nunca se abre una aplicación automáticamente.
- Thunar como gestor de archivos puntual (`Super+Shift+F`).
- Fuente JetBrainsMono Nerd Font, wallpaper y paleta **Warm Charcoal**
  (`#18181A`, `#202022`, `#D8D3CC`, `#B9A99A`, `#8FA6B4`).
- Backups, logs, `--dry-run` y diagnóstico con `desktop-doctor`.
- NVIDIA detectada e instalada de forma condicional.

No incluido todavía:

- Neovim/IDE, VS Code, Firefox/Brave/Chromium, correo, Teams, música.
- Bluetooth, zathura, htop, lsd, ripgrep, nvitop/nvtop, Node/nvm.
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
4. **Paquetes**: base, Xorg, compilación mínima, escritorio, audio/códecs,
   cámara, almacenamiento, red, fuentes, firmware, microcódigo y GPU.
5. **Fuente**: descarga JetBrainsMono Nerd Font 3.5.1, verifica SHA-256 y
   ejecuta `fc-cache`. Si falla, usa JetBrains Mono o monospace y avisa.
6. **Configuración**: renderiza bspwm, sxhkd, polybar, picom, dunst, rofi y
   kitty con paleta Warm Charcoal; instala `.xinitrc`, wallpaper,
   `~/Pictures/Screenshots`, `desktop-safe` y `desktop-doctor`.
7. **Limpieza**: retira restos de la barra anterior (`DesktopLogo`) con
   backup previo.
8. **Verificación**: comprueba binarios, ficheros, módulos de polybar,
   placeholders, permisos, propiedad del home, servicios, versiones y
   sintaxis POSIX de los binarios instalados.

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
levanta polybar, dunst, picom, xwallpaper, udiskie, xss-lock, lxpolkit y el
notificador de batería baja.

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
```

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
| `Super+Shift+b` | chromium (pendiente de instalar) |
| `Super+Shift+v` | codium (pendiente; no está en Debian) |
| `Super+Shift+i` | ristretto (pendiente) |
| `Super+Shift+a` | lxappearance (pendiente) |
| `Super+Shift+f` | Thunar |
| `Super+Shift+l` | bloquear (desktop-safe lock) |
| `Super+Shift+e` | salir (desktop-safe logout) |
| `Super+Shift+c` | recargar sxhkd y bspwm |
| `Super+Shift+r` | reiniciar bspwm |
| `Super+Alt+P` | alternar variante de polybar A/B |
| `Super+Shift+space` | alternar floating |
| `Super+Shift+q` | cerrar ventana |
| `Super+a` | enfocar contenedor padre |
| `Super+b` / `Super+v` | split horizontal / vertical (preselección) |
| `Super+f` | fullscreen |
| `Alt+Tab` / `Alt+Shift+Tab` | siguiente / anterior ventana |
| `Super+{h,j,k,l}` | foco ventanas |
| `Super+Shift+{h,j,k,l}` | mover/intercambiar ventanas |
| `Super+{1-5}` | ir a escritorio |
| `Super+Shift+{1-5}` | mover ventana a escritorio |
| `Super+r`, luego `h/j/k/l` | redimensionar (Escape sale) |
| `Super+m` | monocle/tiled |
| `Print` | pantalla completa al portapapeles |
| `Super+Print` | menú de capturas |
| `XF86AudioRaise/Lower/Mute` | volumen |
| `XF86MonBrightnessUp/Down` | brillo |

`Super` es la tecla Windows. La barra muestra 12 módulos (logo StumbleUpon,
workspaces 1-5, pomodoro, temperatura, RAM, CPU, red, servicios, volumen,
batería, fecha y actualizaciones). La red muestra un solo `󰖩 connected` o
`󰈀 connected` según la conexión activa; si no hay ninguna, no muestra nada.
Las actualizaciones muestran calavera + número y se ocultan si N=0. El módulo
de servicios muestra un engranaje y el número de servicios systemd activos;
al hacer clic abre un menú para iniciarlos, detenerlos o reiniciarlos.

### Variantes de polybar

Hay dos barras instaladas:

- **actual**: la barra compacta de 12 módulos (logo, workspaces 1-5,
  updates, servicios, pomodoro, temperatura, RAM, CPU, red, volumen,
  batería y fecha).
- **referencia**: variante de 14 módulos. Workspaces como círculos al
  centro; a la izquierda `date`, `day`, `updates`, pomodoro y `der`; a la
  derecha `izq`, servicios, temperatura, RAM, CPU, red, volumen y batería.
  Barra transparente de 18 px, fuentes 10/13, iconos JBM y círculos Font
  Awesome. El fondo de los módulos de la derecha es oscuro semitransparente.

Cambiar de variante:

```sh
~/.config/polybar/polybar-variant actual
~/.config/polybar/polybar-variant referencia
~/.config/polybar/polybar-variant toggle
```

También se puede alternar con **`Super+Alt+P`**.

La variante se guarda en `~/.config/polybar/variant` y `launch.sh` arranca
la elegida al iniciar sesión.

Los atajos de apps que aún no están instaladas se dejan puestos para no
cambiar la memoria muscular; no hacen nada hasta instalar la app. `codium`
requiere el repositorio de VSCodium. `Super+s/w/e` de i3 (stacking/tabbed)
no tienen equivalente exacto en bspwm y no se mapean.

## Estructura del repositorio

```text
install.sh                 Entrada principal
lib/common.sh              Logs, sudo, ownership, backups, render
lib/detect.sh              Detección de sistema/hardware
lib/packages.sh            Grupos de paquetes y Nerd Font
lib/bspwm.sh               bspwm, bspwmrc, autostart y .xinitrc
lib/sxhkd.sh               sxhkdrc
lib/polybar.sh             polybar config/modules/scripts/launch
lib/picom.sh               picom.conf
lib/dunst.sh               dunstrc
lib/rofi.sh                rofi powermenu
lib/kitty.sh               kitty.conf
lib/config.sh              Configs de usuario, wallpaper y binarios
lib/verify.sh              Verificación estática final
lib/theme.sh               Paleta Warm Charcoal y render
lib/audio.sh               Quirk ALC255 condicionado por hardware
bin/desktop-safe           Acciones de sesión
bin/desktop-doctor         Diagnóstico y cámara (POSIX sh)
templates/bspwm/           bspwmrc.in, autostart.in, scripts/
templates/sxhkd/           sxhkdrc.in
templates/polybar/         config.ini.in, modules/, scripts/
templates/picom/           picom.conf.in
templates/dunst/           dunstrc.in, notification-sound.sh.in
templates/rofi/            powermenu.rasi.in
templates/kitty/           kitty.conf.in
templates/modprobe/        alsa-fx504.conf (quirk ALC255)
templates/colors/          palette-warm.sh y palette-nord.sh
assets/wallpaper.jpg       Wallpaper
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
- No se instala ningún navegador, IDE, cliente de correo ni música.
- Los atajos `Super+Shift+p/b/v/i/a` existen en `sxhkdrc` pero las apps
  (`pcmanfm`, `chromium`, `codium`, `ristretto`, `lxappearance`) no se
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
