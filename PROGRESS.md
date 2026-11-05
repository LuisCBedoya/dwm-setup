# Progreso — fase 1b (bspwm + polybar)

Última actualización: 2026-11-02

## Resumen

La fase 1b está implementada y validada en la sesión viva del host de
referencia (Debian 13, Intel UHD 630 + NVIDIA GTX 1050 Ti Mobile,
1920x1080). El instalador se ha corregido para que los backups se hagan
antes de escribir, el home quede con el propietario correcto, `bspwmrc` sea
ejecutable, la barra arranque y la verificación final no falle.

- Estado del código: implementado; `bash -n`, `sh -n`, `--dry-run` y
  verificación sobre home simulado pasan.
- Estado de validación real: **sesión viva validada**; falta la instalación
  desde cero en VM Debian 13 minimal.
- Sesión: `startx` manual desde TTY; sin display manager ni auto-login.
- Barra A: 12 módulos; B: 14 módulos. Logo StumbleUpon, 5 workspaces,
  red unificada, servicios systemd y fecha al final.

## Validación viva (2026-10-24)

Host: Debian GNU/Linux 13 (trixie), kernel 6.12, Xorg 1920x1080, NVIDIA 550
instalado (Xorg usa Intel `modeset`), PipeWire 1.4.2.

Procesos comprobados:

- `bspwm 0.9.10`
- `sxhkd 0.6.2`
- `polybar 3.7.2`; variante A con **12 módulos** y variante B con
  **14 módulos**: `logo`, `bspwm`, `polypomo`, `temp`, `memory`, `cpu`,
  `network`, `services`, `pipewire`, `battery`, `date`, `updates`.
  Con backlight se añade `brightness` (A 13 / B 15).
- Sin compositor. La variante B usa `pseudo-transparency` de polybar para
  dejar transparente solo el centro.
- `dunst 1.12.2`, `lxpolkit`, `udiskie -N -a`, `xss-lock` activos.
  Las críticas se cierran a los 10 s. Volumen máximo 120 % en pasos de 10.
- `BAT1`, `ACAD`, `enp3s0`, `wlo1`, batería y volumen visibles en la barra.
  La red es un solo módulo: con WiFi down y Ethernet up muestra `󰈀 connected`;
  sin conexión muestra `󰖩 NoC`. El layout `latam` se aplica con `setxkbmap` pero ya no
  ocupa un módulo de la barra.
- `notify-send` funciona.
- `low_bat_notifier.sh` avisa al 10 % descargando y al 99 % cargando
  (`Charging`/`Full`), una vez por evento. Probado con batería simulada
  mediante `POWER_SUPPLY_DIR` y un `notify-send` falso.
- `services.sh` cuenta los servicios systemd en ejecución y abre un menú
  `dmenu`/`rofi` con los servicios y su estado `enabled/disabled/static`.
  Al elegir uno consulta `systemctl is-active` y ofrece detener/reiniciar
  si está activo, o iniciar/reiniciar si está parado. Probado con un
  `systemctl` y un menú simulados; la variante B cargó 14 módulos.
- `volume.sh` limita el volumen a 120 % y cambia de 10 en 10; probado
  subiendo 80→90→100→110→120 y bajando a 110.
- Las notificaciones críticas de dunst se cierran a los 10 s; comprobado con
  `dunstctl count displayed`. El módulo de brillo queda condicionado a que
  exista backlight; en este host no hay `/sys/class/backlight`.

Comprobaciones:

- `~/.config/bspwm/bspwmrc` y `~/.xinitrc`: `0755`; `.xinitrc` termina en
  `exec bspwm` y ya no lanza `kitty`.
- Sin placeholders `@...@` en las configuraciones vivas.
- `low_bat_notifier.sh` contiene `BATTERY="BAT1"`.
- Sin ficheros root en `~/.config/{bspwm,sxhkd,polybar,dunst,rofi,kitty}`.
- `desktop-doctor` (repo) muestra todos los binarios/configs/procesos OK;
  solo avisa de que no hay cámara.
- Home simulado (`/tmp/opencode/fakehome`) renderizado y `verify_install`
  pasa con código 0.

## Pasada de estabilidad (2026-10-25)

Se verificó que el repo y la sesión viva siguen pasando `--dry-run` y
`verify_install`. No se desinstalaron paquetes ni se deshabilitaron
servicios: `redshift`, `ssh`, `bluez`, `playerctl`, `acpi`,
`network-manager-gnome`, `flameshot`, `dmenu` y el grupo de compilación se
mantienen. Solo se sincronizaron formatos seguros de los scripts de red y
volumen.

## VLC oscuro (2026-10-25)

Se activó `qt-dark-palette=1` en el `vlcrc` vivo y se añadió el módulo
`lib/vlc.sh` con su plantilla `templates/vlc/vlcrc.in`. Probado en vivo:
VLC arranca con la interfaz en negro.

## Tema GTK e iconos (2026-10-25)

Se vendorizó Windows-10-Dark en el repo y se añadió la instalación de
settings GTK2/3/4, GSettings en autostart, Papirus y `librsvg2-common`.
El tema ocupa unos 3 MB dentro del repo.

## Perfil gráfico Intel/NVIDIA (2026-10-25)

Se añadió detección de Intel/NVIDIA y generación de
`/etc/X11/xorg.conf.d/20-modesetting.conf` con modesetting/glamor/DRI3.
NVIDIA queda como PRIME/offload. `--intel-glitch` permite probar
`enable_fbc=0` (y PSR en eDP) sin aplicarlo por defecto.

## Neovim desde ranger (2026-10-25)

Se añadió Neovim a los paquetes y reglas prioritarias en `rifle.conf` para
abrir texto, código y Markdown con `nvim`. La edición se hace en la misma
terminal de ranger.

## Ranger, zathura y VLC (2026-10-25)

Se añadió ranger como gestor desde terminal, zathura para documentos,
VLC para vídeo y previews con ueberzug/poppler/ffmpegthumbnailer. EPUB se
resuelve con `zathura-pdf-mupdf` 0.4.6 compilado contra `libmupdf-dev` de
Debian 13, sin apvlv. No se modifica el atajo de Thunar.

## Shell zsh y lsd (2026-10-25)

Se añadió al instalador `zsh`, `zsh-autosuggestions`, `lsd`, Oh My Zsh con
cypher y la configuración de lsd. La `.zshrc` conserva keybindings,
opciones, aliases y autosuggestions. La shell de login se cambia a
`/usr/bin/zsh`; kitty usa Nord, `font_size 13` y zsh.

## Mapa de atajos i3 (2026-10-24)

Se adaptó `templates/sxhkd/sxhkdrc.in` a los atajos de i3 del usuario,
manteniendo gaps 10, borde 2 y el wallpaper actual. El rediseño final
redujo a 5 escritorios; los ajustes manuales posteriores retiraron `dots`
y movieron `updates` al inicio de la derecha:

- Apps: `Super+Return` kitty, `Super+Shift+s` scrot región+portapapeles,
  `Super+Shift+p` pcmanfm, `Super+Shift+b` chromium, `Super+Shift+v`
  codium, `Super+Shift+i` ristretto, `Super+Shift+a` lxappearance y
  `Super+Shift+d` rofi run. Las apps que no están en fase 1 quedan como
  bindings no-op.
- `Super+Shift+e` pasa a logout; el editor se mueve a `Super+Shift+v`.
- `Alt+Tab` / `Alt+Shift+Tab` ciclan ventanas visibles del escritorio.
- `Super+Ctrl+Tab` / `Super+Ctrl+Shift+Tab` cambian al escritorio
  siguiente/anterior.
- `Super+r` + `h/j/k/l` redimensiona con cadena de sxhkd (`:`); `Escape`
  sale. Se retiró `Super+Alt+{flechas}`.
- Se añadieron `Super+Shift+c` (reload), `Super+Shift+r` (restart),
  `Super+Shift+space` (floating), `Super+a` (parent) y `Super+b/v`
  (split h/v por preselección). `Super+Alt+p` cicla A/B y su posición
  superior/inferior. El padding de bspwm se invierte para que la barra
  inferior no quede tapada.
