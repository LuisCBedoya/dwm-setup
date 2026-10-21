# bspwm + polybar · Debian 13 (fase 1b)

Instalador reproducible de un escritorio mínimo sobre **Debian 13 (trixie)**:
Xorg, bspwm, sxhkd, polybar, picom, dunst, rofi, kitty, xwallpaper,
flameshot, i3lock/xss-lock, PipeWire, cámara UVC y montaje de discos
extraíbles con notificación.

> **Estado:** el código de la fase 1b está implementado en este repositorio y
> los checks locales/estáticos pasan, pero **todavía no se ha validado una
> instalación real en una VM Debian 13 minimal ni en el hardware de
> referencia**. No ejecutes la instalación real en el equipo principal hasta
> completar la checklist de `docs/testing.md`.
>
> El host actual tiene XFCE/LightDM y se usa solo como referencia; el
> instalador está pensado para una instalación limpia.

## Alcance de esta fase

Incluido:

- Debian 13 minimal, x86_64.
- Xorg + **startx** (sin display manager).
- **bspwm** como window manager + **sxhkd** para atajos.
- **polybar** para barra de estado (workspaces 1-5 con dígitos árabes, CPU, RAM, temp, red, audio, batería, fecha, pomodoro, updates, logo U+F2DD en extremo izquierdo, barra **arriba**, 26px, fondo `#0D1117`, sin subrayados — réplica exacta del diseño de referencia).
- picom, dunst, rofi, kitty, flameshot.
- Bloqueo con i3lock y xss-lock.
- Brillo, volumen, portapapeles y agente polkit.
- PipeWire + WirePlumber + ALSA + pavucontrol.
- FFmpeg, `libavcodec-extra`, GStreamer completo y aceleración VA-API/VDPAU.
- Cámara UVC (`uvcvideo`, `v4l-utils`, `libcamera-tools` opcional).
- Almacenamiento extraíble con `udisks2` + `udiskie`: montaje automático y
  **solo notificación**; nunca se abre una aplicación automáticamente.
- `thunar` como gestor de archivos (Super+Shift+F o rofi).
- Fuente JetBrainsMono Nerd Font, wallpaper y tema **Nord**.
- Backups, logs, `--dry-run` y diagnóstico con `desktop-doctor`.
- NVIDIA detectada e instalada de forma condicional; no hay CUDA ni
  instalación incondicional.
- **Repo dotfiles opcional:** puedes dar una URL Git HTTPS con tus configs;
  estructura esperada: `repo/config/.config/{bspwm,sxhkd,polybar,picom,dunst,rofi,kitty}`.

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
- Conexión a Internet durante la primera instalación: se descargan paquetes
  y la Nerd Font. **Ya no se compila nada** (ni chadwm, ni eww, ni Ly).
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
#    Opcionalmente te preguntará por un repo Git HTTPS de dotfiles
./install.sh

