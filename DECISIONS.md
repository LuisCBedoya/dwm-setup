# Decisiones de arquitectura

Registro de decisiones importantes. Formato: contexto, decisión,
consecuencias. Las decisiones se pueden reemplazar con una entrada nueva; no
se borra la historia.

## ADR-001 — Solo Debian 13 (trixie)

**Contexto:** el proyecto nace de un equipo con Debian 13 y un prototipo
anterior con decisiones mezcladas de Arch/Artix/NixOS.

**Decisión:** la fase 1 soporta exclusivamente Debian 13 x86_64. El instalador
aborta en cualquier otra distribución o versión.

**Consecuencias:** paquetes y nombres de servicios son Debian; no hay
abstracción multi-distro. Arch/Artix/NixOS quedan fuera de alcance.

## ADR-002 — chadwm como base de dwm

**Contexto:** el usuario usa chadwm y quiere conservar sus parches (gaps,
systray, status2d, tags, etc.).

**Decisión:** se mantiene chadwm y su `config.h` se renderiza desde
`templates/dwm/config.h.in`.

**Consecuencias:** el build depende de los headers X11/Xft/Xinerama/Imlib2.
No se adopta dwm 6.5 liso ni otro WM.

## ADR-003 — eww v0.6.0 compilado desde fuente

**Contexto:** Debian 13 no empaqueta eww; el dashboard/control center es parte
del diseño visual.

**Decisión:** compilar eww `v0.6.0` con features X11 y instalarlo en
`/usr/local/bin/eww`.

**Consecuencias:** se necesita Rust/Cargo y red en la primera instalación. Si
falla, el instalador se detiene antes de habilitar Ly; el escritorio base aún
puede recuperarse con `startx` si dwm ya está instalado.

## ADR-004 — Ly compilado desde fuente; fallback startx

**Contexto:** Debian 13 no tiene paquete `ly`. El usuario quiere Ly en lugar
de LightDM.

**Decisión:** compilar Ly en el commit
`4e0f23f08406f20b95146de6ce2e876918d7903d` con Zig `0.17.0`, instalar
`ly@tty2.service` y dejar `~/.xinitrc` como fallback.

**Consecuencias:** se descargan Zig y Ly; el commit/versión están fijados. La
compilación requiere `libpam0g-dev` y `libaudit-dev`, porque `pam.pc` exige
`audit.pc`. Ly lanza Xorg como el usuario de la sesión, así que el instalador
crea `~/.local/share/xorg` con modo `0700`; sin ese directorio Xorg no puede
escribir su log y la sesión no arranca. No se inicia Ly durante la instalación
para no matar la sesión actual. `startx` sigue siendo una vía de recuperación.

## ADR-005 — PipeWire, no PulseAudio

**Contexto:** el instalador de referencia usaba PulseAudio. El hardware
moderno y Debian 13 funcionan mejor con PipeWire.

**Decisión:** PipeWire + WirePlumber + `pipewire-pulse`; `pavucontrol` y
`pactl` se usan como clientes. No se instala el servidor PulseAudio.

**Consecuencias:** los scripts usan `pactl`/`wpctl`, pero el servidor es
PipeWire. Los códecs se instalan por separado (FFmpeg/GStreamer).

## ADR-006 — pcmanfm como gestor de archivos

**Contexto:** el prototipo usaba Thunar (XFCE), que se excluye.

**Decisión:** `pcmanfm`, accesible con `Mod+E` y desde rofi. No se instala
Thunar ni XFCE.

**Consecuencias:** se instalan `gvfs`/`gvfs-backends` para integración. No hay
auto-apertura al montar.

## ADR-007 — USB: montar y notificar, nunca abrir

**Contexto:** el requisito es evitar que un USB abra una aplicación
automáticamente.

**Decisión:** `udisks2` + `udiskie --automount --notify`, sin
`--file-manager`. `pcmanfm` se lanza solo por acción del usuario.

**Consecuencias:** el montaje es automático; la notificación la muestra dunst.
Si `udiskie` no está corriendo, `dwm-doctor` avisa.

## ADR-008 — NVIDIA condicional, sin CUDA

**Contexto:** el equipo de referencia tiene Intel Iris Plus + NVIDIA MX330;
el prototipo instalaba NVIDIA/CUDA sin condiciones.

**Decisión:** detectar GPU. Instalar `nvidia-driver` solo si hay NVIDIA y la
política automática lo permite: Secure Boot desactivado y no es una VM. Las
flags avanzadas `--nvidia`/`--no-nvidia` permiten forzar o desactivar.

No se instala CUDA.

**Consecuencias:** en Secure Boot activo se omite el driver por defecto y se
avisa. PRIME/offload se documenta, pero no se configura un `xorg.conf`
automático. La validación con hardware real está pendiente.

## ADR-009 — x86_64 exclusivo

**Contexto:** el hardware de referencia y los binarios descargados (Zig, eww,
Nerd Font) se eligen por arquitectura.

**Decisión:** soportar solo `x86_64`/`amd64`; abortar en otras.

**Consecuencias:** no hay soporte ARM en fase 1.

## ADR-010 — Instalador idempotente, con backups y dry-run

**Contexto:** el usuario quiere poder repetir la instalación y ver qué va a
pasar antes de tocar el sistema.

**Decisión:** `--dry-run` sin modificaciones; backups de sistema/usuario;
logs; compilaciones se omiten si el binario existe salvo `--rebuild`.

**Consecuencias:** una segunda ejecución no reinstala paquetes ya presentes,
aunque vuelve a ejecutar `apt-get update/install` (APT es idempotente), y no
recompila por defecto. Las configuraciones se reemplazan con backup; las
ediciones manuales se pierden si no se usa el backup.

## ADR-011 — Sesión basada en script, no en autostart XFCE

**Contexto:** no hay XFCE ni un session manager completo.

**Decisión:** `/usr/share/xsessions/dwm.desktop` ejecuta
`~/.config/dwm/run.sh`; `run.sh` inicia barra, eww, dunst, picom, udiskie,
lxpolkit, nm-applet (si existe) y xss-lock, y termina con `exec dwm`.

**Consecuencias:** el orden y los logs están centralizados. `~/.xinitrc`
ejecuta el mismo script como fallback. Ly puede ocultar shell/xinitrc para
mostrar solo dwm.

## ADR-012 — `dwm-safe` centraliza acciones de energía

**Contexto:** eww y los atajos necesitan apagar, reiniciar, suspender,
bloquear y cerrar sesión sin duplicar lógica.

**Decisión:** `bin/dwm-safe` se instala en `/usr/local/bin` y usa
`i3lock`, `systemctl`, `loginctl` y `dwm-doctor`. `xss-lock` lo llama para
bloquear antes de suspender.

**Consecuencias:** todos los widgets y atajos apuntan a `dwm-safe`; el
comportamiento es consistente. `suspend` comprueba que `xss-lock` esté activo
y falla de forma segura si no lo está, para no suspender sin bloquear.
`restart` mata dwm y no reinicia el proceso por sí solo (se documenta el atajo
Mod+Shift+R).

## ADR-013 — Fuente Nerd Font fijada

**Contexto:** los iconos de eww/barra/dunst necesitan Nerd Font; el paquete
`fonts-jetbrains-mono` de Debian no incluye los glifos Nerd.

**Decisión:** descargar JetBrainsMono Nerd Font `3.5.1` con SHA-256 fijo y
extraer en `/usr/local/share/fonts/JetBrainsMonoNerd`. Si falla, usar la
fuente de Debian y avisar.

**Consecuencias:** la primera instalación requiere red. Los iconos pueden
mostrarse como cuadros si la descarga falla; `dwm-doctor` lo detecta.

## ADR-014 — Fase 1 sin IDE, navegadores, correo ni música

**Contexto:** el usuario quiere avanzar por fases y no repetir el error de
instalar todo de golpe.

**Decisión:** no incluir Neovim/IDE, navegadores, correo/Teams, música,
Bluetooth, zathura, htop, lsd, ripgrep, nvitop/nvtop ni Node/nvm.

**Consecuencias:** la fase 1 es más pequeña y verificable. Las fases
posteriores deben añadir sus propios grupos y pruebas.

## ADR-015 — `PLAN.md` y prototipo antiguo son historia

**Contexto:** `PLAN.md` todavía dice “dwm 6.5, XFCE se queda, Thunar,
LightDM”, lo que contradice el diseño actual.

**Decisión:** conservar `PLAN.md` con un banner de obsoleto y mover los
archivos del prototipo a `legacy/`. La fuente de verdad es `README.md`,
`PROGRESS.md`, `AGENTS.md`, `DECISIONS.md`, `lib/` y `templates/`.

**Consecuencias:** no se borra historia, pero no se debe usar `legacy/` para
la instalación.

**Nota:** el directorio `legacy/` se eliminó posteriormente junto con
`src/chadwm/` y `src/eww/` (ADR-022). Este ADR se conserva como historial.

## ADR-016 — Fuentes de chadwm y eww vendorizadas (eliminadas en ADR-022)

**Contexto:** `src/chadwm` y `src/eww` eran repositorios Git anidados. Git los
registraba como gitlinks, sin `.gitmodules`, así que un clon del proyecto no
incluía las fuentes y la compilación de chadwm fallaba.

**Decisión:** incluir las fuentes directamente en el repositorio, sin
submódulos. Se fijan los commits upstream: chadwm `7991ac8` y eww `v0.6.0`
(`d87c2fd`). Los metadatos `.git` de los repos anidados no forman parte del
proyecto.

**Consecuencias:** un `git clone` era autocontenido para chadwm y eww; solo
Zig, Ly y la Nerd Font se descargaban durante la instalación.

**Nota (ADR-022):** con la migración a bspwm + sxhkd + polybar, chadwm/eww/Ly
se eliminaron. Los directorios `src/chadwm/`, `src/eww/` y `legacy/` se borraron
del repositorio. Este ADR se conserva solo como historial.

## ADR-017 — `--home` limitado al home real del usuario

**Contexto:** el instalador escribía configuraciones en `--home`, pero la
sesión arranca con el `HOME` de `/etc/passwd`. Con un home distinto, `run.sh`
buscaba la configuración en el home real y la sesión quedaba incompleta.

**Decisión:** `--home` solo se acepta si coincide con el home real del usuario
destino. Si no coincide, el instalador aborta antes de modificar el sistema.

**Consecuencias:** se evita una instalación parcial silenciosa. Un home
alternativo requeriría propagar explícitamente el home a `run.sh`, eww, kitty,
`dwm.desktop` y `dwm-safe`, y queda fuera de la fase 1.

## ADR-018 — Preflight APT con menú y auto-add autorizado

**Contexto:** el instalador no añadía repositorios y los grupos opcionales
(firmware, GPU, microcódigo, cámara) podían omitir paquetes sin que el usuario
viera las consecuencias hasta después de confirmar. A la vez, obligar a editar
`sources.list` a mano hacía la instalación frágil.

**Decisión:** leer los componentes APT habilitados con
`apt-get indextargets` antes de instalar. Si falta `main`, abortar: nunca se
auto-añade. Si faltan componentes opcionales, mostrar qué falta y ofrecer un
menú genérico: `1) añadir`, `2) continuar sin ellos`, `3) cancelar`. La opción
1 exige autorización explícita, hace backup de las fuentes, modifica solo
entradas oficiales de Debian 13 (`trixie`/`stable` y dominios `debian.org`),
ejecuta `apt update` y vuelve a comprobar. `--dry-run` solo muestra el aviso;
`--yes` continúa sin modificar repositorios.

**Consecuencias:** el usuario decide con información antes de tocar el sistema.
`contrib` se trata como cualquier componente opcional: solo afecta a
`nvidia-settings`, no al driver NVIDIA. Los grupos obligatorios siguen
abortando si falta un paquete; los opcionales avisan y continúan.

## ADR-019 — `./install.sh` como interfaz normal

**Contexto:** el uso normal requería recordar `--user`, `--home`, `--nvidia` y
otras flags. El instalador ya puede detectar el usuario, el home y el hardware.

**Decisión:** `./install.sh` es la interfaz normal. Detecta el usuario destino
(`SUDO_USER` o el usuario actual), su home real y el hardware, y solo pregunta
cuando hay una decisión real: confirmar la instalación o resolver componentes
APT. `--dry-run` y `--yes` quedan como opciones simples; las flags antiguas se
conservan solo para automatización avanzada y no se necesitan en uso normal.

**Consecuencias:** la instalación es más corta de explicar y menos propensa a
errores. Las flags avanzadas siguen disponibles para pruebas y automatización,
pero no se anuncian como parte del flujo normal.

## ADR-020 — Sistema de temas con paletas (`templates/colors/`, `lib/theme.sh`)

**Contexto:** el prototipo usaba `themes/gruvchad.h` hardcodeado en `config.h`.
El usuario quiere una paleta monocromática "Monolith" y mantener Gruvbox como
fallback, sin recompilar chadwm cada vez que se cambia un color.

**Decisión:**
- Paletas en `templates/colors/palette-<name>.sh` (formato HEX `#rrggbb`).
- `lib/theme.sh` carga la paleta, exporta helpers RGBA, y tiene generadores:
  `generate_bar_theme`, `generate_rofi_colors`, `generate_eww_scss`,
  `generate_eww_vars`, `generate_dunstrc`, `generate_picom_conf`,
  `generate_kitty_theme`, `generate_chadwm_config_h`.
- Plantillas `.in` con placeholders `@COLOR_*@`, `@THEME_NAME@`,
  `@HOME@`, `@FONT@`, `@FONT_SIZE@`, `@KEYMAP@`, `@WALLPAPER@`,
  `@RESOLUTION@` → renderizadas en instalación.
- Flag `--theme <monolith|gruvbox>` en `install.sh`; default `monolith`.
- `config.h.in` ya no incluye `themes/gruvchad.h`; colores inline.

**Consecuencias:**
- Cambiar el tema no requiere recompilar chadwm salvo `config.h` (se hace en
  `build_dwm` vía `generate_chadwm_config_h`).
