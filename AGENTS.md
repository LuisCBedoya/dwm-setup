# AGENTS.md — instrucciones persistentes

Este archivo es la guía para cualquier modelo o persona que continúe el
proyecto. Leer primero `README.md`, `PROGRESS.md` y `DECISIONS.md`.

## Objetivo

Instalador reproducible de un escritorio mínimo para **Debian 13 (trixie)**
con Xorg, **startx manual** (sin display manager), **bspwm**, **sxhkd**,
**polybar**, **dunst**, **rofi**, **kitty**, **flameshot**, **zsh/Oh My Zsh**, **lsd**,
**ranger**, **zathura**, **VLC**, **Brave**,
**i3lock/xss-lock**, **picom** (compositor, ADR-107), PipeWire, cámara UVC
y almacenamiento extraíble con notificación. La CPU arranca en
`performance` y se alterna desde la barra (módulo `governor`, ADR-108).

La barra final es la de la config viva: **13 módulos** (**14 con backlight**),
logo StumbleUpon
(`U+F1A4`), escritorios dinámicos (solo los existentes), actualizaciones al inicio de la derecha, fecha al final,
red unificada (`󰖩/󰈀 connected`, Ethernet prioritario, `󰖩 NoC` sin conexión), servicios systemd, gobernador
de CPU (`󱃋 performance` con acento, `󰾆 powersave`; clic alterna + toast), volumen,
batería y fecha; sin `dots`. Sin `xkeyboard`, `wlan`/`eth` separados ni
fuente `DesktopLogo`.
Fuentes: `font-1` 10 y `font-3` 13; logo en `font-0`. Separación compacta:
`module-margin-left/right = 0`; `updates`/`polypomo` con padding 1/1;
volumen y batería juntos. Espaciados por módulo afinados a mano (no
nuevo marginal): `cpu` cierra en `%{O2}`, `governor` añade `%{O5}` y
`pipewire` lleva `format-padding 2` en ambas variantes (en la B,
`memory` padding 1).

Hay una **variante B "referencia"** instalada aparte: 15 módulos (16 con
backlight), escritorios dinámicos como círculos al centro; a la izquierda `date`, `day`,
gobernador, `updates`,
pomodoro y `der`; a la derecha `izq`, servicios, temperatura, RAM, CPU,
red, volumen y batería. Barra de 30 px con fondo del modo activo, fuentes 10/13 y flechas del color del
bloque; temperatura conserva fondo en warning. Se cambia con
`~/.config/polybar/polybar-variant referencia` o `... actual`.

La fase 1 termina en el escritorio. No implementar todavía:

- VS Code y Node/nvm. Neovim sí se usa para editar archivos.
- Firefox ESR, OpenH264 y \`userChrome\` (sustituidos por Brave, ADR-113).
- Correo, Teams.
- Reproductores de música locales (cmus/mpd) y widgets de música. `mpv` y
  `yt-dlp` sí se usan para streaming de YouTube; VLC para vídeo local.
- Bluetooth, htop, ripgrep, nvitop/nvtop.
- XFCE, LightDM, Thunar como entorno completo (Thunar sí se instala como
  gestor de archivos puntual).

## Reglas de trabajo

1. **No ejecutar la instalación real en un host con datos** sin backup y sin
   una VM validada. Para pruebas usar una VM Debian 13 minimal con snapshot.
2. **Mantener la idempotencia.** Volver a ejecutar el instalador no debe
   romper el sistema. Los backups se hacen **antes** de escribir.
3. **Mantener `--dry-run` libre de modificaciones.** No debe descargar,
   instalar, escribir configuraciones ni habilitar servicios. Solo puede leer
   hardware y mostrar el plan.
4. **No guardar contraseñas.** El instalador usa `sudo -v` y `sudo`; nunca
   escribe credenciales. Debian 13 y x86_64 se validan antes de pedir `sudo`.
5. **Backups antes de reemplazar.** Sistema:
   `/var/backups/dwm-setup/<timestamp>/`; usuario:
   `~/.config-backup/dwm-setup/<timestamp>/`. El backup debe contener la
   versión **anterior**, no la recién renderizada.
6. **Propiedad correcta del home.** `~/.config`, `~/.local`,
   `~/.config-backup` y los logs pertenecen al usuario, no a root. Usar
   `make_user_dir`/`run_user` y `chown_managed_paths`; no crear directorios
   con `install -d` como root sin `-o/-g` para el usuario.
7. **Fallos visibles.** No ocultar errores de compilación, paquetes o
   servicios. Los grupos opcionales pueden avisar y continuar; los
   obligatorios deben detener la instalación.
8. **No modificar repositorios APT sin autorización explícita.** El preflight
   lee los componentes habilitados (`main`, `contrib`, `non-free`,
   `non-free-firmware`). Si falta `main`, aborta. Si faltan componentes
   opcionales, ofrece un menú: añadirlos, continuar sin ellos o cancelar.
   Solo la opción 1 modifica fuentes, y debe hacer backup, tocar únicamente
   entradas oficiales de Debian 13, ejecutar `apt update` y comprobar de
   nuevo. `--dry-run` y `--yes` nunca modifican repositorios.
9. **No introducir PulseAudio como servidor.** PipeWire es el servidor;
   `pulseaudio-utils` solo aporta `pactl`.
10. **No introducir NVIDIA/CUDA incondicionalmente.** La GPU se detecta; el
    driver propietario es opcional y se omite con Secure Boot activo salvo
    `--nvidia`. Con driver presente el instalador deja `prime-run` (offload
    por app a la dGPU, ADR-111) y `nvidia-vulkan-icd`; sin driver no crea
    nada. La Intel sigue primaria en Xorg. Docker GPU
    (nvidia-container-toolkit) solo documentado, nunca automático.
11. **No abrir gestores de archivos automáticamente** al montar USB.
    `udiskie` solo monta y notifica; Thunar se abre con `Super+Shift+f`.
12. **Mantener las rutas portables.** Las plantillas usan `@HOME@`, `@FONT@`,
    `@FONT_SIZE@`, `@KEYMAP@`, `@WALLPAPER@`, `@RESOLUTION@`. No hardcodear
    `/home/luc`.
13. **No renderizar `@DEFAULT_SINK@`.** Es una cadena literal de `pactl`.
14. **`bspwmrc` debe ser ejecutable.** bspwm no lo ejecuta si no tiene `+x`;
    sin él no hay sxhkd, polybar ni autostart.
15. **No lanzar `kitty` desde `.xinitrc`.** El terminal se abre con
    `Super+Return`.
16. **Actualizar la documentación** (`PROGRESS.md`, `DECISIONS.md`,
    `docs/testing.md`) cuando cambie el diseño o se valide una prueba.
17. **Estilo:** Bash con `#!/usr/bin/env bash`, `set -Eeuo pipefail` en la
    entrada, funciones pequeñas, `printf`, arrays citados y `shellcheck` si
    está disponible. Los scripts instalados que corren en sesión usan
    `#!/bin/sh` POSIX; `desktop-doctor` y `desktop-safe` deben pasar `sh -n`.
18. **Atajos:** `templates/sxhkd/sxhkdrc.in` sigue el mapa de i3 del usuario
    (`Super+Return`, `Super+Shift+s` scrot región+portapapeles,
    `Super+Shift+d` rofi run, `Super+Shift+p/b/v/i/a`, `Alt+Tab`, etc.). Las
    apps que no están en fase 1 se dejan como bindings no-op. `Super+r`
    abre el modo resize: `resize-mode.sh` arranca un sxhkd hijo que captura
    solo `h/j/k/l` y `Escape`; `Escape` o 6 s sin teclas lo cierran.
    `Print` captura pantalla completa al portapapeles; `Super+Print` abre el
    menú de capturas. `Super+Alt+p` cicla A arriba → A abajo → B arriba → B abajo.
    `Super+Alt+t` alterna Catppuccin Mocha Black / Latte (`theme-mode toggle`).
    `Ctrl+Space` alterna flotante/tiled (además de `Super+Shift+Space`).
    Los argumentos `~...` de bspwm en `sxhkdrc` van entre comillas
    (`'~floating'`, `'~fullscreen'`, `'~east'`, `'~south'`): sxhkd ejecuta
    con `$SHELL` (zsh) y sin comillas `~floating` se expande a un usuario
    inexistente.
    `XF86AudioPlay/Next/Prev/Stop/Forward/Rewind` llaman a `music-ctl`
    (mpv vía MPRIS): play-pause y stop actúan sobre **todas** las
    instancias (stop = limpieza cuando ytwatch dejó varias sonando);
    next/prev/seek sobre el reproductor activo.
    ADR-112 retira `Super+h/j/k/l` (y su Shift): el ciclo de ventanas es
    `Alt+Tab` o `Super+c`. Escritorios dinámicos con
    `scripts/workspace.sh` (`focus/move/next/prev/daemon`): nombres
    densos `1..N`, nunca `^N`. `bspwmrc` arranca con `bspc monitor -d 1`;
    `Super+N` va al N si existe y, si no, crea el siguiente (`total+1`);
    `Super+Shift+N` igual pero moviendo la ventana; el daemon borra al
    cambiar de foco los vacíos y renumera para no dejar huecos.
    `Ctrl+Tab` y `Ctrl+Shift+Tab` cambian de escritorio (petición del
    usuario; el navegador usa `Ctrl+PageUp/PageDown`), además de
    `Super+Ctrl+(Shift+)Tab` y `Super+bracket{left,right}`. No cambiar
    este mapa sin una decisión nueva.