- Se mantienen los extras: Thunar, lock, rofi drun, capturas, flags y
  multimedia.
- `Super+s/w/e` de i3 (stacking/tabbed/toggle split) no tienen equivalente
  exacto en bspwm; no se mapean en esta iteración.

Validado en vivo: `sxhkd` recarga el nuevo `sxhkdrc` sin errores; el
`bspwm_resize h/l` cambia el ancho en un layout lado a lado y el modo
`Super+r` se cierra con `Escape` o a los 6 s. `Alt+Tab`/`Alt+Shift+Tab` ciclan
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

Se partió de la barra de referencia y se aplicaron los ajustes manuales
del usuario:

- 5 escritorios (`1-5`); `bspwmrc` y `sxhkd` ajustados.
- Logo StumbleUpon `U+F1A4` en `font-0` (`%{T0}`), padding 1 y sin espacio
  final.
- Workspace enfocado con caja blanca, texto oscuro, font-1 y padding 1.
- Orden derecha: `updates`, `services`, `polypomo`, `temp`, `memory`,
  `cpu`, `network`, `pipewire`, `battery`, `date`.
- `updates` al inicio de la derecha muestra calavera `U+F4F9` + número,
  sin `#`; si N=0 no muestra nada. `date` queda al final.
- Sin etiquetas `[T]`, `[M]` ni `[C]`.
- Red unificada: `󰈀 connected` si hay Ethernet; si no, `󰖩 connected` si
  hay WiFi; si no hay ninguna, `󰖩 NoC`. Sin SSID; Ethernet tiene prioridad. Clic en el módulo abre el menú WiFi (`nmcli`). `NETWORK_FAKE=wifi|eth|both|none` permite probar los estados.
- Variante A sin `dots` ni `xkeyboard`; sin `wlan`/`eth` separados.
- Pomodoro pausa con `U+F04C` (dos barras).
- Fuentes: `font-1 = 10`, `font-3 = 13`; logo en `font-0 = 11`.
- Separación: `module-margin-left/right = 0`; `updates`/`polypomo` 1/1;
  padding 1 en `temp`, `memory`, `cpu`, `pipewire`, `battery` y `date`;
  `network` 0; `cpu` muestra `%` y añade `%{O8}` a la derecha; volumen y
  batería juntos.
- Con `UPDATES_FAKE_FILE=0` el módulo de actualizaciones desaparece y no
  muestra `# 0` (probado en vivo).
- Polybar cargó 12 módulos sin errores; capturas `bar-design3.png`
  (diseño inicial), `bar-spacing-final.png` (separación) y
  `bar-user-final.png` (barra final).

## Variante B — referencia (2026-10-24)

Variante B compacta, ajustada manualmente por el usuario:

- 14 módulos: `date`, `day`, `updates`, `polypomo` y `der` a la izquierda;
  `bspwm` al centro; `izq`, `services`, `temp`, `memory`, `cpu`, `network`,
  `pipewire` y `battery` a la derecha.
- 5 workspaces con glifos Font Awesome (`//`), padding 0.
- Barra de 18 px, transparente; fondos de módulos oscuros.
- `temp` conserva `format-warn-background` en warning; las flechas usan
  `${colors.module-bg}`.
- Fuentes como la variante A: `font-1=10`, `font-3=13`; iconos T1/T3,
  sin `font-6`; `font-4` Font Awesome para los círculos de bspwm.
- `memory` y `network` usan iconos MDI alineados; `izq` es una flecha
  powerline.
- Añadidos `date.ini` y `updates.ini` que faltaban; updates muestra el
  contador con el script de apt.
- `polybar-variant referencia|actual` cambia y guarda la elección.
- Polybar carga 14 módulos sin errores; captura `bar-variant-b.png`.
- La variante A no se toca.

## Modo resize con sxhkd hijo (2026-10-28)

- `Super+r` crea el estado y muestra `RESIZE` al instante.
- `resize-mode.sh` arranca un sxhkd hijo con `resize-mode.sxhkdrc` que
  captura solo `h/j/k/l` y `Escape`; el resto del teclado sigue normal.
- Cada `h/j/k/l` llama a `bspwm_resize` y refresca el TTL de 6 s.
- `Escape` o 6 s sin teclas matan al hijo y quitan `RESIZE`.
- El sxhkd principal ya no usa la cadena `super + r : h/j/k/l`, así que
  no roba `h/j/k/l` después de redimensionar.
- `h` redimensiona hacia la derecha y `l` hacia la izquierda; paso 20 px.
- Con una sola ventana tileada no hay cambio de tamaño (semántica de i3).
- `install_sxhkd` renderiza también `resize-mode.sxhkdrc` y recarga el
  sxhkd principal con `SIGUSR1`.
- Probado con XTEST: `Super+r` → `RESIZE` y un solo `sxhkd` hijo;
  `h`/`l` sobre una ventana flotante 958→978→958; `Escape` y 7 s de
  espera dejan el estado vacío y matan al hijo; una `h` posterior no
  redimensiona.
- Probado en tileado (escritorio 2): `Super+r` + `h` cambia el
  `splitRatio` y `Escape` limpia; `Super+2`/`Super+1` siguen funcionando.
- Una sola ventana tileada no cambia de tamaño (semántica de i3).
- Capturas `bar-clean2-mode-crop.png` y `mode-before-h-bar.png`.

## i915, xinitrc y single-instance (2026-10-26)

- i915: `enable_fbc=0` por defecto en equipos Intel (y `enable_psr=0` si
  hay eDP); el instalador ejecuta `update-initramfs -u` y pide reiniciar.
- `.xinitrc`: añade `XDG_SESSION_TYPE=x11` y `GDK_BACKEND=x11`.
- Kitty: el atajo `Super+Return` usa `kitty --single-instance`; la
  segunda ventana abre en ~54 ms.
- Picom queda fuera del repo y del entorno.
- El resumen del instalador indica que se usa sudo para paquetes, portal,
  opt-2 e i915.

## Congelación de bspwm por script huérfano (2026-10-25)

- Polybar murió durante un reinicio mientras `updates-apt.sh`
  (`tail = true`) seguía vivo.
- El script heredó el socket de bspwm y no lo leía; bspwm llenó el buffer
  (213 KB) y se bloqueó en `sock_alloc_send_pskb`.
- Recuperación: matar los grupos de `updates-apt.sh` y relanzar polybar.
- Prevención:
  - `flock` en `launch.sh` para serializar reinicios.
  - `launch.sh` mata scripts huérfanos (`updates-apt.sh`, `polypomo`)
    antes de arrancar.
  - `updates-apt.sh` termina si su polybar desaparece.
- Probado: matar polybar deja bspwm respondiendo; relanzar funciona.

## Ajustes manuales guardados (2026-10-25)

- Batería A y B: los espacios literales pasan a `%{O5}` en
  `animation-charging`, `label-full` y `ramp-capacity`.
- `.zshrc`: `ZSH_THEME="cypher"` y `export PATH="$HOME/.opencode/bin:$PATH"`.
- Todo lo demás de polybar, kitty, bspwm, sxhkd y rofi coincide ya con
  las plantillas.
- Re-renderizado y comprobado sin diferencias contra la config viva.

## Arranque de zsh sin compinit duplicado (2026-10-25)

- `.zshrc` llamaba a `compinit` después de cargar Oh My Zsh, que ya lo
  ejecuta con su propio `ZSH_COMPDUMP`.
- Se elimina la llamada manual; los `zstyle` de completions se mantienen.
- Medición: `zsh -i -c exit` pasa de ~119 ms a 54-62 ms.
- `compaudit` baja de 4 llamadas a 2.

## Arranque de kitty: portal y caché opt-2 (2026-10-25)

- Causa 1: `xdg-desktop-portal` no estaba instalado y el backend GTK no
  tenía `DISPLAY` en el bus de `systemd --user`; GLFW esperaba ~0,7 s.
