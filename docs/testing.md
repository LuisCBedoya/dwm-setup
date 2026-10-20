# Plan de pruebas — fase 1

Objetivo: validar el instalador en **Debian 13 minimal** antes de tocar el
equipo principal. El host actual (`/home/luc`, XFCE/LightDM) solo se usa como
referencia.

> Estado real: sigue pendiente la instalación en VM/hardware. Los checks
> estáticos listados en `PROGRESS.md` pasan y son solo cobertura local.

## 0. Checks estáticos ya ejecutados localmente

Fecha: 2026-10-20. Estos checks son solo del código/configuración en local; no
sustituyen una instalación real.

- `bash -n` / `sh -n` en `install.sh`, `lib/*.sh` y scripts de sesión.
- Dry-run real con `--yes --user "$USER"` y comprobación de residuos en un home
  de prueba: sin rutas de host ni placeholders sin renderizar.
- Opciones inválidas (`--font-size`, `--keymap`, `--resolution`, `--home`,
  flags vacías y desconocidas) detienen antes de `sudo`.
- chadwm `config.h.in`: verificado con headers extraídos de Debian.
- eww v0.6.0: `cargo check --locked --no-default-features --features x11`
  con Debian Rust 1.85 tras fijar `time 0.3.35`.
- dunst 1.12.2, picom 12.5, rofi 1.7.5 y kitty: parseo/init check local.

## 1. Preparar la VM

Recomendado:

| Recurso | Valor |
|---|---|
| ISO | Debian 13 (trixie) netinst, x86_64 |
| Firmware | UEFI (y una segunda pasada BIOS/legacy si se puede) |
| CPU | 2 vCPU |
| RAM | 4 GB |
| Disco | 20 GB |
| Red | NAT o bridge con salida a Internet |
| Snapshot | “Debian 13 minimal limpio” antes de instalar |

Durante la instalación de Debian:

- desmarcar todo entorno de escritorio;
- no instalar XFCE/GNOME;
- crear usuario normal con sudo;
- instalar SSH si se va a trabajar desde el host;
- dejar `non-free-firmware` si el instalador lo permite, para probar firmware;
- no configurar Secure Boot para la primera pasada.

Comprobar la base:

```sh
cat /etc/os-release       # ID=debian, VERSION_ID=13
uname -m                  # x86_64
systemctl --version
ip a
sudo -v
```

Tomar snapshot. Copiar el repositorio a la VM (scp, rsync o git) y entrar:

```sh
cd ~/dwm-setup
chmod +x install.sh bin/dwm-safe bin/dwm-doctor
./install.sh --dry-run --user "$USER" --no-nvidia
```

El dry-run no debe crear archivos ni ejecutar `apt`, `usermod`, `systemctl`,
descargas ni compilaciones. Revisar:

- usuario y home correctos;
- GPU/CPU/cámara detectadas;
- grupos de paquetes;
- política NVIDIA;
- rutas de backup y log.

## 2. Instalación real

Con snapshot limpio:

```sh
sudo ./install.sh --user "$USER" --yes
```

Si se está probando NVIDIA en la VM, no usar `--nvidia` (la política la omite
en VM). Para una pasada forzada, solo en hardware real:

```sh
sudo ./install.sh --user "$USER" --yes --nvidia
```

Criterios de éxito de esta etapa:

- termina sin errores;
- eww compila tras fijar `time 0.3.35` y responde a `--version`;
- `dwm`, `eww`, `picom`, `dunst`, `rofi`, `kitty`, `pcmanfm`, `i3lock`,
  `xss-lock`, `brightnessctl`, `v4l2-ctl`, `ffmpeg` y `pactl` existen;
- `/usr/share/xsessions/dwm.desktop` existe;
- `/etc/ly/config.lua` existe;
- `ly@tty2.service` está `enabled`;
- `udisks2` está `enabled`;
- el log no tiene errores ignorados;
- los backups se crearon si había archivos previos.

Comandos de comprobación:

```sh
command -v dwm eww picom dunst rofi kitty pcmanfm i3lock xss-lock
command -v brightnessctl v4l2-ctl ffmpeg pactl
systemctl is-enabled ly@tty2.service
systemctl is-enabled udisks2.service
test -f /etc/ly/config.lua && grep -E 'xinitrc|shell|xsessions' /etc/ly/config.lua
```

## 3. Primer reinicio y Ly

```sh
sudo reboot
```

- Ly debe aparecer en `tty2` (o en el tty configurado).
- Debe mostrar usuario/contraseña y la sesión `dwm` (no shell ni xinitrc).
- Entrar con el usuario normal.

Si Ly no aparece:

1. `Ctrl+Alt+F3` para una TTY.
2. `systemctl status ly@tty2 -l`.
3. `journalctl -u ly@tty2 -b`.
4. `startx` como fallback.
5. Si `startx` funciona, el problema es Ly; si no, es Xorg/dwm.

## 4. Sesión dwm

Dentro de la sesión:

```sh
pgrep -a dwm
pgrep -a eww
pgrep -a picom
pgrep -a dunst
pgrep -a xss-lock
pgrep -a udiskie
dwm-doctor
```

Comprobar visualmente:

- [ ] barra superior con CPU/RAM/disco/volumen/WiFi/batería/reloj;
- [ ] `Mod+Return` abre kitty;
- [ ] `Mod+E` abre pcmanfm;
- [ ] `Mod+Shift+D` abre rofi;
- [ ] `Mod+Shift+S` abre flameshot y guarda una captura;
- [ ] `Mod+grave` abre/cierra dashboard eww;
- [ ] `Mod+Escape` abre menú de energía;
- [ ] `Mod+Shift+L` bloquea y la contraseña desbloquea;
- [ ] picom aplica sombras/blur sin artefactos;
- [ ] dunst muestra una notificación de prueba (`notify-send hola`).