- Todos los componentes (barra, rofi, eww, dunst, picom, kitty) usan la misma
  paleta de forma consistente.
- El dry-run muestra los assets generados.
- `pamixer` sustituye a `pactl`; `xwallpaper` a `feh`; `playerctl` para MPRIS.

## ADR-021 — Widgets eww completos en fase 1 (música, bluetooth, energía, nightlight)

**Contexto:** `AGENTS.md` excluye música, Bluetooth, reproductores y Bluetooth de
la fase 1. El usuario aprobó implementar los widgets con funcionalidad real
(stubs no aceptados), degradando a `N/A` si falta el paquete.

**Decisión:**
- Añadir `bluez` y `redshift` a `DESKTOP_PKGS` (dependencias reales, opcionales
  en runtime: los scripts devuelven "Off"/"N/A" si el demonio no corre).
- Scripts nuevos: `music` (playerctl/mpc), `bluetooth` (bluetoothctl),
  `network` (nmcli), `energy` (powerprofilesctl/auto-cpufreq/tuned/cpufreq),
  `nightlight` (redshift).
- Polls en `vars.yuck.in` para CPU/RAM/Disk (`cpu`, `ram`, `disk` scripts JSON).
- Variables de color desde `vars.yuck` (sin hardcodear hex en `widgets.yuck`).

**Consecuencias:**
- La fase 1 incluye control center funcional completo; no hay stubs.
- Si `bluez`/`redshift` no están instalados, los widgets muestran "Off" sin
  romper eww.
- `DECISIONS.md` registra la excepción explícita a `AGENTS.md`.

## ADR-022 — Migración a bspwm + sxhkd + polybar (fase 1b)

**Contexto:** El instalador original compilaba chadwm (C), eww v0.6.0 (Rust+webkitgtk)
y Ly (Zig). El usuario tiene una configuración bspwm madura y probada en
`/home/luc/Documentos/Bspwm` y quiere usarla tal cual, con `startx` en lugar de Ly,
para eliminar tres cadenas de compilación y reducir dependencias.

**Decisión:**
1. **Eliminar:** `lib/dwm.sh`, `lib/eww.sh`, `lib/ly.sh`, `src/chadwm/`, `src/eww/`,
   `templates/dwm/`, `/usr/share/xsessions/dwm.desktop`, servicio `ly@tty2`,
   `bin/dwm-safe`, `bin/dwm-doctor`.
2. **Añadir:** `lib/dotfiles.sh` (clona repo Git HTTPS opcional), `lib/bspwm.sh`,
   `lib/sxhkd.sh`, `lib/polybar.sh`, `lib/picom.sh`, `lib/dunst.sh`,
   `lib/rofi.sh`, `lib/kitty.sh`.
3. **Templates nuevos:** `templates/bspwm/`, `templates/sxhkd/`,
   `templates/polybar/`, `templates/picom/`, `templates/dunst/`,
   `templates/rofi/`, `templates/kitty/` — renderizados con paleta **Nord**
   (vendorizada en `templates/colors/palette-nord.sh`).
4. **Sesión:** `~/.xinitrc` ejecuta `bspwm` (su `autostart` levanta polybar, dunst,
   picom, udiskie, xss-lock, low_bat_notifier, xwallpaper). Sin display manager.
5. **Paquetes:** Añadir `bspwm sxhkd polybar` a `DESKTOP_PKGS`; quitar `zig`,
   `rustc cargo`, headers X11 de dwm, `libpam0g-dev`, `libaudit-dev`.
6. **Dotfiles opcionales:** Prompt interactivo para URL Git HTTPS de un repo
   `dotfiles`. Estructura esperada: `repo/config/.config/{bspwm,sxhkd,polybar,
   picom,dunst,rofi,kitty}`. Si el repo falta carpetas, pregunta si continuar
   con templates integrados o abortar.
7. **Batería condicional:** `polybar/launch.sh` detecta `/sys/class/power_supply/BAT*`
   y elige config con/sin módulo battery.
8. **Binarios:** `desktop-safe` (lock/suspend/logout/poweroff/reboot) y
   `desktop-doctor` (diagnóstico bspwm/sxhkd/polybar/cámara).

**Consecuencias:**
- **−3 compilaciones** (chadwm, eww, Ly) → instalación ~5 min más rápida, ~200 MB
  menos en build-deps, cero red para compilar.
- **Polybar 3.7.2** (C, en apt) reemplaza a eww v0.6.0 (Rust+webkitgtk, ~150–250 MB
  RSS en runtime).
- **startx** elimina display manager; usuario hace `startx` desde TTY o configura
  auto-login en `~/.bash_profile` / `getty@tty1`.
- **Configuración idéntica a `/home/luc/Documentos/Bspwm`**: 5 workspaces, gaps 10px,
  bordes 2px, keybindings completos, polybar modular con 12+ módulos, picom con
  esquinas redondeadas, dunst top-center, rofi powermenu 6 acciones, kitty con
  opacidad y tabs.
- **Templates como fallback** garantizan instalación reproducible sin red ni repo
  externo.
- **Paleta Nord** aplicada a todos los componentes (bspwm borders, polybar, dunst,
  rofi, picom, kitty).

## ADR-023 — Barra polybar réplica exacta del diseño de referencia

**Contexto:** El usuario tiene una captura de pantalla (EndeavourOS + bspwm + polybar)
que quiere replicar píxel a píxel en Debian 13. El diseño del screenshot difiere
de la config actual del repo Bspwm en varios puntos: fondo de barra `#0D1117` (no
`#000`), logo U+F2DD en extremo izquierdo, workspaces 1-5 con dígitos árabes (no
chinos), barra **arriba** (no abajo), sin subrayados visibles, altura ~26 px, y
módulos `updates` + `polypomo` ya integrados. La plantilla actual no tenía
`include-directory`, los módulos no se cargaban, y el módulo `bspwm` usaba
iconos chinos.

**Decisión:**
1. **`config.ini.in` reescrito** con colores exactos del screenshot
   (`background = #0D1117`, `foreground = #C9D1D9`), `height = 26`,
   `bottom = false`, `wm-restack = bspwm`, `include-directory = @HOME@/.config/polybar/modules`.
2. **13 módulos portados** tal cual del repo Bspwm (`modules/`), con glifos Nerd
   Font idénticos: `logo`, `bspwm`, `updates`, `polypomo`, `temp`, `memory`,
   `cpu`, `xkeyboard`, `eth`, `wlan`, `battery`, `pipewire`, `date`.
3. **Módulos condicionales en render time** (`@WLAN_MODULE@`, `@BATTERY_MODULE@`)
   — se omiten si no hay hardware, sin `sed` en `launch.sh`.
4. **Módulo `bspwm` con `%name%`** (dígitos 1-5), enfocado = caja `#C9D1D9`/
   `#0D1117` con padding 2.
5. **`polypomo` vendorizado** en `templates/polybar/scripts/polypomo` (solo stdlib
   Python 3). **`updates` reescrito a `apt-get -s upgrade`**.
6. **`launch.sh` simplificado**: solo `killall` + `polybar -r main`; la detección
   de hardware y la omisión de módulos ocurren en el render, no en runtime.
7. **`bspc config top_padding = 26`** en `bspwmrc.in` (variable `@BAR_HEIGHT@`)
   porque bspwm no respeta struts; así las ventanas no quedan bajo la barra.
8. **`python3` añadido** a `BASE_PKGS` para polypomo.

**Consecuencias:**
- Barra visualmente indistinguible del screenshot (colores, iconos, logo, layout,
  spacing).
- Sin `format-underline` ni `format-background` → barra plana y limpia.
- Glifo del logo U+F2DD (`fa-superpowers`) resuelto por JetBrainsMono Nerd Font
  (Font Awesome 6 no existe en Debian).
- Módulos `wlan`/`battery` desaparecen silenciosamente en desktop/VM sin hardware.
- Próxima validación en VM: comparar `startx` + screenshot lado a lado; afinar
  `pad`/`module-margin` si el espaciado no cuadra exactamente.

## ADR-024 — Glifos Nerd Font 3.x literales y unidades de espaciado de polybar 3.7

**Contexto:** La barra mostraba el texto `\uf2dd`, `\uf79f`, etc. en lugar de
los iconos. Polybar 3.7.2 **no interpreta escapes `\uXXXX`** en los `.ini`:
hay que escribir el carácter UTF-8 literal. Además, la fuente instalada es
JetBrainsMono Nerd Font 3.5.1 y los codepoints MDI que usaba el repo original
(`F85A`, `F6FF`, `F79F`, `FA7D`, `FA80`, `FAA8`) ya no existen en Nerd Fonts 3.
Por último, en polybar 3.7 los valores de `padding`/`margin` sin unidad se
interpretan como múltiplos del ancho del espacio de la fuente (tipo `SPACE`),
no como píxeles: con `padding-left = 4` y `format-padding = 6` la barra quedaba
demasiado separada. La detección de red solo miraba interfaces `UP` (omitía
`wlo1`, que está DOWN) y `xkeyboard` usaba `%layout%` en `format` en lugar de
`<label-layout>`.

**Decisión:**
1. Los templates de polybar llevan **glifos UTF-8 literales**; se prohíbe
   `\uXXXX` en `templates/polybar/`.
2. Mapeo a Nerd Fonts 3.5.1: memory `F035B`, eth `F0200`, updates `F03D7`,
   pipewire `F057E`/`F075F`, wlan `F091F`/`F0920`/`F0921`/`F0922`/`F05A9`;
   temp `F2CA`/`F2C8`/`F2C7`; logo `F2DD`, cpu `E266`, xkeyboard `F11C`,
   battery `F240`-`F244`.
3. Espaciado como la referencia (`var.pad = 2`): `padding-left/right = 1`,
   `format-padding`/`label-padding = 2`, `label-focused-padding = 1`.
4. `xkeyboard`: `format = <label-layout>` y
   `label-layout = "<glifo> %layout%"`.
5. Detección propia de polybar (`polybar_detect_*`) con
   `ip -br link show` (sin `up`, incluye interfaces DOWN) y batería
   `BAT*` + adaptador `AC*`/`ADP*`.
6. Verificación: `fc-list ':charset=...'` para cada glifo y arranque de polybar
   sin errores.

**Consecuencias:**
- Los iconos se renderizan y el espaciado se acerca al screenshot de referencia.
- Un glifo que no exista en la fuente se verá como tofu; hay que comprobar la
  cobertura antes de añadirlo.
- `wlan` se mantiene aunque `wlo1` esté DOWN; con `format-disconnected` vacío
  queda invisible (se puede mostrar `NoC` si se quiere).
- Cualquier `padding` nuevo debe recordar que, sin sufijo `px`, el número son
  espacios de la fuente, no píxeles.

## ADR-025 — Ajuste fino de espaciado y claridad de la barra polybar

**Contexto:** Con la barra ya funcional (ADR-023/024), la comparación con
`yo.png` seguía mostrando demasiado aire: el hueco logo→primer workspace era
42 px (referencia 15 px), los gaps entre módulos ~50 px (referencia ~30 px) y
los módulos se percibían menos nítidos que el workspace enfocado, que parecía
más grueso. Las capturas tienen el mismo color máximo de texto (`#C9D1D9`), así
que la diferencia era de peso/tamaño/contraste, no de color. En polybar 3.7.2
los `padding`/`margin` sin unidad son múltiplos del ancho del espacio de la
fuente, y el fondo de un label interno ocupa toda la altura de la barra (26 px)
tanto con JetBrainsMono Nerd Font size 10/11 como con Noto Sans CJK JP size 11:
cambiar la fuente del workspace **no** reduce la caja a los 19 px de `yo.png`.
`format-padding-right` no tiene efecto en polybar 3.7.2.

**Decisión:**
1. `foreground = #E6EDF3` (más claro que `#C9D1D9`) y `font-0` con
   `JetBrainsMono Nerd Font:style=SemiBold:size=10`; los módulos heredan ese
   peso/color. El workspace enfocado conserva texto oscuro sobre caja clara.
2. `module-margin-left/right = 0`; se mantienen `padding-left/right = 1` y
   `format-padding = 2` de los módulos.
3. Logo sin `format-padding` y con **un espacio literal al final** del
   `format`: el hueco logo→primer dígito queda en 15 px (7 px hasta el borde de
   la caja enfocada), sin tocar el resto de módulos.
4. Workspaces con `font-0` (SemiBold 10) en lugar de `font-2`; unifica el peso
   con los módulos y evita depender de Noto Sans CJK.
5. No se usa `format-padding` en el módulo bspwm: desplazaba el bloque entero
   y dejaba el hueco logo→dígito en ~23 px, más separado que la referencia.

**Consecuencias:**
- Gaps de módulos ~33-35 px (antes ~50 px; referencia ~29-31 px), hueco
  logo→primer dígito 15 px (antes 42 px), bloque derecho comienza ~1092 px.
- La caja enfocada queda en 24×26 px; la de `yo.png` es 22×19 px. La altura es
  una limitación de polybar 3.7.2 (el fondo del label ocupa la barra completa),
  no de la fuente. Igualar los 19 px exigiría parchear polybar o usar un widget
  propio; se documenta como diferencia conocida.
- `format-padding-right` no debe usarse para espaciar un módulo: polybar lo
  ignora silenciosamente. Usar `format-padding`, un espacio en `format` o
  `module-margin` global.
- Backup previo al cambio: `~/.config-backup/dwm-setup/20261021-182732/`.
- La barra viva se validó con 13 módulos, `latam`, `connected`, `100%`, `45%`,
  `25:00` y fecha; captura en `actual_03.png`.

## ADR-026 — Logo propio (fuente `DesktopLogo`) y tres puntos tras la hora

**Contexto:** El logo de `yo.png` no es el icono Nerd Font `U+F2DD`
(`fa-superpowers`) ni una letra S tipográfica: es una marca pequeña de
18×10 px con forma de arco y bloques. Ningún glifo de JetBrainsMono Nerd Font
3.5.1 reproducía esa forma. Además, la fecha no llevaba los tres puntos que sí
aparecen después de la hora en la referencia.

