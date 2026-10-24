# Progreso — fase 1b (bspwm + polybar)

Última actualización: 2026-10-24

## Resumen

La fase 1b está implementada y validada en la sesión viva del host de
referencia (Debian 13, Intel UHD 630 + NVIDIA GTX 1050 Ti Mobile,
1920x1080). El instalador se ha corregido para que los backups se hagan
antes de escribir, el home quede con el propietario correcto, `bspwmrc` sea
ejecutable, picom arranque y la verificación final no falle.

- Estado del código: implementado; `bash -n`, `sh -n`, `--dry-run` y
  verificación sobre home simulado pasan.
- Estado de validación real: **sesión viva validada**; falta la instalación
  desde cero en VM Debian 13 minimal.
- Sesión: `startx` manual desde TTY; sin display manager ni auto-login.
- Barra: 12 módulos, logo StumbleUpon, 4 workspaces, red unificada y `dots`.

## Validación viva (2026-10-24)

Host: Debian GNU/Linux 13 (trixie), kernel 6.12, Xorg 1920x1080, NVIDIA 550
instalado (Xorg usa Intel `modeset`), PipeWire 1.4.2.

Procesos comprobados:

- `bspwm 0.9.10`
- `sxhkd 0.6.2`
- `polybar 3.7.2` con **12 módulos**: `logo`, `bspwm`, `updates`,
  `polypomo`, `temp`, `memory`, `cpu`, `network`, `pipewire`,
  `battery`, `date`, `dots`.
- `picom` 12.5 activo (config sin `glx-swap-method`).
- `dunst 1.12.2`, `lxpolkit`, `udiskie -N -a`, `xss-lock` activos.
- `BAT1`, `ACAD`, `enp3s0`, `wlo1`, batería y volumen visibles en la barra.
  La red es un solo módulo: con WiFi down y Ethernet up muestra `󰈀 connected`;
  no muestra `NoC`. El layout `latam` se aplica con `setxkbmap` pero ya no
  ocupa un módulo de la barra.
- `notify-send` funciona.

Comprobaciones:

- `~/.config/bspwm/bspwmrc` y `~/.xinitrc`: `0755`; `.xinitrc` termina en
  `exec bspwm` y ya no lanza `kitty`.
- Sin placeholders `@...@` en las configuraciones vivas.
- `low_bat_notifier.sh` contiene `BATTERY="BAT1"`.
- Sin ficheros root en `~/.config/{bspwm,sxhkd,polybar,picom,dunst,rofi,kitty}`.
- `desktop-doctor` (repo) muestra todos los binarios/configs/procesos OK;
  solo avisa de que no hay cámara.
- Home simulado (`/tmp/opencode/fakehome`) renderizado y `verify_install`
  pasa con código 0.

## Mapa de atajos i3 (2026-10-24)

Se adaptó `templates/sxhkd/sxhkdrc.in` a los atajos de i3 del usuario,
manteniendo gaps 10, borde 2 y el wallpaper actual. El rediseño final
redujo a 4 escritorios y reincorporó `dots`:

- Apps: `Super+Return` kitty, `Super+Shift+s` scrot región+portapapeles,
  `Super+Shift+p` pcmanfm, `Super+Shift+b` chromium, `Super+Shift+v`
  codium, `Super+Shift+i` ristretto, `Super+Shift+a` lxappearance y
  `Super+Shift+d` rofi run. Las apps que no están en fase 1 quedan como
  bindings no-op.
- `Super+Shift+e` pasa a logout; el editor se mueve a `Super+Shift+v`.
- `Alt+Tab` / `Alt+Shift+Tab` ciclan ventanas visibles del escritorio.
- `Super+r` + `h/j/k/l` redimensiona con cadena de sxhkd (`:`); `Escape`
  sale. Se retiró `Super+Alt+{flechas}`.
- Se añadieron `Super+Shift+c` (reload), `Super+Shift+r` (restart),
  `Super+Shift+space` (floating), `Super+a` (parent) y `Super+b/v`
  (split h/v por preselección).
- Se mantienen los extras: Thunar, lock, rofi drun, capturas, flags y
  multimedia.
- `Super+s/w/e` de i3 (stacking/tabbed/toggle split) no tienen equivalente
  exacto en bspwm; no se mapean en esta iteración.

