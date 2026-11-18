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
for f in bin/desktop-safe bin/desktop-doctor bin/dwm-setup-cpu-governor; do sh -n "$f" || exit 1; done
for f in templates/bspwm/autostart.in templates/bspwm/bspwmrc.in \
         templates/polybar/scripts/cpu-governor.sh.in \
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
- `Super+Shift+d` abre `rofi -show drun`; `Super+d` abre
  `rofi -show run`.
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
- **VA-API**: `avcodec-hw=any` + `vout=gl`; al reproducir, el log debe
  mostrar `avcodec decoder: Using Intel iHD driver ... hardware decoding`
  sin `Failed to create video converter`. `vout=xcb_x11` no sirve para
  VA-API en este equipo.
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

### Modo resize con sxhkd hijo (2026-10-28)

- `Super+r` crea el estado y la barra muestra `RESIZE` antes de pulsar
  `h/j/k/l`.
- `resize-mode.sh` arranca `sxhkd -c ~/.config/sxhkd/resize-mode.sxhkdrc`,
  que solo captura `h/j/k/l` y `Escape`.
- `h`/`l` redimensionan y refrescan el TTL; `Escape` mata al hijo y quita
  `RESIZE`.
- Tras 6 s sin teclas el hijo muere solo; `h/j/k/l` vuelven a las apps.
- Medido con XTEST: ventana flotante 958→978→958 px con `h`/`l`;
  `splitRatio` 0.510417→0.5 en un tileado de dos ventanas.
- Tras `Escape` o 7 s de espera: `status` vacío y `pgrep` del hijo a 0.
- Una `h` sola después de salir no redimensiona.
- `Super+2`/`Super+1` siguen cambiando de escritorio con el modo cerrado.
- Con una sola ventana tileada no cambia el tamaño (semántica de i3).
- `install_sxhkd` renderiza `resize-mode.sxhkdrc` y envía `SIGUSR1` al
  sxhkd principal.

### i915, xinitrc y kitty single-instance (2026-10-26)

- `install.sh --dry-run` muestra
  `/etc/modprobe.d/dwm-setup-i915.conf (enable_fbc=0)`.
- `.xinitrc` exporta `XDG_SESSION_TYPE=x11` y `GDK_BACKEND=x11`.
- `Super+Return` ejecuta `kitty --single-instance`.
- Segunda ventana de kitty: ~54 ms (antes ~250-300 ms).
- `kitty.conf` ya no contiene `single_instance` (clave inválida en 0.41).

### Congelación de bspwm (2026-10-25)

- Síntoma: `bspc` se queda colgado; Xorg sigue respondiendo.
- Causa: `updates-apt.sh` huérfano retiene el socket de bspwm
  (`send-q` 213504).
- `launch.sh` con `flock` y limpieza de huérfanos.
- `updates-apt.sh` sale si su polybar desaparece.
- Prueba: `pkill -x polybar` + esperar 4 s deja `bspc query -D` operativo.

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
- **Miniaturas**: requiere `tumbler` (paquete base; trae plugins de
  imágenes, PDF y vídeo). `misc-thumbnail-mode=1` deja solo archivos
  locales. Comprobar `systemctl --user is-active tumblerd` y que
  `~/.cache/thumbnails/normal` crece al abrir Thunar.
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
| `Super+d` | rofi -show run | Lanzador de comandos |
| `Super+Shift+d` | rofi drun | Abre lanzador |
| `Super+Shift+s` | scrot región | Selecciona y copia al portapapeles |
| `Super+Shift+p` | pcmanfm | Pendiente de instalar pcmanfm |
| `Super+Shift+b` | chromium | Pendiente de instalar chromium |
| `Super+Shift+v` | codium | Pendiente; requiere repo VSCodium |
| `Super+Shift+i` | ristretto | Pendiente de instalar ristretto |
| `Super+Shift+a` | lxappearance | Pendiente de instalar lxappearance |
| `Super+Shift+f` | Thunar | Abre gestor |
| `Super+Shift+g` | grabar pantalla | Alterna empezar/parar; el módulo aparece solo mientras graba |
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
| `Super+r`, luego `h/j/k/l` | resize | Modo resize; Escape o 6 s sale |
| `Print` | captura completa | Copia al portapapeles y muestra miniatura |
| `Super+Print` | menú de capturas | Abre el menú y permite guardar en `~/Imágenes/Capturas` |
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

## 6c. Grabación de pantalla

Directorios y dependencias:

```sh
ls -ld ~/Descargas ~/Documentos ~/Imágenes ~/Imágenes/Capturas \
  ~/Música ~/Vídeos ~/Vídeos/Grabaciones
cat ~/.config/user-dirs.dirs
ls -l ~/.config/bspwm/scripts/screen-record.sh \
  ~/.config/bspwm/scripts/recording-tray.py \
  ~/.config/polybar/scripts/recording-status.sh
grep -n 'super + shift + g' -A1 ~/.config/sxhkd/sxhkdrc
```

Prueba con el atajo (la misma tecla inicia y para):

```sh
# 1. Pulsar Super+Shift+G → notificación "Grabando (sistema + micro)"
# 2. Esperar unos segundos (el módulo polybar muestra ● REC mm:ss)
# 3. Pulsar Super+Shift+G otra vez → "Grabación guardada"

ls -lh ~/Vídeos/Grabaciones/
ffprobe -v error -show_entries stream=codec_type,codec_name \
  -of default=nw=1 "$(ls -t ~/Vídeos/Grabaciones/*.mkv | head -1)"
```

Criterios:

- El archivo se llama `grabacion-YYYY-MM-DD_HH-MM-SS.mkv` y contiene
  `h264` + `aac`.
- `ps -o ni= -p "$(cat "${XDG_RUNTIME_DIR:-/tmp}/dwm-screen-record/ffmpeg.pid")"`
  debe devolver `10`: ffmpeg corre con prioridad baja para no competir
  con el escritorio.
- El audio sale del **monitor del sink por defecto** mezclado con el
  **source por defecto** (micrófono). La salida mantiene la prioridad de
  `audio-watch.sh` (jack > USB > Bluetooth > HDMI > interno). En el jack,
  el micro es el **interno por defecto** (`JACK_MIC=internal`) para no
  reajustar el HDMI; USB/Bluetooth siguen automáticos y
  `JACK_MIC=headset` fuerza el del headset. Se puede comprobar con
  `pactl get-default-sink` y `pactl get-default-source`.
- El micro interno lleva `Internal Mic Boost=2` (+20 dB) y el headset
  `1` (+10 dB). La grabación aplica `mic_gain=3.0` (+9,5 dB) a la pista
  del micro; se puede bajar a 1.0 en `recording.conf`. Si la voz sigue
  baja, usar el micro del headset conectado a mano o subir el boost.
- `~/.config/dwm-setup/recording.conf` elige el modo:
  `audio_mode="mix"` (sistema + micro, por defecto), `"system"` o `"mic"`.
- Prueba de mezcla: reproducir música y hablar a la vez; en el MKV deben
  oírse las dos cosas. Con `audio_mode="system"` no debe oírse la voz y
  con `"mic"` solo la voz. El micro lleva `highpass=f=80` para quitar el
  DC/rumble; sin él, la mezcla puede salir con un offset de ~0,15 y RMS
  alto aunque haya silencio.
- Con Bluetooth, al empezar a grabar debe aparecer `bluez_input.*` (HFP);
  al parar, WirePlumber vuelve a A2DP. Con HDMI se mantiene el micro
  interno/headset del perfil duplex.
- El módulo `recording` de polybar solo se ve mientras dura la grabación:
  punto `●` rojo, `REC` y el tiempo en el color de texto normal, con el
  mismo fondo y padding que el resto de módulos. Al parar desaparece
  (`module_hide`); al empezar reaparece (`module_show`). Si `ffmpeg`
  muere solo, el módulo se oculta en el siguiente ciclo.
- Con un solo monitor empieza directo (sin llamar a `xrandr`); con varios
  abre un menú rofi con nombre y resolución de cada pantalla (y una opción
  «Todas»). La geometría sale de `~/.cache/dwm-setup/monitors`, escrita
  por `display-setup.sh`; si falta, se graba «Todas» con `xdpyinfo`. Tras
  cambiar monitores, ejecutar `display-setup.sh apply` para refrescar.
- El aviso de inicio suena ~1,2 s antes de que empiece ffmpeg (para que
  el chime no se grabe); el de parada suena después. No debe haber ningún
  `paplay` en el monitor mientras graba.
- Mientras graba, `pgrep -af 'ffmpeg.*x11grab'` debe mostrar las dos
  entradas `-f pulse -i` (monitor y micro) y `amix` en `filter_complex`.
- Si el micro no abre, reintenta solo sistema; si el sistema no abre,
  solo vídeo. La notificación indica el modo real: “sistema + micro”,
  “solo sistema”, “solo micro” o “solo vídeo”.
- Parar dos veces no duplica notificaciones ni deja procesos `ffmpeg`.

Prueba desde la terminal (sin atajo):

```sh
~/.config/bspwm/scripts/screen-record.sh start
~/.config/bspwm/scripts/screen-record.sh stop
~/.config/bspwm/scripts/screen-record.sh toggle
```

Quirk ALC255 (solo ASUS FX504GE/ALC255):