Durante las pruebas se comprobó que en polybar 3.7.2 el glifo privado
`U+E000` solo se renderiza de forma fiable cuando la fuente que lo contiene es
`font-0`. Poner `DesktopLogo` en `font-4` y seleccionarla con `%{T4}` o con
`format-font = 4` producía tofu. Por eso la fuente personalizada pasa a ser la
fuente primaria de la barra y los módulos de texto usan explícitamente
`font-1` (JetBrainsMono Nerd Font SemiBold 10).

**Decisión:**
1. Vendorizar `assets/desktop-logo.ttf` con familia **DesktopLogo**, generada
   a partir del recorte `18x10+9+8` de `yo.png`. El glifo útil es `U+E000`, a
   `pixelsize=10` y con offset vertical `2`; el espacio de la fuente mide
   300 unidades (3 px a ese tamaño).
2. Reordenar las fuentes de `templates/polybar/config.ini.in`:
   - `font-0 = "DesktopLogo:pixelsize=10;2"`
   - `font-1 = "JetBrainsMono Nerd Font:style=SemiBold:size=10;3"`
   - `font-2 = "JetBrainsMono Nerd Font:style=Bold:size=10;3"`
   - `font-3 = "JetBrainsMono Nerd Font:size=11;3"`
   - `font-4 = "JetBrainsMono Nerd Font:size=11;5"`
   - `font-5 = "Noto Color Emoji:scale=9:antialias=false;3"`
   El logo ya no ocupa `font-4`: pasa a `font-0`. Las antiguas `font-0..3`
   se desplazan a `font-1..4` y Noto sigue en `font-5`; la JBM Bold 12 que
   llegó a probarse como `font-4` no queda en la configuración. Todos los
   módulos de texto usan `font-1`; `updates` y `polypomo` añaden además
   `%{T1}` y `format-font = 1`.
3. El módulo `logo` no selecciona fuente: hereda `font-0` y usa
   `format = "%{O4}<U+E000> %{F-}"` (con el carácter `U+E000` literal, no la
   cadena `<U+E000>`). El offset de 4 px más el espacio de 3 px de la fuente
   deja el logo en `x=9..26`, la caja enfocada en `x=33..48` y el primer dígito
   en `x=39`, como la referencia.
4. La fecha usa `label-padding = 1` y `label-font = 1`. Se añade el módulo
   `dots` (`custom/text`, `U+22EF`, `font-1`, `format-padding = 0`) y se
   incluye al final de `modules-right`. La barra usa `padding-right = 2`.
5. `lib/polybar.sh` instala la fuente a nivel sistema en
   `/usr/local/share/fonts/dwm-setup/desktop-logo.ttf`, ejecuta
   `fc-cache -f /usr/local/share/fonts` y avisa si
   `fc-list :charset=e000` no encuentra DesktopLogo. `install.sh` exige el
   asset y `dots.ini.in`; `lib/verify.sh` comprueba ambos y la cobertura del
   glifo. `--dry-run` solo muestra la instalación de la fuente.
6. La barra viva se actualizó con la fuente de usuario
   (`~/.local/share/fonts/DesktopLogo/DesktopLogo.ttf`) y la captura final es
   `actual_04.png`.

**Consecuencias:**
- El logo queda en `x=9..26`, `y=8..17`, 18×10 px, y el primer dígito en
  `x=39`; la referencia mide exactamente lo mismo. Los tres puntos quedan en
  `x=1904..1911` con la fecha `07:59 PM`, frente a `1903..1912` de `yo.png`;
  el borde derecho de la barra queda en 1911 (referencia 1912).
- La caja enfocada mide 16×26 px y la referencia 22×19 px. La altura sigue
  siendo una limitación de polybar 3.7.2; el ancho depende del padding del
  label y no se fuerza para no mover el primer dígito de `x=39`.
- **Trampa de mantenimiento:** como `font-0` es DesktopLogo, cualquier módulo
  que no declare `font-1`/`format-font = 1` se renderizará con la fuente del
  logo y mostrará tofu para texto normal. Las pruebas con `%{T4}` no son
  suficientes; el glifo privado debe vivir en `font-0`.
- `fc-list :charset=e000` encuentra la fuente de usuario en la barra viva, pero
  la ruta de sistema `/usr/local/share/fonts/dwm-setup/desktop-logo.ttf` solo
  se valida tras una instalación real. Hasta entonces, `verify_install`
  fallará en ese punto si se ejecuta contra la barra viva.
- El TTF incluye glifos auxiliares (`U+2009`, `U+E001`) no usados por el
  formato actual; no se referencian en los templates.

## ADR-027 — Restaurar la separación de módulos y workspaces

**Contexto:** En ADR-026 se reindexaron las fuentes para que `DesktopLogo`
fuera `font-0`. En la misma iteración se cambiaron los paddings de los
módulos de la derecha de `format-padding`/`label-padding = 6` a `2`, y las
etiquetas de bspwm de `label-focused-padding = 2`/JBM 11 a `1`/JBM SemiBold
10. El resultado fue una barra con gaps visibles de 24–26 px entre módulos y
workspaces cada 16 px, más compacta que `actual_03` (gaps 33–35 px,
workspaces cada 24 px) y que la referencia `yo.png` (gaps 26–30 px). El hueco
logo→primer dígito seguía siendo 13 px, pero la caja enfocada se había
reducido de 24×26 a 16×26.

**Decisión:**
1. Restaurar la separación visible de `actual_03` con los valores que mejor
   funcionan con las fuentes actuales:
   - `config.ini`: `padding-left = 1`, `padding-right = 1`,
     `module-margin-left/right = 1`.
   - módulos de la derecha: `format-padding`/`label-padding = 3`; `date`
     `label-padding = 3`; `dots` `format-padding = 0`.
   - bspwm: `label-focused/occupied/urgent/empty-padding = 2`;
     `label-*-font = 3` (JBM 11).
   - logo: `format = "%{O1}<U+E000>%{O-4}%{F-}"`. El `O-4` posterior al
     glifo compensa el `module-margin` global y deja el bloque bspwm en
     `x=30` sin correr el logo.
2. No volver a usar los valores numéricos antiguos a ciegas: el padding de
   polybar se mide en unidades de espacio de la fuente activa. Con la fuente
   nueva, `format-padding = 6` producía gaps de 48–49 px; `3` produce
   `32–34`, que es el objetivo visual de `actual_03`. Si cambia la fuente de
   los módulos, hay que medir otra vez.
3. Mantener la fuente del logo en `font-0`, los módulos de texto con
   `font-1` y los labels de bspwm con `font-3`; ninguna etiqueta de texto usa
   `font-0`.

**Consecuencias:**
- Medición de `actual_10.png` (1920×26): logo `x=6..23` (18×10); caja
  enfocada `x=30..53` (24×26); primer dígito `x=39`; workspaces 2–5 en
  `62/86/110/134` (24 px); bloque derecho desde ~`1124`; gaps `32–34`;
  fecha→puntos `21`; puntos `x=1908..1915`.
- El logo queda 3 px a la izquierda de `yo.png` (`x=9..26`) y el bloque
  derecho 21 px a la derecha de la referencia (~`1103`), porque la barra
  actual muestra menos módulos. La separación entre workspaces y entre
  módulos coincide con `actual_03`; la caja conserva la altura completa de
  26 px por la limitación de polybar 3.7.2.
- `actual_03` y `actual_04` quedan como capturas históricas; la referencia
  de la barra viva pasa a ser `actual_10.png`.
- El `%{O-4}` es sensible al `module-margin`: si se vuelve a cambiar el
  margen global o el espacio del glifo, hay que recalcularlo para no mover
  bspwm de `x=30`.

## ADR-028 — La config viva pasa a ser la verdad (enmienda ADR-027)

**Contexto:** Tras ADR-025/026/027, la barra quedó estable pero la iteración
visual siguió en la config viva de `~/.config/polybar` (21–22 oct 2026): se
agrandaron los iconos (`font-3 = "JetBrainsMono Nerd Font:size=14;3"`),
subió el texto a `font-1 = "JetBrainsMono Nerd Font:style=SemiBold:size=11;3"`,
los iconos pasaron a usarse via `%{T1}...%{T-}` y el texto via `font-1`,
se redujeron los paddings (`padding-left/right = 0` en la barra;
`format-padding`/`label-padding = 0/1/2` según módulo), cambió el orden de
`modules-right` (dots fuera de la barra), el logo pasó a
`"%{T1}<U+E000>%{T-}"` + `format-padding = 2`, el glifo de `dots` a `<U+F001D>`
y `pipewire` usó `label-muted-font = 2`. El resultado se capturó en
`actual_15.png` y el usuario lo dio por bueno.

**Decisión:**
1. Sincronizar los templates del repo con la config viva, que pasa a ser la
   fuente de verdad: 14 módulos, `config.ini`, `polypomo.in` y
   `launch.sh.in` copiados byte a byte desde lo vivo, con dos excepciones
   re-templatizadas para conservar portabilidad:
   - hardware: `@ETH_IFACE@`, `@WLAN_IFACE@`, `@BATTERY@`, `@AC_ADAPTER@`,
     `@WLAN_MODULE@`, `@BATTERY_MODULE@` (el instalador detecta y completa;
     en esta máquina renderizan `enp3s0`, `wlo1`, `BAT1`, `ACAD`,
     `wlan`, `battery`).
   - rutas de usuario: `@HOME@` en `include-directory` y `exec` de scripts.
2. Separación de iconos y texto resuelta del lado del usuario: icono con
   font dedicada (`font-3` size 14) y texto con `font-1` size 11; agrandar
   iconos = tocar solo `font-3`. Aunque los labels usan `%{T1}`, el
   `T-` posterior devuelve el control a `font-1`.
3. Enmienda a ADR-027: los valores congelados de espaciado
   (`padding 1`, `module-margin 1`, `format-padding 3`, bspwm `font-3`)
   quedan reemplazados por los de esta ADR. ADR-027 sigue valiendo como
   método (medir capturas en px; no tocar valores a ciegas) pero no como
   valores.

**Consecuencias:**
- El render de los templates coincide byte-identical con la config viva
  (validado con diff afectando los 15 archivos); `install.sh` ya no pisará
  los retoques del usuario.
- Gaps de módulos ya no son 32–34 px: varían por módulo según su padding
  propio con el margen global 1. Si se vuelve a medir contra `yo.png`,
  primero fijar los paddings de esta ADR (o definir la nueva referencia).
- `dots` sigue existiendo como módulo y template, pero no está listado en
  `modules-right`; si el usuario lo re-agrega, no hace falta cambiar nada
  más.
- La referencia visual viva pasa de `actual_10.png` a `actual_15.png`.

## ADR-029 — updates como semáforo (rojo/verde) en vez de contador

**Contexto:** El módulo `updates` mostraba el glifo `U+F192` de Nerd Font
más el número de paquetes actualizables (`label = %output%` con el conteo
del script). El usuario pidió quitar el número y que el punto mismo indique
el estado: rojo con actualizaciones pendientes, verde con todo al día.

**Decisión:**
1. `updates-apt.sh` emite el glifo `U+F192` con color polybar embebido:
   `%{F#F47067}` (`colors.alert`) si el conteo es > 0, `%{F#3FB950}`
   (`colors.nord14`) si es 0, siempre con `%{T1}...%{T-}`. Ya no imprime el
   número; el conteo queda como lógica interna para decidir el color.
2. `updates.ini` pasa a `format = <label>` (sin icono en el módulo: llega
   con color desde el script) y conserva `format-padding = 2`,
   `format-font = 1`.
3. Los colores van fijos en el script: el output de `custom/script` no
   resuelve `${colors.*}`. Si cambia la paleta de `[colors]`, actualizar el
   script.

**Consecuencias:**
- Medición real posterior: cada corrida de `apt-get -s upgrade` cuesta
  ~0,5 s (no ~50 ms como se estimó al escribir esta ADR), porque parsea
  ~50 MB de listas de apt. Derivó en ADR-030, que reemplaza el sondeo
  por eventos.
- El punto queda visible junto a la fecha (en `modules-right`, `date` antes
  que `updates`).
- Al materializar en vivo hay que renderizar `@HOME@`: copiar el template
  sin sed rompe el `exec` (`@HOME@/.config...` literal → "not found").
  Revisado: ningún placeholder queda en la config viva.

## ADR-030 — Semáforo de updates por eventos (tail) en vez de sondeo

**Contexto:** Medición de la iteración anterior (ADR-029): cada corrida de
`apt-get -s upgrade` parsea ~50 MB de listas y cuesta ~0,5 s. Con
`interval = 10` eso significaba ~3 s de CPU por minuto (~5% de un core) y
un consumo de RAM transitorio de ~78 MB seis veces por minuto, solo para
actualizar un punto que además podía tardar hasta 10 s en cambiar de
color. La preocupación del usuario fue el costo en batería/sistema.

**Decisión:**
1. `updates-apt.sh` pasa a `tail = true`: un único proceso durmiente que
   observa los mtimes de `/var/lib/dpkg/status` (cambios al instalar/
   actualizar) y de `/var/lib/apt/lists` (`apt update`) cada 1 s, ejecuta
   el conteo grande solo cuando cambia algo real, espera 1,5 s de calma
   (debounce; un `apt upgrade` muta el archivo varias veces) y recalcula
   una vez.
2. La línea de salida es la misma de ADR-029 (glifo `U+F192` con color
   embebido, rojo `#F47067` si hay pendientes, verde `#3FB950` si está al
   día). `updates.ini` pierde `interval` y gana `tail = true`; el resto no
   cambia.
3. El módulo queda vivo el ciclo de la sesión; el estado inicial se imprime
   inmediatamente al arrancar, no deja la barra vacía.
