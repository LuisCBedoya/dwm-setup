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
# install_bspwm/install_sxhkd/install_polybar/install_dunst/
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
  ~/.config/polybar ~/.config/dunst ~/.config/rofi \
  ~/.config/kitty ~/.xinitrc

find ~/.config/bspwm ~/.config/sxhkd ~/.config/polybar \
  ~/.config/dunst ~/.config/rofi ~/.config/kitty -not -user "$USER" -print

grep -nE 'font-[0-9]|modules-(left|right)|include-directory' \
  ~/.config/polybar/config.ini

grep -n 'icon-theme\|icon_theme' ~/.config/rofi/powermenu.rasi ~/.config/dunst/dunstrc
```

Resultado esperado: sin placeholders, sin ficheros de root, 12 módulos en A
y 14 en B, sin picom, iconos Papirus.

## 4. Validación en vivo (2026-10-24)

Host: Debian 13, kernel 6.12, Xorg 1920x1080, Intel UHD 630 + NVIDIA GTX
1050 Ti Mobile, PipeWire 1.4.2.

Comprobado:

- `bspwm 0.9.10`, `sxhkd 0.6.2`, `polybar 3.7.2` (A 12 / B 14 módulos),
  `dunst 1.12.2`, `lxpolkit`, `udiskie -N -a`, `xss-lock`.
- Barra: logo StumbleUpon, workspaces 1-7, `25:00`, temperatura, RAM,
  CPU, red `󰈀 connected`, servicios, volumen, batería `BAT1`, fecha;
  updates (calavera + número) al inicio de la derecha.
- Barra final: 5 workspaces, caja blanca en el enfocado, logo StumbleUpon
  en `font-0`, `updates` al inicio de la derecha con calavera + número,
  sin `[T]/[M]/[C]`,
  red unificada, sin `dots` y sin `xkeyboard` ni `wlan`/`eth` separados
  en la variante A. `font-1` 10 y `font-3` 13. Polybar carga 12 módulos
  sin errores.
- Red: con WiFi down y Ethernet up solo `󰈀 connected`; `NETWORK_FAKE=wifi`
  muestra solo `󰖩 connected`; `NETWORK_FAKE=none` muestra `󰖩 NoC`.
  Captura `bar-network-final.png`.
- Separación final: `module-margin-left/right = 0`; `updates`/`polypomo`
  con padding 1/1; `cpu` con `%{O8}` a la derecha; volumen y batería con
  padding 1. Con `UPDATES_FAKE_FILE=0` el módulo `updates` desaparece y no
  muestra `# 0`; capturas `bar-spacing-final.png` y `bar-user-final.png`.
- Variante B "referencia": 14 módulos, 5 círculos a la izquierda y a la
  derecha `izq`, servicios, pomodoro, temperatura, RAM, CPU, red, volumen y
  batería. Barra de 30 px con fondo sólido `#262626`, fuentes 10/13. Cambia con
  `~/.config/polybar/polybar-variant referencia`;
  captura `bar-variant-b.png`. Polybar carga 14 módulos sin errores.
- `polybar-variant actual` vuelve a la variante A y conserva su estilo.
- Sin picom, B carga con `pseudo-transparency = true`; `pgrep -x picom`
  no devuelve proceso y el centro de B muestra el wallpaper.
- Al poner la barra abajo, `top_padding` pasa a 0 y `bottom_padding` a 26;
  las ventanas no tapan la barra. Al volver arriba se invierte.
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
- `polybar-variant cycle` probado: A arriba → A abajo → B arriba →
  B abajo; sxhkd recargado con el binding `Super+Alt+p`.

### Neovim desde ranger (2026-10-25)

- `mime ^text` y las extensiones de código/Markdown se abren con `nvim`.
- `rifle -l archivo.md` muestra `nvim -- "$@"`.
- El resto de formatos sigue con zathura, VLC o feh.

### VLC oscuro (2026-10-25)

- `grep -n '^qt-dark-palette=1$' ~/.config/vlc/vlcrc` debe devolver la clave.
- Al abrir `vlc`, la ventana, menús y lista de reproducción salen oscuros.
- VLC 3.0.24 en Debian 13 admite `--qt-dark-palette`.
- No requiere `qt5-gtk-platformtheme`.

### Borde enfocado gris (2026-10-25)

- `bspc config focused_border_color` → `#d9d9d9`.
- `normal_border_color` → `#1a1a1a`; `active_border_color` → `#3a3a3a`.
- Visualmente el borde claro se distingue sobre ventanas `#262626` y fondo
  negro, sin el azul anterior.

### Gaps, barra de 30 y menús rofi (2026-10-25)

