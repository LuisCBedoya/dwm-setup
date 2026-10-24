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
- Dry-run real con `./install.sh --dry-run` y comprobación de residuos en un
  home de prueba: sin rutas de host ni placeholders sin renderizar.
- Opciones inválidas (`--font-size`, `--keymap`, `--resolution`, `--home`,
  flags vacías y desconocidas) detienen antes de `sudo`.
- chadwm `config.h.in`: verificado con headers extraídos de Debian.
- eww v0.6.0: `cargo check --locked --no-default-features --features x11`
  con Debian Rust 1.85 tras fijar `time 0.3.35`.
- dunst 1.12.2, picom 12.5, rofi 1.7.5 y kitty: parseo/init check local.
- Ly: `libaudit-dev` añadido a `BUILD_PKGS` porque `pam.pc` exige `audit.pc`;
  la cadena `pam.pc -> audit.pc -> libcap-ng.pc` queda resuelta por
  `libaudit-dev` y su dependencia `libcap-ng-dev`. `pkg-config --exists pam
  audit` debe pasar antes de compilar.
- Xorg sin root: el instalador crea `~/.local/share/xorg` con modo `0700`;
  `dwm-doctor` y la verificación final comprueban que sea escribible.
- Preflight APT y auto-add probados con fixtures temporales: detección de
  componentes, menú, backup, edición limitada a Debian 13, `main` ausente,
  `--dry-run`/`--yes` sin cambios e idempotencia.

## 0b. Validación parcial en host real: polybar (2026-10-21)

> Esta sección conserva la medición de la iteración ADR-025 (13 módulos, logo
> anterior). La medición final del logo, la fuente y los puntos está en **0c**;
> no usar las medidas de 0b como estado final.

Sesión bspwm ya instalada en Debian 13, 1920x1080, Xorg, polybar 3.7.2 y
JetBrainsMono Nerd Font 3.5.1. No sustituye la instalación limpia en VM.

Backups de los configs reemplazados:
`~/.config-backup/dwm-setup/20261021-172323/` (primera iteración) y
`~/.config-backup/dwm-setup/20261021-182732/` (ajuste final de espaciado).

Comprobaciones:

```sh
# los templates no deben llevar escapes \uXXXX (polybar los muestra literales)
grep -RIn '\u[0-9a-fA-F]\{4\}' templates/polybar && echo "HAY ESCAPES" || echo "OK"

# cada glifo debe existir en la fuente instalada (devuelve la familia si existe)
for cp in F035B F0200 F03D7 F057E F075F F091F F0920 F0921 F0922 F05A9; do
  fc-list ":charset=$cp" family | grep -qi jetbrains || echo "FALTA U+$cp"
done

# arranque limpio de la iteración previa: 13 módulos y sin errores
polybar -r main -c ~/.config/polybar/config.ini
```

Resultados:

- 13 módulos cargados sin errores (la barra final añade `dots`: 14).
- Iconos visibles: logo, updates, temp, memory, cpu, xkeyboard (`latam`), eth
  (`connected`), battery (`100%`), pipewire, date; polypomo en `25:00`.
- `BAT1`/`ACAD` detectados; `wlo1` (DOWN) detectada igualmente.
- Espaciado de la barra ajustado a las unidades de polybar 3.7
  (`padding-left/right = 1`, `format-padding = 2`, `label-focused-padding = 1`).

### Ajuste de espaciado y claridad (2026-10-21)

Valores de esta iteración:

```sh
grep -nE 'foreground =|module-margin|font-0' ~/.config/polybar/config.ini
grep -nE 'format|padding' ~/.config/polybar/modules/logo.ini
grep -n 'font' ~/.config/polybar/modules/bspwm.ini
```

- `foreground = #E6EDF3`, `font-0` SemiBold 10, `module-margin = 0`.
- Logo `format` con un espacio final, sin `format-padding`; workspaces con
  `font-0`.
- Medición sobre `actual_03.png` (1920x26):
  - logo 8-19; caja enfocada 26-49 (24×26); primer dígito a 15 px del logo
    (7 px hasta la caja); workspaces 2-5 en 59/83/107/131.
  - gaps de módulos 33-35 px; bloque derecho desde ~1092 px.
- Referencia `yo.png` (medición final, ADR-026): logo 9-26; primer dígito 39;
  caja 76-97 (22×19); puntos 1903-1912.
- La caja de 19 px no se reproduce: en polybar 3.7.2 el fondo del label ocupa
  toda la altura de la barra, tanto con JBM NF size 10/11 como con Noto Sans
  CJK JP size 11. `format-padding-right` tampoco tiene efecto.
- Captura: `actual_03.png`.

Pendiente: reinstalar desde cero con `sudo ./install.sh`, repetir en VM y
probar los atajos de sxhkd de extremo a extremo. La comparación de espaciado
con `yo.png` ya se hizo (ADR-025); queda como diferencia conocida la altura de
la caja enfocada (26 px vs 19 px).

## 0c. Logo propio y tres puntos (2026-10-21)