4. Prueba sin tocar apt: rutas y tiempos sobreescribibles por entorno
   (`UPDATES_DPKG_STATUS`, `UPDATES_APT_LISTS`, `UPDATES_GAP`,
   `UPDATES_DEBOUNCE` y `UPDATES_FAKE_FILE` para simular el conteo).
   Medido: reacción de 0 a N pendientes en ~2,4 s (gap 1 s + debounce
   1,5 s) y vuelta a verde igual.

**Consecuencias:**
- CPU en reposo ~0% (solo dos `stat` por segundo); el costo de ~0,5 s de
  CPU y ~78 MB de RAM ocurre una vez por cambio real de estado, no cada
  10 s.
- El script no termina: si el proceso muere (kill/OOM improbable), el
  módulo queda vacío hasta recargar polybar. Para eso el loop no usa
  `set -e` y una corrida fallida no lo mata.
- Si en el futuro se quiere semáforo para otro origen (flatpak, pip), el
  patrón mtime+debounce se reusa igual.
- `-s` sigue siendo simulación: no toca locks ni escribe en el sistema.

## ADR-031 — polypomo: glifos NF, descanso 5 min, dunst y acción reset

**Contexto:** El pomodoro vendorizado usaba emoji (tomate `U+1F345`,
playa `U+1F3D6`, pausa `U+23F8`) y el click derecho (`end`) crasheaba con
`TypeError` cuando el timer estaba corriendo: `next_timer()` llamaba
`save()` sin guard y `sqlite3.connect(None)` (`--saveto` nunca llega en el
exec), mataba el proceso display y polybar reiniciaba el script
(25:00 en pausa). El usuario también pidió descanso de 5 min y
notificaciones dunst diferenciadas para cada fin (work y break).

**Decisión:**
1. Glifos JetBrainsMono Nerd Font (verificado con `fc-list :charset` que la
   familia `JetBrainsMono Nerd Font` (la del `font-1`) contiene los tres
   codepoints, así que no hace falta tocar fonts): detenido → `PAUSE` =
   `U+F28B`; trabajo corriendo → `PLAY` = `U+E002` (reemplaza al tomate);
   descanso corriendo → `BREAK` = `U+EC15`. El `show()` elige así: no
   activo → pausa; activo+work → play; activo+break → descanso.
2. Notificación al llegar a cero: `Timer` crea el endmsg; work →
   `"Pomodoro terminado — tiempo de descansar"`, break →
   `"Descanso terminado — ¡a seguir!!"` via `notify-send -t 0 -u critical
   "Pomodoro" {endmsg}` (se dispara una vez por timer, flag `notified`).
   Con `-t 0` la popup queda sticky hasta cerrarse (critical).
3. Descanso por defecto de 3 → 5 min (`--breaktime default 5*60`; el
   módulo no pasa args).
4. `save()` con guard: `if not self.saveto: return`. Con eso `end` (que
   queda disponible por CLI pero desconectado de clicks) no crashea.
5. Acción nueva `reset`: `status.reset_timer()` → deja active=False,
   status work, Timer 25:00 pausado; si hay DB y hay sesión abierta, la cierra
   (UPDATE stop). `click-right = ... polypomo reset` (antes era `end`). Incluyo `reset` en el parser (`sub.add_parser("reset", ...)`).
6. Corrección de portabilidad: las líneas `click-/scroll-` de
   `polypomo.ini` usaban `/home/luc` literal; pasan a `@HOME@` (como las
   líneas rest示范antes del template).

**Consecuencias:**
- Click derecho = reinicio limpio a 25:00 pausado, sin perder nada; click
  derecho NO pasa a descanso. `polypomo end` sigue disponible por CLI y ya
  no rompe.
- Al llegar a cero el timer sigue contando en negativo hasta un `reset`
  (comportamiento vendor; la notificación ocurre una vez).
- Notificaciones críticas sticky: hay que cerrarlas a mano o se van al
  history con `dunstctl close`.
- E2E probado con socket aislado (`XDG_RUNTIME_DIR=/tmp/...`): transicion
  de glifos, reset/end sin crash, y ambas notificaciones via dunst
  (`dunstctl count` saltó +1 por cada notificación esperada). Captura viva:
  `actual_18.png`.

## ADR-032 — Barra final: 13 módulos, glifo JBM, sin `DesktopLogo` ni `dots`

**Contexto:** ADR-026 añadió una fuente propia `DesktopLogo` (`U+E000`) y un
módulo `dots`. ADR-028 sincronizó la config viva y dejó `dots` fuera de la
barra; después la config viva siguió usando un glifo de JetBrainsMono Nerd
Font (`U+F1A4`) para el logo. El usuario validó esa barra (13 módulos) y
pidió no volver al logo propio ni a los tres puntos.

**Decisión:**
1. La barra final es la config viva: `logo`, `bspwm` + `polypomo`, `temp`,
   `memory`, `cpu`, `xkeyboard`, `eth`, `wlan`, `battery`, `pipewire`,
   `date`, `updates` (13 módulos; `wlan`/`battery` condicionales).
2. Se retiran `assets/desktop-logo.ttf`, `templates/polybar/modules/dots.ini.in`,
   `install_logo_font`, la comprobación `fc-list :charset=e000` y las
   referencias documentales al logo U+E000 y a los tres puntos.
3. `font-0` deja de ser `DesktopLogo` y pasa a JetBrainsMono Nerd Font; los
   índices `font-1..5` se mantienen para no tocar los módulos.
4. Las fuentes de polybar usan `@FONT@` para que el fallback de Nerd Font
   funcione también en la barra.
5. El instalador limpia restos de la versión anterior
   (`/usr/local/share/fonts/dwm-setup`, `~/.local/share/fonts/DesktopLogo`
   y `~/.config/polybar/modules/dots.ini`) con backup previo.

**Consecuencias:**
- La barra reproducible coincide con la captura viva de 2026-10-24.
- Se elimina la “trampa de mantenimiento” de tener una fuente de logo como
  `font-0`: cualquier texto sin `font-1` ya no sale con tofu.
- Los ADR-026/027/028 quedan como historia; sus valores de logo/dots no se
  usan.

## ADR-033 — Backups previos y ownership automático del home

**Contexto:** El instalador hacía los backups de usuario dentro de
`install_user_configs`, que se ejecutaba después de renderizar bspwm,
polybar, picom, etc. Por tanto el backup contenía los ficheros nuevos, no
los anteriores. Además, varias `make_user_dir` se redefinían sin `-o/-g`, y
`render_theme_template` instalaba como root; `~/.config`, `~/.local` y
`~/.config-backup` podían quedar de root y el usuario tenía que ejecutar
`sudo chown -R luc:luc ...` después de cada instalación. `bspwmrc` se
instalaba 0644, así que bspwm no lo ejecutaba y había que hacer
`chmod +x` a mano; sin bspwmrc no había sxhkd ni polybar, y el `kitty &` de
`.xinitrc` era lo único visible.

**Decisión:**
1. `backup_existing_configs` se ejecuta en `install.sh` antes de
   `preflight_repos` y de cualquier render. Incluye configs de usuario,
   `.xinitrc`, wallpaper, `/usr/local/bin/desktop-*` y la fuente antigua.
2. Una sola `make_user_dir` en `lib/common.sh`, basada en
   `run_user mkdir -p`, para que todos los padres sean del usuario.
3. `render_theme_template` añade `-o/-g` cuando el destino está dentro de
   `$TARGET_HOME`.
4. `prepare_user_dirs`, `fix_user_topdirs` y `chown_managed_paths` crean y
   corrigen `~/.config`, `~/.local`, `~/.config-backup` y los logs.
5. `bspwmrc` se instala 0755 y `.xinitrc` 0755; se elimina `kitty &` de
   `.xinitrc`.
6. `verify_install` comprueba `bspwmrc -x`, ausencia de placeholders,
   módulos de polybar, `glx-swap-method`, ownership y sintaxis POSIX.

**Consecuencias:**
- Ya no hace falta `sudo chown -R` ni `chmod +x` después de instalar.
- Si la instalación falla a mitad, el home no queda con ficheros root.
- El backup contiene la versión anterior y sirve para recuperar.
- `install.sh` debe terminar con código 0; la verificación ya no falla por
  `bspwm -v` (devuelve `0.9.10`, no `bspwm...`).

## ADR-034 — Sin dotfiles externos y sin autoarranque de X

**Contexto:** La integración de dotfiles externos (`lib/dotfiles.sh`)
promptaba por una URL, pero `[[ -n "${ASSUME_YES:-}" ]]` era verdadero
incluso con `ASSUME_YES=0`, así que el prompt se saltaba siempre. Además,
los `post_process_*` sustituían colores por `@COLOR_*@` y comandos por
`@TERM@` sin volver a renderizar, dejando configs rotas. El usuario decidió
mantener `startx` manual y usar este repositorio como fuente de configs.

**Decisión:**
1. Eliminar `lib/dotfiles.sh`, el prompt y las ramas `DOTFILES_DIR` de los
   módulos. Las plantillas del repo son la única fuente de verdad.
2. No añadir auto-login ni display manager: la sesión se inicia con
   `startx` desde TTY1.
3. Mantener `~/.bash_profile` sin bloques de autoarranque.
4. `sxhkdrc` se conserva tal cual; la documentación avisa de que
   `Super+Shift+b` (Firefox) y `Super+Shift+e` (VS Code) requieren apps que
   no instala la fase 1.

**Consecuencias:**
- Menos modos de fallo y menos código muerto.
- El usuario debe ejecutar `startx` a mano tras el login.
- Si más adelante se quiere un repo de dotfiles, habrá que diseñarlo de
  nuevo (copia + render + validación) y añadir un ADR.

## ADR-035 — Mapa de atajos i3 y resize encadenado

**Contexto:** El usuario aportó su configuración de i3 y pidió conservar la
memoria muscular al abrir programas y al cambiar de ventana. Quería mantener
5 escritorios, el estilo actual (gaps 10, borde 2) y el wallpaper
`rocky.jpg`. Las apps de su i3 (`pcmanfm`, `chromium`, `codium`,
`ristretto`, `lxappearance`, `dmenu`) no están instaladas en fase 1, pero
pidió dejar los atajos puestos. `codium` no está en los repositorios Debian;
`xfce-polkit` tampoco existe en Debian 13 (se usa `lxpolkit`). `fuji.png` no
está en el sistema.

**Decisión:**
1. `templates/sxhkd/sxhkdrc.in` adopta el mapa de i3:
   - Apps: `Super+Return` kitty, `Super+Shift+s` flameshot,
     `Super+Shift+p` pcmanfm, `Super+Shift+b` chromium,
     `Super+Shift+v` codium, `Super+Shift+i` ristretto,
     `Super+Shift+a` lxappearance, `Super+Shift+d` dmenu_run.
   - `Super+Shift+e` logout; el editor se mueve a `Super+Shift+v`.
   - `Alt+Tab` / `Alt+Shift+Tab` ciclan ventanas visibles del escritorio.
   - `Super+r` + `h/j/k/l` redimensiona con cadena de sxhkd (`:`);
     `Escape` sale. Se retira `Super+Alt+{flechas}`.
   - Se añaden reload (`Super+Shift+c`), restart (`Super+Shift+r`),
     floating (`Super+Shift+space`), parent (`Super+a`) y split
     (`Super+b/v`).
2. `bspwm_resize` acepta `h/j/k/l` con los sentidos de i3: `h` encoge
   ancho, `j` encoge alto, `k` agranda alto, `l` agranda ancho.
3. Las apps no instaladas quedan como bindings no-op; no se añaden paquetes
   ni repositorios en esta iteración.
4. Se mantienen 5 escritorios, `window_gap 10`, `border_width 2` y
   `rocky.jpg`.
5. `Super+s/w/e` (stacking/tabbed/toggle split de i3) no tienen equivalente
   exacto en bspwm y no se mapean.

**Consecuencias:**
- La apertura de programas y `Alt+Tab` coinciden con la memoria muscular de
  i3; las teclas de apps ausentes no hacen nada hasta instalar la app.
- El resize solo puede cambiar el eje del split en ventanas tiled; `j/k`
  requieren un split vertical (ventanas apiladas) o una ventana flotante.
  Es una limitación del tiling de bspwm, no del binding.
- tmux no choca: usa `Ctrl+b`; `Super` y `Alt` son de sxhkd. Mientras la
  cadena de resize está activa, `h/j/k/l` los captura sxhkd; al salir con
  `Escape` o timeout vuelven a tmux.
- `Super+Shift+b` deja de abrir Firefox; Firefox sigue instalado y se puede
  abrir desde rofi.

## ADR-036 — Scrot región+portapapeles y rofi run

**Contexto:** El usuario pidió sustituir `dmenu_run` por rofi y `flameshot
gui` por scrot, manteniendo la tecla `Super+Shift+s` (la de su i3). Quería
seleccionar una región, copiarla al portapapeles y pegarla en cualquier app.
No necesita anotaciones y prefiere no dejar archivos. Chromium sigue sin
decisión; el atajo `Super+Shift+b` se queda como no-op.

**Decisión:**
1. `Super+Shift+d` pasa de `dmenu_run` a `rofi -show run`.
2. `Super+Shift+s` pasa de `flameshot gui` a un script nuevo,
   `~/.config/bspwm/scripts/screenshot_region.sh`:
   - `scrot -s -q 100` para seleccionar la región.
   - `xclip -selection clipboard -t image/png -i` para copiarla.
   - Archivo temporal con `mktemp` y `trap` para borrarlo siempre; **no se
     guarda ninguna captura**.
   - `notify-send` confirma o avisa del fallo.
3. `Super+Shift+b` se queda con `chromium` como binding no-op hasta que el
   usuario decida instalar un navegador.
4. `flameshot` sigue instalado para anotar manualmente, pero ya no ocupa
   `Super+Shift+s`.
5. `Print`/`Super+Print` mantienen el menú de capturas existente.
6. No se añaden paquetes: `scrot`, `xclip` y `rofi` ya están en el sistema.

**Consecuencias:**
- Pegar la captura funciona en apps que aceptan `image/png` en el
  portapapeles; una terminal normal no pega imágenes.