Validado en vivo: `sxhkd` recarga el nuevo `sxhkdrc` sin errores; el
`bspwm_resize h/l` cambia el ancho en un layout lado a lado y la cadena
`Super+r` se queda activa hasta `Escape`. `Alt+Tab`/`Alt+Shift+Tab` ciclan
ventanas. `Super+Shift+s` probado con XTest: región 400x300 copiada como
`image/png`, sin temporales y con notificación de dunst. `Super+Shift+d`
abre `rofi -show run`; `Super+d` sigue abriendo `rofi -show drun`.
`j/k` solo pueden cambiar altura cuando el split es vertical (ventanas
apiladas) o la ventana es flotante; es una limitación del tiling de bspwm.

## Audio HDMI/auriculares y dunst (2026-10-24)

Se añadió un watcher de audio genérico y sonido de notificación:

- `audio-switch.sh` cambia entre `headphones`, `hdmi` y `analog` usando
  perfiles/puertos detectados con `pactl`; no hardcodea tarjeta ni monitor.
- `audio-watch.sh` aplica la prioridad **auriculares > HDMI > altavoces** y
  respeta sinks/sources USB/Bluetooth seleccionados por el usuario.
- Al cambiar de salida conserva volumen/mute y mueve los streams.
- `notification-sound.sh` reproduce `message-new-instant.oga` con `paplay`
  (fallback `pw-play`) en cada notificación de dunst.
- `stack_duplicates = false`: dos mensajes idénticos ya no se agrupan en
  `(2)`; se muestran por separado y cada uno dispara el script.
- `flock` serializa los sonidos: si llegan dos a la vez, el segundo espera
  al primero.
- `gap_size = 6` deja 6 px entre notificaciones; comprobado con dos
  `notify-send` seguidos (captura `gap.png`).
- `scrot -s --line mode=edge` con borde magenta (`#FF00FF`, 2 px, opacidad
  255) para que se vea sobre fondo blanco. `xrefresh` después de capturar
  borra el rectángulo residual; `--freeze` se descartó porque capturaba la
  pantalla completa con eventos sintéticos.
- Con XTest, la región 400x300 llega al portapapeles, no queda temporal y
  tras `xrefresh` no queda el rectángulo en pantalla.
- La notificación de captura muestra una miniatura de 64 px del recorte
  desde `~/.cache/dunst/last-screenshot.png`; comprobado con una captura de
  la notificación.
- `Print` captura la pantalla completa y la copia al portapapeles con
  miniatura; `Super+Print` mantiene el menú de capturas.
- `sound-theme-freedesktop` se añadió a `AUDIO_PKGS`.
- Quirk `alc255-asus` para ASUS FX504GE/ALC255:
  - Detecta DMI y códec.
  - Pregunta en modo interactivo; `--yes` lo aplica si el hardware coincide.
  - `--headset-quirk` fuerza; `--no-headset-quirk` desactiva.
  - Backup del `.conf`, `update-initramfs -u` y aviso de reinicio.
  - En otros PCs no se aplica.

Probado en vivo:

- `audio-switch.sh hdmi` activa `output:hdmi-stereo` y el sink HDMI.
- `audio-switch.sh headphones` vuelve a `analog-stereo` con
  `analog-output-headphones`, volumen 40% conservado.
- Con auriculares conectados, el puerto de auriculares sigue disponible
  aunque el perfil HDMI esté activo; el watcher puede volver a ellos.
- Dunst reproduce el sonido: aparece un sink-input de `paplay` y la regla
  `[notification-sound]` está cargada.
- `notify-send` se ve y suena en el sink activo.
- Dos `notify-send` idénticos: `dunstctl count displayed` pasa de 0 a 2,
  no aparece `(2)` y se crean dos sink-inputs consecutivos (2953 → 2978),
  confirmando el `flock`.

Pendiente: reiniciar con el quirk ALC255 para confirmar que aparece el
micrófono del jack combo. Si funciona, el watcher lo pondrá como fuente
predeterminada; si no, se usará un headset USB.

## Rediseño polybar (2026-10-24)

Se replicó la barra de referencia:

- 4 escritorios (`1-4`); `bspwmrc` y `sxhkd` ajustados.
- Logo StumbleUpon `U+F1A4` (sin cambio).
- Workspace enfocado con caja blanca, texto oscuro, font-1 y padding 1.
- Orden derecha: `updates`, `polypomo`, `temp`, `memory`, `cpu`, `network`,
  `pipewire`, `battery`, `date`, `dots`.