```sh
# Detección en dry-run
./install.sh --dry-run | grep -A2 'modprobe.d/alsa-fx504'

# El quirk debe apuntar a snd-hda-intel (no a snd-hda-codec-realtek)
grep -x 'options snd-hda-intel model=alc255-asus' /etc/modprobe.d/alsa-fx504.conf

# Con auriculares, el boost del micro debe quedar a 0 y el capture <= 55:
amixer -c0 cget name='Headset Mic Boost Volume' | tail -2
amixer -c0 cget name='Capture Volume' | tail -2

# Tras instalar y reiniciar, el módulo debe llevar el modelo aplicado:
cat /sys/module/snd_hda_intel/parameters/model   # debe empezar por alc255-asus

# Con los auriculares conectados:
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

### Firefox ESR y Teams (2026-10-28)

- `Super+Shift+b` por XTEST abre una ventana de Firefox.
- `/etc/firefox-esr/zz-dwm-setup.js` contiene
  `media.gmp-gmpopenh264.enabled` y
  `media.peerconnection.video.h264_enabled` en `true`.
- `about:plugins` muestra OpenH264 habilitado.
- `desktop-doctor` muestra `[OK] OpenH264 habilitado para WebRTC/Teams`;
  `verify_install` live, mono y warm pasan.
- `/etc/firefox/policies/policies.json` contiene
  `uBlock0@raymondhill.net` con `force_installed`.
- `about:policies` muestra `ExtensionSettings` activo y el perfil tiene
  `extensions/uBlock0@raymondhill.net.xpi`; `desktop-doctor` sube a 77 OK.
- Pendiente: que otra persona comparta pantalla en Teams y se vea el vídeo.

### Bandeja del sistema (2026-11-01)

- `~/.config/polybar/modules/tray.ini` y la variante de referencia existen.
- `modules-right` de A y B termina en `tray`.
- `verify_install` y `desktop-doctor` lo comprueban.
- Probado con `GtkStatusIcon`: icono de 21x21 embebido en A y B a la
  derecha (`xwininfo` → `+1893+1054`).
- Pendiente: probar con Telegram; si no aparece, evaluar `snixembed`.

### Catppuccin Mocha Black y Latte (2026-11-02)

Preview y validación estática; **no** se ha ejecutado la instalación real.

**Preview (sin tocar el sistema):**

- Contact sheets y escritorios en `/tmp/opencode/mocha-variants` para
  `black`, `mauve`, `blackmauve` y `latte`.
- Barras A/B reales (clonadas de `~/.config/polybar` y solo con el bloque
  `[colors]` sustituido), Thunar con tema GTK real, kitty, ranger, zathura,
  Firefox con `userChrome.css`, VLC, rofi y dunst.
- El usuario elige `mocha-black` (dark) y `latte` (light).

**Estático:**

- `bash -n` de `install.sh`, `lib/*.sh`, `bin/theme-mode`,
  `templates/bspwm/{autostart,bspwmrc}.in`: OK.
- `./install.sh --dry-run` y `--dry-run --theme latte`: OK; el resumen
  muestra el tema cargado y el `qt-dark-palette` correcto.
- Render de ambos modos en un HOME simulado con `theme-mode --no-reload`:
  sin `@TOKEN@` pendientes, permisos 0755 (`bspwmrc`), 0644 y 0600
  (`vlcrc`), y colores de polybar/GTK/bspwm acordes a la paleta.
- Derivación de `catppuccin-mocha-black` probada en `/tmp`: no quedan
  hex de la rampa Mocha (`#1e1e2e`, `#181825`, `#11111b`, `#313244`,
  `#45475a`, `#585b70`) en `*.css`/`*.svg` y el acento `#89b4fa` se
  mantiene.
- Overlay de iconos probado en `/tmp` con `XDG_DATA_HOME` temporal:
  `Catppuccin-Mocha` hereda de `Papirus-Dark`, `papirus-folders` crea los
  symlinks `folder*.svg` y Thunar pinta las carpetas con el azul de
  Catppuccin.

**Pendiente (requiere `sudo ./install.sh`):**

- Instalar temas en `/usr/share/themes` y comprobar que
  `catppuccin-mocha-black` abre Thunar con la superficie `#0d0d14`.
- Comprobar que `Catppuccin-Mocha` y `Catppuccin-Latte` coexisten con
  colores de carpeta distintos.
- `theme-mode dark` / `light` en la sesión viva: polybar recarga, dunst se
  reinicia, bordes de bspwm cambian y `desktop-doctor` no falla.
- Firefox: `userChrome.css` y `ui.systemUsesDarkTheme` tras reiniciar.
- VLC: `qt-dark-palette` 1/0.

### Firefox: botones, SurfingKeys y atajo (2026-11-02)

**Estático:**

- `bash -n` de `lib/firefox.sh`, `bin/theme-mode` e `install.sh`: OK.
- `render de surfingkeys.js.in` en `/tmp`: sin `@TOKEN@`, 2 backticks,
  paréntesis y llaves balanceados, sin alias de reddit, `#sk_status` a 11pt.
- `build_surfingkeys_theme` emite los dos bloques con los hex de
  `mocha-black` y `latte`.
- `policies.json` valida como JSON y contiene uBlock y SurfingKeys.

**Pendiente (requiere `sudo ./install.sh` y reiniciar Firefox):**

- `about:policies` muestra los dos `ExtensionSettings`.
- El chrome usa `#0d0d14` y se ven atrás/adelante/recargar/descargas/menú.
- Pegar `~/.config/dwm-setup/surfingkeys.js` y comprobar que el tema cambia
  con `Super+Alt+t` sin volver a pegarlo (prueba de `prefers-color-scheme`).
- `theme-mode toggle` muestra la notificación de dunst.

### kitty en caliente (2026-11-02)

- `kitty.conf` contiene `allow_remote_control socket-only` y
  `listen_on unix:kitty-{kitty_pid}`.
- Prueba en una instancia aparte: el socket aparece en `/tmp/kitty-<pid>`,
  `get-colors` responde y
  `set-colors --all --configured ~/.config/kitty/colorshemes/monochromatic.conf`
  cambia el fondo a `#0d0d14`/`#eff1f5` y el cursor a `#89b4fa`/`#1e66f5`.
- `load-config` no revierte los colores fijados previamente: se descartó.
- Pendiente: reiniciar el kitty vivo y comprobar `Super+Alt+t` en la sesión
  real; el binario instalado debe actualizarse con `sudo ./install.sh`.

### Fix de la sonda de VLC (2026-11-02)

- Causa: `vlc -H --advanced` como root devuelve rc=1 sin salida
  ("VLC is not supposed to be run as root"), así que el instalador creía que
  la opción no existía y se saltaba el paso.
- Reproducido con `unshare -r vlc -H --advanced`: rc=1, 0 líneas.
- Con `run_user vlc -H --advanced` salen 300 KB de ayuda y aparece
  `--qt-dark-palette`.
- Tras `theme-mode --no-reload dark`, `~/.config/vlc/vlcrc` tiene
  `qt-dark-palette=1` y `verify_install` no marca el fallo.

### Zathura y contenido de Firefox (2026-11-02)

- Zathura 0.5.11: `^r` es "Recolor (grayscale and invert colors)". Con
  `set recolor true` los cómics se ven en negativo; con `false` se ven
  normales y `Ctrl+R` invierte solo el documento.
- Prueba de contenido en caliente: instancia aparte con
  `content-override=2`, `ui.systemUsesDarkTheme=-1` y una página con
  `@media (prefers-color-scheme: dark)`. Permaneció en `DARK` (13,13,20) tras
  poner `color-scheme=default` y volver a `prefer-dark`; el evento `change`
  no se disparó. Conclusión: no hay cambio en caliente.
- Se revirtió a 0/1 y 1/0. Pendiente: reiniciar Firefox y comprobar Google;
  YouTube con "Usar tema del dispositivo".

### fastfetch (2026-11-02)

- `fastfetch -c templates/fastfetch/config.jsonc` (renderizado a /tmp)
  imprime los módulos sin errores de parseo.
- En kitty, con `type: kitty`, el logo `Neofet.png` se renderiza a 28x15
  respetando la proporción (956x1062).
- Fuera de kitty cae al logo builtin; no es un fallo del config.
- Pendiente: `sudo ./install.sh` y comprobar `~/.config/fastfetch/`.

### Streaming de YouTube (2026-11-02)

- `ytdlp-update` en sandbox (`YTDLP_BIN=/tmp/...`): descarga 2026.10.26,
  `--version` correcto y "prueba de arranque: OK".
- `ytdlp-check` con ese binario en PATH: "al día".
- `ytdlp-rollback` sin `.bak`: error claro; con `.bak`: restaura.
- `yt-play lofi` sin fzf y `yt-play <url>` sin mpv: mensajes claros.
- Búsqueda real con yt-dlp: `ytsearch3:lofi hip hop` devuelve título, canal,
  duración (NA en directos, mostrado como "en vivo") e id.
- `install.sh --dry-run`: muestra la sección de streaming y no falla el layout.
- Pendiente: instalar y probar reproducción real y teclas multimedia.

### Preview de miniaturas (2026-11-02)

- `yt-preview rFZHOHl-L8A` descarga la miniatura (320x180, ~10 KB) y la deja
  en `~/.cache/yt-play/thumbs`; sin `chafa` imprime "sin preview".
- La URL `i.ytimg.com/vi/<id>/mqdefault.jpg` responde para el id probado.
- Con chafa 1.14.5 y un panel de 44×14, la salida son 13 líneas de texto
  (18 KB), sin secuencias `\033_G` (kitty) ni `\033P` (sixel), y restaura el
  cursor. Pendiente: comprobar visualmente el panel completo en fzf.
- Sustituido por el preview equilibrado (opción A): panel al 50%, metadatos
  y `maxresdefault` con respaldo.

### Número de resultados de yt-play (2026-11-02)

Con el binario oficial 2026.10.26, `--flat-playlist`:

```text
ytsearch10  → 2527 ms
ytsearch20  → 2556 ms
ytsearch30  → 3644 ms
ytsearch50  → 4533 ms
```

20 es gratis frente a 10 (misma página); 30+ pagina y se nota.
`YT_PLAY_RESULTS` se valida: vacío, `abc`, `0` y negativos usan 20.

### Fix del preview de yt-play (2026-11-02)

- Síntoma: al cerrar fzf con Esc, la miniatura se quedaba dibujada; al mover
  el cursor se solapaban dos imágenes.
- Causa: chafa en kitty usa el protocolo gráfico por defecto; fzf no limpia
  esas capas.
- Con `--format=symbols` la salida es texto (0 secuencias `\033_G`/`\033P`),
  13 líneas para un panel de 14 y cursor restaurado.

### Preview equilibrado de yt-play (2026-11-02)

- `yt-play` con `yt-dlp` y `fzf` falsos: escribe
  `~/.cache/yt-play/meta/<id>` con título, canal y duración; `NA` se guarda
  como "en vivo". La entrada de fzf es solo `título<TAB>id`.
- `yt-preview` con metadatos y red real: `dQw4w9WgXcQ` descarga
  `maxresdefault` (1280x720) en `~/.cache/yt-play/preview`.
- `yt-preview jNQXAC9IVRw`: `maxresdefault` responde 404 y se usa
  `mqdefault` (320x180), sin dejar el archivo temporal.
- Panel simulado de 60x30: título en 2 líneas, canal · duración, línea en
  blanco y 17 líneas de chafa (21 en total). Sin secuencias kitty/sixel y
  cursor restaurado.
- Título con acentos y palabra larga en panel de 20 columnas: la salida es
  UTF-8 válido (`iconv`) y no parte caracteres; un título con `ESC`/tab/CR
  pierde los controles antes de imprimirse.
- Pendiente: abrir `yt-play lofi` en la sesión viva y comprobar el panel
  completo, el cambio de resultado y que Esc no deja restos.

### Flujo de instalación y autoremove (2026-11-02)

- `bash -n` de `install.sh`, `lib/*.sh` y los seis scripts de streaming:
  OK. `shellcheck` no está instalado en el host.
- `./install.sh --dry-run`: rc=0, 406 líneas, sin errores ni warnings.
  Muestra la sección de streaming y termina con `apt-mark manual` y
  `apt-get -y autoremove` simulados.
- `install_music` en HOME temporal: primera ejecución descarga yt-dlp
  2026.10.26 e instala los seis scripts 0755; la segunda imprime
  "yt-dlp ya instalado" y no descarga.
- `protect_build_toolchain` con los paquetes del host: ejecuta
  `apt-mark manual build-essential make gcc g++ patch meson ninja-build
  pkg-config git`. `cmake`, `autoconf`, `automake`, `libtool` y
  `libtool-bin` aún no
  están instalados, así que no aparecen hasta que los instale el
  instalador.
- `cleanup_packages` con un `apt-get` falso que falla: avisa
  "apt-get autoremove falló" y devuelve 0, sin abortar la instalación.
- Pendiente: ejecutar `sudo ./install.sh` en el host y comprobar que dunst
  queda reiniciado con la paleta activa y que el autoremove real no toca
  la cadena de compilación.

- `desktop-safe lock` con un `i3lock` falso: en modo dark usa `0d0d14` y en
  modo light `eff1f5`, leídos de `~/.local/share/dwm-setup/colors` y
  `~/.config/dwm-setup/mode`.

### Pantalla siempre encendida (2026-11-02)

- Antes: `xset q` con `timeout: 600` y `DPMS is Enabled` (600 s).
- `DISPLAY=:0 xset s off` y `DISPLAY=:0 xset -dpms`: `timeout: 0` y
  `DPMS is Disabled`.
- `sh -n templates/bspwm/autostart.in` y `sh -n
  templates/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh.in`: OK.
- `autostart` e `i3lock-fancy` instalados sincronizados desde las plantillas
  con backup en `~/.config-backup/dwm-setup/20261102-193117`; `sh -n` de los
  archivos instalados OK y permisos 0755 `luc:luc`.
- Pendiente: `sudo ./install.sh` para el resto del bloque, reinicio de
  sesión, inactividad >10 min, `Super+Shift+L` (pantalla encendida) y
  suspensión (bloquea antes de dormir).

### yt-play audio/vídeo y Ctrl+Space (2026-11-02)

- `bash -n bin/yt-play`: OK.
- `yt-play` con `mpv` falso y URL directa:
  - sin flag y `--audio`: recibe `--no-video --ytdl-format=bestaudio`.
  - `--video`: no recibe `--no-video` ni `--ytdl-format`; recibe la URL.
- `yt-play` con `yt-dlp` y `fzf` falsos:
  - fzf imprime una línea vacía + `<título>	<id>` (Enter) → audio.
  - fzf imprime `ctrl-v` + `<título>	<id>` → vídeo.
  - `--video` invierte el modo por defecto.
- Error de extracción con un `mpv` falso que escribe en stderr: el `tee`
  captura el mensaje y `yt-play` muestra "YouTube ha cambiado". Ya no se usa
  `--log-file`.
- `zsh -c 'bspc node -t ~floating'` falla con "no such user"; con
  `'~floating'` bspwm cambia tiled→floating→tiled.
- `sxhkdrc` contiene `ctrl + space` → `bspc node -t '~floating'`; también
  están citados `'~fullscreen'`, `'~east'` y `'~south'`. sxhkd rearrancado
  sin errores de grab.
- `yt-play --video` con un `mpv` falso recibe `--autofit=80%x80%` y no
  `--no-video`.
- Pendiente: `sudo ./install.sh`, probar `Ctrl+Space`, `Super+Shift+Space`,
  `Super+f`, los splits, audio y vídeo en vivo.

### Compositor picom y módulo governor (2026-11-04)

- `bash -n` en libs (`cpu.sh`, `picom.sh`) e `install.sh`: OK.
- `sh -n` en `bin/dwm-setup-cpu-governor` (POSIX), `cpu-governor.sh.in`
  y `autostart.in`: OK.
- Helper con sysfs falsa en `/tmp/opencode` (override
  `DWM_SETUP_CPU_SYS`): escribe `performance`/`powersave` en las 4 CPUs
  falsas (rc 0); valor inexistente → rc 64 con lista de disponibles en
  stderr; sin CpUs escribibles → rc 65; CPU parcialmente bloqueada →
  rc 0 con aviso por la que no.
- Script de la barra con sysfs falsa + `sudo` de stub + helper de stub:
  `--status` imprime `%{F#89b4fa}%{T3}` rayo ` performance` (acento
  mocha) y `%{T3}` velocímetro ` powersave` sin acento (bytes
  `U+F10CB`/`U+F0F86` verificados con `od -c`); `--next` cicla en
  caliente los dos modos con toasts dunst cada clic. Sin sudo real:
  toast crítico "sudo denegado"/"Falta el helper" (comportamiento
  esperado antes de `sudo ./install.sh`).
- `sed "s/@USER@/luc/g"` del fragmento de sudoers → `visudo -cf`:
  "parsed OK".
- `systemd-analyze verify templates/systemd/...service`: la única
  queja es el ejecutable de `/usr/local/bin aún no instalado (va con
  `sudo ./install.sh`); la sintaxis de la unidad no produce errores.
- `./install.sh --dry-run`: rc 0, sin modificaciones; el plan incluye
  renders de `governor.ini` en ambas variantes, `cpu-governor.sh`,
  helper/sudoers/unidad y picom.conf.
- En vivo (host de referencia, variante referencia activa): backups en
  `~/.config-backup/dwm-setup/20261104-130202/`; ` governor` insertado
  tras `cpu` en ambos `config.ini`; módulos y script instalados con
  acento del modo activo (light: `#1e66f5`); picom reiniciado con la
  config final (pid activo) y polybar recargada con `launch.sh`.
  El bloque root (helper/sudoers/unidad, unidad habilitada) quedó
  instalado con el `sudo ./install.sh` de las 13:13. La prueba visual
  del fade y del alternado por clic la hace el usuario; el store de
  theme-mode quedó sincronizado tras el port.
- picom usa libconfig: comentarios `#` (un `;` provoca "syntax error" y
  el daemon aborta al arrancar).

### Port de ajustes manuales del usuario (2026-11-04, tarde)

- Origen: comparación render del repo vs ficheros vivos (ficheros cambiados
  después del `sudo ./install.sh` de las 13:13); port de 8 archivos de
  plantilla (B config, 2 governor, cpu A, 2 pipewire, memory B,
  cpu-governor.sh) + check de verify + docs.
- Prueba de identidad: re-render de las plantillas nuevas con las
  variables del instalador (`render.env` + paleta del modo activo):
  **9/9 IDÉNTICO** contra los ficheros en vivo, incluidos el
  `@HOME@`/`@BAR_HEIGHT@` resueltos. El próximo render (`sudo
  ./install.sh` o `theme-mode`) conserva los tweaks tal cual.
- Store de theme-mode refrescado sin sudo (los tres ficheros del store
  son user-owned): configurado antes del próximo `theme-mode toggle`.
- `bash -n`/`sh -n` de todo: OK. `--dry-run`: rc 0 (275 pasos).

### ytwatch en el instalador (2026-11-04, ADR-109)

- Prueba del binario suelto en la máquina: release v0.1.0 verificada
  con `checksums.txt` (SHA-256 OK), `ytwatch doctor` con yt-dlp/mpv/
  ffmpeg/xclip/browser OK y solo ueberzugpp+wmctrl ausentes; capturas
  del TUI (búsqueda, LIVE/VOD/SHORT/PLAYLIST, descripción y cola) sin
  miniaturas.
- Aprendido: `[preview] output = kitty|chafa` NO evita ueberzugpp; el
  binario es el renderizador real → el instalador lo trae como .deb.
- Validado en repo: `bash -n` completo, `--dry-run` rc 0 con URLs y
  checksums, `--dry-run --no-ytwatch` omite el bloque, `ytwatch-check`
  real (al día + ueberzugpp ausente) y `ytwatch-update` early-exit.
- Pendiente: `sudo ./install.sh` en la sesión (instala .deb + config),
  miniaturas en kitty, tecla de vídeo de `?` y prueba de
  `ytwatch-update --ueberzugpp` cuando salga versión nueva.
- Incidente 2026-11-04 15:38: dpkg rechazó ueberzugpp_2.9.10 porque el
  paquete legado `ueberzug` (18.3.1-2+b1) posee /usr/bin/ueberzug; el
  .deb trae el shim. Fix: retirar el legado antes del dpkg (instalador
  y `ytwatch-update --ueberzugpp`); sin dependientes en Debian 13 y
  ranger sigue con el shim. Re-ejecutar `sudo ./install.sh`.
- 2026-11-04 (noche): miniaturas visibles confirmadas con
  `preview.output = "x11"` en kitty+X11 (backend `kitty` del
  ueberzugpp v0.1.0 no pinta). Audio sin ventana negra:
  `--force-window=no` en `[mpv] args` gana contra el
  `--force-window=immediate` de ytwatch (comprobado con xwininfo).
  Pendiente: confirmar que `a` conmuta el modo y `Enter` abre vídeo.
- 2026-11-04 (noche): `music-ctl` pasó a controlar todas las instancias
  (play-pause/stop con `playerctl -a`) y ganó forward/backward (±10 s)
  con bindings XF86AudioForward/Rewind. picom con fade-step 0.05
  (~100 ms). Pendiente de probar en sesión tras `sudo ./install.sh`.
- 2026-11-04 (noche, cierre): el override `--force-window=no` se
  revierte por decisión del usuario; ytwatch queda con el
  comportamiento del proyecto (ventana de mpv visible en audio). Se
  mantiene `preview.output = "x11"`.
- Incidente 2026-11-04 18:34: `apt-get install` del grupo escritorio
  reintentó el ueberzug legado (estaba en DESKTOP_PKGS tras haberlo
  quitado para ueberzugpp) y falló a la inversa. Fix: sin `ueberzug`
  en el grupo; se instala solo con `--no-ytwatch`. Validado con
  dry-run en ambos ramales.
- 2026-11-04 (cierre): `audio_only = false` (vídeo por defecto) por
  decisión del usuario; el modo audio mantiene la ventana del proyecto
  (sin imagen). Revertir sería `audio_only = true` +
  `--force-window=no` si se quiere audio puro sin ventana.
- 2026-11-04 (noche): sombras sutiles de picom (ADR-110): shadow true,
  radius 10, opacity 0.35, offsets -8/-8, excluye dock/desktop; sin
  transparencias ni blur. verify.sh comprueba shadow/opacity y rechaza
  blur. Pendiente: valoración visual del usuario.
- 2026-11-04 (noche): timer de avisos de YouTube (usuario), swappiness
  10 y prune de backups >3 días (conserva 3). Checkers con --no-notify.
  Pendiente: `sudo ./install.sh` para instalar binario/unidades/sysctl
  y probar el toast cuando alguna versión cambie.
- 2026-11-04 (noche): notificador de batería con umbrales 10/7/5/3/1
  (uno por descarga; ≤5 % toast pegajoso `-t 0`). Probado en sandbox
  con POWER_SUPPLY_DIR falso: secuencia completa y salto 9→4 (una sola
  notificación). Aplicado en vivo y notificador reiniciado.
- 2026-11-04 (noche): MTP por cable añadido al instalador
  (`libmtp-runtime`); backend gvfs MTP ya presente. Pendiente de prueba
  real con el móvil del usuario (conectar en modo transferencia y
  ver el dispositivo en Thunar).
- 2026-11-04 (noche): wallpaper por modo y override local
  (`local-dark/local-light`). `wallpaper.sh apply` respeta el modo;
  `theme-mode` lo re-aplica. Previews Vagabond en /tmp para revisión;
  los fondos finales serán locales (copyright) y no entran al repo.
- 2026-11-05: borde 2 / gap 10 de bspwm y
  browser.fullscreen.autohide=false (Firefox) pasan a las plantillas.
  Aplicado en vivo (bspc config + user.js del perfil); Firefox lo toma
  al reiniciarse.
- 2026-11-05: esquinas redondeadas (picom) + borde 0 + dunst
  corner_radius 10; foco indicado por sombra (`!focused`); Super+m con
  monocle.sh (picom sin radios en monocle). Probado el toggle
  monocle/tiled y el radio temporal; sin commit aún.
- 2026-11-05: `inactive-dim 0.18` + dunst con sombra
  (`!focused && !(class_g = 'Dunst')`). Pendiente de confirmar en
  pantalla si dunst queda sin atenuar (si no, pasar a opacity-rule).
- 2026-11-05: halo de acento en la ventana enfocada (picom shadow-color
  desde la paleta, offsets 0, radius 12, opacity 0.45). picom añadido
  al store de theme-mode y a su re-render/reinicio; verify incluye
  picom.conf en el chequeo de paleta. Aplicado en vivo; pendiente de
  valoración y de commit.
- 2026-11-05: se descartó el halo/inactive-dim por feo; foco por borde
  2px (bspwm) con gap 10 y redondeo picom intacto. Aplicado en vivo;
  pendiente de commit.
- 2026-11-05: fade de picom ajustado a 0.035 (~143 ms) por sensación
  del usuario; reiniciado y verificado el valor en el conf vivo.
- 2026-11-05: display-setup.sh todo terreno creado y aplicado en vivo
  (HDMI-1 sigue en 1920x1080). i915 con PSR/DC off en plantilla
  (pendiente de instalar con sudo + reboot). Apagón aleatorio del
  monitor externo: pendiente de captura del kernel log y prueba de
  cable/puerto.
- 2026-11-05: Vulkan verificado (Intel UHD 630 + llvmpipe) y añadido al
  instalador (libvulkan1 + mesa-vulkan-drivers). Uso futuro: upscalers
  ncnn si se opta por el camino local.
- 2026-11-06: fluidez verificada. `xrandr` aplica 120 Hz vía
  display-setup (resolución preferida + max rate). VA-API activado en
  Firefox por pref (requiere reiniciar el navegador para verse en
  about:support). Compositor y sistema sin cuellos de botella.
- 2026-11-06: fastfetch truecolor por paleta (marco overlay0, lavanda
  cabeceras/iconos, azul etiquetas). Verificado con --pipe false +
  cat -v: secuencias \e[1;38;2;… correctas, valores sin color (
  \e[m tras cada clave), placeholders @…@ = 0, dry-run OK.
- 2026-11-10: `prime-run` y Vulkan de la dGPU implementados (ADR-111):
  wrapper POSIX en `templates/nvidia/prime-run`, `nvidia-vulkan-icd`
  con el grupo del driver, checks de verify (ejecutable + offload) y
  bloque de `lib/gpu.sh` condicionado a driver presente. Checks
  estáticos OK (bash -n, sh -n, --dry-run). Pendiente de aplicar en
  vivo con `sudo ./install.sh` y validar `prime-run glxinfo -B` /
  `prime-run vulkaninfo --summary` (GTX 1050 Ti).
- 2026-11-10: escritorios dinámicos (ADR-112) aplicados en vivo:
  workspace.sh (focus/move/next/prev/daemon), bspwmrc `-d 1`,
  sxhkdrc sin hjkl y con Ctrl+Tab. Backup previo, daemon activo.
  Pendiente: `sudo ./install.sh` y prueba manual (Super+3 aparece, al
  volver al 1 desaparece; Ctrl+Tab recorre solo existentes;
  Super+Shift+3 mueve y crea). No usar `Super+Shift+r` (reinicia
  bspwm y re-ejecuta bspwmrc con `-d 1`) hasta el próximo startx.
- 2026-11-10: regla densa de escritorios: Super+N salta al N si
  existe y crea el siguiente si no; renumeración 1..N tras borrar.
  Probado en vivo (1→2, [1,2]→3, [1..5] Super+5 va al 5, move y
  rename con ventanas). Pendiente `sudo ./install.sh`.
- 2026-11-10: selección de kitty #585b70 y bordes (foco #89b4fa,
  vecina #35353f) vía COLOR_SEL_BG/paleta. Aplicado en vivo: bspc
  config + kitty @ set-colors, verificado con get-colors. Pendiente
  comprobar en pantalla y `sudo ./install.sh`.
- 2026-11-10: install falló por placeholder `@COLOR_SEL_BG@` (lista
  fija en lib/theme.sh). Añadido a lib/theme.sh (render + fallback) y
  a lib/verify.sh (palette_hex). Re-render en vivo OK y kitty
  recoloreado; pendiente repetir `sudo ./install.sh` para verificación
  completa.
- 2026-11-10: fastfetch roto por `export_rgba_helpers` (hex sin # en
  SGR 38;2). Corregido base.sh, store + re-render en vivo OK y guard
  en verify. Pendiente repetir `sudo ./install.sh`.
- 2026-11-10: telemetría de Firefox apagada por user.js + policies
  (DisableTelemetry/Studies/Pocket) y verify ampliado. Render en vivo
  OK. Pendiente: cerrar Firefox para borrar IDs cacheados y
  `sudo ./install.sh` para las policies.
- 2026-11-10: fallo de install por (1) merge de policies que solo
  tocaba ExtensionSettings y (2) verify mirando perfiles legacy.
  Corregidos ambos; merge probado en /tmp. Pendiente repetir
  `sudo ./install.sh` + reiniciar Firefox.
- 2026-11-10: barra de Firefox minimalista por CSS (firefox-view,
  alltabs, sidebar ocultos). Render vivo OK; pendiente reiniciar
  Firefox para comprobarlo en pantalla.
- 2026-11-10: más minimalismo Firefox: iconos cuenta/privacidad/
  extensiones ocultos, panel sin «+» ni scrollbar, borde inferior
  quitado, tools=history,bookmarks. Render OK; pendiente reinicio y
  comprobación visual.
- 2026-11-10: telemetría restante cubierta (usage/Glean-gate/PPA/
  serp/urlbar/crash/ads) + DisableFeedbackCommands; render OK.
  Pendiente reinicio, sudo install y borrado de pings/IDs con Firefox
  cerrado.
- 2026-11-10: SurfingKeys Ctrl+n/Ctrl+p → next/previousTab y Alt+N →
  firefox-sidebar.sh (xdotool + Ctrl+Alt+Z nativo, filtrado por
  WM_CLASS). sxhkd recargado; pendiente instalar xdotool y pegar la
  config en la extensión para probar en pantalla.
- 2026-11-10: ui.prefersReducedMotion=1 (sidebar instantánea con
  Alt+N). Render OK; pendiente reiniciar Firefox y pegar la config de
  SurfingKeys para Ctrl+N/P.
- 2026-11-10: corregida la sintaxis de Ctrl+N/P en SurfingKeys
  (mapkey + RUNTIME). Alt+N verificado en vivo (toggle sidebar
  ~1.25M px por pulsación). Pendiente re-pegar la config y probar.
- 2026-11-10: Ctrl+N/Ctrl+P implementados por autoconfig de Firefox
  (reservado en el navegador para Ctrl+N). Pendiente `sudo
  ./install.sh` + reinicio y prueba real.
- 2026-11-10: autoconfig reescrita con reapuntado de key_newNavigator
  y printKb (reserved). Pendiente sudo install + reinicio + prueba.
- 2026-11-10: migración Brave (ADR-113): repo APT, policies, atajos
  nativos y tema CWS. Checks estáticos OK; pendiente instalar en vivo y
  validar atajos/policies/tema y VA-API.
- 2026-11-13: atajos Brave Alt+N (panel), Alt+Shift+N (ventana) y
  Ctrl+Alt+L/H (split) añadidos y probados en vivo con IDs 56215,
  34000, 34057 y 56325. Pendiente sudo install para llevarlo al repo.
- 2026-11-13: Alt+H/Alt+L mapeados a panel anterior/siguiente
  (39005/39004) y Alt+H retirado de Historial. F6/Shift+F6 probados en
  vivo moviendo el foco entre los dos paneles del split; pendiente
  probar Alt+H/Alt+L tras cerrar Brave y reescribir las prefs.
- 2026-11-13: SurfingKeys: `o`/`O`/`b`/`H`/`L` conservados; historial
  movido a `<Alt-y>` y retirados los Alt+Q/Alt+O que Brave intercepta.
  Pendiente pegar la config en la extensión del perfil de Brave y
  comprobar con `?`.
- 2026-11-13: Brave minimalista (NTP limpia, iconos apagados, verticales
  sobrias) y hints de SurfingKeys a 15px azules. Pendiente reiniciar
  Brave y revisar captura; `BookmarkBarEnabled` requiere `sudo
  ./install.sh` para escribir la policy.
- 2026-11-13: NTP de Brave sustituida por /usr/share/dwm-setup/newtab.html
  vía policy NewTabPageLocation (negro liso, sin buscador ni sitios).
  Pendiente `sudo ./install.sh` con Brave cerrado y captura de Ctrl+T.
- 2026-11-13: hints de SurfingKeys a 17px con fondo azul sólido y
  letra oscura (colores literales; `var()` no resuelve en el shadow
  root). Pendiente re-pegar la config y comprobar con `f`.
- 2026-11-13: pendiente probar que dunst sigue mostrando toasts con una
  ventana a pantalla completa (valor por defecto `fullscreen = show`).
- 2026-11-13: análisis de rendimiento completo (aperturas, GPU, boot,
  idle). Pendiente tras `sudo ./install.sh` + reinicio: confirmar
  arranque ~8-10 s más corto y `prime-run glxinfo` sin nvidia-drm
  precargado. VA-API verificado el 2026-11-13: `brave://gpu` muestra
  "Video Decode: Hardware accelerated" con `VaapiVideoDecoder`.
- 2026-11-13: pruebas funcionales (zathura, feh, VLC, mpv, ranger,
  audio, portapapeles, dunst). Corregido: previews de ranger con
  `kitty`, asociaciones MIME (zathura/feh/VLC) y diálogo de privacidad
  de VLC. Pendiente revalidar tras `sudo ./install.sh`.
- 2026-11-13: `ytwatch-check`/`ytwatch-update` instalados en
  `~/.local/bin` y `--quiet` corregido; `yt-update-notify` probado con
  toast real de dunst (ytwatch 0.1.0→0.3.0, ueberzugpp 2.9.10→2.9.11).
- 2026-11-13: `ytwatch-update` arreglado (checksum por nombre real de
  asset) y actualizado a 0.3.0. Avisos de actualización persistentes
  (`[actualizaciones]`, timeout 0) y clicables: probado clic izquierdo →
  kitty "dwm-setup: actualizar". Nota: tras cambiar `mouse_*` hay que
  reiniciar dunst.
- 2026-11-13: instalador aborta si Brave está abierto; verify de Brave
  pasa a JSON; VA-API por wrapper (`~/.local/bin/brave-browser` +
  `.desktop`). Ya aplicado del intento anterior: GRUB 2 s, nvidia fuera
  del boot, tmpfiles 1 h, wait-online off, newtab.html, at-spi2-core.
- 2026-11-13: ytwatch pin v0.3.0 + SHA verificado; tmpdir del tarball
  creado por el usuario y guardia anti-downgrade. Pendiente reejecutar
  `sudo ./install.sh` y comprobar que no hay `curl: (23)`.
- 2026-11-14: límite de carga de batería al 80 % (helper + unidad).
  Comprobado que el portátil (TUF FX504GE) expone
  `charge_control_end_threshold` (estaba en 100) y que `desktop-doctor`
  calcula la salud (42 %). Pendiente `sudo ./install.sh` para escribirlo
  y verificar.
- 2026-11-14: módulo `fan` (modo del ventilador) en A y B. En este TUF
  el backend es `fan_boost_mode` (normal/overboost/silent). Pendiente
  `sudo ./install.sh` (helper + sudoers) y prueba del clic con toast.
- 2026-11-14: daemons `dwm-setup-fan-auto` y `dwm-setup-power-auto`,
  estado `auto` del ventilador y perfiles de energía. Pendiente
  `sudo ./install.sh` (helpers + sudoers) y probar clic de 4 estados y
  cambio AC/batería.
- 2026-11-14: wallpaper dark B (`#14161f`, grano 0.32, viñeta 15 %,
  tira `1259x333+341+384`) aplicado en vivo y copiado a `local-dark.png`;
  backup del original en `local-dark-original.png`.
- 2026-11-14: anillo del logo de fastfetch por modo. `theme-mode
  --no-reload` en un HOME simulado: `light` → `Neofet-light.png`
  (`#8b9cf7`), `dark` → `Neofet-dark.png` (`#89b4fa`); el modo real no
  cambia. PNG vivos 640x640 de 8 bits, 19.764 px de anillo exactos y
  ninguno dentro del arte; `~/.cache/fastfetch/images` borrado.
  Pendiente ver `fastfetch` en kitty en ambos modos.
- 2026-11-14: Brave sigue el modo Catppuccin (ADR-114, superseded por
  ADR-115). Helper
  `bin/brave-theme` probado en HOME simulado: `dark` → Mocha, `light` →
  Latte, esquema 2/1, `follows_system_colors=false`; sin `user_color2`
  ni `color_variant2` (color base del pack); migración desde un perfil
  con ambos campos los borra; segunda pasada idempotente (mtime
  intacto); modo inválido rechazado; con `pgrep` simulando Brave
  abierto no se escribe `Preferences`. `theme-mode --no-reload` aplica
  el helper en ambos modos y `--dry-run` pasa. Pendiente reiniciar
  Brave y validar el toolbar oscuro base; Latte puede necesitar un
  arranque extra tras instalarse por policy.
- 2026-11-14: Brave «Usar GTK» + xsettingsd (ADR-115). Simulado con
  `xsettingsd` 1.0.2 extraído del `.deb`: carga el config y `SIGHUP`
  cambia `_XSETTINGS_SETTINGS` (serial 1→2, tema latte→mocha-black);
  `theme-mode --no-reload` renderiza `Net/ThemeName` en ambos modos y
  `brave-theme` migra de pack a GTK, es idempotente, devuelve 3 con
  Brave abierto y 0 si ya está aplicado. Pendiente `sudo ./install.sh`
  para instalar el paquete y desplegar
  `~/.config/xsettingsd/xsettingsd.conf`; después, con Brave abierto,
  pulsar `Super+Alt+T` y comprobar que el toolbar pasa de
  `catppuccin-mocha-black` a `catppuccin-latte-blue` y vuelve sin
  reiniciar. Comprobar también `xsettingsd` vivo y que
  `theme-mode status` sigue mostrando el modo correcto.
- 2026-11-14: NTP de Brave por re-render. Se probó
  `prefers-color-scheme`: el toolbar de Brave cambia con xsettingsd,
  pero el contenido web no actualiza el media query (ni con pestaña
  nueva). Se descartó. La NTP vive en
  `~/.local/share/dwm-setup/newtab.html` (usuario), `/usr/share/...` es
  un symlink y `theme-mode` la re-renderiza con `COLOR_BG`/`COLOR_FG`.
  También se quitaron los colores fijos de `gtk-3.0.css`/`gtk-4.0.css`
  (solo estructura): con ellos, el toolbar tampoco cambiaba en caliente.
  Probado en vivo: con `gtk.css` estructural y `xsettingsd`, el toolbar
  de Brave pasó de `#eff1f5` a `#1a1a24` y volvió sin reiniciar. El
  contenido web no cambió con `prefers-color-scheme` (ni con un proceso
  nuevo), por eso la NTP se re-renderiza. NTP de usuario: light
  `#eff1f5`, dark `#0d0d14`. Pendiente `sudo ./install.sh` para crear
  el symlink `/usr/share` y prueba visual final; las pestañas abiertas
  necesitan `Ctrl+R`.
- 2026-11-14: UFW y Bluetooth en polybar. Simulado: helper UFW
  (status/rules/enable/disable) con fakes; estado UFW on/off; estado
  Bluetooth conectado/off; menú Bluetooth conectando un emparejado y
  seleccionando `bluez_output.*`; `visudo -cf` del sudoers UFW OK.
  Pendiente `sudo ./install.sh` y prueba en vivo: SSH desde el cliente,
  DHCP/Wi-Fi con UFW activo, auriculares Bluetooth con audio, menú de
  escaneo/pareo y barra A/B. Conteos: A 15 (16 con backlight), B 17
  (18 con backlight). Corregido falso negativo: `ufw --force enable`
  podía dejar `ufw.service` inactivo; ahora se hace `systemctl enable
  --now ufw` y el estado se lee de `ufw status` con `LC_ALL=C`.
  Bluetooth arranca apagado (`AutoEnable=false`); el servicio sigue
  activo y el módulo puede encenderlo desde el menú.
- 2026-11-14: rofi, esquinas y bordes. `config.rasi` usa radio 12 y el
  listview con padding en vez de borde; `powermenu.rasi` tiene
  `background-color` en `window`, radio 12 y `mainbox`/`listview`/
  `element`/`element-text`/`element-icon` transparentes para evitar
  bloques blancos dentro del borde. Probado visualmente en Xorg en
  claro; `-dump-theme` correcto en ambos. Fallback documentado: borde
  en `mainbox` con `window { border: 0; }` si rofi 1.7.5 no redondeara
  el borde de `window` (no fue necesario).
- 2026-11-14: rofi pasa a sidebar izquierdo a altura completa, con
  borde (`border: 2px`) y sin redondeo (`border-radius: 0`). En la
  sesión viva, drun y powermenu salen en 360x1080, en `x=0,y=0`, con
  borde visible y esquinas cuadradas; `listview lines: 0` ocupa el
  alto. `keybindings_rofi.sh` y `screenshot.sh` ya no pasan `-width`.
  Probados visualmente drun y el tema de powermenu; pendiente menús
  largos y claro/oscuro. Picom excluye rofi de sombra, redondeo y fade
  (`class_g = 'Rofi'`/`class_i = 'rofi'`); verificado que drun mantiene
  esquinas cuadradas con picom activo.
- 2026-11-14: Bluetooth, pareo y audio. Faltaba
  `libspa-0.2-bluetooth` (WirePlumber: plugin BlueZ ausente); añadido
  a `AUDIO_PKGS` y `restart_bluetooth_audio`. El menú ahora pareja con
  `--agent NoInputNoOutput`, verifica `Paired: yes`/`Connected: yes`
  con reintentos (~3 s; evita el falso fallo por carrera de BlueZ),
  muestra el error real y escribe
  `~/.local/state/dwm-setup/bluetooth.log`. Simulado con fakes: pareo
  exitoso con `info` retrasado, pareo exitoso normal y fallo de
  autenticación con notificación clara. Añadidos `rtkit`, nombre a 28
  caracteres y menú `Perfil de audio` (A2DP/SBC-XQ/HFP); simulado que
  HFP fija `bluez_input.*` como source. Pendiente probar con los GM2
  Pro en modo emparejamiento y comprobar sink `bluez_output.*`.
- 2026-11-15: audio automático por dispositivo. `audio-watch.sh` aplica
  jack > USB > Bluetooth > HDMI > altavoces internos solo cuando cambia
  la firma del hardware, con dos lecturas seguidas para no reaccionar al
  hueco de un cambio A2DP↔HFP; simulado con `pactl` falso: HDMI,
  Bluetooth (sink + loopback, sin `bluez_input_internal`), jack, USB,
  prioridad completa, watcher con cambios en caliente (HDMI → Bluetooth
  → jack) y un hueco breve de Bluetooth que no provoca cambio de salida.
  `audio-switch.sh` elige `output:hdmi-stereo+input:analog-stereo` y no
  arrastra el volumen entre sinks. En vivo con HDMI conectado, el perfil
  pasó de `output:hdmi-stereo` a
  `output:hdmi-stereo+input:analog-stereo`, el source por defecto pasó
  de `hdmi-stereo.monitor` a `alsa_input...analog-stereo` y `parecord`
  grabó 3 s sin errores. Se forzó el monitor de HDMI como source por
  defecto y el watcher lo corrigió solo en ~7 s. Menú `Perfil de audio`
  probado con fakes:
  `Automático` aplica `a2dp-sink`, fija el sink y el loopback, no el
  source `_internal`. Menú de encendido probado con fakes: reconecta el
  headset `Trusted` con `Icon: audio-headset` y omite un teclado.
  `50-dwm-setup.conf` de WirePlumber instalado;
  `wpctl settings bluetooth.autoswitch-to-headset-profile` = `true`.
  Pendiente: con los GM2 Pro, grabar y comprobar el salto automático a
  `headset-head-unit` y la vuelta a `a2dp-sink`, además de la
  reconexión (`Bonded`).
- 2026-11-15: menú contextual de Brave con doble recuadro. Con picom
  activo se veía el menú y, detrás, un segundo recuadro redondeado gris;
  con picom parado el menú quedaba limpio. La ventana del menú es
  `_NET_WM_WINDOW_TYPE_MENU`, override-redirect, ARGB, 475x330, con
  márgenes transparentes para la sombra que dibuja Chromium; picom
  añadía su propia sombra (`radius 10`, `opacity 0.35`) visible a través
  de esos márgenes. Solución: añadir `window_type = 'menu'`,
  `'popup_menu'`, `'dropdown_menu'` y `'tooltip'` a `shadow-exclude` en
  `templates/picom/picom.conf.in` (sin tocar `corner-radius`). Probado
  con una config temporal: el recuadro desaparece y se mantiene la sombra
  propia del menú; también se comprobó con picom parado como control.
  Aplicado a la sesión viva reiniciando picom; pendiente la captura
  final con Brave abierto.
- 2026-11-15: mpv en la iGPU y temperatura del paquete. Con un vídeo
  720p H.264 local, mpv por defecto usó 45,5 % de CPU, decodificación
  software y 105 MiB en la NVIDIA; con `hwdec=vaapi` + EGL/Mesa (Intel)
  bajó a 17–18 % de CPU y 0 en la dGPU; con Vulkan Intel, 22 %. Se
  instaló `mpv.conf` (`hwdec=vaapi`, `vo=gpu`, `gpu-api=opengl`,
  `gpu-context=x11egl`) y el wrapper `~/.local/bin/mpv` con
  `__EGL_VENDOR_LIBRARY_FILENAMES=50_mesa.json`, que respeta
  `prime-run`. El módulo `temp` pasó de `thermal-zone=0` (acpitz) a un
  script que lee `coretemp/temp1_input`; en vivo la barra pasó de 66 °C
  ACPI a 67–84 °C del paquete real (según carga). `brave://gpu` con el
  perfil real: Canvas/Compositing/Rasterization/Video Decode/WebGL/
  WebGPU hardware accelerated; GPU1 Intel *ACTIVE*, Optimus true;
  `--enable-features=VaapiVideoDecoder` presente. Red: YouTube TTFB
  0,33–0,42 s y total 0,56–0,87 s; portada en pestaña fría ~6 s por
  JavaScript/miniaturas. Pendiente: reiniciar ytwatch para que el vídeo
  ya abierto use el mpv nuevo (los siguientes ya lo usan).
- 2026-11-15: arranque y limpieza. `lib/boot.sh` pasa a
  `GRUB_TIMEOUT=0` + `GRUB_TIMEOUT_STYLE=hidden` (Shift/Esc para el
  menú) y `cleanup_packages` hace `apt-get clean`; el dry-run los
  muestra y termina con rc=0. En vivo quedan pendientes porque `sudo
  -n` no está disponible: `/tmp/opencode/apply-optimizations.sh`
  limpia `/var/cache/apt` (3,2 GB), purga 6.12.116/headers y actualiza
  GRUB. La dGPU (P0, 1493/3504 MHz, 51 °C, sin procesos, `prime-run`
  OK) se prueba con `/tmp/opencode/nvidia-ondemand-test.sh`; si
  `modprobe -r` la apaga y `prime-run` la recarga, se implementa la
  carga bajo demanda. Governor, fan y Brave no se tocan.
- 2026-11-16: actualizaciones manuales y ventilador. `lib/boot.sh`
  enmascara `apt-daily-upgrade.timer` (el servicio corría 1,07 s en el
  boot); `apt-daily.timer` sigue para metadatos. `lib/verify.sh` exige
  GRUB 0/hidden y el timer enmascarado. La prueba de overboost mostró
  que el ventilador funciona (paquete 79 → 62–66 °C), aunque el EC
  reporta `cpu_fan=0`/`pwm1=0 %`. Dry-run rc=0; falta aplicar el timer
  en vivo con sudo.
- 2026-11-16 14:49: instalación completa real en el ASUS FX504GE con
  `sudo -A ./install.sh --yes` (contraseña vía rofi askpass), modo
  `light`/Latte. `install.sh` conservó el modo guardado; `run_root`
  volvió a pedir sudo solo si hacía falta y la limpieza final no se
  saltó. Resultado: **verificación estática correcta**, `apt-get clean`
  OK, `apt-daily-upgrade.timer=masked/inactive`, `apt-daily.timer`
  activo, GRUB 0/hidden y picom con menús excluidos. Código 0.
- 2026-11-16: bloqueo con wallpaper desenfocado. `desktop-safe lock`
  llama a `i3lock-fancy.sh`, que elige el wallpaper light/dark, aplica
  `convert -blur 0x18` una vez y cachea en
  `~/.cache/dwm-setup/lockscreen-<modo>-0x18.png`; luego usa `i3lock -i`
  normal. Prueba con `i3lock` falso: light y dark generan cache
  (239/234 KB) y la llamada correcta; la primera generación light tardó
  1,24 s y las siguientes son instantáneas. Sin captura por bloqueo.
  Pendiente la prueba visual con `Super+Shift+L` y suspensión.
- 2026-11-16: `theme-mode` pisaba el locker. `bin/theme-mode` renderizaba
  `i3lock-fancy.sh` desde el store viejo (color sólido) y
  `Super+Alt+t` revertía el blur. Se sacó el locker del render de
  `theme-mode` y de `install_theme_store`, se borró la copia vieja del
  store y se restauró el script vivo desde la plantilla. Prueba:
  `theme-mode --no-reload light` no cambió el mtime del script y sigue
  usando `i3lock -i`. Pendiente la prueba visual de `Super+Alt+t` +
  `Super+Shift+L`.

### ytwatch: sin chat replay y con wmctrl (2026-11-17, ADR-132)

- Al reproducir un **LIVE VOD**, ytwatch abría su chat replay en
  `127.0.0.1:<puerto>` con Brave. No era el vídeo: el vídeo va a mpv.
- `[chat] enabled = false` en `~/.config/ytwatch/config.toml` y en
  `templates/ytwatch/config.toml.in`. Comprobar con
  `grep -A2 '^\[chat\]' ~/.config/ytwatch/config.toml`.
- `wmctrl` instalado y añadido a paquetes/verify; `ytwatch doctor`
  devuelve **“All required programs found”**.
- Pendiente: abrir un LIVE VOD desde el TUI y confirmar que solo aparece
  mpv (sin ventana de Brave).

### Pantalla automática 120/60 y hotplug (2026-11-17, ADR-133)

- `display-setup.sh apply` en una sesión que ya está en 120 **no cambia
  el modo** (sin parpadeo). La primera pasada puede tardar lo que tarde
  `xrandr`, pero no hay modeset.
- Prueba de política: `DISPLAY_REFRESH=60 ... apply` deja
  `1920x1080|60.00`; `DISPLAY_REFRESH=auto ... apply` vuelve a
  `1920x1080|120.00`. Comprobar en `~/.local/state/dwm-setup/display.log`.
- `DISPLAY_REFRESH=auto` con el monitor actual:
  `xrandr` debe mostrar `120.00*`.
- `DISPLAY_SETUP_DRY_RUN=1` imprime los `xrandr` que haría sin aplicarlos.
- Hotplug: `autostart` lanza `display-setup.sh watch`; se puede comprobar
  con `pgrep -af 'display-setup.sh watch'`. El watcher lee
  `/sys/class/drm/*/status` cada 2 s (sin DDC) y solo llama a `xrandr`
  cuando cambia la firma.
- `~/.config/dwm-setup/display.conf` debe existir con `layout=` y
  `refresh=`. Los cambios de `refresh=60` se aplican al reconectar o al
  reiniciar la sesión; para aplicarlo ya: `display-setup.sh apply`.
- Casos a probar en hardware real: conectar un monitor 60 Hz (debe quedar
  a 60), reconectar el HDMI 120 Hz (debe volver a 120) y arrancar con el
  monitor apagado.

### Geometría de bspwm 2/15 (2026-11-17, ADR-134)

- `bspc config border_width` debe devolver `2` y `bspc config window_gap`
  debe devolver `15`.
- En el `bspwmrc` instalado:
  `grep -E 'border_width|window_gap' ~/.config/bspwm/bspwmrc`.
- `install.sh --dry-run` renderiza la plantilla nueva; una instalación
  limpia debe arrancar con borde 2 y gap 15 sin tocar nada a mano.
- El padding (30 px) sigue viniendo de la posición de polybar.

### Herdr TUI (terminal) y zsh (2026-11-17, ADR-135)

- `herdr --version` → 0.9.5; binario estático en `~/.local/bin/herdr`.
  El servidor se comprueba con `herdr status` y se para con
  `herdr server stop`.
- Atajos: `alt+k` nueva pestaña (pide nombre), `alt+o` siguiente,
  `alt+q` cerrar pestaña, `alt+n` sidebar, `ctrl+alt+d` nuevo space,
  `ctrl+alt+n/p` navegar y `ctrl+alt+q` cerrar con confirmación.
- Comprobado con `xdotool`: el panel pasa de expandido a colapsado y
  vuelve con `alt+n`; `ctrl+alt+d` crea un workspace y `ctrl+alt+q` +
  `Enter` lo cierra.
- zsh: con `herdr` en PATH, `bindkey "^[n"`, `"^[N"`, `"^[k"`, `"^[q"`
  y `"^[^D"` deben devolver `undefined-key`. En shells abiertas antes
  del cambio hay que abrir una nueva o `exec zsh`.
- La app gráfica `herdr-app` y su `herdr-core`/`hc` no se usan.

### Herdr: renombrar workspace (2026-11-17)

- `ctrl+alt+r` abre el diálogo **rename workspace** con el nombre actual.
- `Ctrl+C` limpia el campo (el pie muestra `^C clear`), `Enter` guarda
  y `Esc` cancela. `Ctrl+A` **no** selecciona todo: no usarlo para
  reemplazar.
- Comprobado: renombrar a `prueba2` y volver a `~` con
  `herdr workspace list`.
- `ctrl+alt+n/p` siguen navegando; Herdr desactiva una de las dos si se
  repite la misma tecla.

### Herdr: splits (2026-11-17)

- `Ctrl+B` + `Enter` → split a la derecha (`split_vertical`).
- `Ctrl+B` + `Alt+Enter` → split abajo (`split_horizontal`).
- Se mantienen `prefix+v` y `prefix+minus`.
- Comprobado con `herdr pane list`: aparecen los panes nuevos y se
  cierran con `herdr pane close <id>`.
- `Ctrl+Space` sigue siendo el toggle flotante de sxhkd.

### Herdr: Alt+Q en cascada (2026-11-17)

- `alt+q` ejecuta `$HOME/.local/bin/herdr-close` (comando `[[keys.command]]`
  de tipo `shell`). Usa `HERDR_ACTIVE_*` y `HERDR_BIN_PATH`.
- Comprobado en un workspace temporal:
  1. Última pestaña/pane → **no** cierra; lanza el aviso por `notify-send`.
  2. Dos pestañas → cierra la pestaña activa.
  3. Split → cierra solo el pane.
- `Ctrl+Alt+Q` + `Enter` sigue cerrando el workspace con confirmación.
- Si Herdr no exporta `HERDR_ACTIVE_*`, el comando no hace nada; revisar
  que la versión sea 0.9.5 o superior.

### Herdr: Ctrl+Q y Alt+Q sin aviso (2026-11-17)

- `alt+q` (helper `herdr-close`): cierra pane; si es el último, cierra
  pestaña; en la última pestaña **no hace nada** (sin `notify-send`).
- `ctrl+q` cierra el workspace con el diálogo nativo `Close workspace?`
  (`↵ confirm` / `esc cancel`). También siguen `ctrl+alt+q` y
  `prefix+shift+d`.
- Comprobado: `ctrl+q` + `Enter` cerró el workspace de prueba; las
  notificaciones “Última pestaña” no aumentaron al pulsar `alt+q`.
- zsh: `bindkey "^Q"` debe devolver `undefined-key` con Herdr instalado.

### Herdr sigue el modo de color (2026-11-17, ADR-136)

- `theme-mode dark` debe dejar en `~/.config/herdr/config.toml`:
  `name = "catppuccin"`, `auto_switch = false`,
  `sidebar_bg = "#181825"`, `panel_bg = "#1e1e2e"`.
- `theme-mode light` debe dejar `name = "catppuccin-latte"` y
  `sidebar_bg/panel_bg = "#eff1f5"`.
- Con Herdr abierto, el comando debe listar `herdr` en
  `recargado:` y el sidebar/barra de pestañas cambia sin reiniciar la
  TUI. Comprobado con capturas en ambos modos.
- `herdr config check` debe devolver `config: ok`.
- El contenido de los panes (opencode, etc.) no cambia: usa su propio
  tema.

### Herdr: config TOML válido (2026-11-17)

- `grep -c '^\[theme\.custom\]' ~/.config/herdr/config.toml` debe dar
  `1`; dos tablas `[theme.custom]` hacen que Herdr rechace el config y
  muestre la barra “config.toml invalid”.
- `herdr config check` debe devolver `config: ok`.
- `theme-mode light` y `theme-mode dark` deben dejar una sola sección y
  recargar Herdr; usar `herdr server reload-config` **sin sudo**.
- Si hay duplicados, la versión del repo de `theme-mode` los funde en la
  primera sección antes de escribir.

### opencode sigue el modo (2026-11-17, ADR-137)

- `theme-mode light` deja en `~/.config/opencode/cli.json`:
  `theme.name = "catppuccin"`, `theme.mode = "light"`.
- `theme-mode dark` deja `theme.mode = "dark"`.
- Con opencode abierto, `recargado:` debe incluir `opencode` y el TUI
  cambia de tema sin reiniciar ni perder la sesión. Comprobado con
  capturas en ambos modos.
- `theme-mode --no-reload` escribe el config sin ejecutar
  `opencode reload`.
- Si el JSON no existe o no hay proceso de opencode, no se toca nada.
- `$schema`, `keybinds` y `plugins` se conservan.

### Dark unificado (2026-11-17, ADR-138)

- `theme-mode dark` deja en Herdr: `sidebar_bg/panel_bg = "#0d0d14"`,
  `active_row_bg = "#1a1a24"`, `selection_bg = "#26262f"`.
- `theme-mode light` deja `#eff1f5`, `#e6e9ef`, `#bdd0f5`.
- opencode dark: `theme.name = "system"`, `theme.mode = "dark"`; light:
  `catppuccin`/`light`.