- Scrot no dibuja flechas ni texto; para eso queda flameshot manual.
- El script es POSIX sh y se instala con el resto de scripts de bspwm.
- No queda basura en `/tmp` ni en `~/Pictures/Screenshots` por esta captura.

## ADR-037 — Audio HDMI/auriculares, sonido dunst y quirk ALC255

**Contexto:** En el host de referencia (ASUS FX504GE, Intel HDA + ALC255,
monitor `24 TV` por HDMI y jack combo 3.5 mm) el perfil HDMI estaba
disponible pero no activo, y `pavucontrol` solo mostraba la salida analógica.
Con auriculares de cable, la salida cambiaba sola, pero el micrófono del jack
combo no aparecía: solo existía `analog-input-mic` (interno). El usuario
quiere que el sistema elija HDMI/auriculares automáticamente, sonido en cada
notificación de dunst y micrófono de headset para Teams. El instalador se
usará en otros PCs, así que el quirk no puede aplicarse a ciegas.

**Decisión:**
1. `audio-switch.sh` y `audio-watch.sh`:
   - Prioridad **auriculares > HDMI > altavoces**.
   - Detección dinámica con `pactl` de tarjetas, perfiles y puertos; sin
     hardcodear `alsa_card.*`, monitor ni perfiles salvo fallback.
   - Si el sink/source predeterminado es USB/Bluetooth, no se pisa.
   - Conserva volumen/mute y mueve streams.
   - Arranca desde `autostart`.
2. `notification-sound.sh` con `paplay` y
   `message-new-instant.oga`; fallback `pw-play`. Regla dunst
   `[notification-sound]` sin filtros y `always_run_script = true`.
   `sound-theme-freedesktop` se añade a `AUDIO_PKGS` y `paplay` a la
   verificación.
3. Quirk `alc255-asus`:
   - Solo se propone si DMI coincide con `FX504GE`/`FX504` y el códec es
     `Realtek ALC255`.
   - En modo interactivo pregunta (por defecto sí); `--yes` lo aplica si el
     hardware coincide; `--headset-quirk` fuerza; `--no-headset-quirk`
     desactiva.
   - Backup de `/etc/modprobe.d/alsa-fx504.conf`, `update-initramfs -u` y
     aviso de reinicio.
   - En cualquier otro PC no se toca el kernel.
4. `lib/audio.sh` centraliza detección e instalación del quirk.
5. `verify_install` comprueba scripts de audio, sonido de dunst y, si se
   instaló, el `.conf` del quirk.

**Consecuencias:**
- El audio cambia solo cuando cambia el estado de HDMI/auriculares; una
  selección manual se respeta hasta el siguiente cambio de hardware.
- Solo puede haber una salida activa a la vez en la tarjeta analógica
  (auriculares, HDMI o altavoces).
- El quirk requiere reinicio y está pendiente de validación en el FX504GE;
  si no funciona, se revierte y se usa un headset USB.
- En PCs sin HDMI/auriculares o en VM, el watcher no falla.
- Bluetooth sigue fuera de fase 1.

## ADR-038 — Notificaciones duplicadas y sonidos serializados

**Contexto:** Con `stack_duplicates = true`, dos notificaciones idénticas de
la misma aplicación (mismo appname, summary, body, icono y urgencia) se
fusionaban en una sola con contador `(2)`. El script de sonido no se volvía
a ejecutar para el duplicado, así que solo se oía una vez. El usuario quiere
que cada mensaje suene.

**Decisión:**
1. `stack_duplicates = false` en `dunstrc`: cada notificación se muestra por
   separado y dispara el script de sonido.
2. `notification-sound.sh` usa `flock` sobre
   `${XDG_RUNTIME_DIR:-/tmp}/dunst-sound-$(id -u).lock` antes de `paplay`.
   Si llegan dos sonidos a la vez, el segundo espera al primero.
3. `hide_duplicate_count` se deja como está; con stacking desactivado no se
   muestra el contador.

**Consecuencias:**
- Dos mensajes idénticos producen dos notificaciones y dos sonidos
  consecutivos.
- El coste es que no se agrupan los duplicados; pueden aparecer varias
  ventanas si llegan muchos iguales.
- `flock` no bloquea la visualización de la notificación, solo el audio.
- Si `flock` no está disponible, el sonido sigue funcionando sin serializar.
- Validado en vivo: `dunstctl count displayed` 0 → 2 y dos sink-inputs
  consecutivos (2953 → 2978).

## ADR-039 — Gap de dunst y scrot `mode=edge`

**Contexto:** Con `stack_duplicates = false`, las notificaciones se muestran
en una misma ventana separadas por una línea de 2 px; el usuario pidió una
separación pequeña. Además, `scrot -s` dejaba restos del rectángulo de
selección en pantalla. La solución documentada de scrot incluye
`--freeze` y `--line mode=edge`; en pruebas con XTest, `-f` capturaba la
pantalla completa en lugar de la región, mientras que `mode=edge`
seleccionaba correctamente y no dejaba restos.

**Decisión:**
1. `gap_size = 6` en dunstrc. Dunst ignora `separator_height` cuando
   `gap_size > 0` y dibuja un borde de `frame_width` alrededor de cada
   notificación. Requiere compositor (picom).
2. Las capturas de región usan `scrot -s --line mode=edge -q 100`; no se
   usa `--freeze`.
3. Se mantiene `stack_duplicates = false` y `flock` para el sonido.

**Consecuencias:**
- Dos notificaciones se ven como tarjetas separadas 6 px.
- La selección de región funciona y no deja rectángulos residuales.
- `--freeze` queda documentado como descartado en este entorno por el
  problema con eventos sintéticos; si en otro PC funciona mejor, se puede
  cambiar, pero el valor probado es `mode=edge`.
- Sin paquetes nuevos.

## ADR-040 — Borde magenta de scrot y `xrefresh`

**Contexto:** La línea de selección por defecto de scrot es fina y con
opacidad baja; sobre un fondo blanco el usuario no veía la región. Además,
con `mode=edge` el rectángulo podía quedar pintado en pantalla tras la
captura. La prueba con una ventana blanca confirmó que el borde magenta se
ve, pero el rectángulo residual seguía ahí; `xrefresh` lo borra.

**Decisión:**
1. Las capturas de área usan:
   ```sh
   scrot -s --line 'mode=edge,color=#FF00FF,width=2,opacity=255' -q 100 ...
   ```
   Magenta, 2 px, opacidad total.
2. Después de capturar se ejecuta `xrefresh` (si está disponible) para
   repintar la pantalla y eliminar el rectángulo residual.
3. Se mantiene `mode=edge`; no se usa `--freeze`.
4. Se aplica a `Super+Shift+s` y a las opciones de área del menú de capturas.

**Consecuencias:**
- La selección se ve sobre blanco y sobre fondos oscuros.
- No queda el rectángulo residual tras la captura.
- `xrefresh` puede provocar un repintado breve; en las pruebas no alteró
  wallpaper ni ventanas.
- Si `xrefresh` no está disponible, la captura sigue funcionando, pero el
  rectángulo podría quedar visible.
- Sin paquetes nuevos.

## ADR-041 — Miniatura del recorte en la notificación

**Contexto:** El usuario vio que algunas notificaciones muestran logos o
imágenes (por ejemplo WhatsApp) y quiso que la notificación de scrot mostrara
también lo que acababa de recortar. El temporal de scrot se borra al salir,
así que no se puede pasar directamente a dunst. `max_icon_size` ya está en
64 px.

**Decisión:**
1. Tras copiar la región al portapapeles, `screenshot_region.sh` copia el
   PNG temporal a `~/.cache/dunst/last-screenshot.png`.
2. La notificación usa `notify-send -i ~/.cache/dunst/last-screenshot.png`;
   dunst lo escala a 64 px en el lado mayor.
3. Si la copia a caché falla, se envía la notificación sin icono. Si falla
   `xclip`, se muestra una notificación de error sin miniatura.
4. El archivo de caché se sobrescribe en cada captura; no se acumulan
   archivos.
5. El menú `Print`/`Super+Print` no cambia; la miniatura se añade solo a la
   captura directa `Super+Shift+s`.

**Consecuencias:**
- La notificación de captura muestra una miniatura del recorte, estilo
  WhatsApp.
- La imagen completa sigue en el portapapeles; la caché es solo para el
  icono.
- `~/.cache/dunst/last-screenshot.png` conserva la última captura; se puede
  borrar sin afectar a la funcionalidad.
- Sin paquetes nuevos.

## ADR-042 — `Print` captura pantalla completa al portapapeles

**Contexto:** `Print` y `Super+Print` abrían el mismo menú de capturas. El
usuario quiere `Print` como atajo directo de pantalla completa al
portapapeles, manteniendo `Super+Shift+s` para región y `Super+Print` para el
menú.

**Decisión:**
1. Nuevo `screenshot_full.sh`: `scrot -q 100` a un temporal, `xclip` al
   portapapeles, copia a `~/.cache/dunst/last-screenshot.png` y notificación
   con miniatura de 64 px. Sin archivo permanente.
2. `Print` ejecuta `screenshot_full.sh`.
3. `Super+Print` sigue ejecutando el menú `screenshot.sh`.
4. `Super+Shift+s` sigue usando `screenshot_region.sh`.
5. `screenshot_full.sh` se añade a la instalación y a `verify_install`.

**Consecuencias:**
- `Print` es inmediato y no muestra menú.
- La captura completa se pega desde el portapapeles; no se guarda en disco,
  salvo la caché del icono.
- `Super+Print` conserva las opciones de guardar, ventana y clipboard.
- Sin paquetes nuevos.

## ADR-043 — Rediseño polybar según la referencia

**Contexto:** El usuario aportó una captura de una barra con logo StumbleUpon,
4 workspaces, un contador de actualizaciones con calavera, etiquetas
`[T]/[M]/[C]`, estado WiFi `NoC`, Ethernet `connected`, volumen, batería,
fecha y tres puntos. La barra anterior tenía 5 workspaces, `latam`,
`updates` como semáforo al final y no tenía `dots`.

**Decisión:**
1. 4 workspaces en `bspwmrc` y `sxhkd` (`1-4`).
2. Logo StumbleUpon `U+F1A4` sin cambios.
3. `modules-right = updates polypomo temp memory cpu wlan eth pipewire
   battery date dots`.
4. `updates-apt.sh` pasa a mostrar `󰚌 # N` (calavera `U+F068C` + número)
   y no muestra nada si N=0; sin colores rojo/verde.
5. `temp` añade `[T]`, `memory` `[M]` y `cpu` `[C]`.
6. `wlan` muestra `󰖪 NoC` cuando está desconectado.
7. Se reincorpora `dots` con `...` al final.
8. Se elimina `xkeyboard` de la barra.
9. Workspace enfocado: fondo `#FFFFFF`, texto `#0D1117`, `font-1` y
   `padding = 1` para acercarse a la referencia.
10. Pomodoro en pausa usa `U+F04C` (dos barras) en vez de `U+F28B`.

**Consecuencias:**
- La barra coincide con la referencia en estructura, orden y colores; los
  valores (temperatura, RAM, CPU, batería, hora, número de updates) son
  datos reales y cambian.
- Si no hay actualizaciones, el módulo `updates` queda vacío y no muestra
  calavera ni `# 0`.
- `wlo1` sin conexión muestra `NoC`; si no hay interfaz WiFi, el módulo no
  se renderiza.
- El workspace enfocado mantiene la altura completa de la barra (26 px) por
  limitación de polybar 3.7; el ancho se ajusta con padding 1.
- `xkeyboard` deja de renderizarse; el layout `latam` sigue aplicándose por
  `setxkbmap`.
- Polybar cargó 13 módulos sin errores; captura de referencia
  `bar-design3.png`.

## ADR-044 — Separación compacta entre módulos de polybar

**Contexto:** Con el rediseño de ADR-043, los módulos de la derecha seguían
demasiado separados respecto a la referencia. Los huecos grandes venían de
`module-margin-left/right = 1`, `format-connected-padding = 3` en `wlan` y
`eth`, y `format-padding = 2` en `temp`, `cpu` y `pipewire`.

**Decisión:**
1. `module-margin-left = 0` y `module-margin-right = 0` en `[bar/main]`.
2. Padding 1 en `updates`, `temp`, `memory`, `cpu`, `wlan`, `eth`,
   `pipewire`, `date` y `dots`.
3. Padding 0 en `polypomo` y `battery`.
4. No se cambian orden, colores, fuentes, altura ni la caja del workspace.

**Consecuencias:**
- Los huecos entre módulos quedan en ~1-2 unidades; los mayores recortes
  son `wlan`/`eth` (de 3 a 1) y `temp`/`cpu`/`pipewire` (de 2 a 1).
- El logo y los workspaces también quedan algo más juntos al anular el
  margen global.
- Con `UPDATES_FAKE_FILE=0`, `updates` desaparece y no muestra `# 0`; el
  padding 1 no deja un hueco visible porque el grupo está alineado a la
  derecha.
- Verificado en vivo: polybar carga 13 módulos sin errores; captura
  `bar-spacing-final.png`.

## ADR-045 — Red unificada y volumen/batería juntos

**Contexto:** El usuario no quiere ver `NoC` cuando WiFi está desconectado,
solo un `connected`. Si hay WiFi conectado quiere un único `Connected`, sin
SSID ni el módulo Ethernet duplicado. También señaló que volumen y batería
seguían demasiado separados, y fijó manualmente `updates` con padding 2 y
`polypomo` con padding 1.

**Decisión:**
1. Un único módulo `network` (`custom/script`) reemplaza a `wlan` y `eth`.
   - WiFi conectado → `󰖩 connected`.
   - Sin WiFi y Ethernet conectado → `󰈀 connected`.
   - Sin conexión → no imprime nada.
   - Si ambos están conectados, prioriza WiFi.
2. `network-status.sh` usa `nmcli` y fallback a `/sys/class/net` para
   interfaces no gestionadas por NetworkManager; `NETWORK_FAKE=wifi|eth|none`
   permite probar sin tocar la red.