Sustituye la medición de 0b para el extremo izquierdo y la fecha. Se validó en
la barra viva parcial (no es una instalación desde cero): Debian 13, Xorg
1920x1080, bspwm + polybar 3.7.2.

Implementación final:

- `assets/desktop-logo.ttf`, familia **DesktopLogo**, glifo `U+E000` generado
  desde el recorte `18x10+9+8` de `yo.png`; `pixelsize=10`, offset `2` y
  espacio de 300 unidades (3 px).
- `font-0` es DesktopLogo; `font-1` JBM SemiBold 10; `font-2` JBM Bold 10;
  `font-3/4` JBM 11; `font-5` Noto Color Emoji. El logo hereda `font-0`; todos
  los módulos de texto usan `font-1`; `updates` y `polypomo` añaden `%{T1}` y
  `format-font = 1`.
- Logo: `format = "%{O4}<glifo U+E000> %{F-}"`, sin `format-font`.
- Fecha: `label-padding = 1`, `label-font = 1`. Módulo `dots`: `U+22EF`,
  `format-font = 1`, `format-padding = 0`, al final de `modules-right`.
- Barra: `padding-right = 2`. La fuente se instala a nivel sistema desde
  `lib/polybar.sh`; `lib/verify.sh` comprueba el asset, `dots.ini.in` y
  `fc-list :charset=e000`.

Comprobaciones:

```sh
# los templates no deben llevar escapes \uXXXX (polybar los muestra literales)
grep -RIn '\u[0-9a-fA-F]\{4\}' templates/polybar && echo "HAY ESCAPES" || echo "OK"

# fuente del logo y glifo de los puntos
fc-list :charset=e000 family
fc-list :charset=22ef family | grep -qi jetbrains && echo "OK" || echo "FALTA"

# referencias de fuente y formato
grep -nE 'font-[0-9]|padding-right' ~/.config/polybar/config.ini
grep -nE 'format|font|padding' templates/polybar/modules/logo.ini.in \
  templates/polybar/modules/date.ini.in templates/polybar/modules/dots.ini.in

# arranque limpio: 14 módulos y sin errores
polybar -r main -c ~/.config/polybar/config.ini
```

Resultados:

- 14 módulos cargados, una sola instancia de polybar y sin errores de parseo.
- Logo en `x=9..26`, `y=8..17` (18×10); caja enfocada `x=33..48` (16×26);
  primer dígito centrado en `x=39`. La referencia `yo.png` tiene el logo en
  `x=9..26` y el primer dígito en `x=39`; su caja enfocada es `x=76..97`
  (22×19).
- Fecha `07:59 PM` con tres puntos en `x=1904..1911`; borde derecho de la
  barra 1911. La referencia tiene los puntos en `x=1903..1912` y borde 1912.
- `fc-list :charset=e000` encuentra la fuente de usuario de la barra viva. La
  ruta de sistema `/usr/local/share/fonts/dwm-setup/desktop-logo.ttf` solo se
  valida tras ejecutar el instalador real.
- **Diferencia conocida:** la caja enfocada mide 16×26 frente a 22×19 de
  `yo.png`. La altura es una limitación de polybar 3.7.2; el ancho se mantiene
  para conservar el primer dígito en `x=39`.
- **Trampa de mantenimiento:** `format-font`/`%{T4}` con la fuente privada en
  una posición no primaria renderizaba tofu. La fuente del logo debe ser
  `font-0`; cualquier módulo nuevo de texto debe declarar `font-1`.
- Captura final: `actual_04.png`.

Pendiente: instalación real con `sudo ./install.sh`, comprobar la fuente del
sistema con `fc-list :charset=e000` y repetir la comparación en VM.

## 0d. Restauración del espaciado entre módulos y workspaces (2026-10-21)

Corrige la regresión de 0c: al reindexar las fuentes, los módulos de la
derecha pasaron de `format-padding`/`label-padding = 6` a `2`, y bspwm de
`label-focused-padding = 2`/JBM 11 a `1`/JBM SemiBold 10. La barra quedó con
gaps visibles de 24–26 px y workspaces cada 16 px, frente a los gaps de
33–35 px y workspaces cada 24 px de `actual_03`.

Valores finales (template y barra viva):

- `config.ini`: `padding-left = 1`, `padding-right = 1`,
  `module-margin-left/right = 1`.
- Módulos de la derecha: `format-padding`/`label-padding = 3`; `date`
  `label-padding = 3`; `dots` `format-padding = 0`.
- bspwm: `label-*-padding = 2`, `label-*-font = 3` (JBM 11).
- logo: `format = "%{O1}<U+E000>%{O-4}%{F-}"`. El `O-4` posterior al glifo
  compensa el `module-margin` global para que bspwm empiece en `x=30` sin
  mover el glifo; el logo queda en `x=6..23`, 3 px a la izquierda de `yo.png`.

Medición sobre `actual_10.png` (1920×26):

- logo `x=6..23` (18×10); caja enfocada `x=30..53` (24×26); primer dígito
  `x=39`; workspaces 2–5 en `62/86/110/134` (24 px entre cada uno).