- `updates` muestra `󰚌 # N`; si N=0 no muestra nada.
- `temp [T]`, `memory [M]`, `cpu [C]`.
- Red unificada: `󰖩 connected` si hay WiFi; si no, `󰈀 connected` si hay
  Ethernet; si no hay ninguna, nada. Sin `NoC` ni SSID; WiFi tiene
  prioridad. `NETWORK_FAKE=wifi|eth|none` permite probar los tres estados.
- `dots` vuelve con `...` al final.
- `xkeyboard`/`latam` eliminado de la barra; `wlan`/`eth` separados
  eliminados.
- Pomodoro pausa con `U+F04C` (dos barras) como la referencia.
- Separación compacta: `module-margin-left/right = 0`; `updates`/`polypomo`
  con padding 2/1; padding 1 en `temp`, `memory`, `cpu`, `pipewire`,
  `date` y `dots`; `network` 0; volumen y batería juntos (el volumen lleva
  un espacio inicial y la batería un solo espacio icono-porcentaje).
- Con `UPDATES_FAKE_FILE=0` el módulo de actualizaciones desaparece y no
  muestra `# 0` (probado en vivo).
- Polybar cargó 12 módulos sin errores; capturas `bar-design3.png` (diseño),
  `bar-spacing-final.png` (separación) y `bar-network-final.png` (red
  unificada).

## Correcciones aplicadas

- **Backups antes de escribir**: `backup_existing_configs` se ejecuta antes
  de instalar; los backups de usuario ya no copian los ficheros nuevos.
- **Ownership**: una sola `make_user_dir` con `run_user mkdir -p`;
  `render_theme_template` instala con `-o/-g` cuando el destino está en el
  home; `prepare_user_dirs`, `fix_user_topdirs` y `chown_managed_paths`
  corrigen `~/.config`, `~/.local` y `~/.config-backup`. Ya no hace falta
  `sudo chown -R` manual.
- **`bspwmrc` 0755**: bspwm ya lo ejecuta y arranca sxhkd, polybar y el
  autostart. El `kitty &` de `.xinitrc` se eliminó.
- **Picom**: se quitó `glx-swap-method` (eliminado en picom 12), `refresh-rate`
  y condiciones deprecadas; arranca sin errores.
- **Autostart**: sin `set -e`, log en `~/.local/state/dwm-setup/session.log`,
  `lxpolkit`, `udiskie -N -a` sin `-t`, aviso si picom no arranca.
- **Batería baja**: se pasa `BATTERY` al renderizar el script.
- **`desktop-doctor`**: reescrito en POSIX sh; ya no usa `[[`,
  `WAYLAND_DISPLAY` sin `:-` ni `ls BAT* | xargs basename`.
- **Barra**: font-0 pasa de `DesktopLogo` a JBM; se retira
  `assets/desktop-logo.ttf` y la instalación de la fuente. `dots.ini` se
  retiró temporalmente y se reincorporó en el rediseño final; se añade
  limpieza idempotente de restos.
- **Limpieza**: eliminados `lib/dwm.sh`, `lib/eww.sh`, `lib/ly.sh`,
  `templates/dwm/`, paletas no usadas, `--rebuild` y la integración de
  dotfiles externos.
- **Documentación**: `AGENTS.md`, `README.md`, `PROGRESS.md`,
  `docs/testing.md` actualizados; capturas movidas a `docs/images/`.

## Checklist de implementación — fase 1b

- [x] Estructura del proyecto (`install.sh`, `lib/`, `bin/`, `templates/`).
- [x] Detección de Debian/arquitectura/VM/CPU/GPU/Secure Boot/resolución.
- [x] Detección de cámara, batería, backlight, WiFi, audio y raíz.
- [x] Resolución automática de usuario/home y validación de `sudo`.
- [x] Uso normal `./install.sh`, con `--dry-run`/`--yes`.
- [x] Grupos de paquetes Debian 13 (bspwm, sxhkd, polybar, sin compilación).
- [x] Preflight de componentes APT con menú y auto-add autorizado.
- [x] Nerd Font con versión y checksum fijos, con fallback.
- [x] bspwm instalado desde apt + bspwmrc 0755 + autostart + scripts.
- [x] sxhkd instalado desde apt + sxhkdrc renderizado.
- [x] polybar instalado desde apt + config.ini, modules/, scripts/, launch.sh.
- [x] picom instalado desde apt + picom.conf moderno.
- [x] dunst instalado desde apt + dunstrc (Adwaita).
- [x] rofi instalado desde apt + powermenu.rasi (Adwaita).
- [x] kitty instalado desde apt + kitty.conf.
- [x] Sesión: `~/.xinitrc` → `bspwm`; autostart interno.
- [x] `desktop-safe` para lock/suspend/logout/poweroff/reboot.
- [x] `desktop-doctor` POSIX para bspwm/sxhkd/polybar/picom/cámara.
- [x] Verificación estática final (`verify_install`).
- [x] Backups de sistema y usuario antes de escribir.
- [x] Ownership automático del home y logs.
- [x] `--dry-run` sin modificaciones.
- [x] Limpieza de restos de la barra anterior.
- [x] Documentación actualizada.