3. Se retiran los módulos y plantillas `wlan`/`eth`; la barra queda en 12
   módulos.
4. `updates` y `polypomo` conservan los paddings 2/1 elegidos por el usuario
   y pasan a las plantillas.
5. Volumen: `format-volume-padding = 0` y `format-muted-padding = 0`; la
   etiqueta empieza con un espacio para mantener separación con la red.
6. Batería: se elimina el espacio duplicado en carga/descarga; queda un solo
   espacio entre icono y porcentaje. `label-full` ya tenía uno.

**Consecuencias:**
- La barra muestra un solo estado de red y nunca `NoC` ni el SSID.
- Sin conexión, el módulo `network` queda vacío y no deja hueco.
- El estado se actualiza cada 5 s (`interval = 5`).
- Volumen y batería quedan juntos; la batería no separa el porcentaje con
  dos espacios.
- `updates`/`polypomo` mantienen el espaciado que el usuario dejó.
- Verificado en vivo: WiFi down + Ethernet up → `󰈀 connected`;
  `NETWORK_FAKE=wifi` → `󰖩 connected`; `NETWORK_FAKE=none` → nada.
  Polybar carga 12 módulos; capturas `bar-network-eth.png`,
  `bar-network-wifi.png`, `bar-network-none.png` y `bar-network-final.png`.

## ADR-046 — Barra final ajustada manualmente por el usuario

**Contexto:** El usuario ajustó su barra viva en `~/.config/polybar`:
redujo fuentes, quitó etiquetas `[T]/[M]/[C]`, movió `updates` al final,
eliminó `dots`, cambió el logo y afinó paddings. Quiere que esos cambios
se conserven en el repo y que una reinstalación no los revierta.

**Decisión:**
1. Barra final de **11 módulos**:
   `logo`, `bspwm`, `polypomo`, `temp`, `memory`, `cpu`, `network`,
   `pipewire`, `battery`, `date`, `updates`.
2. `modules-right = polypomo temp memory cpu network pipewire battery date updates`.
3. Fuentes: `font-1 = 10`, `font-3 = 13`; `font-0 = 11`. El logo usa
   `font-0` (`%{T0}`) para conservar su tamaño.
4. Logo StumbleUpon `U+F1A4` sin espacio final y `format-padding = 1`.
5. Sin etiquetas `[T]`, `[M]` ni `[C]`.
6. `cpu` usa `label = "... %percentage%%%{O8}"`: porcentaje con signo `%`
   y 8 px extra a la derecha.
7. `updates` al final: calavera `U+F4F9` + espacio + número, sin `#`;
   `updates`/`polypomo` con padding 1/1.
8. Se elimina `dots` del repo, de `lib/polybar.sh`, de `lib/verify.sh`,
   de `install.sh` y de la config viva.
9. `pipewire` y `battery` con padding 1; volumen sin espacio entre icono y
   porcentaje; rampas de batería sin espacio final.

**Consecuencias:**
- La barra coincide con la que el usuario ajustó manualmente.
- `updates` queda al final; si N=0 no ocupa espacio visible.
- El logo no se reduce al bajar `font-1`; los números y módulos sí.
- `dots`, `eth` y `wlan` ya no forman parte de la barra; se retiraron
  también los archivos vivos no usados.
- Polybar cargó 11 módulos sin errores; captura `bar-user-final.png`.
- Verificado con `verify_install`, home simulado y `--dry-run`.

## ADR-048 — Dos variantes de polybar y 5 workspaces

**Contexto:** El usuario quiere conservar la barra actual (variante A) y
añadir una segunda (variante B) basada en una referencia powerline con
5 workspaces circulares, centro transparente, hora/fecha/pomodoro a la
izquierda y estadísticas a la derecha. Eligió 5 workspaces globales, red
unificada y que el `3%` de la referencia sea el uso de `/home`.

**Decisión:**
1. `bspwmrc` y `sxhkd` pasan a 5 escritorios (`1-5`). La variante A
   conserva su estilo, pero muestra 5 números.
2. La variante A sigue en `~/.config/polybar/config.ini` y sus módulos.
3. La variante B vive en `~/.config/polybar/variants/reference/`:
   - 15 módulos: hora, fecha, separadores, pomodoro, flecha, bspwm, batería,
     temperatura, volumen, red, RAM, CPU, `xkeyboard` y `fs`.
   - Workspaces con glifos de `bspwm_circle` adaptados a FA6
     (`` enfocado, `` ocupado, `` vacío), sin caja de fondo;
     el `` original se ve cuadrado en FA6.
   - Barra transparente (`#00000000`); centro sin fondo; bloques izquierdo
     y derecho con `#B31E1E2E`; flecha powerline azul.
   - Sin logo, sin `dots` y sin updates.
   - Red unificada con un `network-status.sh` propio de la variante, usando
     el icono de red de la referencia; sin `No connection`.
   - SSD con `internal/fs` sobre `/home`.
   - Iconos de volumen, RAM, red y SSD adaptados de la referencia; los
     glifos no presentes en las fuentes instaladas se sustituyen por
     equivalentes disponibles.
4. `polybar-variant actual|referencia` guarda la elección en
   `~/.config/polybar/variant` y reinicia; `launch.sh` lee ese archivo.
5. Se instalan ambas variantes y se verifican; no se cambia la variante A
   salvo los 5 workspaces.

**Consecuencias:**
- La variante A mantiene su estilo y ahora muestra 5 workspaces; los
  atajos son `Super+1..5`.
- La variante B carga 15 módulos; captura `bar-variant-b.png`.
- El centro de la variante B deja ver el wallpaper; izquierda/derecha son
  oscuros semitransparentes.
- `polybar-variant actual` vuelve a la barra actual.
- Sin paquetes nuevos.
- Los cambios quedan sin commit hasta que el usuario lo autorice.

## ADR-049 — Variante B compacta final

**Contexto:** El usuario ajustó manualmente la variante B: la dejó en 20 px,
con `bspwm` a la izquierda y un bloque derecho compacto. Al probarla faltaban
`date.ini` y `updates.ini`, y los iconos Font Awesome de memoria/red quedaban
más altos que el texto.

**Decisión:**
1. Barra de 11 módulos:
   `modules-left = bspwm`;
   `modules-right = izq polypomo temp memory cpu network pipewire battery date updates`.
2. Altura 20, fuentes `font-0=10`, `font-1=9`, `font-3=11`.
3. `font-4` Font Awesome con offset `;3` para los círculos y
   `font-6 = @FONT@:size=8;3` para iconos, de modo que no se recorten con
   altura 20.
4. Workspaces con `//`, padding 0.
5. Añadir `date.ini` y `updates.ini` a la variante B. `updates` reutiliza
   `updates-apt.sh` y muestra el contador.
6. `izq` usa `format` (no `content`, que está deprecado) y color
   `${colors.secondary}`.
7. `memory` y `network` usan iconos MDI alineados en vez de glifos FA que
   quedaban altos.
8. La variante A no se toca.

**Consecuencias:**
- Polybar carga 11 módulos sin errores y sin warnings de `content`.
- Updates vuelve a mostrarse al final.
- Los iconos de memoria/red quedan alineados con el texto.
- La barra queda compacta, transparente y con fondos derechos oscuros.
- Captura `bar-variant-b.png`.
- Sin commit hasta autorización explícita.


## ADR-050 — Paleta global Warm Charcoal

**Contexto:** El usuario aportó una referencia visual con carbón cálido,
azul grisáceo y beige, y pidió aplicarla a todo el sistema, no solo a la
variante B.

**Decisión:**
1. Nueva paleta `templates/colors/palette-warm.sh` y tema por defecto
   `warm`; `install.sh` carga `warm`.
2. Colores base: `#18181A`, `#202022`, `#2A2A2C`, texto `#D8D3CC`, muted
   `#8E8A85`, beige `#B9A99A`, azul `#8FA6B4`, alerta `#C97A6D`.
3. Polybar A y B actualizan sus bloques `[colors]`; A conserva su layout.
4. Kitty, rofi, dunst, bspwm, i3lock y scripts de sesión se renderizan con
   la nueva paleta.
5. La variante B conserva los ajustes manuales de layout del usuario.
6. Se mantiene picom selectivo: blur solo para kitty/Polybar.

**Consecuencias:**
- Toda la sesión usa la misma paleta cálida.
- `palette-nord.sh` queda como alternativa.
- Captura `bar-warm.png`.
- Sin commit hasta autorización explícita.

## ADR-051 — Servicios systemd en polybar

**Contexto:** El usuario quiere ver cuántos servicios systemd están activos y
poder iniciarlos, detenerlos o reiniciarlos desde la barra, con `dmenu` y
soporte para otros menús.

**Decisión:**
1. Añadir el módulo `services` a la variante A y a la variante B, antes de
   `battery`.
2. El módulo ejecuta `services.sh --count` y muestra un engranaje y el
   número de servicios en ejecución; `interval = 10`.
3. `services.sh` es un script POSIX común:
   - `--count` usa `systemctl list-units --type=service --state=running`.
   - Sin argumentos muestra primero los servicios y su estado
     `enabled/disabled/static`; al elegir uno consulta `systemctl is-active`.
   - Servicio activo: ofrece detener y reiniciar.
   - Servicio parado o fallido: ofrece iniciar y reiniciar.
   - Usa `dmenu` y cae a `rofi -dmenu` si falta.
   - No usa `sudo`; `systemctl` recurre a polkit.
4. Añadir `dmenu` a los paquetes de escritorio.
5. Verificar el script y los módulos A/B; el módulo se oculta si no hay
   `systemctl`.

**Consecuencias:**
- La variante A pasa a 12 módulos y la B a 14.
- El botón no abre nada hasta hacer clic; no se ejecutan acciones
  automáticamente.
- El script se puede probar con `SYSTEMCTL` y un menú simulados.

## ADR-052 — Atajo para alternar variantes de polybar

**Contexto:** El usuario quiere cambiar entre la variante A (`actual`) y la
B (`referencia`) sin escribir el comando en una terminal.

**Decisión:**
1. `polybar-variant` acepta `actual`, `referencia` y `toggle`.
2. `toggle` lee `~/.config/polybar/variant` y elige la contraria; si no
   existe, pasa a `referencia`.
3. `sxhkd` mapea `Super+Alt+P` a `polybar-variant toggle`.
4. El atajo se documenta en `README.md`, `AGENTS.md`, `PROGRESS.md` y
   `docs/testing.md`.

**Consecuencias:**
- Cambiar de barra es inmediato y conserva la variante elegida al reiniciar.
- `Super+Alt+Q/R` siguen siendo de bspwm; `Super+Alt+P` no colisiona.

## ADR-053 — Sincronización de ajustes manuales de las barras

**Contexto:** El usuario ajustó manualmente la variante A y el orden de un
módulo en la B; esos cambios estaban solo en `~/.config/polybar`.

**Decisión:**
1. Variante A: altura 20 y orden derecho
   `updates services polypomo temp memory cpu network pipewire battery date`.
2. Variante B: `services` pasa justo después de `izq`:
   `izq services temp memory cpu network pipewire battery`.
3. Las plantillas, la documentación y el render del instalador reflejan
   esos valores.
4. Se conservan los 12/14 módulos y el atajo `Super+Alt+P`.

**Consecuencias:**
- Reinstalar no vuelve a la altura 26 ni al orden anterior.
- La barra viva y el repositorio quedan sincronizados.

## ADR-054 — Ctrl+Tab para cambiar de escritorio

**Contexto:** El usuario pidió cambiar de escritorio con `Ctrl+Tab`.

**Decisión:**
1. `Ctrl+Tab` → `bspc desktop -f next.local`.
2. `Ctrl+Shift+Tab` → `bspc desktop -f prev.local`.
3. Se mantienen `Super+Left/Right` y `Super+1..5`.

**Consecuencias:**
- `Ctrl+Tab` es global y deja de llegar a navegadores y editores.
- La decisión prioriza el cambio de escritorio sobre el cambio de pestañas.

## ADR-055 — Super+Ctrl+Tab para escritorios

**Contexto:** El atajo global `Ctrl+Tab` quitaba el cambio de pestañas a los
navegadores y editores.

**Decisión:**
1. Retirar `Ctrl+Tab` y `Ctrl+Shift+Tab`.
2. Usar `Super+Ctrl+Tab` → `bspc desktop -f next.local`.
3. Usar `Super+Ctrl+Shift+Tab` → `bspc desktop -f prev.local`.
4. Mantener `Super+Left/Right` y `Super+1..5`.

**Consecuencias:**
- `Ctrl+Tab` vuelve a funcionar en las aplicaciones.
- `Super+Ctrl+Tab` no colisiona con los atajos actuales de bspwm o sxhkd.

## ADR-056 — Retirar picom y usar pseudo-transparencia en B

**Contexto:** El usuario pidió eliminar picom y conservar únicamente la
transparencia del módulo central de la variante B.

**Decisión:**
1. Retirar picom del instalador, autostart, verificación, diagnóstico y
   plantillas; no se instala ni se arranca.
2. La variante B usa `pseudo-transparency = true` y mantiene
   `background = #00000000`; solo el centro queda transparente.
3. Los fondos laterales de B pasan a ser opacos (`module-bg = #1F1F21`).
4. Kitty queda opaca (`background_opacity 1.0`), porque sin compositor no
   puede mezclar transparencia.
5. La variante A no cambia.

**Consecuencias:**
- Desaparecen blur y transparencia real de kitty/polybar.
- B conserva el centro transparente mediante el wallpaper y polybar.
- El paquete picom ya instalado no se desinstala automáticamente; puede
  quitarse con `sudo apt remove picom`.

## ADR-057 — Ciclo de variante y posición de polybar

**Contexto:** El usuario quiere que `Super+Alt+P` recorra las dos variantes
y sus dos posiciones.

**Decisión:**
1. `polybar-variant cycle` recorre:
   `actual/top → actual/bottom → referencia/top → referencia/bottom`.