- `fastfetch` en dark debe mostrar el logo con disco `#0d0d14` (no el
  círculo blanco) y, tras re-ejecutarlo, `Desktop Theme` =
  `catppuccin-mocha-black` y `Icon Theme` = `Catppuccin-Mocha`.
- Capturas de control: terminal/sidebar/tab bar/opencode/logo con el
  mismo fondo; light sin cambios.

### opencode tema mocha-black (2026-11-17)

- `theme-mode dark` debe dejar `cli.json` con
  `theme.name = "mocha-black"`, `theme.mode = "dark"` y crear
  `~/.config/opencode/themes/mocha-black.json`.
- Ese JSON debe ser **V2**: `base.background.base = "#0d0d14"`,
  `raised.base = "#0d0d14"`, `raised.high = "#1a1a24"`,
  `raised.max = "#26262f"` y una paleta `dark.hue` completa. Un archivo
  V1 (`defs`/`theme`) se ignora y el TUI usa el tema por defecto.
- `theme-mode light` deja `theme.name = "catppuccin"` y `mode = "light"`.
- Con opencode abierto, `opencode reload` cambia entre temas ya
  conocidos. Si el archivo `mocha-black.json` es **nuevo**, hay que
  reiniciar el TUI una vez: la lista de temas se lee al arrancar.