19. **Audio portable.** El watcher elige auriculares > HDMI > altavoces
    detectando tarjetas/perfiles/puertos con `pactl`; no hardcodear
    `alsa_card.*`, nombres de monitor ni perfiles salvo como fallback
    documentado. Si el sink o source predeterminado es USB/Bluetooth, no se
    pisa. El quirk `alc255-asus` solo se aplica en ASUS FX504GE con códec
    ALC255; en otro hardware se omite. `--headset-quirk` fuerza y
    `--no-headset-quirk` desactiva. El sonido de dunst usa
    `sound-theme-freedesktop` y `paplay`/`pw-play`; `stack_duplicates = false`
    hace que cada mensaje suene, `gap_size = 6` los separa y `flock` serializa
    sonidos simultáneos. Las capturas de región usan
    `scrot -s --line mode=edge,color=#FF00FF,width=2,opacity=255` y un
    `xrefresh` posterior para borrar el rectángulo residual; el magenta se
    ve sobre fondo blanco. La notificación usa como icono
    `~/.cache/dunst/last-screenshot.png` (64 px) para mostrar el recorte.

20. **Paleta única.** Todos los colores de las configuraciones renderizadas
    deben venir de `templates/colors/palette-<tema>.sh` mediante
    `@COLOR_*@`. Solo hay dos paletas: `mocha-black` (oscuro, por defecto) y
    `latte` (claro). `mocha-black` es Catppuccin Mocha con la rampa de
    superficies a casi negro (`#0d0d14`, `#08080d`, `#050509`, `#1a1a24`,
    `#26262f`, `#35353f`) y acento azul `#89b4fa`; `latte` usa
    `#eff1f5`/`#4c4f69` con acento `#1e66f5`. El terminal usa
    `COLOR_TERM_BG` y la rampa `COLOR_TERM_0..15` de cada paleta. Los ajustes
    que no son color pero dependen del modo (`THEME_GTK`, `THEME_ICONS`,
    `THEME_VLC_DARK`, `THEME_FIREFOX_DARK`, `THEME_PREFERS_DARK`,
    `THEME_CONTENT_OVERRIDE`) también salen de la paleta. No introducir hex a
    mano en plantillas nuevas; las únicas excepciones son `#FF00FF` (selector
    de scrot) y `#00000000` (transparencia de la barra B). `lib/verify.sh`
    comprueba que no haya colores fuera de la paleta activa.

20b. **Modo de color en caliente.** `theme-mode dark|light|toggle|status`
    cambia entre las dos paletas re-renderizando desde
    `~/.local/share/dwm-setup` (plantillas y paletas instaladas) y recargando
    polybar, dunst, bspwm y kitty. No debe pedir sudo. Si se añade una
    plantilla con color, hay que incluirla en el store de `lib/config.sh` y en
    `bin/theme-mode`. kitty se recolorea con
    `kitty @ set-colors --all --configured <colorsheme>`, que exige
    `allow_remote_control socket-only` y `listen_on unix:kitty-{kitty_pid}`
    en `kitty.conf`; sin ese socket, kitty solo cambia al reiniciarse.

21. **No commitear sin permiso.** No ejecutar `git commit` ni `git add`
    definitivo sin autorización explícita del usuario.