## Checklist de validación

- [x] Sesión viva en Debian 13 (host de referencia).
- [x] `desktop-doctor` sin falsos `[FALTA]`.
- [x] Barra con 12 módulos y sin placeholders.
- [x] Picom, dunst, lxpolkit, udiskie y xss-lock activos.
- [x] `bspwmrc` ejecutable y `.xinitrc` sin kitty.
- [x] Ownership de `~/.config`, `~/.local` y `~/.config-backup`.
- [ ] Instalar Debian 13 minimal en VM con UEFI y snapshot.
- [ ] Ejecutar `./install.sh --dry-run` en la VM.
- [ ] Ejecutar `./install.sh` en la VM y comprobar salida 0.
- [ ] Repetir la instalación para comprobar idempotencia y backups previos.
- [ ] Reiniciar y comprobar `startx` desde TTY1.
- [ ] Probar atajos (kitty, rofi, thunar, capturas, lock, volumen, brillo).
- [ ] Probar audio PipeWire/WirePlumber y `pavucontrol`.
- [ ] Reproducir vídeo H.264/HEVC y comprobar VA-API si hay GPU.
- [ ] Ejecutar `desktop-doctor --camera` con una cámara real o virtual.
- [ ] Conectar USB exFAT/NTFS/FAT y comprobar montaje + notificación.
- [ ] Probar suspensión y bloqueo con xss-lock.
- [ ] Probar NVIDIA con Secure Boot desactivado y documentar MOK si aplica.
- [ ] Subir el repositorio y validar un clon limpio.

## Bloqueos actuales

- No hay una VM Debian 13 minimal preparada en este entorno.
- La cámara, el montaje USB, el audio/códecs y NVIDIA/PRIME necesitan
  hardware real o pass-through de VM.
- La instalación real con `sudo ./install.sh` no se ha podido ejecutar desde
  el agente (sudo sin TTY); se validó el render y `verify_install` en un home
  simulado. El usuario debe ejecutar el instalador en su terminal.
- Falta commit final y subida del repositorio.

## Riesgos conocidos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| `bspwmrc` sin `+x` | Alto | Se instala 0755 y `verify_install` lo comprueba |
| Backups tardíos | Alto | `backup_existing_configs` antes de escribir |
| Directorios root en el home | Medio | `make_user_dir` + `chown_managed_paths` |
| Picom no arranca | Medio | Config sin `glx-swap-method`; log de sesión |
| Módulo battery/red inexistente | Bajo | Batería condicional; red oculta si no hay conexión |
| Nerd Font no descarga | Bajo | Fallback a JetBrains Mono/monospace |
| Glifo Nerd Font 3.x incorrecto | Bajo | Verificar con `fc-list :charset=...` |
| NVIDIA DKMS falla | Medio | Grupo GPU opcional; se continúa con Intel |
| Secure Boot activo | Medio | Se omite NVIDIA y se avisa; `--nvidia` fuerza |
| USB no monta | Medio | `udiskie -N -a` en autostart; doctor lo muestra |
| El usuario no cierra sesión tras `usermod` | Medio | Se avisa; grupos se aplican al reentrar |

## Próximos pasos

1. Ejecutar `sudo ./install.sh` en el host actual y comprobar salida 0.
2. Reiniciar y entrar con `startx`; validar atajos y sesión.
3. Repetir la instalación para comprobar idempotencia.
4. Preparar VM Debian 13 minimal con snapshot y repetir.
5. Validar cámara, USB, audio y NVIDIA/PRIME en hardware.
6. Subir el repositorio y validar un clon limpio.