- En un TUI nuevo, el panel de contexto debe tener el mismo fondo
  `#0d0d14` que el terminal, las tarjetas `#1a1a24` y `Build` el azul
  `#89b4fa`; no debe aparecer `#0a0a0a`, `#141414` ni `#1e1e1e`.
- `python3 -m json.tool ~/.config/opencode/themes/mocha-black.json`
  debe ser válido.
- `templates/opencode/mocha-black.json` está en el store y en los
  requeridos de `install.sh`.

### Previews reales en Herdr (2026-11-17, ADR-139)

- En una pane de Herdr, `kitty +kitten icat` emite los escapes
  (`\x1b_G...`) pero no se ve imagen, ni en una sesión nueva ni con
  `[terminal] kitty_graphics = true`.
- Dentro de Herdr, `ranger` (imagen y PDF) y `ytwatch lofi` deben
  mostrar la preview real. Las funciones de zsh exportan `WINDOWID`;
  sin ellas ueberzug no encuentra la ventana de kitty.
- Al cambiar de pestaña, la preview de la anterior debe ocultarse y
  reaparecer al volver (daemon `preview-sync.py`, etiqueta
  `_DWM_SETUP_TAB` en las ventanas `ueberzugpp`).
- `ytwatch doctor` debe decir `thumbnails ueberzugpp, output: x11`.
- `command -v ueberzugpp` debe resolver a `~/.local/bin/ueberzugpp` (el
  wrapper) y este debe existir y ser ejecutable.