22. **Brave y Teams.** `brave-browser` es el navegador del escritorio
    (ADR-113) y `Super+Shift+b` lo abre. Se instala desde el **repo APT
    oficial** de Brave (llave en
    `/usr/share/keyrings/brave-browser-archive-keyring.gpg`, fuente
    `brave-browser-release.list`; autorizado por el usuario, regla 8).
    `/etc/brave/policies/managed/dwm-setup.json` apaga telemetría
    (P3A, stats ping, Web Discovery, Rewards, Wallet, News, Talk, VPN,
    Leo, metrics/crash, UKM, sugerencias y surveys) y fuerza por
    `ExtensionSettings` SurfingKeys (`gfbliohnnapiefjpjlpjnehglfpaknnc`)
    y el tema oficial Catppuccin Mocha
    (`bkkmolkhemgaeaeggcmfbghljjjoofoh`).
    Los atajos nativos viven en `brave.accelerators` del perfil
    (`Preferences`): `lib/brave.sh` escribe Ctrl+N/P (pestañas,
    quitándolos de ventana nueva/imprimir), Alt+Q cerrar, Alt+O
    recargar, Alt+K nueva pestaña, Alt+N expandir/colapsar pestañas
    verticales, Alt+Shift+N ventana nueva, Ctrl+Alt+L dividir con la
    pestaña actual, Ctrl+Alt+H nueva vista dividida, y Alt+H/Alt+L para
    saltar al panel izquierdo/derecho de la vista dividida (son
    "panel anterior/siguiente", cíclicos). Alt+H ya no abre el
    historial: queda solo Ctrl+H. IDs 34016/17/15/02, 34014, 56215,
    34000, 34057, 56325, 39005 (panel anterior) y 39004 (panel
    siguiente). Con Brave abierto ese paso se omite (se pide cerrarlo y
    repetir). `verify.sh` exige las policies y los atajos.
    La config de SurfingKeys se genera en
    `~/.config/dwm-setup/surfingkeys.js` y se pega una vez a mano: la
    extensión no lee archivos locales sin native host. Mantiene el mapa
    heredado (`o` = búsqueda Google por el alias `go`, `O` = pestaña
    nueva, `b` = elegir pestaña, `H`/`L` = atrás/adelante). Los
    `Alt+…` nativos (Alt+Q/O/H/K/N) los captura Brave antes que la
    página, así que no se mapean en SurfingKeys: el historial de páginas
    queda en `<Alt-y>`. Los hints se pintan a 15px con
    `Hints.style(...)` y las variables `--sk-*` de `:root` (shadow
    root). La interfaz se limpia con `install_brave_minimal`
    (`brave.new_tab_page.*`, iconos de la barra y pestañas verticales);
    `BookmarkBarEnabled: false` quita la barra de marcadores y
    `NewTabPageLocation` apunta a `/usr/share/dwm-setup/newtab.html`
    (renderizado desde `templates/brave/newtab.html.in`, negro liso).
    Chromium no
    soporta `userChrome`/CSS de UI: el tema es el de CWS (Mocha
    estándar, no el mocha-black exacto) y no se puede replicar el
    minimalismo de Firefox. VA-API queda activo por
    `install_brave_vaapi`: wrapper `~/.local/bin/brave-browser` con
    `--enable-features=VaapiVideoDecoder` y `.desktop` de usuario que
    apunta a él (Brave borra ese flag de `Local State` al salir). El
    instalador aborta si Brave está abierto (preflight en `install.sh`). Firefox, OpenH264 y sus
    policies/autoconfig ya no se instalan.

23. **Bandeja del sistema.** Polybar usa `internal/tray` en A y B, al final
    de `modules-right`. Solo soporta XEmbed; las apps que usan
    StatusNotifierItem (Telegram moderno, Discord/Electron) pueden no
    aparecer y necesitarían `snixembed`, que no está en Debian 13 stable.
    No ejecutar otro tray (stalonetray, nm-applet como host) a la vez.

24. **Pantalla siempre encendida.** `autostart` ejecuta `xset s off` y
    `xset -dpms`; no hay bloqueo por inactividad. No reintroducir blanking,
    DPMS ni `xset dpms force off` en scripts de sesión. El bloqueo manual
    (`Super+Shift+L`) y el de suspensión siguen activos. Las notificaciones
    de dunst **deben verse también con una ventana a pantalla completa**:
    no poner `fullscreen = delay` ni `pushback` en `dunstrc` (el valor por
    defecto, `show`, es el deseado).

25. **Compositor picom (ADR-107).** picom 12.5 inicializa la sesión desde
    `autostart` (antes de polybar, con guard `pgrep -x picom`) usando
    `~/.config/picom/picom.conf` generado desde `templates/picom/`:
    `backend glx`, `vsync true`, `use-damage`, fade sutil (delta 5,
    pasos 0.035) que excluye dock/notificaciones/desktop, `shadow true`
    sutil (radius 10, opacity 0.35, offsets -8/-8, sin sombra en
    dock/desktop) y todas las opacidades a 1. **No añadir blur ni
    transparencias de picom** (romperían la decisión tomada en vivo);
    la translucidez de la barra B es el fondo `#00000000` de
    polybar, no un alpha de picom. `unredir-if-possible` deja pasar el
    vídeo a pantalla completa. picom usa libconfig: comentarios `#`, no
    `;`. Si se añade color a alguna plantilla nueva de picom, entra al
    store (regla 20b); hoy no tiene.