- `window_gap` baja de 10 a 4 px; `border_width` sigue en 2.
- `BAR_HEIGHT=30` se usa en polybar A/B, en `bspwmrc` y en `launch.sh`.
- `bspc config window_gap` → `4`; `bottom_padding` → `30`.
- El menú WiFi (`network-menu.sh`) abre con `rofi -dmenu`, no dmenu.
- `services.sh` también prefiere rofi; dmenu queda como respaldo.
- Capturas: `gaps-bar30.png`, `net-rofi2.png`.

### Ajustes manuales persistidos (2026-10-25)

- `diff` entre la config viva y la renderizada: sin diferencias en
  polybar, kitty, bspwm, sxhkd y rofi.
- Batería con `%{O5}` en ambos módulos.
- `~/.zshrc` usa `cypher` y el PATH de opencode con `$HOME`.

### Arranque de zsh (2026-10-25)

- `zsh -i -c exit` → 54-62 ms (antes ~119 ms).
- `zprof` muestra un solo `compinit` (el de Oh My Zsh).
- Las completions siguen funcionando; no se tocaron los `zstyle`.

### Arranque de kitty (2026-10-25)

- `busctl --user list` muestra `org.freedesktop.portal.Desktop` y el
  backend GTK activos.
- `systemctl --user is-active xdg-desktop-portal` → `active`.
- Portal Settings responde en ~7 ms.
- `kitty --help` → ~141 ms; apertura de ventana → ~250-296 ms
  (antes ~870 ms).
- `find /usr/lib/kitty -name '*.opt-2.pyc' | wc -l` → 170.

### Iconos de batería MDI (2026-10-25)

- La rampa usa 󰁺 󰁽 󰁿 󰂁 󰁹.
- Cargando muestra 󰂄; llena, 󰁹.
- Verificado en las variantes A y B con la batería al 95-96 %.
- Los glifos existen en JetBrainsMono Nerd Font (`font-1`/`font-3`).

### Siete escritorios (2026-10-25)

- `bspc query -D --names` → `1 2 3 4 5 6 7`.
- `Super+7` cambia al escritorio 7; `Super+Shift+7` mueve la ventana.
- La barra B muestra los 7 círculos centrados.
- `sxhkdrc` ya no contiene `{1-5}`.

### Kitty sin barra de pestañas (2026-10-25)

- `tab_bar_style hidden` en `kitty.conf`.
- Una kitty nueva no muestra la barra ni el título `zsh`.
- `Ctrl+Shift+T` sigue abriendo pestañas sin barra visible.
- `kitty` arranca sin avisos de configuración.

### Contador en monocle (2026-10-25)

- En tiled: `monocle-count.sh --check` → rc=1 y el módulo no se ve.
- En monocle con 1 ventana: `[1]`; con 2: `[2]`.
- Se actualiza en 1 s al abrir/cerrar ventanas.
- Visible en la barra A (izquierda) y B (centro).

### Wallpaper alternativo (2026-10-25)

- `wallpaper.sh primary` aplica Nothing2 y guarda `primary`.
- `wallpaper.sh toggle` aplica Nothing1 y guarda `alt`.
- `wallpaper.sh apply` respeta la última elección en el autostart.
- `Super+Alt+W` está en sxhkdrc y sxhkd se recargó con `-USR1`.
- Ambas imágenes instaladas en `~/.local/share/wallpapers/`.

### Borde 1, gap 0 y wallpaper (2026-10-25)

- `bspc config border_width` → `1`; `bspc config window_gap` → `0`.
- `assets/wallpaper.png` (2337x1080, PNG) instalado en
  `~/.local/share/wallpapers/wallpaper.png`.
- `xwallpaper --zoom` lo muestra correctamente en 1920x1080.
- `install.sh --dry-run` y `verify_install` encuentran el nuevo asset.

### Dunst según posición de polybar (2026-10-25)

- `dunst-position.sh` lee `~/.config/polybar/position`.
- Con `bottom`: `origin = bottom-right`, notificación por encima de la
  barra (offset 40 px).
- Con `top`: `origin = top-right`, notificación por debajo de la barra.
- Cambia automáticamente al ciclar con `Super+Alt+P` (lo llama
  `launch.sh`).
- `dunstctl reload` aplica el cambio sin reiniciar la sesión.

### Kitty #1C1C1C (2026-10-25)

- `colorshemes/monochromatic.conf` con `background #1c1c1c`.
- Píxel comprobado en ventana real: `(28,28,28)`.
- `kitty` arranca sin avisos de claves desconocidas.

### Kitty y paleta de terminal (2026-10-25)