- Causa 2: kitty lanza Python con `-OO` y Debian no trae `.opt-2.pyc`;
  Python recompilaba los módulos en cada arranque.
- Añadidos `xdg-desktop-portal` y `xdg-desktop-portal-gtk` a
  `DESKTOP_PKGS`.
- Autostart importa `DISPLAY`/`XAUTHORITY` y reinicia el portal.
- `lib/kitty.sh` compila la caché `opt-2` de `/usr/lib/kitty` y
  `/usr/lib/python3.13`.
- Medición: arranque 870 → 250-296 ms; `kitty --help` 636 → 141 ms.

## Iconos de batería MDI (2026-10-25)

- Rampa de capacidad con iconos Material Design:
  󰁺 󰁽 󰁿 󰂁 󰁹.
- Carga con 󰂄 y batería llena con 󰁹.
- Aplicado solo en los módulos de batería de las variantes A y B; no se
  tocaron colores, fuentes, porcentajes ni el resto de la barra.

## Siete escritorios (2026-10-25)

- `bspwmrc` pasa de 5 a 7 escritorios: `bspc monitor -d 1 2 3 4 5 6 7`.
- `sxhkdrc` cubre `Super+{1-7}` y `Super+Shift+{1-7}`.
- En vivo se añadieron con `bspc monitor -a 6 7`; sxhkd recargado.
- Las barras A y B muestran los 7 workspaces automáticamente.
- Captura `desktops7-crop.png`.

## Kitty sin barra de pestañas (2026-10-25)

- `tab_bar_style` pasa de `powerline` a `hidden`.
- Se eliminan `tab_bar_edge` y `tab_bar_min_tabs`.
- El badge `zsh` de la esquina inferior izquierda desaparece.
- Los atajos de pestañas siguen funcionando; el usuario usará herdr.
- Captura `kitty-notab-win.png`.

## Contador de ventanas en monocle (2026-10-25)

- Nuevo `monocle-count.sh`: imprime `[N]` con las ventanas del escritorio
  y `--check` devuelve 0 solo si el layout es monocle.
- Módulo `custom/script` `monocle` con `exec-if`, `interval = 1`.
- Añadido a la izquierda en la barra A y al centro en la B.
- En tiled el módulo desaparece; en monocle muestra `[1]`, `[2]`, etc.
- Probado en vivo con 1 y 2 ventanas; capturas `monocle-bar-crop.png`,
  `monocle-bar2-crop.png` y `tiled-bar-crop.png`.

## Wallpaper alternativo Nothing1 (2026-10-25)

- `Descargas/Nothing1/contents/images/5521x2487.png` optimizado a
  2560x1153 PNG (918 KB) como `assets/wallpaper-alt.png`.
- Nuevo `wallpaper.sh`: `apply`, `primary`, `alt`, `toggle`; guarda el
  estado en `~/.config/bspwm/wallpaper`.
- Atajo `Super+Alt+W` para alternar.
- Autostart aplica la wallpaper guardada.
- `lib/config.sh` instala ambas imágenes.
- Probado en vivo: Nothing2 (principal) y Nothing1 (alternativa).
  Capturas `wall-primary.png` y `wall-alt.png`.

## Borde 1, gap 0 y wallpaper Nothing (2026-10-25)

- `border_width` 2 → 1 y `window_gap` 4 → 0 en
  `templates/bspwm/bspwmrc.in`, a partir de los ajustes manuales del
  usuario.
- Nuevo wallpaper por defecto:
  `Descargas/Nothing2/contents/images/2337x1080.png` → vendorizado como
  `assets/wallpaper.png` (PNG original, 732 KB).
- Instalado en `~/.local/share/wallpapers/wallpaper.png`; todas las
  referencias actualizadas (`config.sh`, `common.sh`, `verify.sh`,
  `polybar.sh`, `sxhkd.sh`, `bspwm.sh`, `install.sh`).
- Eliminado `assets/wallpaper.jpg`.
- Aplicado en vivo con `xwallpaper --zoom`; captura
  `wall-nothing2.png`.

## Dunst según la posición de polybar (2026-10-25)

- Nuevo `templates/bspwm/scripts/dunst-position.sh.in`.
- Barra arriba → `origin = top-right`; barra abajo → `bottom-right`.
- Se ejecuta antes de `dunst &` en autostart y desde `launch.sh`, así
  cambia solo al usar `Super+Alt+P`.
- `dunstrc` pasa de `top-center` a `top-right` como valor base.
- Probado en vivo: notificación abajo con barra inferior y arriba con
  barra superior. Capturas `dunst-bottom-crop3.png` y `dunst-top.png`.

## Kitty #1C1C1C (2026-10-25)

- `COLOR_TERM_BG` pasa de `#212121` a `#1C1C1C`; solo afecta a kitty.
- Comprobado en ventana real: fondo `(28,28,28)`.
- Se eliminaron claves de kitty ignoradas (`window_min_width`,
  `window_min_height`, `decorations`, `tab_bar_margin`,
  `tab_inactive_text_alpha`) para dejar el log limpio.

## Kitty y paleta de terminal (2026-10-25)

- `COLOR_TERM_BG=#1C1C1C` solo para kitty; el escritorio sigue en
  `#262626`.
- Nueva paleta `templates/kitty/colorshemes/monochromatic.conf.in` con
  rampa de grises de alto contraste (`#6e6e6e` … `#ffffff`).
- `include` movido al final de `kitty.conf` para que no lo sobrescriban
  las líneas de la plantilla.
- `render_theme_template` sustituye también `COLOR_TERM_*`.
- Añadidas `COLOR_TERM_*` a las paletas mono, warm y nord.
- Captura `kitty-palette-win.png`: `ls` distingue directorios, archivos e
  imágenes.

## Superficie #262626 (2026-10-25)

- `COLOR_BG` y `COLOR_BG_ALT` pasan de `#2A2A2A` a `#262626`.
- Elevado/hover siguen en `#3A3A3A`; bordes en `#1A1A1A`.
- Barra y Thunar comprobados en `(38,38,38)`.
- Captura `surface-26.png`.

## Superficie #2A2A2A (2026-10-25)

- `COLOR_BG` y `COLOR_BG_ALT` pasan de `#2F2F2F` a `#2A2A2A`.
- `COLOR_BG_ELEV`/`COLOR_BG_HOVER` siguen en `#3A3A3A`; bordes `#1A1A1A`.
- Comprobado con captura de la ventana de Thunar: fondo `(42,42,42)`.
- Barra, kitty, rofi, dunst y zathura renderizados con `#2A2A2A`.
- Captura `surface-2a.png`.

## Superficie #2F2F2F (2026-10-25)

- `COLOR_BG` y `COLOR_BG_ALT` pasan de `#1A1A1A` a `#2F2F2F`.
- `COLOR_BG_ELEV` y `COLOR_BG_HOVER` a `#3A3A3A`; `COLOR_BORDER` a `#1A1A1A`.
- `normal_border_color` usa `@COLOR_BORDER@` para no desaparecer sobre la
  nueva superficie; `active_border_color` usa `@COLOR_BG_ELEV@`.
- Wallpaper sin cambios (negro).
- Píxel comprobado en barra, Thunar y kitty: `(47,47,47)`.
- Captura `surface-2f.png`.

## Borde enfocado gris claro (2026-10-25)

- `focused_border_color` pasa de azul `#569CD6` a `#D9D9D9`
  (`COLOR_ACCENT_ALT`).
- `normal_border_color` se queda en `#1A1A1A`; `active` en `#2A2A2A`.
- Aplicado en vivo y en la plantilla `templates/bspwm/bspwmrc.in`.
- El azul queda solo para cursor de kitty, borde de rofi y dunst.
- Captura `border-gray.png`.

## Gaps 4, barra 30 y rofi en menús (2026-10-25)

- `window_gap` 10 → 4 en `templates/bspwm/bspwmrc.in` y en vivo.
- `BAR_HEIGHT=30` como constante única en `install.sh`; se pasa a polybar
  A/B (`height`), a `bspwmrc` (padding) y a `launch.sh` (padding).