26. **Gobernador de CPU (ADR-108).** El módulo `governor` va en la A
    justo tras `cpu` en `modules-right` y en la B en `modules-left`
    tras `day`; cicla la lista leída de `scaling_available_governors`
    (nada hardcodeado): clic → helper
    `/usr/local/bin/dwm-setup-cpu-governor` vía `sudo -n` + toast dunst.
    Esa escritura de raíz solo está admitida con el fragmento
    `/etc/sudoers.d/dwm-setup-cpu-governor` (`NOPASSWD` para ese binario
    exacto, validado con `visudo -cf` antes de instalar); no ampliar el
    sudoers. La unidad `dwm-setup-cpu-governor.service` aplica
    `performance` al boot. La carga de la batería se limita al 80 % con
    `battery-charge-threshold.service` + `dwm-setup-battery-limit`
    (`lib/power.sh`), solo si existe
    `/sys/class/power_supply/BAT*/charge_control_end_threshold`;
    `desktop-doctor` avisa si la salud cae por debajo del 60 %. El modo
    del ventilador se cicla desde el módulo `fan` (tras `governor` en A,
    tras `cpu` en B): `dwm-setup-fan-mode` detecta
    `fan_boost_mode`/`throttle_thermal_policy` (normal/overboost/silent)
    o `platform_profile` (quiet/balanced/performance); sin backend el
    módulo se oculta con `exec-if` y no se escribe sudoers. Iconos:
    `U+F0210` normal, `U+F0241` overboost, `U+F0717` silent. Estado en
    `~/.config/dwm-setup/fan-mode` (`auto` por defecto o `manual:<modo>`);
    el clic cicla `auto → normal → overboost → silent → auto` y
    `dwm-setup-fan-auto` solo actúa en `auto` (80 °C/80 % 10 s para subir,
    70 °C/<40 % 30 s para bajar). Energía:
    `dwm-setup-power-auto` aplica `performance` con cargador y `powersave`
    + EPP `balance_performance` + suelo 1.2 GHz con batería; el clic del
    gobernador usa el mismo helper `dwm-setup-power-profile`. Iconos del módulo: `U+F10CB`
    performance, `U+F0F86` powersave (font-3); el acento performance
    sale de `@COLOR_ACCENT@` en `scripts/cpu-governor.sh` (re-render de
    `theme-mode`, regla 20b). EPP/balanceado queda fuera hasta decisión
    nueva.

27. **ytwatch (ADR-109).** Buscador TUI opcional, por defecto ON con
    `--no-ytwatch` para saltarlo. Versiones fijadas con SHA-256 en
    `lib/ytwatch.sh`: binario de GitHub en `~/.local/bin` (usuario, sin
    sudo) y `ueberzugpp` 2.9.10 por `.deb` directo del proyecto (nunca
    añadir el repo OBS a APT; solo `dpkg -i` + `apt-get -f`). ytwatch
    usa el yt-dlp oficial y mpv; `yt-play`, `ytdlp-{check,update,
    rollback}` y las notificaciones dunst NO se retiran. La config va
    de `templates/ytwatch/config.toml.in` (tema `terminal`, sin hex:
    no entra en el store 20b), browser es `brave-browser` y
    `audio_only = false` (vídeo por defecto; `a` conmuta a audio en el
    TUI; cambiar el default exige decisión). Actualizaciones: `ytwatch-check` (avisa por dunst) y
    `ytwatch-update` (`--ueberzugpp` para el paquete); `lib/ytwatch.sh`
    instala ambos en `~/.local/bin` (usuario, sin sudo) — sin ellos el
    timer de avisos no puede revisar ytwatch. **Sin binding de
    sxhkd**: se lanza tecleando `ytwatch`. Un **timer de usuario**
    `dwm-setup-yt-update-notify.timer` (13:00 diario; `Persistent`
    cubre el arranque después de esa hora) ejecuta
    `bin/yt-update-notify`: corre los dos checkers con
    `--quiet --no-notify` y manda un único toast de dunst; no toca APT
    ni el módulo `updates` de polybar. El doctor global con avisos
    dunst de todo el sistema es backlog, no fase actual. `lib/sysctl.sh`
    instala `vm.swappiness=10` vía `/etc/sysctl.d/` (23 GB de RAM).
    `lib/boot.sh` acorta el arranque: `GRUB_TIMEOUT=2`, quita
    `/etc/modules-load.d/nvidia.conf` (nvidia-drm se carga con
    `prime-run`), difiere `systemd-tmpfiles-clean.timer` (`OnBootSec=1h`)
    y desactiva `NetworkManager-wait-online`. Medido antes: 22,4 s de
    boot (GRUB 8,6 + modules-load 6,3 por nvidia + tmpfiles 4,8).

