# Progreso — fase 1b (bspwm + polybar)

Última actualización: 2026-10-25

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