- La barra ya no vuelve a 20/18 al reinstalar ni al cambiar de variante.
- `network-menu.sh` y `services.sh` prefieren rofi; dmenu solo si falta.
- Probado: menú WiFi sale con rofi y la barra mide 30 px.
- Capturas `gaps-bar30.png` y `net-rofi2.png`.

## Superficie #1A1A1A y bordes corregidos (2026-10-25)

- `COLOR_BG` y `COLOR_BG_ALT` pasan a `#1A1A1A`; `COLOR_BG_ELEV` y
  `COLOR_BG_HOVER` a `#2A2A2A`. El wallpaper sigue negro.
- La barra B deja de ser transparente (`#00000000`) y usa `#1A1A1A`.
- Se aplicó `bspwmrc` en vivo: el borde enfocado estaba en `#b9a99a`
  (Warm Charcoal) porque bspwm no recarga el archivo solo.
  Ahora: foco `#569CD6`, normal `#1A1A1A`, activo `#2A2A2A`.
- Capturas `surface-desktop.png`, `surface-bar-a.png` y
  `surface-bar-b.png`.

## Thunar minimalista y CSS GTK (2026-10-25)

- `templates/gtk/gtk-3.0.css.in` y `gtk-4.0.css.in` con la paleta Mono
  Slate: fondo negro, texto `#F2F2F2`, selección `#569CD6` y bordes
  `#2A2A2A`.
- Toolbar compacta, filas juntas, sin sombras ni degradados, esquinas
  rectas.
- `templates/bspwm/scripts/thunar-defaults.sh.in`: oculta menú, panel
  lateral y barra de estado solo si las propiedades de xfconf no existen.
- `last-side-pane=THUNAR_SIDEPANE_TYPE_HIDDEN_SHORTCUTS`; Ctrl+M recupera
  el menú y F9 el panel lateral.
- Aplicado en vivo con Thunar 4.20.2; captura `thunar-min3.png`.
- `lib/verify.sh` incluye los CSS en el chequeo de colores y
  `desktop-doctor` comprueba los ficheros.

## Paleta global Mono Slate (2026-10-25)

Se sustituyó la paleta por defecto por una monocromática con azul tenue:

- `templates/colors/palette-mono.sh`; `DEFAULT_THEME="mono"`.
  Valores exactos: `#000000` fondo, `#0E0E0E` superficie, `#1A1A1A` tile,
  `#2A2A2A` línea, `#4A4A4A` mute, `#8C8C8C` gris, `#F2F2F2` texto y
  acento azul `#569CD6` (sustituye al rojo `#D71921` de la referencia).
- Polybar A y B, módulos `bspwm`/`fs`, kitty, rofi (`powermenu.rasi` y
  `config.rasi`), dunst, bspwm, i3lock y zathura renderizados desde
  `@COLOR_*@`.
- `--theme mono|warm|nord` en `install.sh`; se eliminaron los
  `THEME_NAME=warm` fijos de `lib/{polybar,dunst,kitty,rofi}.sh`.
- `templates/rofi/config.rasi.in` incorpora el menú de aplicaciones al
  repo (antes solo existía en el home).
- `templates/zathura/zathurarc.in` con fondo oscuro y `recolor` para las
  páginas.
- `assets/wallpaper.jpg` regenerado: 2560x1440 grafito con halo azul tenue
  y viñeta (JPEG q92, ~80 KB).
- `lib/verify.sh` comprueba que ninguna config renderizada tenga colores
  fuera de la paleta activa.
- Aplicado en vivo con `install_bspwm`, `install_dunst`, `install_rofi`,
  `install_kitty` e `install_polybar`; capturas `mono-*.png`.
- La variante B se dejó en `referencia` arriba.

## Paleta global Warm Charcoal (2026-10-25)

Se aplicó una paleta global carbón cálido + azul grisáceo + beige:

- `palette-warm.sh` fue el tema por defecto hasta la llegada de
  `palette-mono.sh`; sigue disponible con `--theme warm`.
- Polybar A y B con colores nuevos (A mantiene su layout).
- Kitty, rofi, dunst, bspwm, i3lock y scripts de sesión renderizados con
  la nueva paleta.
- Bordes bspwm aplicados en vivo.
- `dunstctl reload` y reinicio de polybar.
- Captura `bar-warm.png`.
- La variante B mantiene además los ajustes manuales de layout del usuario.

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
- **Sin compositor**: se retiró picom. La B usa transparencia simulada de
  polybar solo en el centro; los bloques laterales son opacos.
- **Autostart**: sin `set -e`, log en `~/.local/state/dwm-setup/session.log`,
  `lxpolkit` y `udiskie -N -a` sin `-t`.
- **Batería baja**: se pasa `BATTERY` al renderizar el script.
- **`desktop-doctor`**: reescrito en POSIX sh; ya no usa `[[`,
  `WAYLAND_DISPLAY` sin `:-` ni `ls BAT* | xargs basename`.
- **Barra**: font-0 pasa de `DesktopLogo` a JBM; se retira
  `assets/desktop-logo.ttf` y la instalación de la fuente. `dots.ini` se
  retiró temporalmente y el ajuste final del usuario lo eliminó
  definitivamente; se añade limpieza idempotente de restos.
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
- [x] dunst instalado desde apt + dunstrc (Papirus).
- [x] rofi instalado desde apt + powermenu.rasi (Papirus).
- [x] kitty instalado desde apt + kitty.conf.
- [x] Sesión: `~/.xinitrc` → `bspwm`; autostart interno.
- [x] `desktop-safe` para lock/suspend/logout/poweroff/reboot.
- [x] `desktop-doctor` POSIX para bspwm/sxhkd/polybar/cámara.
- [x] Verificación estática final (`verify_install`).
- [x] Backups de sistema y usuario antes de escribir.
- [x] Ownership automático del home y logs.
- [x] `--dry-run` sin modificaciones.
- [x] Limpieza de restos de la barra anterior.
- [x] Documentación actualizada.

## Checklist de validación

- [x] Sesión viva en Debian 13 (host de referencia).
- [x] `desktop-doctor` sin falsos `[FALTA]`.
- [x] Barra A con 12 módulos y B con 14; sin placeholders.
- [x] Servicios systemd en polybar con menú dmenu/rofi.
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

## Firefox ESR y Teams (2026-10-28)

- `Super+Shift+b` abre Firefox ESR; antes renderizaba Chromium.
- `firefox-esr` se añade al instalador con el grupo `BROWSER_PKGS`.
- `/etc/firefox-esr/zz-dwm-setup.js` activa OpenH264 y H.264 en WebRTC;
  se carga después de `firefox-esr.js` y corrige la pantalla compartida de
  Teams en Firefox.
- `Ctrl+Shift+B` no se captura: es el atajo de la barra de marcadores del
  navegador.
- Chromium sigue instalado como plan B para Teams.
- `/etc/firefox-esr/zz-dwm-setup.js` instalado; `verify_install` y
  `desktop-doctor` (75 OK) lo validan.
- `/etc/firefox/policies/policies.json` instala uBlock Origin con
  `force_installed`; se fusiona con políticas existentes y se puede
  desactivar por sitio, pero no desinstalar.
- `about:policies` muestra `ExtensionSettings` activo y el perfil tiene
  `extensions/uBlock0@raymondhill.net.xpi`; `desktop-doctor` sube a 77 OK.
- Pendiente: prueba real de Teams con pantalla compartida.

## Bandeja del sistema (2026-11-01)

- Módulo `internal/tray` añadido a las variantes A y B, al final de
  `modules-right`.
- `tray-size = 70%`, `tray-spacing = 6px`, `tray-padding = 2px`.
- `verify_install` y `desktop-doctor` comprueban los módulos y que `tray`
  esté en `modules-right` de ambas barras.
- Probado con un `GtkStatusIcon` de prueba: icono de 21x21 embebido en la
  barra A y B, a la derecha (`+1893+1054`).
- Polybar solo soporta XEmbed; Telegram/Discord modernos pueden necesitar
  `snixembed` (no está en Debian 13 stable).

