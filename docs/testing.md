# Plan de pruebas — fase 1b (bspwm + polybar)

Objetivo: validar el instalador en **Debian 13 minimal** y comprobar que un
`./install.sh` deja el escritorio listo sin `chown` ni `chmod` manuales.

> Estado 2026-10-24: sesión viva validada en el host de referencia. Falta la
> instalación desde cero en VM y la prueba de idempotencia.

## 1. Checks estáticos

```sh
cd ~/dwm-setup

# Sintaxis Bash
for f in install.sh lib/*.sh; do bash -n "$f" || exit 1; done

# Sintaxis POSIX de binarios y scripts de sesión
for f in bin/desktop-safe bin/desktop-doctor; do sh -n "$f" || exit 1; done
for f in templates/bspwm/autostart.in templates/bspwm/bspwmrc.in \
         templates/bspwm/scripts/*.in; do sh -n "$f" || exit 1; done

# Plan sin cambios
./install.sh --dry-run

# ShellCheck si está instalado
shellcheck install.sh lib/*.sh bin/desktop-safe bin/desktop-doctor
```

Resultado esperado: todo en silencio excepto el plan del dry-run.

## 2. Render en home simulado (sin root)

Se puede validar el render sin tocar el home real:

```sh
# Ajustar TARGET_HOME a /tmp/opencode/fakehome y ejecutar las funciones
# install_bspwm/install_sxhkd/install_polybar/install_picom/install_dunst/
# install_rofi/install_kitty. Después:
grep -RInE '@[A-Z][A-Z0-9_]*@' /tmp/opencode/fakehome/.config \
  /tmp/opencode/fakehome/.xinitrc
stat -c '%A %n' /tmp/opencode/fakehome/.config/bspwm/bspwmrc \
  /tmp/opencode/fakehome/.xinitrc
grep -n 'BATTERY=' /tmp/opencode/fakehome/.config/bspwm/scripts/low_bat_notifier.sh
```

Criterios:

- Sin placeholders.
- `bspwmrc` y `.xinitrc` en `0755`.
- `.xinitrc` sin `kitty &` y con `exec bspwm`.
- `BATTERY` renderizado al nombre real (por ejemplo `BAT1`).
- Todos los ficheros pertenecen al usuario.
- `verify_install` pasa con código 0.

## 3. Limpieza y coherencia de configs

```sh
grep -RInE '@[A-Z][A-Z0-9_]*@' ~/.config/bspwm ~/.config/sxhkd \
  ~/.config/polybar ~/.config/picom ~/.config/dunst ~/.config/rofi \
  ~/.config/kitty ~/.xinitrc

find ~/.config/bspwm ~/.config/sxhkd ~/.config/polybar ~/.config/picom \
  ~/.config/dunst ~/.config/rofi ~/.config/kitty -not -user "$USER" -print

grep -nE 'font-[0-9]|modules-(left|right)|include-directory' \
  ~/.config/polybar/config.ini

grep -n 'glx-swap-method' ~/.config/picom/picom.conf && echo "MAL"
grep -n 'icon-theme\|icon_theme' ~/.config/rofi/powermenu.rasi ~/.config/dunst/dunstrc
```

Resultado esperado: sin placeholders, sin ficheros de root, 13 módulos,
sin `glx-swap-method`, iconos Adwaita.

## 4. Validación en vivo (2026-10-24)

Host: Debian 13, kernel 6.12, Xorg 1920x1080, Intel UHD 630 + NVIDIA GTX
1050 Ti Mobile, PipeWire 1.4.2.

Comprobado:

- `bspwm 0.9.10`, `sxhkd 0.6.2`, `polybar 3.7.2` (13 módulos), `picom 12.5`,
  `dunst 1.12.2`, `lxpolkit`, `udiskie -N -a`, `xss-lock`.
- Barra: logo StumbleUpon, workspaces 1-4, updates `󰚌 # N`, `25:00`,
  temperatura `[T]`, RAM `[M]`, CPU `[C]`, WiFi `NoC`, eth `connected`,
  volumen, batería `BAT1`, fecha y `dots`.
- Barra rediseñada: 4 workspaces, caja blanca en el enfocado, logo
  StumbleUpon, `updates` con calavera y contador, `[T]/[M]/[C]`, `NoC`,
  `connected`, `dots` y sin `xkeyboard`. Polybar carga 13 módulos sin
  errores.