- `kitty.conf` incluye `colorshemes/monochromatic.conf` al final.
- Fondo de kitty `#1C1C1C`; barra y Thunar siguen en `#262626`.
- Rampa ANSI con contraste: `ls` distingue directorios y archivos.
- Comprobado en ventana real: fondo `(33,33,33)`.
- `verify_install` valida `COLOR_TERM_*` y el archivo del tema.

### Superficie y bordes (2026-10-25)

- Kitty, Thunar, rofi, dunst, zathura y polybar usan `#262626` como
  superficie; el wallpaper sigue negro.
- Captura: barra A y B y ventanas con fondo `(47,47,47)`.
- `bspc config focused_border_color` devuelve `#d9d9d9` y el borde normal
  `#1a1a1a`; ya no queda el beige `#b9a99a` de Warm Charcoal.
- `thunar` y una kitty nueva muestran fondo `#1a1a1a`.

### Thunar minimalista y CSS GTK (2026-10-25)

Probado en vivo con Thunar 4.20.2:

- `~/.config/gtk-3.0/gtk.css` y `gtk-4.0/gtk.css` cargan sin errores.
- IconView: fondo `#000000`, texto `#F2F2F2`, selección `#569CD6` con
  texto `#000000` (comprobado con `Gtk.StyleContext`).
- Thunar arranca sin menú, sin panel lateral y sin barra de estado:
  `last-menubar-visible=false`, `last-statusbar-visible=false`,
  `last-side-pane=THUNAR_SIDEPANE_TYPE_HIDDEN_SHORTCUTS`.
- Ctrl+M recupera el menú y F9 el panel lateral (defaults de
  `~/.config/Thunar/accels.scm`).
- `thunar-defaults.sh` no pisa propiedades existentes.
- `desktop-doctor` reconoce los CSS y el script.

### Paleta Mono Slate (2026-10-25)

Probado en vivo en ASUS FX504GE, Debian 13, 1920x1080:

- `./install.sh --dry-run` muestra `Tema: mono — Mono Slate (grises + azul tenue)`.
- Paleta exacta de referencia con acento azul `#569CD6` en lugar del rojo
  `#D71921`; comprobado en vivo (barra A/B, rofi, dunst, kitty, zathura).
- `./install.sh --theme warm` y `--theme nord` siguen funcionando; un tema
  inexistente aborta con la lista de disponibles.
- Render en home temporal: polybar A/B, kitty, rofi, dunst, bspwm,
  zathura y wallpaper sin `@COLOR_` pendientes.
- `lib/verify.sh` falla si se inyecta `#123456` en una config renderizada.
- En vivo: barra A y B monocromas, workspace enfocado blanco, rofi con
  borde azul, dunst normal/crítico con borde azul, zathura oscuro y
  wallpaper grafito con halo tenue.
- `desktop-doctor` reconoce `rofi/config.rasi` y `zathura/zathurarc`.

### Tema GTK e iconos (2026-10-25)

- `Windows-10-Dark` se instala en `~/.themes`.
- GTK2/3/4 usan Windows-10-Dark y Papirus.
- `gsettings` aplica el tema y los iconos al iniciar sesión.
- `papirus-icon-theme` y `librsvg2-common` vienen de APT.
- Si falta `librsvg2-common`, GTK no renderiza los SVG de Papirus.

### Perfil gráfico Intel/NVIDIA (2026-10-25)

- Con Intel se escribe `20-modesetting.conf` con glamor, DRI3 y PageFlip.
- Con NVIDIA se escribe solo `nvidia_drm.modeset=1` para PRIME.
- `--intel-glitch` añade `i915 enable_fbc=0` (y PSR en eDP).
- `--dry-run --intel-glitch` no escribe archivos.
- En este host se detecta Intel UHD 630 + NVIDIA GTX 1050 Ti y HDMI.

### Ranger, zathura, VLC y EPUB (2026-10-25)

- `ranger` abre documentos y usa `rifle` para lanzar zathura/VLC/feh.
- `zathura` incluye PDF, DjVu, PS y CB; el plugin `zathura-pdf-mupdf` 0.4.6
  añade EPUB/MOBI/FB2.
- El plugin se compila contra `libmupdf-dev` 1.25.1 de Debian 13; si falla,
  la instalación se detiene y no se instala apvlv.
- `scope.sh` genera portadas de PDF y vídeo, extrae portadas EPUB y usa
  `ueberzug` para imágenes.
- Los vídeos se abren con VLC.
- No se modifica el atajo de Thunar; ranger se ejecuta desde la terminal.

### Iconos Papirus

- `papirus-icon-theme` y `librsvg2-common` deben estar instalados.
- GTK necesita el loader SVG para mostrar los iconos de Papirus.

### Zsh, Oh My Zsh y lsd (2026-10-25)

