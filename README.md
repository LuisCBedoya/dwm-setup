# dwm + eww · Debian 13 (fase 1)

Instalador reproducible de un escritorio mínimo sobre **Debian 13 (trixie)**:
Xorg, Ly, chadwm, eww, barra status2d, picom, dunst, rofi, feh, kitty,
flameshot, i3lock/xss-lock, PipeWire, cámara UVC y montaje de discos
extraíbles con notificación.

> **Estado:** el código de la fase 1 está implementado en este repositorio y
> los checks locales/staticos pasan, pero **todavía no se ha validado una
> instalación real en una VM Debian 13 minimal ni en el hardware de
> referencia**. No ejecutes la instalación real en el equipo principal hasta
> completar la checklist de `docs/testing.md`.
>
> El host actual tiene XFCE/LightDM y se usa solo como referencia; el
> instalador está pensado para una instalación limpia.

## Alcance de esta fase

Incluido:

- Debian 13 minimal, x86_64.
- Xorg + Ly como display manager (Ly compilado desde fuente).
- chadwm como window manager.
- eww para dashboard, calendario, census y centro de control.
- Barra status2d, picom, dunst, rofi, feh, kitty, flameshot.
- Bloqueo con i3lock y xss-lock.
- Brillo, volumen, portapapeles y agente polkit.
- PipeWire + WirePlumber + ALSA + pavucontrol.
- FFmpeg, `libavcodec-extra`, GStreamer completo y aceleración VA-API/VDPAU.
- Cámara UVC (`uvcvideo`, `v4l-utils`, `libcamera-tools` opcional).
- Almacenamiento extraíble con `udisks2` + `udiskie`: montaje automático y
  **solo notificación**; nunca se abre una aplicación automáticamente.
- `pcmanfm` como gestor de archivos (Mod+E o rofi).
- Fuente JetBrainsMono Nerd Font, wallpaper y tema Gruvbox Material.
- Backups, logs, `--dry-run` y diagnóstico con `dwm-doctor`.
- NVIDIA detectada y instalada de forma condicional; no hay CUDA ni
  instalación incondicional.

No incluido todavía (fases posteriores):

- Neovim/IDE, navegadores, correo/Teams, música/reproductores.
- Bluetooth, zathura, htop, lsd, ripgrep, nvitop/nvtop.
- Node/nvm, VS Code, Firefox, Brave/Chromium.
- XFCE, LightDM, Thunar o un entorno de escritorio completo.

## Requisitos

- Debian 13 minimal instalado en x86_64.
- Sistema con systemd.
- `git` instalado para clonar el repositorio; el instalador instala el resto
  de dependencias.
- Usuario no-root con home real y `sudo`. El instalador detecta el usuario y
  su home automáticamente; si se ejecuta como root, usa `SUDO_USER` o pregunta
  el usuario destino.
- Conexión a Internet durante la primera instalación: se descargan paquetes,
  Zig, Ly, dependencias de Cargo y la Nerd Font.
- UEFI o BIOS. Con NVIDIA, Secure Boot `enabled` o no detectable omite el
  driver propietario; con Secure Boot desactivado se instala automáticamente
  si hay GPU NVIDIA. La opción avanzada `--nvidia` permite forzarlo.
- Fuentes `non-free-firmware`, `non-free` y `contrib` habilitadas si se
  quieren firmware/drivers opcionales. Si faltan, el instalador ofrece
  añadirlas con autorización explícita. `contrib` solo hace falta para
  `nvidia-settings`; el driver NVIDIA está en `non-free`.

## Inicio rápido

En una Debian 13 minimal (consola, con `git` e Internet):

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