## Catppuccin: Mocha Black + Latte (2026-11-02)

- Solo dos paletas: `palette-mocha-black.sh` (oscuro, por defecto) y
  `palette-latte.sh` (claro). Se eliminan `mono`, `warm` y `nord`.
- `mocha-black` lleva la rampa de Mocha a casi negro (`base #0d0d14`,
  `mantle #08080d`, `crust #050509`, surfaces `#1a1a24`/`#26262f`/`#35353f`)
  y mantiene el acento azul `#89b4fa`.
- `latte` mantiene Latte con acento `#1e66f5`.
- `bin/theme-mode dark|light|toggle|status`: re-renderiza desde
  `~/.local/share/dwm-setup` y recarga polybar, dunst y bspwm sin sudo.
- Temas GTK vendorizados (`catppuccin-mocha-blue`, `catppuccin-latte-blue`)
  instalados en `/usr/share/themes`; `catppuccin-mocha-black` se genera al
  instalar sustituyendo la rampa de Mocha.
- Iconos overlay `Catppuccin-Mocha`/`Catppuccin-Latte` en
  `/usr/share/icons`, con carpetas `cat-mocha-blue`/`cat-latte-blue`.
  Necesario porque Papirus-Dark y Papirus-Light comparten `places/`.
- Firefox: `userChrome.css` y `user.js` por modo en el perfil detectado.
- VLC: `qt-dark-palette` según el modo. Polybar: `selected` pasa a
  `@COLOR_ACCENT@`.
- Sustituido `Windows-10-Dark` por los temas Catppuccin en `lib/gtk.sh`,
  `lib/firefox.sh`, `lib/vlc.sh`, `lib/config.sh`, `lib/verify.sh` e
  `install.sh`.
- Preview aprobado por el usuario (contact sheets y escritorios en
  `/tmp/opencode/mocha-variants`).
- Validado en estático: `bash -n`, `--dry-run` con ambas paletas y
  `theme-mode` en un HOME simulado (render dark/light, sin placeholders,
  permisos 0755/0644/0600).
- Pendiente: ejecutar `sudo ./install.sh` y probar `theme-mode` en la
  sesión viva; validar Thunar/Firefox/VLC con el tema derivado.

## Firefox: tema, botones, SurfingKeys y atajo de modo (2026-11-02)

- `userChrome.css` fusionado: mantiene el diseño compacto del usuario
  (`--tab-min-height: 16px`, urlbar compacta, 10 px) y añade los colores de
  la paleta. Vuelven a verse atrás, adelante, recargar, parar, descargas y
  el menú hamburguesa; siguen ocultos home, library, cuenta, puzzle,
  candado y estrella.
- `Super+Alt+t` → `/usr/local/bin/theme-mode toggle`, con notificación de
  dunst (`Modo oscuro` / `Modo claro`).
- SurfingKeys `{a8332c60-5b6d-41ee-bfc8-e9bb331d34ad}` añadida a
  `policies.json` con `force_installed`.
- Config de SurfingKeys generada en `~/.config/dwm-setup/surfingkeys.js`
  si no existe: keymaps del usuario, `@FONT@`, sin alias de reddit,
  `#sk_status` a 11pt y tema con `prefers-color-scheme` para dark/light en
  un solo archivo.
- `verify_install` comprueba la política de SurfingKeys, el archivo de
  config y el atajo.
- Pendiente: instalar y comprobar en vivo que `prefers-color-scheme`
  funciona dentro del CSS inyectado por SurfingKeys; si no, habrá que
  renderizar un archivo por modo.

## kitty en caliente con theme-mode (2026-11-02)

- `kitty.conf` añade `allow_remote_control socket-only` y
  `listen_on unix:kitty-{kitty_pid}` (socket en `/tmp/kitty-<pid>`).
- `bin/theme-mode` recolorea cada instancia con
  `kitty @ --to unix:/tmp/kitty-<pid> set-colors --all --configured
  ~/.config/kitty/colorshemes/monochromatic.conf`.
- `load-config` no servía: no revierte colores fijados con `set-colors`;
  `set-colors --configured <archivo>` sí.
- Verificado en un kitty de prueba: fondo `#eff1f5` → `#0d0d14` → `#eff1f5`
  y cursor `#1e66f5` / `#89b4fa`, con el modo final en `light`.
- Pendiente: reiniciar el kitty vivo (pid 1416) una vez para que cree el
  socket.

## Fix: VLC no soporta qt-dark-palette (2026-11-02)

- `install_vlc_config` sondeaba `vlc -H --advanced` como root. VLC aborta
  con "VLC is not supposed to be run as root. Sorry." y sin salida, así que
  el paso se saltaba y `vlcrc` se quedaba con el valor anterior.
- Reproducido con `unshare -r vlc -H --advanced` (rc=1, 0 líneas).
- Ahora la sonda se ejecuta con `run_user` (usuario destino) y se captura
  la salida; si está vacía se continúa y se escribe el valor.
- `verify_install` vuelve a pasar: `qt-dark-palette=1` con el modo `dark`.

## Zathura sin recolor y límite del tema web (2026-11-02)

- Zathura invertía las páginas (`set recolor true`), incluidos cómics e
  imágenes. Ahora `set recolor false` y `Ctrl+R` queda disponible para
  invertir PDFs de texto en la sesión.
- Se probó que el contenido web de Firefox siguiera al modo en caliente:
  `content-override=2` + `ui.systemUsesDarkTheme=-1` + `gsettings
  color-scheme`. Una instancia de prueba en `about:...`/`prefers-color-scheme`
  siguió en `DARK` tras cambiar gsettings a claro y volver a oscuro; el
  evento `change` no disparó. El contenido solo sigue al reiniciar Firefox.
- Se revirtió a `content-override` 0/1 y `ui.systemUsesDarkTheme` 1/0, que es
  determinista. `THEME_COLOR_SCHEME` se mantiene para apps GTK.
- Google Search respeta `prefers-color-scheme`; YouTube necesita "Usar tema
  del dispositivo".

## fastfetch con logo propio (2026-11-02)

- `templates/fastfetch/config.jsonc.in`: la config del usuario con el bloque
  `logo` activado (`type: kitty`, `source: @HOME@/.config/fastfetch/Neofet.png`,
  28x15). El resto de módulos y colores ANSI se mantienen.
- `assets/fastfetch/Neofet.png` vendorizado (956x1062).
- `lib/fastfetch.sh` instala config y logo en `~/.config/fastfetch/`.
- `fastfetch` añadido a `DESKTOP_PKGS` y a `required_pkgs`.
- `verify_install` comprueba el binario, el config y el PNG; el logo debe
  apuntar a `Neofet.png`.
- Probado en kitty: `fastfetch -c config` renderiza el PNG a 28x15 sin
  deformarlo.

## Streaming de YouTube (2026-11-02)

- `bin/yt-play`: URL directa o búsqueda de 20 resultados con fzf (título,
  canal, duración); mpv reproduce solo audio (`--ytdl-format=bestaudio`).
- `bin/ytdlp-check`: compara con la última release de GitHub (API y
  redirección como respaldo) y notifica; no actualiza.
- `bin/ytdlp-update`: descarga el binario oficial en `~/.local/bin`, guarda
  `.bak`, comprueba que arranca y restaura si falla.
- `bin/ytdlp-rollback`: restaura la copia anterior.
- `bin/music-ctl`: teclas `XF86Audio*` vía `playerctl` (mpv + mpv-mpris).
- Chequeo diario silencioso desde `yt-play` (`~/.cache/yt-play/last-check`).
- Detecta `Unable to extract`/`Sign in`/`403` y avisa con `ytdlp-update`.
- `mpv`, `mpv-mpris`, `fzf` y `yt-dlp` (respaldo APT) en `DESKTOP_PKGS`.
- `~/.local/bin` añadido al PATH de `.zshrc` y `.xinitrc`.
- Probado: descarga real de yt-dlp 2026.10.26, `--version`, check "al día",
  rollback, errores de `yt-play` sin fzf/mpv y búsqueda real con yt-dlp.