- bloque derecho desde ~`1124`; gaps entre módulos `32–34`; fecha→puntos
  `21`; puntos `x=1908..1915`.
- Referencia `yo.png`: logo `x=9..26`, primer dígito `x=39`, workspaces 2–4
  en `61`, caja de 3 en `76..97`, workspace 4 en `106`; gaps `26–30`; puntos
  `x=1903..1912`.
- `actual_03` (estado anterior aceptado): logo `8..19`; caja `26..49`;
  workspaces `59/83/107/131`; gaps `33–35`.

La separación entre workspaces (24 px) y entre módulos (32–34 px) coincide
con `actual_03`; el logo queda 3 px a la izquierda de `yo.png` y el bloque
derecho 21 px a la derecha (porque la barra actual muestra menos módulos).
La caja enfocada mide 24×26; los 19 px de altura de `yo.png` siguen siendo
una limitación de polybar 3.7.2.

Comprobaciones:

```sh
grep -nE 'padding-left|padding-right|module-margin' ~/.config/polybar/config.ini
grep -RInE 'format-padding|format-.*-padding|label-.*-padding|label-padding' \
  ~/.config/polybar/modules | sort
grep -n 'format =' ~/.config/polybar/modules/logo.ini

# captura de la ventana de polybar (no de la pantalla completa)
import -window "$(xwininfo -root -tree | awk '/polybar-main_/ {print $1; exit}')" actual_10.png
```

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
- habilitar `non-free` y `contrib` si se va a probar NVIDIA (`contrib` solo
  aporta `nvidia-settings`);
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
./install.sh --dry-run
```

El dry-run no debe crear archivos ni ejecutar `apt`, `usermod`, `systemctl`,
descargas ni compilaciones. Revisar:

- usuario y home correctos;
- GPU/CPU/cámara detectadas;
- componentes APT detectados y avisos del preflight;
- grupos de paquetes;
- política NVIDIA;
- rutas de backup y log.

Prueba específica del preflight: en una copia/snapshot, deshabilita temporalmente
`contrib` (con GPU NVIDIA o `--nvidia`), `non-free` o `non-free-firmware` y
repite el dry-run. Debe avisar
antes de la sección de paquetes, explicar qué se omite y no debe preguntar ni
modificar nada. En una instalación interactiva debe aparecer el menú:

```text
1) Añadirlos automáticamente (backup + apt update + comprobar)
2) Continuar sin ellos
3) Cancelar
```

Comprobar también:

- opción 1: crea backup en `/var/backups/dwm-setup/<timestamp>/`, modifica solo
  entradas oficiales de Debian 13 y ejecuta `apt update` antes de recheck;
- opción 2: continúa y avisa de los paquetes que se omitirán;
- opción 3: sale sin instalar;
- `--dry-run`: no muestra menú ni modifica fuentes;
- `--yes`: no muestra menú y no modifica fuentes;
- si falta `main`, aborta sin ofrecer auto-add.

Para probar la edición de fuentes sin tocar `/etc/apt`, usar fixtures temporales
`.list` y `.sources` y verificar que no se tocan repositorios de terceros ni
entradas con `Enabled: no`. El auto-add solo edita hosts `*.debian.org`; con un
mirror propio hay que editar las fuentes a mano.

## 2. Instalación real

Con snapshot limpio:

```sh
./install.sh
```

Para una ejecución no interactiva (por ejemplo, automatización):

```sh
./install.sh --yes
```

Si se está probando NVIDIA en la VM, la política automática omite el driver.
Para una pasada forzada, solo en hardware real y con Secure Boot/MOK resuelto:

```sh
./install.sh --nvidia
```

Para instalar también el CUDA toolkit (nvcc, librerías desarrollo):

```sh
./install.sh --nvidia --cuda
```

En modo interactivo, el instalador pregunta si se quiere CUDA.

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
- `pkg-config --exists pam audit` pasa antes de compilar Ly;
- los backups se crearon si había archivos previos.

Comandos de comprobación:

```sh
pkg-config --exists pam audit
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
4. Comprueba `ls -ld ~/.local/share/xorg`; debe existir, ser del usuario y
   tener modo `0700`. Si falta:
   `sudo install -d -m 0700 -o "$USER" -g "$(id -gn)" ~/.local/share/xorg`.
5. `startx` como fallback.
6. Si `startx` funciona pero Ly vuelve al login con `Cannot open log file`,
   el problema era el directorio del log de Xorg. Si `startx` tampoco
   funciona, es Xorg/dwm.

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

Si falla, restaurar snapshot y volver a ejecutar con la política automática
(o con `--no-nvidia` solo para automatización).

## 10. Idempotencia y recuperación

Con una instalación ya hecha:

```sh
./install.sh --yes
./install.sh --yes --rebuild
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
| pendiente | VM Debian 13 minimal | `./install.sh` | pendiente | primera prueba |

## 13. Rollback

- Restaurar snapshot de la VM (lo más limpio).
- En hardware:
  - backups en `/var/backups/dwm-setup/<timestamp>/` (incluye fuentes APT si
    se añadieron componentes);
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