# 3. Reiniciar y entrar en TTY1: ejecuta `startx`
sudo reboot
```

El ejecutable es **`install.sh`**, no `installer.sh`. Si se ejecuta como
usuario normal, el script pide `sudo -v` una vez y usa `sudo` para las
operaciones de sistema. `sudo ./install.sh` también funciona: el instalador
usa `SUDO_USER` para el usuario destino. Si se inicia como root sin
`SUDO_USER`, pregunta el usuario.

La primera instalación necesita Internet para descargar paquetes y la Nerd Font.
**Ya no se descarga Zig, Ly, Cargo ni se compila nada.** En una VM de prueba
la política automática omite el driver NVIDIA.

Uso normal:

| Opción | Efecto |
|---|---|
| `./install.sh` | Instalación guiada; solo pregunta cuando hay una decisión real |
| `./install.sh --dry-run` | Muestra el plan completo sin modificar el sistema |
| `./install.sh --yes` | No pide confirmación; no modifica repositorios APT |

Opciones avanzadas para automatización (no necesarias en uso normal):
`--user`, `--home`, `--rebuild`, `--nvidia`, `--no-nvidia`, `--cuda`, `--no-cuda`,
`--keymap`, `--font`, `--font-size`, `--resolution` y `--debug`. También están disponibles
`--help` y `--version`.

## Qué hace el instalador

1. **Detección**: Debian 13 y x86_64 se verifican antes de pedir `sudo`. Luego
   detecta VM, CPU, GPU, Secure Boot, resolución, cámaras, batería, backlight,
   WiFi, audio y tipo de sistema de archivos raíz.
2. **Dotfiles opcional**: pregunta por una URL Git HTTPS de un repo `dotfiles`.
   Si se da, lo clona, valida la estructura `config/.config/{7 carpetas}` y
   las copia a `~/.config/`. Si faltan carpetas, pregunta si continuar con
   templates integrados o abortar.
3. **Preflight APT**: lee los componentes habilitados (`main`, `contrib`,
   `non-free`, `non-free-firmware`). Si falta `main`, aborta. Si faltan
   componentes opcionales, ofrece tres opciones: añadirlos automáticamente,
   continuar sin ellos o cancelar. La opción 1 hace backup de las fuentes,
   modifica solo entradas oficiales de Debian 13, ejecuta `apt update` y
   vuelve a comprobar. `--dry-run` solo muestra el aviso; `--yes` continúa
   sin modificar repositorios.
4. **Paquetes**: grupos base, Xorg, compilación mínima, escritorio
   (bspwm+sxhkd+polybar+apps), audio/códecs, cámara, almacenamiento, red,
   fuentes, firmware, microcódigo y GPU.
5. **Fuente**: descarga JetBrainsMono Nerd Font `3.5.1`, verifica SHA-256 y
   ejecuta `fc-cache`. Si falla y no se pasó `--font`, usa `JetBrains Mono` de
   Debian o `monospace`, y avisa.
6. **Configuración**: renderiza templates de bspwm, sxhkd, polybar, picom,
   dunst, rofi, kitty con paleta Nord; copia `~/.xinitrc`, wallpaper; instala
   `desktop-safe` y `desktop-doctor` en `/usr/local/bin/`.
7. **Verificación**: comprueba binarios, archivos, servicios y permisos.
   La prueba gráfica real se hace después de entrar a la sesión con `startx`.

### Backups y logs

- Backups de sistema: `/var/backups/dwm-setup/<timestamp>/`
- Backups de usuario: `~/.config-backup/dwm-setup/<timestamp>/`
- Log: `~/.local/state/dwm-setup/install-<timestamp>.log` (fallback a `~/.cache/dwm-setup/`)

Si se elige añadir componentes APT, `/etc/apt/sources.list` y
`/etc/apt/sources.list.d/` se guardan antes de editarlos. El log se escribe en
el home del usuario destino. `--dry-run` no crea log ni modifica archivos.

### Sesión (startx)

El instalador **no instala ningún display manager**. Genera `~/.xinitrc` que
ejecuta `bspwm`; el `autostart` interno de bspwm levanta polybar, dunst, picom,
udiskie, xss-lock, low_bat_notifier (si hay batería) y xwallpaper.

Para iniciar:
1. Reinicia: `sudo reboot`
2. En TTY1 entra con tu usuario.
3. Ejecuta `startx`.

Opcional: auto-login en TTY1 añadiendo a `~/.bash_profile`:
```sh
if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
  exec startx
