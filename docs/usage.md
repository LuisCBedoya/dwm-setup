# Uso diario y aplicaciones

Atajos, variantes de la barra, apps y tema. El
[README](../README.md) tiene el inicio rápido.

## Uso diario

| Atajo | Acción |
|---|---|
| `Super+Return` | kitty |
| `Super+d` | rofi -show run |
| `Super+Shift+d` | rofi (drun) |
| `Super+Shift+s` | scrot: seleccionar región y copiar al portapapeles |
| `Super+Shift+g` | grabar pantalla: empezar / parar (misma tecla) |
| `Super+Shift+p` | pcmanfm (pendiente de instalar) |
| `Super+Shift+b` | brave-browser |
| `Super+Shift+v` | codium (pendiente; no está en Debian) |
| `Super+Shift+i` | ristretto (pendiente) |
| `Super+Shift+a` | lxappearance (pendiente) |
| `Super+Shift+f` | Thunar |
| `Super+Shift+l` | bloquear (desktop-safe lock) |
| `Super+Shift+e` | salir (desktop-safe logout) |
| `Super+Shift+c` | recargar sxhkd y bspwm |
| `Super+Shift+r` | reiniciar bspwm |
| `Super+Alt+P` | ciclo A arriba → A abajo → B arriba → B abajo |
| `Super+Alt+W` | alterna wallpaper dark / light |
| `Super+Alt+T` | alterna tema oscuro / claro |
| `Ctrl+Space` | alternar flotante/tiled |
| `Super+Shift+space` | alternar floating |
| `Super+Shift+q` | cerrar ventana |
| `Super+a` | enfocar contenedor padre |
| `Super+b` / `Super+v` | split horizontal / vertical (preselección) |
| `Super+f` | fullscreen |
| `Alt+Tab` / `Alt+Shift+Tab` | siguiente / anterior ventana |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | siguiente / anterior escritorio (ADR-112) |
| `Ctrl+N` / `Ctrl+P` (Brave) | siguiente / anterior pestaña (nativo) |
| `Alt+Q` / `Alt+K` (Brave) | cerrar / nueva pestaña |
| `Alt+O` (Brave) | recargar |
| `Alt+H` / `Alt+L` (Brave) | ir al panel izquierdo / derecho (vista dividida) |
| `Alt+N` (Brave) | expandir/colapsar pestañas verticales |
| `Alt+Shift+N` (Brave) | ventana nueva |
| `Ctrl+Alt+L` / `Ctrl+Alt+H` (Brave) | dividir con la pestaña actual / nueva vista dividida |
| `Super+Ctrl+Tab` / `Super+Ctrl+Shift+Tab` | siguiente / anterior escritorio |
| `Super+{1-7}` | ir al escritorio N; si no existe, crea el siguiente |
| `Super+Shift+{1-7}` | mover ventana al N; si no existe, crea el siguiente |
| `Super+r`, luego `h/j/k/l` | modo resize (Escape o 6 s sale) |
| `Super+m` | monocle/tiled (en monocle, picom sin esquinas ni sombra) |
| `Print` | pantalla completa al portapapeles |
| `Super+Print` | menú de capturas |
| `XF86AudioRaise/Lower/Mute` | volumen |
| `XF86AudioPlay` / `Next` / `Prev` | play-pausa (todos), pista del activo |
| `XF86AudioStop` | detiene todas las instancias (limpieza) |
| `XF86AudioForward` / `Rewind` | ±10 s en el activo |
| `XF86MonBrightnessUp/Down` | brillo |

Escritorios dinámicos (ADR-112): la sesión arranca con uno solo; `Super+1..7`
salta al N si ya existe y, si no, crea el siguiente (secuencia densa `1..N`
sin huecos: al borrarse un vacío, los demás se renumeran). Recorren los
existentes `Ctrl+Tab`,
`Ctrl+Shift+Tab`, `Super+Ctrl+(Shift+)Tab` y `Super+bracket{left,right}`.
`Ctrl+Tab` deja de cambiar de pestaña en el navegador (quedan
`Ctrl+PageUp/PageDown`).

