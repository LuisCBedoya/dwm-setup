# Hardware de referencia y detección

Este documento describe el equipo usado como referencia y cómo el instalador
detecta cada pieza. **No sustituye una prueba real**: el host de referencia
tiene XFCE/LightDM y no debe ser modificado sin backup.

## Equipo de referencia

| Pieza | Valor observado |
|---|---|
| Equipo | Acer Aspire A315-57G (`Happy_IL`) |
| Sistema actual | Debian GNU/Linux 13.7 (trixie) |
| CPU | Intel Core i5-1035G1 @ 1.00 GHz (Ice Lake) |
| GPU integrada | Intel Iris Plus Graphics G1 (`8086:8a56`) |
| GPU discreta | NVIDIA GeForce MX330 (`10de:1d16`) |
| Pantalla | 1366×768 |
| Firmware | UEFI, Secure Boot deshabilitado |
| Cámara | UVC `VGA WebCam` en `/dev/video0` y `/dev/video1` |
| Backlight | `intel_backlight` |
| Red | `wlp4s0` WiFi + `enp3s0` Ethernet |
| Audio | ALSA/PCH Intel; comprobar SOF en el destino |
| Raíz | ext4 |

Notas:

- El host actual no expone una batería en `/sys/class/power_supply`
  (solo `ACAD`). El instalador trata la batería como opcional y `dwm-doctor`
  avisa si no existe.
- El nombre exacto de la cámara puede variar entre revisiones del mismo
  modelo. La detección real se hace por `/sys/class/video4linux`.
- El resumen de conversaciones anteriores mencionaba “Chicony UVC”; el host
  actual reporta `VGA WebCam`. No confiar en el nombre comercial: usar
  `v4l2-ctl --list-devices` en el equipo destino.

## Matriz de detección

| Componente | Cómo se detecta | Qué instala | Prueba |
|---|---|---|---|
| Debian/versión | `/etc/os-release` | — | aborta si no es Debian 13 |
| Arquitectura | `uname -m` | — | aborta si no es x86_64 |
| VM | `systemd-detect-virt` / `/sys/hypervisor` | — | NVIDIA se omite en VM salvo `--nvidia` |
| CPU | `LC_ALL=C lscpu` | microcódigo Intel/AMD | `lscpu` |
| GPU | `LC_ALL=C lspci -nn` | Intel/NVIDIA/AMD según detección | `vainfo`, `nvidia-smi`, `dwm-doctor` |
| Secure Boot | `mokutil` o efivar `SecureBoot-*` | — | bloquea NVIDIA automático |
| Resolución | `/sys/class/drm/card*-*/modes` o `xrandr` | se registra en `environment` | `xrandr` |
| Cámara | `/sys/class/video4linux/video*` | `v4l-utils`; `libcamera-tools` opcional | `dwm-doctor --camera` |
| Batería | `/sys/class/power_supply/BAT*` | `upower`, `acpi` | barra/eww/dwm-doctor |
| Backlight | `/sys/class/backlight/*` | `brightnessctl` | `brightnessctl info` |
| WiFi | `lspci` / `/sys/class/net/*/wireless` | `network-manager` | `nmcli` |
| Audio | `/proc/asound/cards` | PipeWire, WirePlumber, ALSA, códecs | `pactl`, `wpctl`, `aplay -l` |
| Raíz | `findmnt -n -o FSTYPE /` | — | se registra |
| USB | `udisks2` + `udiskie` | `udisks2`, `udiskie`, `exfatprogs`, `ntfs-3g`, `dosfstools` | montar USB y mirar notificación |

## Cámara

La cámara del equipo es UVC; el kernel carga `uvcvideo`. El instalador:

- detecta `/dev/video0`, `/dev/video1`, etc. y sus nombres en sysfs;
- instala `v4l-utils`;
- intenta `libcamera-tools` como opcional;
- añade el usuario a `video`.

La prueba real no se hace durante la instalación porque requiere sesión y
puede necesitar luz. Después de entrar a dwm:

```sh
v4l2-ctl --list-devices
dwm-doctor --camera
```

`dwm-doctor --camera` intenta capturar un frame con FFmpeg desde cada
`/dev/video*`, primero con el formato por defecto y luego con 640×480. Si
falla:

1. Comprobar que el usuario está en `video` y que cerró sesión después de
   `usermod`.
2. Comprobar que la cámara no está ocupada por otro proceso.
3. Probar `ffmpeg -f v4l2 -i /dev/video0 -frames:v 1 /tmp/cam.jpg`.
4. Revisar `dmesg | grep -i uvc` y `lsusb`.

En una VM hace falta pass-through USB de la cámara; si no, la prueba se
omitirá o fallará y no debe considerarse un fallo del escritorio.

## Audio y códecs

El objetivo es PipeWire, no PulseAudio:

```sh
pactl info          # debe mostrar PipeWire
wpctl status
aplay -l
pavucontrol
```