- `bspwmrc` y `.xinitrc` ejecutables; `.xinitrc` sin `kitty`.
- Sin placeholders y sin ficheros root en `~/.config`.
- `desktop-doctor` sin falsos `[FALTA]`; solo avisa de cámara ausente.
- `notify-send` funciona.
- Picom arranca sin errores (`glx`).
- `sxhkd` recarga el nuevo mapa de i3 sin errores.
- `Super+r` + `h`/`l` probado con XTest: cambia el ancho y `Escape` sale.
- `Alt+Tab` y `Alt+Shift+Tab` probados con XTest: ciclo de ventanas.
- `Super+Shift+s` probado con XTest: región 400x300 copiada como
  `image/png`, sin temporales y con notificación de dunst.
- `Super+Shift+d` abre `rofi -show run`; `Super+d` sigue abriendo
  `rofi -show drun`.

Pendiente de la prueba real completa:

- `sudo ./install.sh` desde el agente no se pudo ejecutar (sudo sin TTY).
  El usuario debe ejecutarlo en su terminal.
- Reinicio/`startx` y prueba E2E de atajos.
- Cámara real o virtual.
- USB exFAT/NTFS/FAT.
- Audio/códecs y VA-API.
- NVIDIA/PRIME y MOK.
- Idempotencia y backups previos.

## 5. Instalación en VM Debian 13 minimal

1. Crear VM Debian 13 minimal (UEFI, snapshot, 2 GB RAM, 20 GB disco).
2. Instalar `git` y clonar el repo.
3. `./install.sh --dry-run` y revisar el plan.
4. `./install.sh` y comprobar salida 0.
5. Reiniciar y entrar en TTY1 con el usuario.
6. `startx`.
7. Ejecutar `desktop-doctor`.
8. Repetir `./install.sh` para idempotencia.
9. Comprobar que el segundo backup contiene la versión anterior.

Criterios de aceptación:

- `./install.sh` termina con código 0.
- No hace falta `chown` ni `chmod` manual.
- No hay placeholders ni ficheros root en el home.
- Tras `startx`, bspwm, sxhkd, polybar, picom, dunst, lxpolkit, udiskie y
  xss-lock están activos.
- La barra muestra los módulos disponibles (13 en el host de referencia).
- `desktop-doctor` no reporta fallos.
- El segundo backup contiene las configs anteriores.

## 6. Atajos (E2E)

| Atajo | Acción | Criterio |
|---|---|---|
| `Super+Return` | kitty | Abre terminal |
| `Super+d` | rofi drun | Abre lanzador |
| `Super+Shift+d` | rofi -show run | Lanzador de comandos |
| `Super+Shift+s` | scrot región | Selecciona y copia al portapapeles |
| `Super+Shift+p` | pcmanfm | Pendiente de instalar pcmanfm |
| `Super+Shift+b` | chromium | Pendiente de instalar chromium |
| `Super+Shift+v` | codium | Pendiente; requiere repo VSCodium |
| `Super+Shift+i` | ristretto | Pendiente de instalar ristretto |
| `Super+Shift+a` | lxappearance | Pendiente de instalar lxappearance |
| `Super+Shift+f` | Thunar | Abre gestor |
| `Super+Shift+l` | lock | Bloquea |
| `Super+Shift+e` | logout | Cierra la sesión |
| `Super+Shift+c` | reload | Recarga sxhkd/bspwm |
| `Super+Shift+r` | restart | Reinicia bspwm |
| `Super+Shift+space` | floating | Alterna flotante |
| `Super+a` | parent | Enfoca contenedor padre |
| `Super+b` / `Super+v` | split h/v | Preselección para la próxima ventana |
| `Super+f` | fullscreen | Alterna fullscreen |
| `Alt+Tab` / `Alt+Shift+Tab` | ciclo | Siguiente/anterior ventana |
| `Super+{h,j,k,l}` | foco | Cambia ventana |
| `Super+Shift+{h,j,k,l}` | mover | Intercambia ventana |
| `Super+{1-4}` | escritorios | Cambia escritorio |
| `Super+r`, luego `h/j/k/l` | resize | Redimensiona; Escape sale |
| `Print` | captura completa | Copia al portapapeles y muestra miniatura |
| `Super+Print` | menú de capturas | Abre el menú y permite guardar en `~/Pictures/Screenshots` |
| `XF86Audio*` | volumen | pamixer |
| `XF86MonBrightness*` | brillo | brightnessctl |

Los atajos de apps no instaladas se dejan puestos para conservar la memoria
muscular; no hacen nada hasta instalar la app. `Super+s/w/e` de i3 no tienen
equivalente exacto en bspwm y no se mapean.