`Super` es la tecla Windows. La barra muestra 16 módulos (17 si hay
backlight): logo StumbleUpon, escritorios dinámicos, pomodoro, temperatura, RAM,
CPU, red, Bluetooth, UFW, servicios, volumen, batería, fecha, grabación,
actualizaciones y bandeja del sistema. La temperatura es la del paquete
real (`coretemp`, `Package id 0`), no la zona ACPI. La red muestra un
solo `󰖩 connected` o
`󰈀 connected`; Ethernet tiene prioridad si el cable está conectado. Si no
hay conexión, muestra `󰖩 NoC` y sigue siendo clicable. Al hacer clic en el módulo se abre un menú
WiFi para elegir y conectar una red. Las actualizaciones muestran calavera +
número y se ocultan si N=0. El módulo
de servicios muestra un engranaje y el número de servicios systemd activos;
al hacer clic abre un menú para iniciarlos, detenerlos o reiniciarlos.
El volumen llega como máximo a 120 % y sube/baja de 10 en 10. Las
notificaciones críticas de dunst se cierran solas a los 10 s. El brillo
aparece solo si el equipo tiene backlight y también cambia de 10 en 10.
Bluetooth arranca **apagado** (`AutoEnable=false`) y muestra `off`, `on`
o el dispositivo conectado (con batería si la informa); al hacer clic se
abre un menú para encender/apagar, conectar/desconectar, escanear,
emparejar, elegir el sink de audio y cambiar el perfil de audio
(automático/A2DP/HFP). Al encender el adaptador reconecta los dispositivos
de audio de confianza (`Icon: audio*`). Con el perfil automático, el
micrófono del headset se activa solo mientras una aplicación graba y
vuelve a A2DP al terminar. El audio Bluetooth usa `libspa-0.2-bluetooth` y
`rtkit`; si el pareo falla, el error real queda en
`~/.local/state/luc-workspace/bluetooth.log`. UFW
muestra `on`/`off` y el número de reglas; su menú permite ver estado y
reglas, activar, desactivar y recargar. UFW mantiene `22/tcp` permitido
para no cambiar el acceso SSH.

### Variantes de polybar

Hay dos barras instaladas:

- **actual**: la barra compacta de 16 módulos (17 con backlight): logo,
  workspaces 1-7, updates, servicios, pomodoro, temperatura, RAM, CPU,
  red, Bluetooth, UFW, volumen, batería, fecha, grabación, bandeja del
  sistema y brillo opcional. En monocle añade un contador `[N]` junto a los
  workspaces.
- **referencia**: variante de 18 módulos (19 con backlight). Workspaces
  como círculos al centro; a la izquierda `date`, `day`, **gobernador**, `updates`,
  pomodoro y `der`; a la derecha `izq`, servicios, temperatura, RAM, CPU, red,
  Bluetooth, UFW, volumen, batería, grabación, bandeja del sistema y brillo
  opcional.
  En monocle, `[N]` junto a los círculos de workspaces.
  La bandeja usa XEmbed; Telegram/Discord modernos pueden no aparecer hasta
  añadir `snixembed`.
  Barra de 30 px con fondo sólido del modo activo, fuentes 10/13, iconos JBM y
  círculos Font Awesome. Todos los bloques comparten el mismo tono;
  laterales son oscuros y opacos.

Cambiar de variante:

```sh
~/.config/polybar/polybar-variant actual
~/.config/polybar/polybar-variant referencia
~/.config/polybar/polybar-variant toggle
~/.config/polybar/polybar-variant cycle
```

`Super+Alt+P` recorre el ciclo **A arriba → A abajo → B arriba → B
abajo**. La posición se guarda en `~/.config/polybar/position`.

La variante se guarda en `~/.config/polybar/variant` y `launch.sh` arranca
la elegida al iniciar sesión.

Los atajos de apps que aún no están instaladas se dejan puestos para no
cambiar la memoria muscular; no hacen nada hasta instalar la app. `codium`
requiere el repositorio de VSCodium. `Super+s/w/e` de i3 (stacking/tabbed)
no tienen equivalente exacto en bspwm y no se mapean.

## Música y streams

Audio o vídeo de YouTube/YouTube Music sin salir de la terminal:

```sh
yt-play --audio https://music.youtube.com/watch?v=XXXX   # solo audio
yt-play --video https://www.youtube.com/watch?v=XXXX     # vídeo en mpv
yt-play lofi hip hop                                     # busca y elige con fzf
```

`--audio` es el modo por defecto. En la búsqueda, **Enter** reproduce solo
audio y **Ctrl+V** abre el vídeo en una ventana de mpv; con `--video`, Enter
abre el vídeo y Ctrl+V reproduce solo audio. La ventana de vídeo abre al 80%
de la pantalla y se puede dejar flotante con `Ctrl+Space`.