## Estructura relevante

| Archivo | Responsabilidad |
|---|---|
| `install.sh` | Flujo, opciones, confirmación, backups y resumen |
| `lib/common.sh` | Logs, sudo, ownership, backups, render, helpers |
| `lib/detect.sh` | Detección de sistema/hardware y usuario |
| `lib/packages.sh` | Preflight APT, paquetes, cadena de compilación y autoremove |
| `lib/bspwm.sh` | bspwm, bspwmrc, autostart, scripts y `.xinitrc` |
| `lib/sxhkd.sh` | sxhkdrc |
| `lib/polybar.sh` | config.ini, módulos, scripts y launch.sh |
| `lib/cpu.sh` | Gobernador de CPU: helper root, sudoers y unidad systemd |
| `lib/picom.sh` | picom: config del compositor (glx + vsync + fade) |
| `lib/dunst.sh` | dunstrc |
| `lib/rofi.sh` | powermenu.rasi |
| `lib/kitty.sh` | kitty.conf y paleta del terminal |
| `lib/zsh.sh` | zsh, Oh My Zsh y lsd |
| `lib/ranger.sh` | ranger, zathura, VLC y previews (método `kitty`) |
| `lib/gpu.sh` | configuración Xorg/i915/NVIDIA por hardware |
| `lib/gtk.sh` | temas GTK Catppuccin, tema derivado e iconos |
| `lib/vlc.sh` | VLC con paleta oscura (`qt-dark-palette`) |
| `lib/config.sh` | Configs de usuario, wallpaper y binarios de sesión |
| `lib/fastfetch.sh` | fastfetch: config y logos `Neofet-{light,dark}.png` |
| `lib/music.sh` | yt-dlp oficial, scripts de streaming y teclas |
| `lib/ytwatch.sh` | ytwatch (binario GitHub) y ueberzugpp (.deb OBS) con SHA-256 |
| `lib/brave.sh` | Brave: repo APT, policies, atajos y SurfingKeys |
| `lib/verify.sh` | Verificación estática final |
| `lib/theme.sh` | Paletas (Mocha Black, Latte), par de modos y render |
| `lib/audio.sh` | Quirk ALC255 condicionado por DMI/códec |
| `bin/desktop-safe` | Acciones de sesión (lock/suspend/logout/poweroff) |
| `bin/desktop-doctor` | Diagnóstico y cámara (POSIX sh) |
| `bin/dwm-setup-cpu-governor` | Helper root del módulo governor: valida y escribe `scaling_governor` |
| `templates/bspwm/` | bspwmrc, autostart (con picom) y scripts de sesión (incl. thunar-defaults y workspace.sh, ADR-112) |
| `templates/sxhkd/` | sxhkdrc |
| `templates/polybar/` | config.ini, modules/ (incl. governor), scripts/ (cpu-governor.sh) y variants/ |
| `templates/dunst/` | dunstrc y notification-sound.sh |
| `templates/rofi/` | powermenu.rasi y config.rasi |
| `templates/kitty/` | kitty.conf y colorshemes/ |
| `templates/zsh/` | zshrc |
| `templates/lsd/` | config.yml e icons.yaml |
| `templates/ranger/` | rc.conf, rifle.conf y previews |
| `templates/xorg/` | 20-modesetting.conf |
| `templates/picom/` | picom.conf.in (libconfig: comentarios `#`) |
| `templates/sudoers/` | Fragmento de sudoers del gobernador (`@USER@`) |
| `templates/systemd/` | `dwm-setup-cpu-governor.service` (performance al boot) |
| `templates/gtk/` | settings GTK2/3/4 y CSS |
| `templates/brave/` | `surfingkeys.js.in` (config para pegar a mano) |
| `templates/vlc/` | vlcrc (oscuro o claro según el modo) |
| `templates/zathura/` | zathurarc |
| `templates/themes/` | `catppuccin-mocha-blue` y `catppuccin-latte-blue` |
| `templates/fastfetch/` | `config.jsonc.in` (logo PNG y módulos) |
| `assets/fastfetch/` | `Neofet-{light,dark}.png` |
| `templates/icons/` | `papirus-folders` y carpetas `cat-mocha-blue`/`cat-latte-blue` |
| `bin/theme-mode` | Cambio de modo dark/light en caliente |
| `bin/yt-play` | Reproduce audio o vídeo de YouTube (URL o búsqueda con fzf) |
| `bin/yt-preview` | Miniatura del vídeo para el preview de fzf |
| `bin/ytdlp-check` | Avisa si hay versión nueva de yt-dlp |
| `bin/ytdlp-update` | Actualiza yt-dlp con copia y rollback |
| `bin/ytdlp-rollback` | Restaura la copia anterior de yt-dlp |
| `bin/music-ctl` | Teclas multimedia del reproductor activo |
| `bin/ytwatch-check` | Avisa (dunst) si ytwatch o ueberzugpp van desactualizados |
| `bin/ytwatch-update` | Actualiza ytwatch (checksums.txt) o ueberzugpp (`--ueberzugpp`) |
| `bin/yt-update-notify` | Wrapper del timer: agrupa los dos checkers en un toast dunst |
| `lib/yt-notify.sh` | Instala el timer de usuario de avisos (unidades + enable) |
| `lib/boot.sh` | Arranque: GRUB 2 s, nvidia fuera del boot, tmpfiles diferido, sin wait-online |
| `lib/power.sh` | Límite de carga de batería (80 %) vía sysfs + unidad systemd |
| `lib/fans.sh` | Modo del ventilador: helper root y sudoers acotado |
| `lib/sysctl.sh` | Instala `/etc/sysctl.d/99-dwm-setup-swappiness.conf` |
| `templates/ytwatch/` | `config.toml.in` (tema `terminal`, audio default, preview kitty) |
| `templates/sysctl/` | `99-dwm-setup-swappiness.conf` (vm.swappiness=10) |
| `templates/modprobe/` | i915.conf, nvidia.conf y alsa-fx504.conf (quirk ALC255) |
| `templates/nvidia/prime-run` | Wrapper de offload por app a la dGPU NVIDIA (ADR-111) |
| `templates/colors/` | `palette-mocha-black.sh`, `palette-latte.sh` y helpers |
| `assets/wallpaper.png` | Wallpaper principal |
| `assets/wallpaper-alt.png` | Wallpaper alternativo |

