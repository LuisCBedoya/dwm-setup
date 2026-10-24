# Hardware y detección — fase 1b

## Host de referencia (2026-10-24)

| Elemento | Valor |
|---|---|
| Sistema | Debian GNU/Linux 13 (trixie), x86_64 |
| Kernel | 6.12.113+deb13-amd64 |
| CPU | Intel Core i5-8300H (GenuineIntel) |
| iGPU | Intel UHD Graphics 630 (CoffeeLake-H) |
| dGPU | NVIDIA GeForce GTX 1050 Ti Mobile (GP107M) |
| Driver NVIDIA | 550.163.01 (`nvidia-smi` funciona) |
| Xorg | 1920x1080, Intel `modeset`; NVIDIA disponible para PRIME |
| Audio | Intel HDA + PipeWire 1.4.2 / WirePlumber |
| Batería | `BAT1`; adaptador `ACAD` |
| Ethernet | `enp3s0` |
| WiFi | `wlo1` (puede estar DOWN sin conexión) |
| Cámara | no detectada |
| Backlight | no detectado por sysfs |
| Raíz | ext4 |

La sesión se inicia con `startx` desde TTY1. No hay LightDM, XFCE ni
display manager.

## Detección del instalador

| Elemento | Fuente | Notas |
|---|---|---|
| Debian 13 | `/etc/os-release` | Aborta si no es Debian 13 |
| Arquitectura | `uname -m` | Solo `x86_64`/`amd64` |
| Virtualización | `systemd-detect-virt` | NVIDIA se omite en VM por defecto |
| CPU | `lscpu` o `/proc/cpuinfo` | Microcódigo Intel/AMD opcional |
| GPU | `lspci -nn` o sysfs `/sys/bus/pci` | Intel/AMD/NVIDIA |
| Secure Boot | `/sys/firmware/efi` + `mokutil`/efivars | NVIDIA propietario omitido si está activo |
| Resolución | `/sys/class/drm/card*-*/modes` o `xrandr` | 1920x1080 en el host |
| Cámara | `/sys/class/video4linux/video*` | `uvcvideo` |
| Batería | `/sys/class/power_supply/BAT*` | `BAT1` |
| Backlight | `/sys/class/backlight/*` | No detectado en el host |
| WiFi | `lspci`/`/sys/class/net/*/wireless` | `wlo1` |
| Audio | `/proc/asound/cards` | Intel HDA |
| Raíz | `findmnt -n -o FSTYPE /` | ext4 |

## NVIDIA y PRIME

El driver propietario se instala si hay GPU NVIDIA, Secure Boot está
desactivado y no es una VM. En el host está instalado y `nvidia-smi`
funciona, pero Xorg usa la iGPU Intel (`modeset`).

Para probar una aplicación con la NVIDIA:

```sh
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep OpenGL
nvidia-smi
```

Si DKMS falla, el grupo GPU es opcional y el instalador continúa con
Intel/Mesa. Revisar el log y `dkms status`. Con Secure Boot activo se omite
el driver salvo `--nvidia`; hace falta configurar MOK.

## Sesión y Xorg

- `~/.xinitrc` configura el teclado con `setxkbmap`, el cursor y hace
  `exec bspwm`.
- `~/.config/bspwm/bspwmrc` **debe ser ejecutable**; lanza sxhkd y
  `scripts/autostart`.
- `~/.local/share/xorg` se crea con modo `0700` y propietario del usuario
  para que Xorg escriba su log sin root.
- `autostart` levanta polybar, dunst, picom, xwallpaper, udiskie,
  xss-lock, lxpolkit y el notificador de batería.
- Log de sesión: `~/.local/state/dwm-setup/session.log`.

## Almacenamiento extraíble

Se instalan `udisks2`, `udiskie`, `gvfs`, `gvfs-backends`, `exfatprogs`,
`ntfs-3g`, `dosfstools` y `e2fsprogs`.

`autostart` ejecuta `udiskie -N -a`: monta y notifica, sin abrir ninguna
aplicación. Thunar se abre manualmente con `Super+Shift+F`.

## Audio y vídeo

PipeWire es el servidor; WirePlumber el gestor de sesión. Se instalan
`alsa-utils`, `pavucontrol`, `pamixer`, `pulseaudio-utils`,
`sound-theme-freedesktop`, FFmpeg, `libavcodec-extra`, GStreamer
base/good/bad/ugly/libav/vaapi y `ffmpegthumbnailer`.

En el host de referencia la tarjeta Intel HDA expone:

- `card 0`, device 3: `HDMI 0 [24 TV]` con ELD válido (FL/FR, LPCM 2ch).
- Perfil `output:hdmi-stereo` disponible.
- Jack de auriculares combo 3.5 mm; perfil
  `output:analog-stereo+input:analog-stereo`.

`audio-watch.sh` aplica la prioridad auriculares > HDMI > altavoces
detectando perfiles/puertos con `pactl`. Respeta sinks/sources USB/Bluetooth.
No hardcodea tarjeta ni monitor.

El codec es **Realtek ALC255**. En el FX504GE el micrófono del jack combo no
aparece por defecto; el instalador detecta DMI + códec y ofrece el fixup
`alc255-asus` (`/etc/modprobe.d/alsa-fx504.conf`). En otros PCs no se aplica.
Requiere reinicio y es reversible.

Dunst reproduce `message-new-instant.oga` en cada notificación con `paplay`
(fallback `pw-play`). La aceleración VA-API/VDPAU depende de la GPU y del
firmware. Comprobar con `vainfo`, `vdpauinfo` y `desktop-doctor`.

## Cámara

Se instala `v4l-utils` y `libcamera-tools` si está disponible. En el host no
hay cámara detectada. La prueba real:

```sh
desktop-doctor --camera
```

Intenta capturar un frame con FFmpeg desde cada `/dev/video*`. Si el usuario
acaba de entrar al grupo `video`, debe cerrar sesión y volver a entrar.

## Batería, brillo y energía

- `brightnessctl` controla el backlight; el usuario debe estar en `video`.
- `upower`/`acpi` se instalan como soporte; la barra lee sysfs directamente.
- `desktop-safe suspend` delega en `systemctl suspend`; `xss-lock` bloquea
  antes de dormir.
- En equipos sin batería, el módulo `battery` no se añade a la barra.

## Hardware fuera de fase 1

Bluetooth, lector de huellas, cámaras IR/Windows Hello, teclados RGB,
impresoras y cualquier periférico que requiera software propietario quedan
fuera. No se instala CUDA ni se configura Bluetooth.