- Pendiente: `sudo ./install.sh` y probar reproducción real con audio.

### Fix: yt-play usaba el yt-dlp viejo de Debian (2026-11-02)

- Síntoma: `[youtube] The page needs to be reloaded` al reproducir.
- Causa: `mpv` resuelve `yt-dlp` por PATH y la shell no tenía
  `~/.local/bin`, así que usaba `/usr/bin/yt-dlp` (2025.04.30) en vez del
  oficial (2026.10.26). Comprobado: el oficial resuelve el id, el de Debian
  falla.
- `yt-play` y `ytdlp-check` prefieren `~/.local/bin/yt-dlp` de forma
  explícita, y `yt-play` le pasa a mpv un PATH con esa carpeta delante.
- Ampliado el patrón de error: `page needs to be reloaded`,
  `youtube-dl failed`, `unexpected error`. El aviso muestra la versión de
  yt-dlp en uso.
- Probado con un mpv falso: PATH correcto y mensaje correcto.

### Simulación del instalador para streaming (2026-11-02)

- `install_music` ejecutado con `TARGET_HOME` y `MUSIC_BIN_ROOT` en /tmp
  (run_root/run_user sin sudo): descarga yt-dlp 2026.10.26, instala los 6
  scripts con 0755 y `ytdlp-check` responde "al día".
- `yt-play` instalado por el instalador inyecta `~/.local/bin` en el PATH de
  mpv; con un mpv falso se comprobó que recibe esa carpeta primero.
- `MUSIC_BIN_ROOT` permite probar el módulo sin tocar `/usr/local/bin`.

### Preview de miniaturas en yt-play (2026-11-02)

- `bin/yt-preview <id>` descarga `i.ytimg.com/vi/<id>/mqdefault.jpg` a
  `~/.cache/yt-play/thumbs` y la dibuja con `chafa --format=symbols`,
  ajustada a `FZF_PREVIEW_COLUMNS` / `FZF_PREVIEW_LINES`.
- `yt-play` usa `fzf --height=80% --preview 'yt-preview {2}'
  --preview-window=right,55%`; la lista sigue mostrando título, canal y
  duración.
- `chafa` añadido a paquetes; `yt-preview` a scripts y a `verify_install`.
- Probado: descarga y caché de la miniatura (10 KB), salida de respaldo sin
  chafa y salida de texto sin secuencias gráficas (13 líneas para un panel
  de 14).
- Sustituido por el preview equilibrado (opción A) de más abajo: lista de
  títulos, panel al 50%, metadatos y `maxresdefault`.

### yt-play: 20 resultados por defecto (2026-11-02)

- Medido con el binario oficial: 10→2527 ms, 20→2556 ms, 30→3644 ms,
  50→4533 ms. YouTube devuelve ~20 por página, así que 20 no cuesta más
  que 10; 30+ pagina.
- `YT_PLAY_RESULTS` (por defecto 20) con validación: valores no numéricos,
  0 o negativos caen a 20.

### Fix: la miniatura de yt-play dejaba restos (2026-11-02)

- chafa 1.14.5 autodetecta kitty y usaba el protocolo gráfico (`--format`
  auto). fzf solo borra texto, así que la imagen quedaba en pantalla al
  pulsar Esc y se solapaba al cambiar de resultado.
- `yt-preview` fuerza `--format=symbols` y usa `FZF_PREVIEW_COLUMNS` /
  `FZF_PREVIEW_LINES` para encajar en el panel.
- Comprobado: la salida ya no contiene `\033_G` (kitty) ni `\033P` (sixel),
  y restaura el cursor (`?25h`).

### Preview equilibrado de yt-play (opción A) (2026-11-02)

- La lista de fzf queda solo con el título; el panel derecho (50%) muestra
  título en negrita ajustado a dos líneas, canal, duración y miniatura.
- El ajuste de línea es por caracteres UTF-8 en bash (`fold` partía los
  acentos) y se limpian los controles del título/canal antes de imprimirlos.
- `yt-play` escribe un sidecar por vídeo en `~/.cache/yt-play/meta/<id>`
  antes de abrir fzf; `yt-preview` lo lee sin consultar YouTube otra vez.
- `yt-preview` descarga `maxresdefault.jpg` y cae a `mqdefault.jpg` si no
  existe (vídeos antiguos). Caché nueva en `~/.cache/yt-play/preview`.
- fzf pasa a `--height=75%` y `--preview-window=right,50%,border-left`; se
  mantiene `--format=symbols` para no dejar restos de kitty/sixel.
- Probado con un `yt-dlp` y un `fzf` falsos: se generan los sidecars con
  duración `NA` convertida a "en vivo" y la lista recibe solo `título<TAB>id`.
- Probado con red real: `dQw4w9WgXcQ` cachea 1280x720; `jNQXAC9IVRw`
  (sin `maxresdefault`, HTTP 404) cae a `mqdefault` 320x180.
- Panel simulado de 60x30: 21 líneas (2 de título, 1 de canal/duración, 1 en
  blanco y 17 de imagen), sin `\033_G` ni `\033P`, cursor restaurado.
- Pendiente: probar el panel completo en fzf tras `sudo ./install.sh`.

### Flujo de instalación endurecido (2026-11-02)

- `lib/dunst.sh`: `restart_dunst_session` reinicia dunst tras renderizar
  `dunstrc`. Lee `DISPLAY` y `DBUS_SESSION_BUS_ADDRESS` de `sxhkd`, `bspwm`
  o `polybar`; sin sesión gráfica no mata nada y avisa. Elimina restos de
  dunst de root.
- `lib/common.sh`: `~/.local/bin` entra en `chown_managed_paths` y en los
  backups; se respaldan los seis scripts de streaming y `yt-dlp`.
- `lib/music.sh`: si `~/.local/bin/yt-dlp` ya funciona no se vuelve a
  descargar; antes de reemplazarlo guarda `yt-dlp.bak`.
- `lib/verify.sh`: si falta el yt-dlp oficial avisa (no falla) de que
  `yt-play` usará el de Debian y sugiere `ytdlp-update`.
- `lib/packages.sh`: `BUILD_PKGS` incluye la cadena completa
  (`build-essential make gcc g++ patch cmake autoconf automake libtool
  libtool-bin meson ninja-build pkg-config git`). `cleanup_packages` marca esos
  paquetes como manuales y ejecuta `apt-get -y autoremove` al final; un
  fallo solo avisa.
- `install.sh`: `cleanup_packages` va después de `verify_install`; el
  resumen y `--help` documentan `yt-play` y las teclas multimedia.
- `--dry-run` muestra `apt-mark manual` y `apt-get -y autoremove` sin
  ejecutarlos.

- `bin/desktop-safe lock` lee el modo activo y `COLOR_BG` de la paleta
  instalada, así el fondo de i3lock sigue a Mocha Black o Latte sin
  recompilar nada.

## Pantalla siempre encendida (2026-11-02)

- Diagnóstico inicial: `xset q` mostraba `timeout: 600`, `cycle: 600` y DPMS
  `Standby/Suspend/Off: 600`; a los 10 min se activaba el salvapantallas,
  `xss-lock` bloqueaba y DPMS apagaba el monitor.
- `templates/bspwm/autostart.in` ejecuta `xset s off` y `xset -dpms` tras
  esperar a X. Con timeout 0 no hay bloqueo por inactividad; `xss-lock`
  sigue para el bloqueo manual y el de suspensión.
- `templates/bspwm/scripts/i3lock-fancy/i3lock-fancy.sh.in` ya no ejecuta
  `xset dpms force off` tras 5 s.
- Aplicado en vivo el 2026-11-02: `xset q` muestra `timeout: 0` y
  `DPMS is Disabled`.
- `autostart` e `i3lock-fancy` instalados se sincronizaron a mano desde las
  plantillas (backup en `~/.config-backup/dwm-setup/20261102-193117`), así
  el cambio sobrevive a `startx`.