fi
```

### Almacenamiento extraíble

`bspwm/scripts/autostart` arranca:
```sh
udiskie --automount --notify
```
`udiskie` monta el dispositivo y muestra una notificación. No se abre ninguna
ventana. `thunar` se abre manualmente con `Super+Shift+F`.

### Audio y vídeo

PipeWire es el servidor; WirePlumber es el gestor de sesión. `pavucontrol`
sirve para elegir dispositivos. La instalación incluye FFmpeg,
`libavcodec-extra`, GStreamer base/good/bad/ugly/libav/vaapi y
`ffmpegthumbnailer`. La aceleración VA-API/VDPAU depende de la GPU y de los
drivers de firmware; `desktop-doctor` muestra el estado.

### Cámara

Se instala `v4l-utils`, y `libcamera-tools` si está disponible. La prueba real
se ejecuta después de entrar a la sesión:

```sh
desktop-doctor --camera
```

Esto prueba `/dev/video*` con `ffmpeg` y crea un frame temporal. Si el usuario
acaba de ser añadido al grupo `video`, hay que cerrar sesión y volver a entrar.

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
2. Ejecuta `startx` para usar `~/.xinitrc`.
3. Revisa `journalctl -b` y el log del instalador.
4. Comprueba que existe `~/.local/share/xorg` con permisos `0700` y propietario
   del usuario. Si falta, créalo:
   `sudo install -d -m 0700 -o "$USER" -g "$(id -gn)" ~/.local/share/xorg`.

## Uso diario

| Atajo | Acción |
|---|---|
| `Super+Return` | kitty |
| `Super+d` | rofi (drun) |
| `Super+Shift+b` | firefox |
| `Super+Shift+e` | VS Code |
| `Super+Shift+f` | thunar |
| `Super+Shift+l` | bloquear (desktop-safe lock) |
| `Super+Shift+s` | captura de pantalla (rofi menu) |
| `Print` | captura completa |
| `Super+Print` | menú capturas |
| `Super+{h,j,k,l}` | foco ventanas |
| `Super+Shift+{h,j,k,l}` | mover ventanas |
| `Super+{1-5}` | ir a escritorio |
| `Super+Shift+{1-5}` | mover ventana a escritorio |
| `Super+Alt+{h,j,k,l}` | redimensionar |
| `Super+m` | monocle/tiled |
| `Super+f` | fullscreen |
| `XF86AudioRaise/Lower/Mute` | volumen |
| `XF86MonBrightnessUp/Down` | brillo |

`Super` es la tecla Windows. La barra polybar muestra **workspaces 1-5 con dígitos árabes** (enfocado = caja clara), logo U+F2DD en el extremo izquierdo, CPU, RAM, temp, red (ethernet + wifi si hay), audio, fecha, pomodoro, updates y batería (si hay).

## Estructura del repositorio

```text
install.sh                 Entrada principal
lib/common.sh              Logs, sudo, backups, render de plantillas
lib/detect.sh              Detección de sistema/hardware
lib/packages.sh            Grupos de paquetes y Nerd Font
lib/dotfiles.sh            Clonar repo dotfiles opcional
lib/bspwm.sh               bspwm + autostart + xinitrc
lib/sxhkd.sh               sxhkdrc
lib/polybar.sh             polybar config/modules/scripts/launch
lib/picom.sh               picom.conf
lib/dunst.sh               dunstrc
lib/rofi.sh                rofi powermenu
lib/kitty.sh               kitty.conf
lib/config.sh              Configs de usuario y sesión
lib/verify.sh              Verificación estática final
lib/theme.sh               Paleta Nord y generadores de assets
bin/desktop-safe           Acciones de sesión (lock/suspend/logout/poweroff/reboot)
bin/desktop-doctor         Diagnóstico y prueba de cámara
templates/colors/          palette-nord.sh
templates/bspwm/           bspwmrc.in, autostart.in, scripts/
templates/sxhkd/           sxhkdrc.in
templates/polybar/         config.ini.in, modules/, scripts/
templates/picom/           picom.conf.in
templates/dunst/           dunstrc.in
templates/rofi/            powermenu.rasi.in
templates/kitty/           kitty.conf.in
assets/wallpaper.jpg       Wallpaper de referencia
src/chadwm/                Fuente chadwm (vendorizada, ya no se usa)
src/eww/                   Fuente eww (vendorizada, ya no se usa)
docs/                      Hardware y testing
legacy/                    Prototipo antiguo, no usado
```

Los archivos de `legacy/` se conservan solo como referencia histórica. La
fuente de verdad es `install.sh`, `lib/` y `templates/`.

## Limitaciones conocidas

- No hay validación real todavía en Debian 13 minimal ni en el hardware de
  referencia; los checks locales y de dry-run no sustituyen esa prueba.
- La cámara, el montaje USB, el audio/códecs y NVIDIA/PRIME necesitan hardware
  real o pass-through de VM.
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
- [`DECISIONS.md`](DECISIONS.md): decisiones de arquitectura (ADR-022 migración).
- [`docs/hardware.md`](docs/hardware.md): hardware de referencia y matriz de
  detección.
- [`docs/testing.md`](docs/testing.md): plan de pruebas y criterios de
  aceptación.
- [`PLAN.md`](PLAN.md): plan antiguo, conservado solo como historia.