Ya no existen `src/chadwm`, `src/eww`, `legacy/`, `lib/dwm.sh`,
`lib/eww.sh`, `lib/ly.sh`, `templates/dwm/` ni la integración de dotfiles
externos. No reañadirlos sin una decisión nueva en `DECISIONS.md`.

## Comandos de validación

```sh
cd ~/dwm-setup

# Sintaxis
for f in install.sh lib/*.sh; do bash -n "$f" || exit 1; done
for f in bin/desktop-safe bin/desktop-doctor bin/dwm-setup-cpu-governor; do sh -n "$f" || exit 1; done
sh -n templates/polybar/scripts/cpu-governor.sh.in
bash -n bin/theme-mode
bash -n bin/yt-play bin/yt-preview bin/ytdlp-check bin/ytdlp-update \
  bin/ytdlp-rollback bin/music-ctl bin/ytwatch-check bin/ytwatch-update \
  bin/yt-update-notify
bash -n templates/bspwm/autostart.in templates/bspwm/bspwmrc.in
sh -n templates/bspwm/scripts/workspace.sh.in

# Gobernador: lista oficial y sudoers renderizado (sin tocar el sistema)
sh -n bin/dwm-setup-cpu-governor
sed "s/@USER@/$(id -un)/g" templates/sudoers/dwm-setup-cpu-governor.in > /tmp/opencode/sudoers-render
visudo -cf /tmp/opencode/sudoers-render
systemd-analyze verify templates/systemd/dwm-setup-cpu-governor.service
# (el aviso "Command ... is not executable" es normal: falta hasta sudo ./install.sh)

# Plan sin cambios (incluye apt-mark manual + autoremove simulados)
./install.sh --dry-run

# Comprobar restos y coherencia de la barra
grep -RInE '@[A-Z][A-Z0-9_]*@' ~/.config/bspwm ~/.config/sxhkd \
  ~/.config/polybar ~/.config/dunst ~/.config/rofi \
  ~/.config/kitty ~/.xinitrc
grep -nE 'modules-(left|right)' ~/.config/polybar/config.ini
stat -c '%A %n' ~/.config/bspwm/bspwmrc ~/.xinitrc

# ShellCheck (si está instalado)
shellcheck install.sh lib/*.sh bin/desktop-safe bin/desktop-doctor \
  bin/dwm-setup-cpu-governor bin/theme-mode bin/yt-play bin/yt-preview \
  bin/ytdlp-check bin/ytdlp-update bin/ytdlp-rollback bin/music-ctl \
  bin/ytwatch-check bin/ytwatch-update

# Streaming y limpieza
ytdlp-check
ytwatch-check
./install.sh --dry-run 2>&1 | grep -A2 'Limpiando dependencias'

# Modo de color (no pide sudo)
theme-mode status
theme-mode --no-reload light && theme-mode --no-reload dark

# Diagnóstico en una sesión instalada
desktop-doctor
desktop-doctor --camera
```