- Pendiente: `sudo ./install.sh` para el resto del bloque pendiente
  (`yt-play`/`yt-preview`) y comprobar >10 min de inactividad, el bloqueo
  manual y la suspensión.

## yt-play audio/vídeo y Ctrl+Space (2026-11-02)

- `yt-play [--audio|--video]`: audio por defecto; `--video` abre una ventana
  de mpv al 80% (`--autofit=80%x80%`). En la búsqueda, `fzf --expect=ctrl-v`:
  Enter usa el modo por defecto y Ctrl+V el otro.
- `Ctrl+Space` se añadió a sxhkd como `bspc node -t '~floating'` (alterna
  flotante/tiled); se mantienen `Super+s` y `Super+Shift+Space`.
- Fix sxhkd: `SHELL=/usr/bin/zsh` expandía `~floating` a un usuario
  inexistente y el comando fallaba. Se citaron `'~floating'`, `'~fullscreen'`,
  `'~east'` y `'~south'` en la plantilla y en `~/.config/sxhkd/sxhkdrc`.
  Esto arregla Ctrl+Space, Super+Shift+Space, Super+f y los splits.
- Tests: zsh sin comillas falla; con comillas bspwm cambia tiled→floating;
  sxhkd rearrancado sin errores de grab; `--autofit=80%x80%` aceptado por
  mpv; `yt-play --video` con mpv falso recibe `--autofit`.
- Pendiente: `sudo ./install.sh` para instalar el `yt-play` nuevo (el
  instalado aún es la versión anterior); probar Ctrl+Space, Super+Shift+Space,
  Super+f y splits en la sesión viva.

## Diagnóstico de tearing y prueba de picom (2026-11-04)

- Diagnóstico de la sesión: Xorg con `modesetting + glamor + DRI3`,
  sin errores en el log; `glxgears` marca 61 FPS con vsync (correcto) y
  1252 FPS sin vsync (márgen enorme de GPU). Intel UHD 630 con
  `enable_fbc=0` aplicado; monitor KTC 2400 (2012) en HDMI-1 1080p60
  preferred. Sin compositor y sin opción TearFree (modesetting no la
  tiene y `xserver-xorg-video-intel` no está instalado): el rasgado al
  arrastrar ventanas es lo esperado en X sin compositor.
- El arrastre torpe que el usuario notó corresponde a mpv abierto a
  tamaño nativo 4K (3840x2160): el `yt-play` instalado aún no tenía
  `--autofit=80%x80%`; cerrado con el `sudo ./install.sh`
  (2026-11-04 ~13:13).
- Gobernador de CPU en `powersave` (intel_pstate active). Prueba de
  `performance` queda en manos del usuario (requiere sudo).
- Picom: se preparó una config mínima de prueba
  (`~/.config/picom/picom.conf`, glx + vsync + use-damage, sin
  sombras/fading/blur, `unredir-if-possible`) tras respaldar la config
  vieja de la era nord en
  `~/.config-backup/dwm-setup/20261104-104836/.config/picom/`. picom no
  está instalado; pendiente `sudo apt install picom` y arrancarlo para
  la prueba visual (`pkill picom` revierte).
- Si picom se queda, se integra con ADR nuevo: `templates/picom/`,
  `lib/picom.sh`, entrada en `autostart`, docs y `verify.sh`.

## picom formal y módulo governor (2026-11-04)

- El usuario validó picom en vivo: "más fluido, menos rasgado al
  scrollear" y pidió fade sutil; NO quiere transparencias de picom (la
  barra B translúcida se mantiene tal cual: es su fondo `#00000000`
  frente al compositor). Decisión adoptada como ADR-107.
- El módulo `governor` (ADR-108) queda junto a `cpu` en `modules-right`
  de ambas variantes; los counts pasan a A 13 (14 con backlight) y
  B 15 (16 con backlight). Sin tocar espaciados ni resto de módulos.
- Implementación: `templates/picom/picom.conf.in` (libconfig,
  comentarios `#`: con `;` picom 12.5 abortaba con "syntax error" línea
  1), `lib/picom.sh`, bloque picom con guard en `autostart.in`,
  `lib/cpu.sh`, `bin/dwm-setup-cpu-governor` (POSIX, valida contra
  `scaling_available_governors`, escribe todas las CPUs), sudoers
  `dwm-setup-cpu-governor` (`@USER@`, NOPASSWD solo para el helper,
  validado con `visudo -cf` en archivo provisional antes de moverlo) y
  unidad `dwm-setup-cpu-governor.service` (oneshot, performance al
  boot). `lib/packages.sh` añade `picom`; `lib/polybar.sh` renderiza
  módulo/script en ambas variantes; `lib/common.sh` añade backups del
  helper/sudoers/unidad y `~/.config/picom`; `lib/config.sh` mete
  `cpu-governor.sh.in` en el store y `bin/theme-mode` lo re-renderiza
  (regla 20b); `lib/verify.sh` exige helper/sudoers 0440/unidad
  habilitada, `governor` tras `cpu` en ambas barras y picom con
  `vsync true` + `shadow false`.
- Validación: `bash -n`, `sh -n` (helper, script de barra, autostart),
  `systemd-analyze verify` (aviso del ejecutable ausente solo hasta
  instalar), `visudo -cf` del sudoers renderizado ("parsed OK"),
  `--dry-run` rc=0 con el plan completo, y pruebas del helper con
  sysfs falsa en `/tmp/opencode` (aplicar/rechazado rc 64/sin
  escribibles rc 65/parcial con aviso) y del script de barra con
  `sudo` de stub + sysfs falsa (ciclo completo performance →
  powersave → performance con toasts dunst e iconos `U+F10CB`/`U+F0F86`
  verificados por bytes).
- Aplicado en vivo sin sudo: backups previos en
  `~/.config-backup/dwm-setup/20261104-130202/` (configs de polybar,
  scripts y picom), ` governor` insertado en los modules-right
  instalados, módulos y `cpu-governor.sh` escritos con el acento del
  modo activo (light: `#1e66f5`), picom.conf final, picom reiniciado
  (pid activo) y polybar recargado con `launch.sh` (variante
  referencia).
- `sudo ./install.sh` ejecutado (2026-11-04 ~13:13): helper, sudoers,
  unidad y render completo aplicados; `systemd-analyze verify` ya no
  da el aviso del ejecutable. Pendiente: probar el clic del módulo
  (alterna + toast) y el fade en la sesión viva.

## Port de los ajustes manuales de polybar al repo (2026-11-04)

Tras el `sudo ./install.sh` el usuario afinó a mano la barra viva; el
análisis por diff (render completo del repo vs mtime post-instalación)
aisló los cambios reales y se portaron a las plantillas:

- Variante B: `governor` pasa de `modules-right` a `modules-left`,
  tras `day` (conserva su bloque `module-bg`); `modules-right` vuelve al
  layout original. ADR-108, regla 26 y README/AGENTS actualizados.
- Espaciados por módulo: `governor` cierra con `%output%%{O5}` (A y B);
  `cpu` (A) de `%{O8}` a `%{O2}`; `pipewire` con `format-padding 2` en
  ambas variantes; `memory` (B) `format-padding 1`.
- `cpu-governor.sh`: el hueco tras el icono va dentro del bloque font-3
  (`ICON_PERF`/`ICON_SAVE` con espacio; `%{T-}$gov` sin espacio extra en
  performance y powersave; el fallback del alien conserva el suyo).
- `lib/verify.sh`: la B exige `governor` en `modules-left` (antes se
  comprobaba en ambas `modules-right`).
- Store de theme-mode: refrescados sin sudo (los tres ficheros user-
  owned: config.ini A/B y cpu-governor.sh.in) para que un
  `theme-mode toggle` no borre los tweaks antes del próximo
  `sudo ./install.sh`.

## ytwatch integrado en el instalador (ADR-109, 2026-11-04)

Buscador TUI de YouTube añadido al flujo con `--no-ytwatch` para
saltarlo. No sustituye nada: usa el mismo yt-dlp oficial y mpv;
`yt-play`, `ytdlp-*`, teclas XF86Audio y los toasts de dunst siguen
intactos.