- `zsh`, `zsh-autosuggestions` y `lsd` se instalan desde apt.
- Si no existe `~/.oh-my-zsh`, se clona desde el repositorio oficial.
- `.zshrc` conserva keybindings, opciones, aliases y autosuggestions.
- `lsd` usa `~/.config/lsd/config.yml` e `icons.yaml`.
- La shell de login del usuario queda en `/usr/bin/zsh`.
- `kitty` arranca zsh, con Nord y `font_size 13`.

### Red y WiFi (2026-10-25)

- `NETWORK_FAKE=both` muestra Ethernet aunque WiFi esté activo.
- `NETWORK_FAKE=wifi` muestra WiFi; `eth` muestra Ethernet; `none` muestra
  `󰖩 NoC`, dejando el módulo clicable.
- El módulo A/B tiene `click-left` a `network-menu.sh`.
- El menú se probó con `nmcli` y `rofi` simulados: filas numeradas
  (`1  SSID  80%  WPA2`), sin tabs visibles; una red WPA pide contraseña y
  conecta; una red abierta conecta directamente.
- Si ya existe un perfil por SSID pero no tiene PSK, se actualiza con
  `nmcli connection modify ... wifi-sec.psk` y se vuelve a activar.
- `nmcli` real lista redes WiFi; la sesión viva no se conectó a ninguna
  red durante la prueba.

### Volumen, brillo y dunst (2026-10-25)

- `volume.sh` se probó con `pamixer`: 80 → 90 → 100 → 110 → 120, sin
  superar 120, y bajada a 110. Se restauró el volumen original.
- Las notificaciones críticas se cierran solas: `displayed` pasa de 1 a 0
  tras 10 segundos.
- `brightness.ini` se instala y solo se referencia si `BACKLIGHT` existe.
  Este host no tiene `/sys/class/backlight`; en hardware con backlight el
  módulo usa `scroll-interval = 10`.

### Servicios systemd (2026-10-25)

`services.sh` se probó con un `systemctl` y un `dmenu` simulados para no
tocar servicios reales:

- `services.sh --count` devuelve el número de servicios en ejecución.
- El primer menú muestra los servicios con `enabled`, `disabled` o
  `static`, como `systemctl list-unit-files`.
- Al elegir un servicio se consulta `systemctl is-active`.
- Servicio activo: el menú ofrece solo detener y reiniciar.
- Servicio parado o fallido: ofrece solo iniciar y reiniciar.
- Seleccionar `cups.service` + detener ejecuta `systemctl stop cups.service`.
- Seleccionar `cups.service` + reiniciar ejecuta
  `systemctl restart cups.service`.
- Seleccionar `test.service` + iniciar ejecuta `systemctl start test.service`.
- No se ejecutan acciones sin seleccionarlas.
- En la sesión viva, sin `dmenu`, el script cae a `rofi -dmenu`. El
  instalador añade `dmenu` como paquete de escritorio.

### Notificador de batería (2026-10-25)

`low_bat_notifier.sh` se probó con una batería simulada y un `notify-send`
falso:

```sh
POWER_SUPPLY_DIR=/tmp/opencode/bat-test \
NOTIFY_SEND=/tmp/opencode/bat-test/notify-send \
CHECK_INTERVAL=1 ~/.config/bspwm/scripts/low_bat_notifier.sh
```

Resultados:

- 10 % descargando: aviso `critical` una vez; 9 % no duplica.
- Subir a 15 % reinicia el estado; volver a 10 % avisa otra vez.
- 99 % `Charging`: aviso para desconectar el cargador una vez.
- 100 % `Full`: no duplica; bajar a 98 % reinicia el estado.
- Capacidad vacía o no numérica: no notifica.

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
- Tras `startx`, bspwm, sxhkd, polybar, dunst, lxpolkit, udiskie y
  xss-lock están activos; no hay proceso picom.
- La barra muestra los módulos disponibles (12 en A y 14 en B; 13/15 si
  hay backlight).
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
| `Super+Alt+p` | ciclo polybar | A arriba → A abajo → B arriba → B abajo |
| `Super+Shift+space` | floating | Alterna flotante |
| `Super+a` | parent | Enfoca contenedor padre |
| `Super+b` / `Super+v` | split h/v | Preselección para la próxima ventana |
| `Super+f` | fullscreen | Alterna fullscreen |
| `Alt+Tab` / `Alt+Shift+Tab` | ciclo | Siguiente/anterior ventana |
| `Super+Ctrl+Tab` / `Super+Ctrl+Shift+Tab` | escritorios | Siguiente/anterior escritorio |
| `Super+{h,j,k,l}` | foco | Cambia ventana |
| `Super+Shift+{h,j,k,l}` | mover | Intercambia ventana |
| `Super+{1-7}` | escritorios | Cambia escritorio |
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