## Estado esperado al retomar

- El código de fase 1b está implementado y los checks estáticos pasan.
- Catppuccin (Mocha Black + Latte) implementado el 2026-11-02: dos paletas,
  `theme-mode`, temas GTK vendorizados y temas de iconos overlay. Pasan
  `bash -n`, `--dry-run` con ambas paletas y `theme-mode --no-reload` en un
  HOME simulado. Pendiente probar el cambio de modo en la sesión viva
  (la instalación ya está aplicada).
- La sesión viva se validó el 2026-10-24: bspwm, sxhkd, polybar (A 13 /
  B 15 módulos), dunst, lxpolkit, udiskie, xss-lock y picom activos;
  `startx` manual. picom es el compositor de la sesión (ADR-107) y la
  barra B usa su fondo transparente frente al compositor.
- Pantalla siempre encendida (2026-11-02): `autostart` aplica `xset s off`
  y `xset -dpms`; `i3lock-fancy` ya no fuerza DPMS off. Aplicado en vivo y
  sincronizado en `~/.config/bspwm` con backup; falta `sudo ./install.sh`
  para el resto del bloque y prueba de inactividad >10 min.
- Streaming (2026-11-02): `yt-play` (20 resultados, lista de títulos y
  preview al 50% con metadatos + chafa), `yt-preview`,
  `ytdlp-{check,update,rollback}` y `music-ctl` implementados. `yt-play`
  acepta `--audio` (por defecto) y `--video` (ventana de mpv al 80%); en
  fzf, Enter usa el modo por defecto y Ctrl+V el otro. `Ctrl+Space` alterna
  flotante/tiled; los `~...` de bspwm van entre comillas en sxhkdrc porque
  sxhkd usa zsh. `--dry-run` y la simulación pasan. La instalación se
  aplicó el 2026-11-04 13:13; pendiente probar audio, vídeo y
  Ctrl+Space en la sesión viva.
- picom + módulo `governor` (2026-11-04): picom 12.5 integrado
  (ADR-107) tras prueba del usuario en vivo; `templates/picom/`,
  `lib/picom.sh`, bloque en `autostart` y checks en `verify.sh`. El
  módulo `governor` (ADR-108) está en ambas variantes con helper root,
  sudoers acotado (validado con `visudo -cf`) y unidad systemd
  (`performance` al boot). Barra y picom aplicados en viva y
  reiniciados (picom pid activo, polybar con el módulo). El bloque
  root quedó instalado con el `sudo ./install.sh` de las 13:13
  (unidad habilitada). Tras el install, el usuario afinó a mano la
  barra: el port de esos tweaks a las plantillas quedó validado con
  render idéntico (9/9) y el store de theme-mode sincronizado.
  Pendiente: prueba visual del fade y del alternado por clic con
  reinicio de polybar si hace falta.
- Autoremove (2026-11-02): la cadena de compilación queda marcada como
  manual y `apt-get -y autoremove` corre al final, después de verificar.
- Se corrigieron backups previos, ownership, `bspwmrc` 0755,
  `desktop-doctor`, batería baja y polkit.
- Audio: watcher auriculares > HDMI > altavoces, sonido de dunst y quirk
  ALC255 condicionado a ASUS FX504GE. La validación del quirk requiere
  reinicio; el resto se probó en vivo el 2026-10-24.
- Falta validar una instalación desde cero en VM Debian 13 y subir el repo.
- `PROGRESS.md` contiene la lista de pruebas y bloqueos.
- Si se completa una prueba real, actualizar `PROGRESS.md` y
  `docs/testing.md` con fecha, hardware, fuentes y resultados. Si no hay
  resultado real, marcarlo como pendiente.