2. La posición se guarda en `~/.config/polybar/position`.
3. `launch.sh` exporta `POLYBAR_BOTTOM`; las configuraciones usan
   `bottom = ${env:POLYBAR_BOTTOM:false}`.
4. El atajo `Super+Alt+P` llama a `polybar-variant cycle`.
5. Se conservan `actual`, `referencia` y `toggle` para cambiar solo la
   variante.

**Consecuencias:**
- Un solo atajo controla las cuatro combinaciones.
- La posición y la variante persisten entre reinicios.

## ADR-058 — Padding dinámico para la barra arriba/abajo

**Contexto:** Al mover polybar al borde inferior, bspwm seguía reservando
`top_padding = 26` y dejaba las ventanas tapar la barra.

**Decisión:**
1. `bspwmrc` lee `~/.config/polybar/position` y configura:
   - arriba: `top_padding = 26`, `bottom_padding = 0`;
   - abajo: `top_padding = 0`, `bottom_padding = 26`.
2. `launch.sh` vuelve a aplicar esos padding cada vez que cambia la posición.
3. La altura reservada se mantiene en 26 px, igual que la configuración
   anterior.
4. Los cuatro estados del ciclo conservan la variante y la posición.

**Consecuencias:**
- La barra inferior no se oculta debajo de las ventanas.
- El cambio de posición es inmediato y persiste al reiniciar.

## ADR-059 — Volumen 120 %, dunst crítico y brillo condicional

**Contexto:** El usuario pidió que las notificaciones urgentes se cierren
solas, que el volumen llegue a 120 % en pasos de 10 y que exista un módulo
de brillo cuando el hardware lo permita.

**Decisión:**
1. `[urgency_critical] timeout = 10` y quitar `-t 0` de `polypomo`.
2. Sustituir `internal/pulseaudio` por `volume.sh`:
   - máximo 120 %;
   - pasos de 10 %;
   - scroll, teclas de volumen, mute y `pavucontrol`.
3. Añadir `@BRIGHTNESS_MODULE@` a A/B y un módulo `internal/backlight` con
   `scroll-interval = 10`.
4. El módulo de brillo solo se incluye si `lib/detect.sh` encuentra
   `/sys/class/backlight`.
5. Mantener `brightnessctl` para las teclas de brillo.

**Consecuencias:**
- Las notificaciones críticas desaparecen sin clic.
- El volumen nunca supera 120 %.
- En equipos sin backlight no aparece el módulo de brillo.

## ADR-060 — Menú WiFi y prioridad Ethernet

**Contexto:** El usuario quiere conectarse a redes WiFi haciendo clic en el
módulo de red, manteniendo Ethernet como prioridad cuando el cable está
conectado.

**Decisión:**
1. `network-status.sh` muestra Ethernet antes que WiFi.
2. Los módulos A/B añaden `click-left` a `network-menu.sh`.
3. `network-menu.sh` lista redes con `nmcli device wifi list`.
4. Conexiones abiertas o guardadas se intentan directamente; las redes con
   seguridad piden contraseña mediante un menú oculto de `rofi`.
5. No se usa `sudo`; NetworkManager aplica sus permisos.
6. La contraseña no se guarda en el repositorio ni en el script.

**Consecuencias:**
- El módulo muestra Ethernet si hay cable, aunque WiFi esté conectado.
- El menú WiFi sigue disponible con Ethernet conectado.
- `nmcli` guarda el perfil de conexión si el usuario lo autoriza.

## ADR-061 — Mostrar NoC cuando no hay conexión

**Contexto:** El módulo de red quedaba vacío sin Ethernet ni WiFi, por lo que
no había una zona clara para hacer clic y abrir el menú WiFi.

**Decisión:**
1. Cuando `eth=0` y `wifi=0`, `network-status.sh` muestra `󰖩 NoC`.
2. El módulo conserva `click-left` para abrir `network-menu.sh`.
3. Se mantiene la prioridad Ethernet > WiFi > NoC.

**Consecuencias:**
- El módulo siempre es visible y clicable.
- `NETWORK_FAKE=none` ahora produce `󰖩 NoC`.

## ADR-062 — Actualizar perfiles WiFi existentes sin PSK

**Contexto:** NetworkManager tenía perfiles `ARRIS-AF51` y
`ARRIS-AF51-5G` con `key-mgmt=wpa-psk` pero sin PSK. El primer intento de
conexión sin contraseña reutilizaba el perfil vacío y la contraseña
posterior no se aplicaba.

**Decisión:**
1. Buscar el perfil WiFi por SSID antes de conectar.
2. Si existe, probar `nmcli connection up`; si falla, pedir contraseña y
   actualizar el perfil con `nmcli connection modify ... wifi-sec.psk`.
3. Si no existe, pedir contraseña antes de crear un perfil seguro.
4. Mostrar el error real de `nmcli` en la notificación.
5. Mantener las redes abiertas sin prompt.

**Consecuencias:**
- Los perfiles vacíos se reparan sin borrarlos manualmente.
- La contraseña se guarda en el perfil de NetworkManager, no en el script.

## ADR-063 — Pasada de estabilidad sin retirar paquetes

**Contexto:** El usuario quiere que el instalador reproduzca el sistema
estable actual. La reducción de paquetes o servicios queda supeditada a una
prueba posterior en VM y a autorización explícita.

**Decisión:**
1. No desinstalar paquetes ni deshabilitar servicios en este equipo.
2. Mantener `redshift`, `ssh`, `bluez`, `playerctl`, `acpi`,
   `network-manager-gnome`, `flameshot`, `dmenu` y `BUILD_PKGS` en el
   conjunto actual.
3. Mantener `picom` fuera del instalador, pero no purgar el paquete ya
   instalado sin permiso.
4. Sincronizar únicamente formato y documentación seguros.
5. Reservar la optimización agresiva para una instalación limpia en VM.

**Consecuencias:**
- La instalación prioriza estabilidad y reproducibilidad.
- Ninguna limpieza de paquetes se ejecuta automáticamente.

## ADR-064 — Reproducir zsh, Oh My Zsh y lsd

**Contexto:** El usuario quiere que una instalación limpia incluya su shell
zsh, Oh My Zsh con agnoster, zsh-autosuggestions, sus keybindings y lsd con
sus iconos personalizados.

**Decisión:**
1. Instalar `zsh`, `zsh-autosuggestions` y `lsd`.
2. Clonar Oh My Zsh en `~/.oh-my-zsh` si no existe.
3. Instalar una `.zshrc` renderizada con keybindings, opciones, aliases y
   autosuggestions.
4. Instalar `~/.config/lsd/config.yml` e `icons.yaml`.
5. Cambiar la shell del usuario a `/usr/bin/zsh`.
6. Sincronizar kitty con Nord, `font_size 13` y `shell /usr/bin/zsh`.

**Consecuencias:**
- Una instalación limpia reproduce el entorno zsh/lsd actual.
- Oh My Zsh requiere red la primera vez.
- No se sobrescribe `~/.oh-my-zsh` si ya existe.

## ADR-065 — Ranger, zathura, VLC y EPUB nativo

**Contexto:** El usuario quiere usar ranger desde la terminal para abrir
documentos, EPUB, vídeos e imágenes, con zathura para EPUB.

**Decisión:**
1. Instalar `ranger`, `zathura`, plugins PDF/DjVu/PS/CB, `vlc`, `ueberzug` y
   `poppler-utils`.
2. Compilar `zathura-pdf-mupdf` 0.4.6 contra `libmupdf-dev` 1.25.1 de Debian.
3. No instalar `apvlv`; EPUB se resuelve con zathura + mupdf.
4. Configurar rifle para zathura, VLC y feh.
5. Añadir previews de PDF/vídeo/EPUB e imágenes con ueberzug, `pdftoppm`,
   `ffmpegthumbnailer` y extracción de portada EPUB.
6. No cambiar el atajo de Thunar; ranger se abre escribiendo `ranger`.

**Consecuencias:**
- Una instalación limpia necesita compilar el plugin de zathura.
- Si la compilación falla, el instalador se detiene y no instala un visor
  alternativo.

## ADR-066 — Abrir texto y código con Neovim desde ranger

**Contexto:** El usuario quiere editar desde ranger los archivos de texto,
código y Markdown con Neovim.

**Decisión:**
1. Añadir `neovim` a los paquetes del instalador.
2. Añadir reglas prioritarias en `rifle.conf`:
   - `mime ^text` → `nvim`.
   - Extensiones de código/Markdown → `nvim`.
3. Mantener ranger abierto desde la terminal, sin cambiar el atajo de Thunar.

**Consecuencias:**
- Los archivos de texto y código se abren editables.
- El resto de formatos sigue usando zathura, VLC o feh.

## ADR-067 — Perfil gráfico Intel/NVIDIA por hardware

**Contexto:** El usuario quiere que el instalador elija la configuración
Intel adecuada y, opcionalmente, pruebe parámetros de `i915` para glitches.

**Decisión:**
1. Detectar Intel/NVIDIA y las salidas conectadas con `lib/detect.sh` y
   `/sys/class/drm`.
2. Con Intel, escribir `/etc/X11/xorg.conf.d/20-modesetting.conf`:
   modesetting, glamor, DRI3 y PageFlip.
3. No usar el driver antiguo `intel` ni `20-nvidia.conf` como GPU primaria
   en un híbrido.
4. Con NVIDIA, escribir solo `nvidia_drm.modeset=1` para PRIME/offload.
5. Añadir `--intel-glitch` para escribir `i915 enable_fbc=0` y, si hay eDP,
   `enable_psr=0`; después ejecutar `update-initramfs -u`.
6. Backup de las configuraciones del sistema antes de escribir.

**Consecuencias:**
- La configuración por defecto es conservadora.
- La prueba de FBC/PSR es explícita y requiere reinicio.
- No se copian los archivos de Artix ni se hardcodea el BusID.

## ADR-068 — Papirus como tema de iconos

**Contexto:** Papirus estaba copiado en `/usr/share/icons`, pero GSettings y
rofi/dunst seguían usando Adwaita o un tema inexistente.

**Decisión:**
1. Añadir `papirus-icon-theme` a las fuentes/iconos del instalador.
2. Usar `Papirus` en GSettings, GTK3, GTK4, GTK2, rofi y dunst.
3. Corregir el `icon_path` de dunst para que no apunte a Adwaita.
4. Mantener `icon_theme` coherente en rofi y dunst.

**Consecuencias:**
- Los iconos se ven iguales en GTK, rofi y dunst.
- Las apps abiertas antes del cambio deben reiniciarse.

## ADR-069 — Cargador SVG para Papirus

**Contexto:** Papirus estaba seleccionado, pero GTK caía a Adwaita/iconos
internos porque los iconos de Papirus son SVG y faltaba el cargador
`librsvg2-common`.

**Decisión:**
1. Añadir `librsvg2-common` a los paquetes de fuentes/iconos.
2. Mantener `Papirus` como tema de iconos en GTK, rofi y dunst.
3. Regenerar la caché de iconos si es necesario.

**Consecuencias:**
- GTK puede renderizar los SVG de Papirus.
- No se necesita convertir los iconos a PNG.

## ADR-070 — Tema GTK e iconos en la instalación

**Contexto:** El usuario quiere que una instalación limpia tenga el tema
`Windows-10-Dark` y los iconos `Papirus`, sin depender de su home actual.

**Decisión:**
1. Vendorizar `Windows-10-Dark` en `templates/themes/`.
2. Instalarlo en `~/.themes/Windows-10-Dark`.
3. Instalar settings GTK2/3/4 con tema Windows-10-Dark e iconos Papirus.
4. Aplicar también `gsettings` desde el autostart de la sesión.
5. Instalar `papirus-icon-theme` y `librsvg2-common` desde APT.
6. Mantener las plantillas de rofi y dunst con Papirus.

**Consecuencias:**
- El repo crece unos 3 MB por el tema.
- Los iconos Papirus no se vendorizan; vienen de Debian.
- Las apps que usan GSettings y las que leen settings.ini quedan alineadas.

## ADR-071 — VLC con paleta oscura nativa

**Contexto:** VLC 3.0.24 usa Qt5 y arrancaba con la paleta clara del sistema.
La opción nativa `qt-dark-palette` estaba desactivada en `vlcrc`.

**Decisión:**
1. Activar `qt-dark-palette=1` en `~/.config/vlc/vlcrc`.
2. No instalar `qt5-gtk-platformtheme` ni depender del tema GTK para VLC.
3. Editar solo esa clave si `vlcrc` ya existe; nunca reemplazar el archivo
   completo del usuario.
4. Si no existe `vlcrc`, crearlo desde `templates/vlc/vlcrc.in` con permisos
   `0600`.
5. Verificar la clave en `lib/verify.sh` y en `desktop-doctor`.

**Consecuencias:**
- VLC arranca en modo oscuro sin paquetes extra.
- Los ajustes previos del usuario en `vlcrc` se conservan.
- VLC reescribe `vlcrc` al salir; el valor se mantiene.

## ADR-072 — Paleta global Mono Slate

**Contexto:** la paleta Warm Charcoal (beige/azul) no coincidía con la
referencia visual del usuario: negro, blancos, grises y un único azul
tenue. Además, polybar, kitty y el menú de rofi tenían colores
hardcodeados y no seguían la paleta.

**Decisión:**
1. Nueva `templates/colors/palette-mono.sh` y `DEFAULT_THEME="mono"`.
2. Refactorizar polybar A/B, módulos `bspwm`/`fs`, kitty, rofi
   (`powermenu.rasi` y `config.rasi`), dunst, bspwm, i3lock y zathura
   para usar solo `@COLOR_*@`.
3. Incorporar `templates/rofi/config.rasi.in` (menú de aplicaciones).
4. Añadir `templates/zathura/zathurarc.in` con fondo oscuro y `recolor`.
5. Añadir `--theme mono|warm|nord`; quitar los `THEME_NAME=warm` fijos.
6. Sustituir el wallpaper por un grafito 2560x1440 con halo azul tenue.
7. `lib/verify.sh` rechaza colores fuera de la paleta activa, salvo
   `#FF00FF` (scrot) y `#00000000` (transparencia de la barra B).