# 3. Reiniciar y entrar desde Ly en la sesión "dwm"
sudo reboot
```

El ejecutable es **`install.sh`**, no `installer.sh`. Si se ejecuta como
usuario normal, el script pide `sudo -v` una vez y usa `sudo` para las
operaciones de sistema. `sudo ./install.sh` también funciona: el instalador
usa `SUDO_USER` para el usuario destino. Si se inicia como root sin
`SUDO_USER`, pregunta el usuario.

La primera instalación necesita Internet para descargar paquetes, Zig, Ly,
las dependencias de Cargo y la Nerd Font. En una VM de prueba la política
automática omite el driver NVIDIA.

Uso normal:

| Opción | Efecto |
|---|---|
| `./install.sh` | Instalación guiada; solo pregunta cuando hay una decisión real |
| `./install.sh --dry-run` | Muestra el plan completo sin modificar el sistema |
| `./install.sh --yes` | No pide confirmación; no modifica repositorios APT |

Opciones avanzadas para automatización (no necesarias en uso normal):
`--user`, `--home`, `--rebuild`, `--nvidia`, `--no-nvidia`, `--keymap`,
`--font`, `--font-size`, `--resolution` y `--debug`. También están disponibles
`--help` y `--version`.

## Qué hace el instalador

1. **Detección**: Debian 13 y x86_64 se verifican antes de pedir `sudo`. Luego
   detecta VM, CPU, GPU, Secure Boot, resolución, cámaras, batería, backlight,
   WiFi, audio y tipo de sistema de archivos raíz.
2. **Preflight APT**: lee los componentes habilitados (`main`, `contrib`,
   `non-free`, `non-free-firmware`). Si falta `main`, aborta. Si faltan
   componentes opcionales, ofrece tres opciones: añadirlos automáticamente,
   continuar sin ellos o cancelar. La opción 1 hace backup de las fuentes,
   modifica solo entradas oficiales de Debian 13, ejecuta `apt update` y
   vuelve a comprobar. `--dry-run` solo muestra el aviso; `--yes` continúa
   sin modificar repositorios.
3. **Paquetes**: grupos base, Xorg, compilación, escritorio, audio/códecs,
   cámara, almacenamiento, red, fuentes, firmware, microcódigo y GPU.
4. **Fuente**: descarga JetBrainsMono Nerd Font `3.5.1`, verifica SHA-256 y
   ejecuta `fc-cache`. Si falla y no se pasó `--font`, usa `JetBrains Mono` de
   Debian o `monospace`, y avisa.
5. **chadwm**: renderiza `templates/dwm/config.h.in` con el home, fuente y
   tamaño elegidos, compila en `/var/cache/dwm-setup` e instala en
   `/usr/local/bin/dwm`.
6. **eww**: compila eww `v0.6.0` con features X11 e instala
   `/usr/local/bin/eww`. Si el lockfile trae `time 0.3.34`, se ajusta a
   `0.3.35` en una copia antes de compilar con `--locked`. Las dependencias
   nativas incluyen `libdbusmenu-glib-dev` y `libdbusmenu-gtk3-dev`.
7. **Ly**: descarga Zig `0.17.0` (SHA-256 fijo), clona el commit fijo de Ly,
   compila, instala `/usr/bin/ly` y `/etc/ly/config.lua`, y habilita
   `ly@tty2.service`. Las dependencias nativas incluyen `libpam0g-dev` y
   `libaudit-dev`: `pam.pc` exige `audit.pc` y sin él la compilación falla.
8. **Configuración**: copia `~/.config/dwm`, `~/.config/kitty`,
   `~/.xinitrc`, wallpaper y `/usr/share/xsessions/dwm.desktop`.
9. **Verificación**: comprueba binarios, archivos, servicios y que Ly quedó
   habilitado. La prueba gráfica real se hace después de entrar a la sesión.

### Backups y logs

- Backups de sistema: `/var/backups/dwm-setup/<timestamp>/`
- Backups de usuario: `~/.config-backup/dwm-setup/<timestamp>/`
- Log: `~/.local/state/dwm-setup/install-<timestamp>.log`

Si se elige añadir componentes APT, `/etc/apt/sources.list` y
`/etc/apt/sources.list.d/` se guardan antes de editarlos. El log se escribe en
el home del usuario destino. `--dry-run` no crea log ni modifica archivos.

### Display manager

Ly se instala con configuración Gruvbox, en español si existe
`/etc/ly/lang/es.ini`, sin shell y sin `~/.xinitrc` (para que solo aparezca la
sesión dwm). El instalador **no inicia Ly inmediatamente**: deshabilita
LightDM/GDM/SDDM si existen y habilita `ly@tty2`; el cambio se aplica al
reiniciar para no matar la sesión desde la que se instala.

`~/.xinitrc` queda como fallback de recuperación: desde una TTY,
`startx` debe iniciar la misma sesión.

## Uso diario

| Atajo | Acción |
|---|---|
| `Mod+Return` | kitty |
| `Mod+E` | pcmanfm |
| `Mod+Shift+D` | rofi (drun) |
| `Mod+Shift+S` | flameshot |
| `Mod+grave` | dashboard eww |
| `Mod+Escape` | menú de energía |
| `Mod+Shift+L` | bloquear con i3lock |
| `Mod+Shift+Q` | cerrar ventana |
| `Mod+Shift+R` | reiniciar dwm |

`Mod` es la tecla Super. La barra muestra CPU, RAM, disco, volumen, WiFi,
batería, actualizaciones y reloj. El centro de control eww permite WiFi,
captura, bloqueo, volumen, brillo, apagado, reinicio, suspensión y logout.

### Almacenamiento extraíble

`run.sh` arranca:

```sh
udiskie --automount --notify
```

`udiskie` monta el dispositivo y muestra una notificación. No se pasa
`--file-manager`, así que no se abre ninguna ventana. `pcmanfm` se abre
manualmente con `Mod+E`.

### Audio y vídeo

PipeWire es el servidor; WirePlumber es el gestor de sesión. `pavucontrol`
sirve para elegir dispositivos. La instalación incluye FFmpeg,
`libavcodec-extra`, GStreamer base/good/bad/ugly/libav/vaapi y
`ffmpegthumbnailer`. La aceleración VA-API/VDPAU depende de la GPU y de los
drivers de firmware; `dwm-doctor` muestra el estado.

### Cámara

Se instala `v4l-utils`, y `libcamera-tools` si está disponible. La prueba real
se ejecuta después de entrar a la sesión:

```sh
dwm-doctor --camera
```

Esto prueba `/dev/video*` con `ffmpeg` y crea un frame temporal. Si el usuario
acaba de ser añadido al grupo `video`, hay que cerrar sesión y volver a entrar.

## Diagnóstico y recuperación

```sh
dwm-doctor              # estado general
dwm-doctor --camera     # prueba real de captura
dwm-safe lock           # bloquear
dwm-safe suspend        # suspender (xss-lock bloquea antes)
dwm-safe logout         # volver a Ly
dwm-safe status         # alias de dwm-doctor
```

Si Ly no arranca:

1. Entra por una TTY (`Ctrl+Alt+F3`).
2. Ejecuta `startx` para usar `~/.xinitrc`.
3. Revisa `journalctl -u ly@tty2 -b` y el log del instalador.
4. Comprueba `/etc/ly/config.lua` y que `/usr/share/xsessions/dwm.desktop`
   tenga el `Exec` correcto.
5. Para volver temporalmente a otro display manager, habilítalo con
   `systemctl enable lightdm` (si está instalado) y deshabilita `ly@tty2`.

Si dwm compila pero no arranca, revisa `~/.cache/dwm/*.log` y ejecuta
`dwm-doctor` desde una TTY con `DISPLAY` válido.

## Estructura del repositorio

```text
install.sh                 Entrada principal
lib/common.sh              Logs, sudo, backups, render de plantillas
lib/detect.sh              Detección de sistema/hardware
lib/packages.sh            Grupos de paquetes y Nerd Font
lib/dwm.sh                 Compilación de chadwm
lib/eww.sh                 Compilación de eww
lib/ly.sh                  Zig, Ly, configuración y servicio
lib/config.sh              Configs de usuario y sesión
lib/verify.sh              Verificación estática final
bin/dwm-safe               Acciones de sesión
bin/dwm-doctor             Diagnóstico y prueba de cámara
templates/dwm/             Plantillas de dwm, eww, barra, dunst, rofi, picom
templates/kitty/           Configuración de kitty
assets/wallpaper.jpg       Wallpaper de referencia
src/chadwm/chadwm/         Fuente de chadwm (vendorizada)
src/eww/                   Fuente de eww v0.6.0 (vendorizada)
docs/                      Hardware y testing
legacy/                    Prototipo antiguo, no usado por el instalador
```

Los archivos de `legacy/` se conservan solo como referencia histórica. La
fuente de verdad es `install.sh`, `lib/` y `templates/`.

Las fuentes de chadwm (commit `7991ac8`) y eww (v0.6.0, commit `d87c2fd`) se
incluyen vendorizadas en el repositorio, sin submódulos. Así un `git clone`
contiene todo lo necesario para compilar sin depender de repositorios
externos (aparte de las descargas de Zig, Ly y la Nerd Font).

## Limitaciones conocidas

- No hay validación real todavía en Debian 13 minimal ni en el hardware de
  referencia; los checks locales y de dry-run no sustituyen esa prueba.
- La compilación de eww y Ly requiere red y puede tardar; los errores se
  muestran y el instalador se detiene antes de habilitar Ly.
- NVIDIA propietario y Secure Boot requiere MOK; si Secure Boot no está
  desactivado, el driver se omite y se avisa. `--nvidia` permite forzarlo de
  forma avanzada.
- `libcamera-tools`, firmware y drivers propietarios son opcionales: el
  preflight avisa de los componentes APT que faltan y de sus consecuencias.
- El instalador no modifica repositorios por defecto. Solo la opción 1 del
  menú, elegida explícitamente, añade componentes a entradas oficiales de
  Debian 13, después de un backup. `main` nunca se añade automáticamente.
  El auto-add solo reconoce hosts `*.debian.org`; con un mirror propio hay que
  editar `sources.list` manualmente.
- No se instala ningún navegador, IDE, cliente de correo ni música.
- El host de referencia tiene XFCE/LightDM: no se debe usar como destino de
  la instalación real sin backup y validación previa.

## Documentación

- [`PROGRESS.md`](PROGRESS.md): estado real, pendientes y bloqueos.
- [`AGENTS.md`](AGENTS.md): reglas para futuras sesiones/modelos.
- [`DECISIONS.md`](DECISIONS.md): decisiones de arquitectura.
- [`docs/hardware.md`](docs/hardware.md): hardware de referencia y matriz de
  detección.
- [`docs/testing.md`](docs/testing.md): plan de pruebas y criterios de
  aceptación.
- [`PLAN.md`](PLAN.md): plan antiguo, conservado solo como historia.