## 5. Audio y vídeo

```sh
pactl info
wpctl status
aplay -l
pavucontrol
ffmpeg -hide_banner -decoders | grep -E 'h264|hevc|vp9|av1|aac|mp3'
gst-inspect-1.0 avdec_h264
vainfo
```

- [ ] PipeWire es el servidor;
- [ ] se oye audio por los altavoces/auriculares;
- [ ] `pavucontrol` muestra dispositivos y streams;
- [ ] un vídeo H.264/HEVC se reproduce sin errores;
- [ ] `vainfo` inicializa si la GPU lo soporta;
- [ ] no hay errores de SOF en `dmesg | grep -i sof`.

Si no hay audio en la VM, comprobar el dispositivo de audio virtual y no
marcarlo como fallo de PipeWire.

## 6. Cámara

En hardware con cámara o VM con USB pass-through:

```sh
v4l2-ctl --list-devices
dwm-doctor --camera
```

- [ ] detecta `/dev/video*`;
- [ ] captura un frame real;
- [ ] el usuario está en `video` (y cerró sesión tras `usermod`);
- [ ] no hay conflictos con otro proceso.

Sin cámara, `dwm-doctor` debe avisar, no romper el escritorio.

## 7. Almacenamiento extraíble

Preparar USBs con:

- exFAT;
- NTFS;
- FAT32;
- ext4.

Conectar uno a uno:

- [ ] aparece notificación de dunst;
- [ ] se monta bajo `/run/media/$USER/...`;
- [ ] **no** se abre pcmanfm ni otra app;
- [ ] se puede abrir pcmanfm con Mod+E y navegar;
- [ ] `udisksctl status` y `lsblk -f` lo muestran;
- [ ] desmontar de forma segura funciona.

Comprobar herramientas:

```sh
command -v mkfs.exfat mount.ntfs-3g mkfs.fat e2fsck
```

## 8. Energía, bloqueo y suspensión

- [ ] `dwm-safe lock` bloquea;
- [ ] `dwm-safe suspend` suspende y al volver pide contraseña;
- [ ] `dwm-safe reboot` y `dwm-safe poweroff` funcionan (probar con cuidado);
- [ ] `dwm-safe logout` vuelve a Ly;
- [ ] `xss-lock` bloquea por inactividad (bajar timeout temporalmente si hace
      falta).

## 9. NVIDIA / híbrido

Solo en hardware real, con snapshot y Secure Boot desactivado:

```sh
lspci -nn | grep -Ei 'vga|3d|display'
nvidia-smi
glxinfo | grep -E 'OpenGL renderer|OpenGL version'
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep OpenGL
```

- [ ] el escritorio arranca con Intel;
- [ ] `nvidia-smi` responde;
- [ ] no hay pantalla negra ni conflicto de drivers;
- [ ] se documenta si hace falta MOK con Secure Boot.

Si falla, restaurar snapshot y volver a ejecutar con `--no-nvidia`.

## 10. Idempotencia y recuperación

Con una instalación ya hecha:

```sh
sudo ./install.sh --user "$USER" --yes
sudo ./install.sh --user "$USER" --yes --rebuild
```

- [ ] la segunda ejecución no rompe configs ni servicios;
- [ ] los backups nuevos existen;
- [ ] `--rebuild` recompila dwm/eww/Ly;
- [ ] `--dry-run` sigue sin modificar;
- [ ] `startx` sigue funcionando como fallback;
- [ ] restaurar un backup de `~/.config/dwm` y `/etc/ly` está documentado.

## 11. Criterios de aceptación de fase 1

La fase 1 se considera validada cuando:

1. La instalación termina sin errores en Debian 13 minimal.
2. Ly arranca y permite entrar a dwm.
3. dwm, barra, eww, picom, dunst y rofi funcionan.
4. PipeWire reproduce audio y los códecs principales están disponibles.
5. La cámara captura un frame real o se documenta la ausencia de hardware.
6. Un USB se monta y notifica sin abrir aplicación.
7. El bloqueo y la suspensión funcionan.
8. `dwm-doctor` no reporta fallos críticos.
9. La segunda ejecución es idempotente.
10. `PROGRESS.md` y este archivo reflejan fecha, hardware y resultados.

## 12. Registro de resultados

Añadir una tabla por ejecución:

| Fecha | Entorno | Opciones | Resultado | Notas |
|---|---|---|---|---|
| pendiente | VM Debian 13 minimal | `--no-nvidia` | pendiente | primera prueba |

## 13. Rollback

- Restaurar snapshot de la VM (lo más limpio).
- En hardware:
  - backups en `/var/backups/dwm-setup/<timestamp>/`;
  - backups de usuario en `~/.config-backup/dwm-setup/<timestamp>/`;
  - deshabilitar `ly@tty2` y habilitar el display manager anterior;
  - restaurar `/etc/ly`, `/usr/share/xsessions/dwm.desktop`,
    `/usr/local/bin/dwm*` desde el backup.
- No borrar `/var/cache/dwm-setup` hasta confirmar que no se necesita el
  binario compilado.

## 14. Qué no prueba esta fase

- IDE/Neovim, navegadores, correo/Teams, música.
- Bluetooth.
- Impresoras, huellas, cámaras IR.
- CUDA.
- Multi-monitor avanzado y HiDPI (se puede probar después).
- Seguridad de producción más allá de `sudo`/backups/permisos básicos.