- `command -v ueberzug` debe resolver a `~/.local/bin/ueberzug` (el
  wrapper de ranger), y `~/.config/ranger/rc.conf` debe usar
  `preview_images_method ueberzug`.
- Dentro de Herdr, la preview de ranger (imagen y PDF) debe quedar
  **dentro del recuadro**, con el borde visible por los cuatro lados; el
  wrapper suma 1 celda a `x`/`y` y resta 2 a `max_width`/`max_height`.
- Fuera de Herdr el wrapper de ranger ejecuta `/usr/bin/ueberzug` sin
  cambios; la preview debe verse como siempre.
- Dentro de Herdr, la miniatura de ytwatch debe quedar **dentro del
  panel PREVIEW**, no sobre la lista de resultados: el wrapper suma el
  sidebar (26 columnas) y la barra de pestañas (2 filas) a `x`/`y`.
- Fuera de Herdr (`HERDR_ENV` sin definir) el wrapper ejecuta
  `/usr/bin/ueberzugpp` sin cambios; ytwatch debe seguir funcionando en
  una kitty normal.
- La config de Herdr no debe llevar `[terminal]` (se dejó como estaba).
- La preview de ranger no debe usar chafa: se retiró por su calidad.

### Herdr reproducible (2026-11-17, ADR-140)

- `./install.sh --dry-run` debe mostrar la descarga de `herdr-linux-x86_64`,
  la instalación en `~/.local/bin/herdr` y el render de
  `~/.config/herdr/config.toml`, sin descargar ni escribir nada.
- `~/.local/bin/herdr --version` debe responder `herdr 0.9.5`.
- `~/.local/bin/herdr config check` debe dar `config: ok`.
- El config debe contener `onboarding = false`, `alt+k` y
  `herdr-close`, y el tema debe coincidir con el modo activo
  (`catppuccin`/`catppuccin-latte`, `#0d0d14`/`#eff1f5`).
- `theme-mode --no-reload light` y `theme-mode --no-reload dark` deben
  actualizar `theme.name`, `sidebar_bg`, `panel_bg`, `active_row_bg` y
  `selection_bg` a los valores de la paleta (`#eff1f5`/`#e6e9ef`/
  `#bdd0f5` en light; `#0d0d14`/`#1a1a24`/`#26262f` en dark).
- `--no-herdr` debe omitir el bloque sin tocar el config ni el binario.
- `herdr-close` debe quedar ejecutable en `~/.local/bin`.
- Pendiente: instalación real desde cero en VM Debian 13.