- `lib/ytwatch.sh`: binario de GitHub `v0.1.0` con SHA-256 verificado en
  `~/.local/bin/ytwatch` (usuario, sin sudo) y `ueberzugpp` 2.9.10 por
  `.deb` directo del build Debian 13 del proyecto (sin añadir repos APT;
  dependencias vía `apt-get -f`). Idempotente y sin red no rompe nada.
- `templates/ytwatch/config.toml.in`: browser `firefox-esr`, audio
  default (`audio_only = true`), `quality = "720p"`, tema `terminal`
  (sigue la paleta viva de kitty; sin hex, fuera del store 20b),
  `preview.output = "kitty"` con fallback comentado `chafa`.
- `bin/ytwatch-check` (avisa por dunst, como `ytdlp-check`) y
  `bin/ytwatch-update` (checksums.txt + `.bak`; `--ueberzugpp` refresca
  el paquete con sudo).
- `install.sh`: flag `--no-ytwatch`, layout ampliado, wiring tras
  `install_music`, resumen y logs; `verify.sh` valida binario/config/
  `/usr/bin/ueberzugpp` con gate por `INSTALL_YTWATCH`.
- Backups previos: `~/.local/bin/ytwatch` y `~/.config/ytwatch`.

Validado en el repo: `bash -n`/`bash -n bins` OK, `--dry-run` rc 0
(bloque ytwatch con URLs y checksums), `--dry-run --no-ytwatch` salta
el bloque, `ytwatch-check` real ("al día" + aviso de ueberzugpp
ausente) y `ytwatch-update` early-exit con misma versión.

Pendiente de la sesión viva: `sudo ./install.sh` para instalar el .deb
y renderizar la config; comprobar miniaturas en kitty y la tecla de
vídeo de `?`. Backlog del usuario: comando tipo doctor global con
avisos dunst de todo el sistema (aparte de ytwatch-check).

### Fix: ueberzugpp chocaba con el paquete legado ueberzug (2026-11-04)

El `sudo ./install.sh` de las 15:38 abortó en verify con
`Falta /usr/bin/ueberzugpp`: dpkg rechazó el .deb porque el paquete
legado `ueberzug` (18.3.1-2+b1, Python) posee `/usr/bin/ueberzug` y el
.deb trae el shim drop-in con ese mismo path. `apt-get -f` no aplica
(no era un problema de dependencias).

- `lib/ytwatch.sh` e `ytwatch-update --ueberzugpp` retiran ahora el
  legado con `apt-get -y remove ueberzug` antes de `dpkg -i` (en
  Debian 13 no arrastra dependientes) y el warn sugiere
  `--force-overwrite` solo como último recurso manual.
- ranger conserva `preview_images_method ueberzug`: el shim de
  ueberzugpp da el mismo comando.
- Pendiente: re-ejecutar `sudo ./install.sh` (idempotente; solo
  reintenta ueberzugpp y la verificación).

### ytwatch: backend x11 y audio sin ventana (2026-11-04, noche)

- Miniaturas confirmadas en vivo con `preview.output = "x11"` (el
  backend `kitty` de ueberzugpp v0.1.0 no pinta en kitty+X11; el panel
  se quedaba vacío aunque el doctor estaba OK).
- mpv en modo audio abría una ventana negra: ytwatch pasa
  `--force-window=immediate --no-video`. La config (plantilla y viva)
  añade `[mpv] args = ["--force-window=no"]`; verificado con
  `xwininfo` que el último flag gana y no se crea ventana.
- Tecla `a` conmutando audio↔vídeo: pendiente de la prueba del
  usuario (el footer `720p · ♪ audio` es el indicador del modo).

### Pulido: controles de audio y fade de picom (2026-11-04, noche)

- `music-ctl`: `play-pause` y `stop` actúan sobre **todas** las
  instancias MPRIS (antes solo la default; con varias mpv de ytwatch
  quedaban sonando). Nuevos `forward`/`backward` (position ±10 s).
  sxhkd: `XF86AudioForward`/`XF86AudioRewind` añadidos (no-op si el
  teclado no tiene esas teclas).
- picom: `fade-in/out-step` 0.03 → 0.05 (delta 5): transición de
  ~167 ms a ~100 ms, "un poco más rápido" pedido por el usuario.
- Pendiente: `sudo ./install.sh` (instala el music-ctl nuevo en
  /usr/local/bin y re-renderiza) y probar `a`+`Enter` (vídeo), stop
  de varias instancias y seek.
- Revertido el override `--force-window=no`: el usuario prefiere ytwatch
  como viene de fábrica (mpv abre su ventana normal también en audio).
  La plantilla vuelve a `[mpv] args = []`. Se queda `preview.output =
  "x11"`, que es lo que da miniaturas. Control de audio por music-ctl.

### Fix: grupo APT reintentaba el ueberzug legado (2026-11-04, 18:34)

El `sudo ./install.sh` de las 18:34 abortó en el grupo obligatorio
"escritorio": `apt-get install` intentó reinstalar `ueberzug` (estaba
en `DESKTOP_PKGS` y el run anterior lo había quitado) y chocó con el
shim de ueberzugpp (`trying to overwrite /usr/bin/ueberzug`).

- `DESKTOP_PKGS` ya no lista `ueberzug`; con ytwatch el shim lo pone
  ueberzugpp. El legado solo se instala con `--no-ytwatch`
  (`install_group "ranger: ueberzug legado"`).
- El post-check `required_pkgs` exige `ueberzug` solo en ese ramal.
- Validado con `--dry-run` (grupo escritorio: 48 paquetes, sin
  ueberzug) y `--dry-run --no-ytwatch` (pide el legado). Pendiente:
  re-ejecutar `sudo ./install.sh`.
- Modo por defecto cambiado a **vídeo** (`audio_only = false`):
  `Enter` abre mpv con imagen; `a` conmuta a audio (ventana sin imagen
  por `--force-window=immediate` del proyecto). Decisión del usuario
  2026-11-04 tras ver que "audio por defecto" implicaba ventana negra
  o el override `--force-window=no`.

### Sombras sutiles en picom (ADR-110, 2026-11-04)

Pedido del usuario tras la auditoría: sombras sin transparencias.
`shadow = true` (radius 10, opacity 0.35, offsets -8/-8) con
`shadow-exclude` de dock y desktop; opacidades siguen a 1, sin blur,
vsync/fade intactos. `verify.sh` actualizado a la nueva expectativa
(añade check de blur-background prohibido). Aplicado en vivo con
reinicio de picom.

### Avisos de YouTube por dunst + swappiness + limpieza de backups (2026-11-04)

- `bin/yt-update-notify` + `dwm-setup-yt-update-notify.{service,timer}`
  (usuario): 13:00 diario, `Persistent=true` (si el PC estaba apagado
  a esa hora, corre al encender).
  Corre `ytdlp-check` y `ytwatch-check` con `--quiet --no-notify` y
  manda **un solo toast** si hay versiones nuevas; silencio si todo está
  al día. No toca APT (la calavera de polybar sigue igual) ni use sudo.
- `--no-notify` añadido a ambos checkers (el uso manual sigue avisando).
- `lib/yt-notify.sh` instala binario en /usr/local/bin, unidades en
  `~/.config/systemd/user` y habilita el timer vía symlink
  (`timers.target.wants`), arrancándolo si hay sesión.
- `lib/sysctl.sh` + `templates/sysctl/99-dwm-setup-swappiness.conf`:
  `vm.swappiness=10` persistente.
- `prune_backups` en `lib/common.sh`: retira backups de >3 días
  conservando los 3 más recientes de /var/backups/dwm-setup y
  ~/.config-backup/dwm-setup; en dry-run solo lista.
- `cleanup_packages` escribe en el log la simulación de autoremove
  (sigue siendo el último paso, sin --purge y tras proteger la cadena
  de compilación).
- Limpieza manual del usuario: chromium y avahi-daemon fuera;
  NetworkManager-wait-online desactivado; xdg default = Firefox ESR.