Se instancia `pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`,
`alsa-utils`, `pavucontrol`, FFmpeg, `libavcodec-extra`, GStreamer
base/good/bad/ugly/libav/vaapi/tools y `ffmpegthumbnailer`. No se instala el
paquete `pipewire-audio` para evitar arrastrar plugins Bluetooth.

Para el hardware Intel:

- `firmware-sof-signed` es importante para algunos códecs SOF.
- `firmware-intel-graphics` cubre firmware de la iGPU.
- En el equipo de referencia, verificar que el códec aparezca en
  `/proc/asound/cards`.
- Si no hay sonido, revisar `dmesg | grep -i sof` y `wpctl status`.

Códecs de prueba:

```sh
ffmpeg -hide_banner -decoders | grep -E 'h264|hevc|vp9|av1|aac|mp3'
gst-inspect-1.0 avdec_h264
vainfo
```

`VA-API`/`VDPAU` solo se pueden validar dentro de una sesión gráfica y con
drivers/firmware cargados. `dwm-doctor` avisa si `vainfo` no inicializa.

## GPU y NVIDIA

El equipo es híbrido Intel + NVIDIA MX330. El instalador:

- detecta ambas GPU;
- instala `intel-media-va-driver-non-free`, `i965-va-driver` e
  `intel-gpu-tools` para Intel (si están disponibles);
- instala `nvidia-driver`, `nvidia-settings`, `nvidia-vaapi-driver` y
  `linux-headers-amd64` para NVIDIA solo si se cumple la política;
- no instala CUDA;
- no escribe un `xorg.conf` de PRIME.

Política NVIDIA:

| Situación | Acción por defecto |
|---|---|
| `--no-nvidia` | no instala driver |
| Secure Boot activo | omite y avisa (usar `--nvidia` tras MOK) |
| VM | omite y avisa (usar `--nvidia` para forzar) |
| NVIDIA + Secure Boot off | instala driver |
| `--nvidia` | fuerza la instalación |

Si Secure Boot está desactivado, se usa `--nvidia` si hay GPU NVIDIA. Con
Secure Boot `enabled`/indeterminado, el driver propietario se omite por defecto,
excepto con `--nvidia`.

La iGPU Intel se usa para el escritorio. Para probar una app con la NVIDIA:

```sh
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep OpenGL
nvidia-smi
```

No se ha validado todavía en el hardware. Si DKMS falla, el grupo GPU es
opcional y el instalador continúa con Intel/mesa; revisar el log y
`dkms status`.

## eww

Eww se compila a partir de la fuente v0.6.0. Debian 13 trae Rust 1.85, y el
recorte fija `time 0.3.34`, que falla a partir de Rust 1.80. Antes de
compilar, el instalador actualiza `time 0.3.34` a `0.3.35` en una copia del
lockfile; Cargo actualiza también sus dependencias (`time-macros`) de forma
transitiva, y después compila con `--locked`.

Las dependencias nativas incluyen `libdbusmenu-glib-dev` y
`libdbusmenu-gtk3-dev`. Si falta un grupo obligatorio, la instalación se
detiene con el error y el log visibles.

## Almacenamiento extraíble

Se instalan `udisks2`, `udiskie`, `gvfs`, `gvfs-backends`, `exfatprogs`,
`ntfs-3g`, `dosfstools` y `e2fsprogs`.

`run.sh` inicia `udiskie --automount --notify`; no se pasa
`--file-manager`, por lo que no se abre ninguna aplicación. `pcmanfm` se abre
con Mod+E o rofi.

Pruebas:

```sh
udisksctl status
lsblk -f
# conectar USB exFAT/NTFS/FAT
mount | grep /run/media
```

Comprobar que aparece una notificación de dunst y que no se abre ninguna
ventana. Los discos se montan bajo `/run/media/$USER/`.

## Resolución y teclado

La resolución detectada se guarda en `~/.config/dwm/environment` como
`DWM_RESOLUTION`; no se fuerza con `xrandr` para evitar modos no soportados.
El teclado usa `DWM_KEYMAP` (`latam` por defecto) y `setxkbmap`.

Si la resolución o el teclado no son correctos, editar
`~/.config/dwm/environment` (se hace backup al reinstalar) y reiniciar la
sesión.

## Batería, brillo y energía

- `brightnessctl` controla el backlight; el usuario debe estar en `video`.
- `upower`/`acpi` se instalan como soporte; la barra lee sysfs directamente.
- `dwm-safe suspend` delega en `systemctl suspend`; `xss-lock` bloquea antes
  de dormir.
- En equipos sin batería, la barra muestra `AC` y `dwm-doctor` avisa.

## Hardware que no se toca en fase 1

Bluetooth, lector de huellas, cámaras IR/Windows Hello, teclados RGB,
impresoras y cualquier periférico que requiera software propietario quedan
fuera. No se instala `bluez`/`blueman` ni CUDA.