## 6b. Audio, HDMI, auriculares y dunst

Comprobar que los scripts existen y son ejecutables:

```sh
ls -l ~/.config/bspwm/scripts/audio-switch.sh \
  ~/.config/bspwm/scripts/audio-watch.sh \
  ~/.config/dunst/scripts/notification-sound.sh
```

Pruebas manuales:

```sh
# Estado actual
pactl get-default-sink
pactl get-default-source
pactl list cards | grep -E 'Active Profile|analog-output|hdmi-output'

# Forzar salidas (sin watcher, o el watcher volverá a la prioridad)
~/.config/bspwm/scripts/audio-switch.sh hdmi
~/.config/bspwm/scripts/audio-switch.sh headphones
~/.config/bspwm/scripts/audio-switch.sh analog
```

Criterios:

- Con auriculares conectados, `analog-output-headphones` está disponible y
  es el puerto activo.
- Con HDMI conectado y sin auriculares, se activa `output:hdmi-stereo` y el
  sink `*.hdmi-stereo`.
- Con un sink/source USB/Bluetooth seleccionado, el watcher no lo pisa.
- El volumen/mute se conserva al cambiar de sink.
- `notify-send "Prueba" "Sonido"` muestra la notificación y aparece un
  sink-input de `paplay`; se oye en el sink activo.
- `dunstctl rules` incluye `notification-sound`.
- Dos notificaciones idénticas seguidas:
  ```sh
  notify-send "Prueba duplicado" "Mismo mensaje"
  notify-send "Prueba duplicado" "Mismo mensaje"
  dunstctl count displayed   # debe ser 2, no (2)
  ```
  Deben verse dos notificaciones separadas por `gap_size = 6` y oírse dos
  sonidos consecutivos (dos sink-inputs distintos con `flock`).
- Captura de región:
  ```sh
  # Super+Shift+s y arrastrar una región
  xclip -selection clipboard -t image/png -o > /tmp/region.png
  file /tmp/region.png        # dimensiones de la región
  ```
  No debe quedar el rectángulo de selección en pantalla ni temporales en
  `/tmp/scrot.*`. Scrot usa `--line mode=edge,color=#FF00FF,width=2,opacity=255`
  y un `xrefresh` posterior. Probar sobre una ventana blanca para confirmar
  que la línea magenta se ve.
  La notificación de “Región copiada al portapapeles” debe mostrar una
  miniatura del recorte desde `~/.cache/dunst/last-screenshot.png` (64 px).
- Captura completa:
  ```sh
  # Pulsar Print
  xclip -selection clipboard -t image/png -o > /tmp/full.png
  file /tmp/full.png          # 1920x1080 o resolución actual
  ```
  Debe copiarse al portapapeles, mostrar miniatura en la notificación y no
  dejar temporales en `/tmp/scrot.*`. `Super+Print` debe seguir abriendo el
  menú de capturas.
- En un PC sin HDMI/auriculares o en VM, el watcher no falla.

Quirk ALC255 (solo ASUS FX504GE/ALC255):

```sh
# Detección en dry-run
./install.sh --dry-run | grep -A2 'modprobe.d/alsa-fx504'

# Tras instalar y reiniciar, con los auriculares conectados:
pactl list sources | grep -A12 -i 'analog-input\|headset\|mic'
pactl list cards | grep -E 'analog-input|Active Profile'
timeout 5 parecord --device=alsa_input.pci-0000_00_1f.3.analog-stereo /tmp/mic-test.wav
paplay /tmp/mic-test.wav
```

Si el quirk no funciona, revertir:

```sh
sudo rm -f /etc/modprobe.d/alsa-fx504.conf
sudo /usr/sbin/update-initramfs -u
sudo reboot
```

## 7. Cámara, USB y NVIDIA

- `desktop-doctor --camera` con una cámara UVC real o virtual.
- USB exFAT/NTFS/FAT: `udiskie` monta y notifica; no se abre Thunar.
- Vídeo H.264/HEVC: `ffmpeg`/GStreamer; `vainfo` si hay GPU.
- NVIDIA: `nvidia-smi`, Secure Boot y MOK; Xorg puede usar Intel y PRIME.

## 8. Diagnóstico

```sh
desktop-doctor
desktop-doctor --camera
less ~/.local/state/dwm-setup/session.log
less ~/.local/state/dwm-setup/install-*.log
```

Si algo falla, entrar por `Ctrl+Alt+F3` y ejecutar `startx` manualmente.