Trae 20 resultados por defecto (una página de YouTube, mismo coste que 10);
se cambia con `YT_PLAY_RESULTS=40 yt-play lofi`.

El menú de fzf muestra los títulos a la izquierda y, a la derecha, el
**título, canal y duración** junto a la **miniatura del vídeo** (chafa en modo
texto, `maxresdefault` con respaldo a `mqdefault`). La lista y las miniaturas
se cachean en `~/.cache/yt-play/{meta,preview}`. `Ctrl+N`/`Ctrl+P` o flechas
para moverse, `Enter`/`Ctrl+V` para reproducir y `Esc` cancela.

`yt-play` usa siempre `~/.local/bin/yt-dlp` aunque esa carpeta no esté en el
PATH (se la pasa a mpv delante), así que el paquete viejo de Debian no
interfiere. El binario oficial se actualiza sin sudo:

```sh
ytdlp-check      # ¿hay versión nueva? solo avisa
ytdlp-update     # actualiza, con copia .bak y rollback automático
ytdlp-rollback   # vuelve a la anterior
```

`yt-play` avisa si YouTube cambia y yt-dlp ya no puede extraer el contenido.

## Herdr — terminal con pestañas

Herdr se instala en `~/.local/bin/herdr` (v0.9.5, SHA-256 fijado en
`lib/herdr.sh`). Se abre escribiendo:

```sh
herdr
```

en una kitty; `Super+Return` sigue abriendo kitty. El instalador deja
`~/.config/herdr/config.toml` con los atajos actuales (`Alt+K/N/Q`,
`Ctrl+Alt+D`; `Alt+Q` cierra pane → pestaña con `herdr-close`), el tema
de la paleta activa y `~/.local/lib/luc-workspace/preview_tag.py`, que ata
cada preview a su pestaña real. `theme-mode` actualiza el tema en
caliente y ranger/ytwatch muestran sus previews reales dentro de Herdr.
Con `--no-herdr` se omite el bloque.

## ytwatch — buscador TUI

Perfil TUI (vim keys, miniaturas junto a cada resultado, filtros de
tipo/duración/fecha, cola multi-select, playlists y live con chat). No
sustituye a `yt-play`: es otra puerta al mismo yt-dlp + mpv. El chat
replay está **desactivado** (`[chat] enabled = false`): un LIVE VOD
reproduce solo en mpv y no abre una ventana de Brave. El navegador
(`brave-browser`) se sigue usando para abrir enlaces y canales (`c`).
`wmctrl` se instala para que ytwatch coloque la ventana de mpv en X11.

```sh
ytwatch            # abre con la búsqueda activa
ytwatch lofi jazz  # abre con una búsqueda precargada
```

**Enter** reproduce en **vídeo** con la ventana normal de mpv (config del
repo: `audio_only = false`). La tecla `a` conmuta a audio y el footer
`720p · ♪ audio` lo indica; en ese modo el proyecto mantiene su ventana
sin imagen (`--force-window=immediate` de ytwatch), que es su
comportamiento, no un fallo. `d`/`a`/`Q` descargan (calidad/audio), `V`
arma cola, `f` filtra,
`?` muestra la ayuda completa. Las miniaturas van con el backend `x11`
de `ueberzugpp` (ventana-hija sobre la terminal; en Debian 13 llega por
`.deb` del proyecto, sin añadir repositorios). Dentro de Herdr funciona
con la función `ytwatch` de zsh, que exporta `WINDOWID` como pista; el
wrapper `~/.local/bin/ueberzugpp` la corrige a la kitty real de Herdr,
suma el offset del sidebar y la barra de pestañas para que la miniatura
caiga en el panel PREVIEW y la etiqueta con su pestaña real
(`preview_tag.py`), y `preview-sync` la oculta al cambiar de pestaña y
la recupera al volver.
El binario se gestiona solo:

```sh
ytwatch-check        # ¿hay versión nueva de ytwatch o ueberzugpp? avisa por dunst
ytwatch-update       # actualiza el TUI (checksums.txt + .bak)
ytwatch-update --ueberzugpp   # refresca el paquete de miniaturas (sudo)
```

En una instalación sin el bloque: `./install.sh --no-ytwatch`.
No actualiza nada por su cuenta: siempre decides tú con `ytdlp-update`.

## Tema y modo de color

El escritorio usa **Catppuccin** en dos modos:

| Modo | Paleta | Fondo | Acento |
|---|---|---|---|
| `dark` | `mocha-black` | `#0d0d14` | `#89b4fa` |
| `light` | `latte` | `#eff1f5` | `#1e66f5` |

`mocha-black` es Catppuccin Mocha con la rampa de superficies llevada a casi
negro; el resto de la paleta (texto, acentos, estados) se mantiene.

```sh
theme-mode dark        # Mocha Black
theme-mode light       # Latte
theme-mode toggle
theme-mode status
brave-theme status     # comprueba que Brave usa «Usar GTK»
```

`theme-mode` re-renderiza polybar A/B, kitty, dunst, rofi, zathura, bspwm,
GTK, xsettingsd y VLC desde `~/.local/share/luc-workspace/`, y recarga en
caliente polybar, dunst, los bordes de bspwm, el **wallpaper del modo**,
kitty y **xsettingsd** (`SIGHUP`). **No pide sudo**: los temas ya están
instalados. `xsettingsd` publica el `Net/ThemeName` del modo y así **Brave
(«Usar GTK») y las apps GTK cambian al instante**, sin reiniciar. VLC
necesita reiniciarse para aplicar el cambio. **Herdr TUI** también sigue
el modo: `theme-mode` ajusta `theme.name` (`catppuccin`/`catppuccin-latte`)
y el `[theme.custom]` de `~/.config/herdr/config.toml` (dark `#0d0d14`,
active `#1a1a24`, selection `#26262f`; light `#eff1f5`, `#e6e9ef`,
`#bdd0f5`), y recarga su servidor. **opencode** sigue el modo por su
cuenta: en dark usa el tema `mocha-black` (Catppuccin con las
superficies de la paleta, fondo `#0d0d14`) y en light
`catppuccin`/`light` en `~/.config/opencode/cli.json`, con
`opencode reload`. El tema vive en
`templates/opencode/mocha-black.json` (formato V2: `background.raised`
`#0d0d14`/`#1a1a24`/`#26262f`) y se instala en
`~/.config/opencode/themes/`; si el archivo es nuevo, hay que reiniciar
opencode una vez para que lo descubra. El logo
`assets/fastfetch/Neofet-dark.png` lleva un disco `#0d0d14` para que
fastfetch se funda con el dark; el de light no se toca.

Tras instalar en una sesión ya abierta, ejecuta `theme-mode light` (o
`theme-mode toggle`) una vez para arrancar `xsettingsd`; si Brave ya estaba
abierto antes, reinícialo una vez para que adopte «Usar GTK». En un
`startx` nuevo, `autostart` lo arranca antes que las apps.

Los ficheros generados (`bspwmrc`, `kitty.conf`, `dunstrc`…) no se
editan a mano: `theme-mode` y `sudo ./install.sh` los regeneran desde
`templates/` y el cambio manual se pierde. Cualquier ajuste va a la plantilla
y se commitea.

### Wallpapers por modo y fondos personales

`wallpaper.sh apply` elige el fondo según el modo (`dark` → `wallpaper.png`,
`light` → `wallpaper-alt.png`); `Super+Alt+W` alterna entre ambos. Si existen
estos archivos del usuario, **tienen prioridad**:

```
~/.local/share/wallpapers/local-dark.png
~/.local/share/wallpapers/local-light.png
```

Sirven para fondos personales (por ejemplo arte con copyright de uso privado
que no puede ir al repo): el instalador nunca los toca, y `theme-mode` los
aplica automáticamente al cambiar de modo.

kitty se recolorea en caliente con `kitty @ set-colors`, gracias a
`allow_remote_control socket-only` y
`listen_on unix:kitty-{kitty_pid}` en `kitty.conf` (socket en
`/tmp/kitty-<pid>`). Las terminales abiertas antes de activar esto necesitan
un reinicio de kitty.

El atajo es `Super+Alt+t` y muestra una notificación con el modo nuevo.

### Brave y SurfingKeys