**Consecuencias:**
- Cambiar de paleta es un flag del instalador.
- Las configuraciones renderizadas no vuelven a divergir del tema.
- Warm Charcoal y Nord quedan como alternativas completas.
- El tema GTK Windows-10-Dark se mantiene; su azul de selección encaja
  con el acento tenue.

## ADR-073 — Paleta Mono Slate exacta con acento azul

**Contexto:** la referencia final del usuario define una escala concreta
(`#000000`, `#0E0E0E`, `#1A1A1A`, `#2A2A2A`, `#4A4A4A`, `#8C8C8C`,
`#F2F2F2`) y un único acento rojo `#D71921`. El usuario pidió mantener la
escala y sustituir el rojo por el azul del token `const` (`#569CD6`).

**Decisión:**
1. `palette-mono.sh` usa exactamente esos grises.
2. `COLOR_ACCENT`, `COLOR_RED` y `COLOR_BLUE` apuntan a `#569CD6`; el
   rojo desaparece de la paleta.
3. `COLOR_ACCENT_ALT=#D9D9D9`, `COLOR_GREEN=#B8B8B8`, `COLOR_YELLOW=#E9E9E9`,
   `COLOR_CYAN=#6E6E6E`, `COLOR_PURPLE=#B8B8B8` para no introducir tonos
   fuera de la escala.
4. Wallpaper regenerado con base `#000000` y halo `#569CD6`.

**Consecuencias:**
- El acento cromático es único y azul.
- Foco de ventana, cursor, borde de rofi, dunst crítico y resaltados de
  zathura comparten el mismo azul.
- `lib/verify.sh` sigue validando que no haya hex fuera de la paleta.

## ADR-074 — Thunar con la paleta global y modo minimalista

**Contexto:** Thunar seguía usando el azul `#004D8C` del tema
`Windows-10-Dark` y mostraba menú, panel lateral y barra de estado, lo
que rompía la estética monocromática del escritorio.

**Decisión:**
1. Añadir `~/.config/gtk-3.0/gtk.css` y `gtk-4.0/gtk.css` con
   `@define-color` y selectores para ventana, vista, toolbar, menú,
   sidebar, barra de estado, botones y scrollbars, usando `@COLOR_*@`.
2. Compactar espaciado y eliminar sombras, degradados y esquinas
   redondeadas.
3. Ocultar menú, panel lateral y barra de estado mediante
   `thunar-defaults.sh`, que solo escribe si la propiedad no existe.
4. Mantener accesibles los controles: Ctrl+M muestra el menú y F9 el
   panel lateral.
5. Verificar los CSS en `lib/verify.sh` y `desktop-doctor`.

**Consecuencias:**
- Thunar usa la misma paleta que polybar, kitty, rofi y dunst.
- El modo minimalista es reversible sin tocar el tema.
- Los cambios del usuario en xfconf se respetan en reinstalaciones.

## ADR-075 — Superficie #1A1A1A y barra B opaca

**Contexto:** el escritorio usaba `#000000` como fondo de terminal, Thunar y
barra. El usuario pidió el gris de su referencia (`#1A1A1A`) para que no se
viera "demasiado negro", y reportó bordes anaranjados.

**Decisión:**
1. `COLOR_BG` y `COLOR_BG_ALT` pasan a `#1A1A1A`; `COLOR_BG_ELEV` y
   `COLOR_BG_HOVER` a `#2A2A2A`. El wallpaper y el fondo raíz siguen
   negros.
2. La variante B deja de usar `#00000000`: la barra pasa a `#1A1A1A`
   sólido, con los módulos al mismo tono.
3. Aplicar `bspwmrc` en vivo tras renderizar. bspwm no recarga el archivo
   solo, por eso el borde enfocado seguía en el beige `#b9a99a` de Warm
   Charcoal.

**Consecuencias:**
- Terminal, Thunar, rofi, dunst, zathura y barras comparten superficie.
- El escritorio negro mantiene contraste con las ventanas.
- El borde enfocado es azul `#569CD6` y el normal `#1A1A1A`.

## ADR-076 — Gaps de 4 px, barra de 30 px y menús con rofi

**Contexto:** el usuario había subido a mano la altura de ambas barras a
30 px, pero el instalador y `launch.sh` seguían usando 20/18 px de altura
y 26 px de padding, por lo que el cambio se perdía y las ventanas podían
meterse debajo de la barra. Además, `network-menu.sh` y `services.sh`
preferían dmenu si estaba instalado, y el usuario tiene dmenu.

**Decisión:**
1. `window_gap` pasa de 10 a 4 px; `border_width` sigue en 2.
2. `BAR_HEIGHT=30` se define en `install.sh` y se usa en:
   - `templates/polybar/config.ini.in` (`height = @BAR_HEIGHT@`)
   - `templates/polybar/variants/reference/config.ini.in`
   - `templates/bspwm/bspwmrc.in` (padding superior/inferior)
   - `templates/polybar/scripts/launch.sh.in` (padding al cambiar variante)
   - `lib/bspwm.sh` y `lib/polybar.sh` al renderizar.
3. Los menús de red y servicios usan rofi primero y dmenu como respaldo.

**Consecuencias:**
- La altura de la barra sobrevive a reinstalaciones y al ciclo A/B.
- Las ventanas no se solapan con la barra.
- Los menús salen con el tema Mono Slate de rofi.

## ADR-077 — Borde enfocado gris claro

**Contexto:** el borde de la ventana enfocada era el azul `#569CD6`. Al
usuario le resultaba demasiado llamativo y quería un blanco/gris tenue que
se diferenciara del resto.

**Decisión:**
1. `focused_border_color` usa `COLOR_ACCENT_ALT` (`#D9D9D9`).
2. `normal_border_color` sigue en `#1A1A1A` y `active_border_color` en
   `#2A2A2A`.
3. El azul `#569CD6` se mantiene solo en cursor de kitty, borde de rofi y
   dunst.

**Consecuencias:**
- El foco se distingue por un contorno claro y neutro.
- La paleta no cambia: `#D9D9D9` ya existía como `COLOR_ACCENT_ALT`.

## ADR-078 — Superficie #2F2F2F

**Contexto:** el usuario pidió subir la superficie principal de `#1A1A1A` a
`#2F2F2F`. Ese cambio hacía que el hover `#2A2A2A` quedara más oscuro que
el fondo y que el borde normal (que usaba `COLOR_BG`) desapareciera.

**Decisión:**
1. `COLOR_BG` y `COLOR_BG_ALT` → `#2F2F2F`.
2. `COLOR_BG_ELEV` y `COLOR_BG_HOVER` → `#3A3A3A`.
3. `COLOR_BORDER` → `#1A1A1A`.
4. `normal_border_color` usa `COLOR_BORDER`; `active_border_color` usa
   `COLOR_BG_ELEV`.
5. El wallpaper se mantiene negro.

**Consecuencias:**
- Barra, terminal, Thunar, rofi, dunst y zathura comparten `#2F2F2F`.
- Los estados hover/elevado y los contornos siguen visibles.
- `lib/verify.sh` valida que no aparezcan colores fuera de la paleta.

## ADR-079 — Superficie #2A2A2A

**Contexto:** tras subir la superficie a `#2F2F2F`, el usuario la quería un
poco más oscura.

**Decisión:**
1. `COLOR_BG` y `COLOR_BG_ALT` → `#2A2A2A`.
2. `COLOR_BG_ELEV` y `COLOR_BG_HOVER` se mantienen en `#3A3A3A`.
3. `COLOR_BORDER` se mantiene en `#1A1A1A`, visible sobre el nuevo fondo.

**Consecuencias:**
- Barra, terminal, Thunar, rofi, dunst y zathura usan `#2A2A2A`.
- El hover y los bordes siguen diferenciándose.

## ADR-080 — Superficie #262626

**Contexto:** el usuario seguía ajustando el tono y pidió bajar un poco más
la superficie, de `#2A2A2A` a `#262626`.

**Decisión:**
1. `COLOR_BG` y `COLOR_BG_ALT` → `#262626`.
2. `COLOR_BG_ELEV`/`COLOR_BG_HOVER` se mantienen en `#3A3A3A`.
3. `COLOR_BORDER` se mantiene en `#1A1A1A`.

**Consecuencias:**
- Barra, terminal, Thunar, rofi, dunst y zathura usan `#262626`.
- El contraste con hover y bordes se mantiene.

## ADR-081 — Kitty #212121 y paleta de terminal

**Contexto:** el usuario añadió `colorshemes/monochromatic.conf` a kitty,
pero el `include` estaba al principio y las líneas posteriores de la
plantilla lo sobrescribían. Además, la rampa empezaba en `#444444`, casi
invisible sobre fondo oscuro. También pidió un fondo de terminal algo más
oscuro que el escritorio.

**Decisión:**
1. `COLOR_TERM_BG=#212121` solo para kitty.
2. El tema del terminal se mueve a
   `templates/kitty/colorshemes/monochromatic.conf.in` y se instala en
   `~/.config/kitty/colorshemes/`.
3. `include` va al final de `kitty.conf`.
4. Rampa ANSI de grises con contraste:
   `#2a2a2a`, `#5f5f5f`, `#6e6e6e`, `#8c8c8c`, `#a8a8a8`, `#c0c0c0`,
   `#d0d0d0`, `#d9d9d9`, `#e0e0e0`, `#f2f2f2`, `#ffffff`.
5. `render_theme_template` sustituye `COLOR_TERM_*`; las paletas warm y
   nord definen sus equivalentes.

**Consecuencias:**
- La terminal tiene su propio fondo sin cambiar el resto del escritorio.
- `ls` y `lsd` distinguen tipos de archivo sin salir de la gama de grises.
- El tema sobrevive a reinstalaciones.

## ADR-082 — Kitty #1C1C1C

**Contexto:** el usuario quería la terminal un poco más oscura que
`#212121`.

**Decisión:**
1. `COLOR_TERM_BG` → `#1C1C1C`; el resto del escritorio sigue en
   `#262626`.
2. Se eliminan claves de kitty que esta versión ignora
   (`window_min_width`, `window_min_height`, `decorations`,
   `tab_bar_margin`, `tab_inactive_text_alpha`) para que el log de
   arranque quede limpio.

**Consecuencias:**
- La terminal se separa visualmente del resto de superficies.
- `kitty` no imprime avisos de configuración desconocida.

## ADR-083 — Dunst sigue la posición de polybar

**Contexto:** con la barra abajo, las notificaciones seguían saliendo
arriba. El usuario quiere `top-right` con barra arriba y `bottom-right`
con barra abajo.

**Decisión:**
1. Nuevo `dunst-position.sh`: lee `~/.config/polybar/position` y ajusta
   `origin` en `dunstrc`; luego `dunstctl reload`.
2. Se ejecuta en autostart antes de `dunst &` y desde `launch.sh` al
   cambiar variante/posición.
3. `dunstrc` usa `top-right` como valor base; `offset = (10, 40)` deja
   10 px entre la notificación y la barra de 30 px.

**Consecuencias:**
- Las notificaciones nunca tapan la barra.
- El cambio de esquina es automático con `Super+Alt+P`.
- No hace falta reiniciar dunst ni la sesión.

## ADR-084 — Borde 1, gap 0 y wallpaper Nothing

**Contexto:** el usuario ajustó a mano `border_width=1` y `window_gap=0`
en bspwm y quiere que se mantenga. También quiere como wallpaper por
defecto la imagen `Descargas/Nothing2/contents/images/2337x1080.png`.

**Decisión:**
1. `templates/bspwm/bspwmrc.in` usa `border_width 1` y `window_gap 0`.
2. El wallpaper se vendoriza como `assets/wallpaper.png` (PNG original)
   y se instala en `~/.local/share/wallpapers/wallpaper.png`.
3. Se actualizan todas las referencias de `rocky.jpg` a `wallpaper.png`
   y se elimina `assets/wallpaper.jpg`.
4. `common.sh` respalda tanto `rocky.jpg` (antiguo) como
   `wallpaper.png`.

**Consecuencias:**
- Ventanas sin separación y con contorno de 1 px.
- Instalaciones limpias usan el wallpaper Nothing sin depender de
  `~/Descargas`.
- El wallpaper anterior se conserva en el backup del usuario.

## ADR-085 — Wallpaper alternativo seleccionable

**Contexto:** además de Nothing2, el usuario tiene Nothing1, del mismo
estilo, y quiere poder alternarlo sin editar archivos.

**Decisión:**
1. Vendorizar Nothing1 como `assets/wallpaper-alt.png`, redimensionado a
   2560 px de ancho en PNG (918 KB).
2. `wallpaper.sh` con `apply`, `primary`, `alt` y `toggle`; guarda la
   elección en `~/.config/bspwm/wallpaper`.
3. Atajo `Super+Alt+W` para alternar.
4. El autostart ejecuta `wallpaper.sh apply` para respetar la última
   elección.
5. `lib/config.sh` instala las dos imágenes.

**Consecuencias:**
- Se puede cambiar de wallpaper sin terminal ni editar rutas.
- La elección sobrevive a reinicios de sesión.
- Instalaciones limpias incluyen ambas imágenes.

## ADR-086 — Contador de ventanas en monocle

**Contexto:** en monocle todas las ventanas se apilan y no hay forma de
saber cuántas hay en el escritorio. El usuario quiere un `[N]` en la
barra solo mientras esté en monocle.

**Decisión:**
1. `monocle-count.sh` imprime `[N]` con `bspc query -N -d focused -n
   .window.!hidden | wc -l`.
2. `--check` devuelve 0 solo si `layout == monocle`, para usarlo como
   `exec-if` del módulo.
3. Módulo `custom/script` con `interval = 1`.
4. Se coloca junto a los workspaces: izquierda en A, centro en B.

**Consecuencias:**
- El contador solo aparece en monocle.
- Se actualiza en un segundo al abrir o cerrar ventanas.
- No requiere `jq` ni dependencias extra.