Brave es el navegador del escritorio (ADR-113) y usa **«Usar GTK»**
(ADR-115). El tema no lo pone un pack de la Chrome Web Store: `xsettingsd`
publica `Net/ThemeName` con el tema GTK del modo (`catppuccin-mocha-black`
o `catppuccin-latte-blue`), y `theme-mode` lo recarga con `SIGHUP`. Brave
escucha ese cambio de GTK y repinta en caliente, sin reiniciar.
`brave-theme` (sin sudo) asegura en `Preferences` el estado «Usar GTK»:
`extensions.theme.id=""`, `extensions.theme.system_theme=1` y
`browser.theme.color_scheme2=0` (sistema), sin `pack`, `user_color2` ni
`color_variant2`. El wrapper `~/.local/bin/brave-browser` lo reaplica en
cada arranque por si Brave reescribe las prefs. Con Brave abierto no se
tocan las prefs; solo hace falta reiniciarlo si el estado GTK estaba
pendiente. Los temas Mocha/Latte de la CWS siguen instalados
(`normal_installed`) como opcionales, pero el escritorio no depende de
ellos. Los atajos
nativos (`Ctrl+N/P`, `Alt+Q/O/K`, `Alt+H/L` para los paneles y `Alt+N` /
`Alt+Shift+N`) se escriben en `brave.accelerators` del perfil (con Brave cerrado).
Chromium **no soporta `userChrome`/CSS de UI**:
el aspecto es el del tema GTK y no replica el minimalismo que tenía
Firefox; algunos controles legacy de Chromium siguen en azul Google.

La telemetría se apaga por `/etc/brave/policies/managed/luc-workspace.json`
(P3A, stats ping, Web Discovery, Rewards, Wallet, News, Talk, VPN, Leo,
metrics/crash, UKM, sugerencias y surveys) y `BookmarkBarEnabled: false`
quita la barra de marcadores.

La interfaz va limpia (`lib/brave.sh` → `install_brave_minimal`): NTP sin
reloj, estadísticas, noticias, Rewards, VPN, patrocinados ni fondos; sin
iconos de Rewards/Wallet/Leo/Today/marcadores/sidebar/tab-search; pestañas
verticales sin scrollbar ni botón de plegado y con la × oculta. Además la
NTP se sustituye por `/usr/share/luc-workspace/newtab.html`, un symlink a
`~/.local/share/luc-workspace/newtab.html` (fondo liso del modo activo: Mocha
Black en oscuro y Latte en claro, sin buscador ni sitios) con la policy
`NewTabPageLocation`. `theme-mode` re-renderiza la NTP sin `sudo`; las
pestañas ya abiertas necesitan recarga, las nuevas salen con el color
correcto. Chromium no permite CSS de UI, así que el puzzle de extensiones,
el avatar y el escudo de Shields siguen ahí.

SurfingKeys viene `force_installed` desde las policies. Su configuración vive
en `~/.config/luc-workspace/surfingkeys.js`; se pega **una vez** en SurfingKeys →
Ajustes → Advanced mode → editor → Save. No se puede automatizar: la
extensión no lee archivos locales sin native host. Conserva el mapa de
siempre: `o` (búsqueda Google, alias `go`), `O` (pestaña nueva), `b`
(elegir pestaña), `H`/`L` (atrás/adelante) y `<Alt-y>` (historial). Los
`Alt+Q/O/H/K/N` son nativos de Brave y no se mapean aquí.

VA-API se activa solo: `install_brave_vaapi` deja un wrapper en
`~/.local/bin/brave-browser` con `--enable-features=VaapiVideoDecoder` y un
`.desktop` propio en `~/.local/share/applications` que apunta a él
(Brave borra ese flag de `Local State` al salir). `brave://gpu` muestra
*Video Decode: Hardware accelerated*. El instalador **exige Brave
cerrado**: con Brave abierto no se pueden escribir atajos/prefs y aborta. `Ctrl+N`/`Ctrl+P` funcionan ahora como pestañas
nativas también con el foco en la barra de direcciones.

Temas GTK instalados:

```text
/usr/share/themes/catppuccin-mocha-blue      vendored
/usr/share/themes/catppuccin-latte-blue      vendored
/usr/share/themes/catppuccin-mocha-black     generado al instalar
/usr/share/icons/Catppuccin-Mocha            overlay sobre Papirus-Dark
/usr/share/icons/Catppuccin-Latte            overlay sobre Papirus-Light
```

`catppuccin-mocha-black` se deriva de `catppuccin-mocha-blue` sustituyendo la
rampa `base/mantle/crust/surface0..2` por los valores de
`palette-mocha-black.sh`, así que no se desincroniza. Los temas de iconos son
overlays: Papirus-Dark y Papirus-Light comparten `places/` mediante symlinks,
y solo un tema propio permite colores de carpeta distintos por modo.
