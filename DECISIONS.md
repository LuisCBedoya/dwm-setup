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

## ADR-016 — Fuentes de chadwm y eww vendorizadas

**Contexto:** `src/chadwm` y `src/eww` eran repositorios Git anidados. Git los
registraba como gitlinks, sin `.gitmodules`, así que un clon del proyecto no
incluía las fuentes y la compilación de chadwm fallaba.

**Decisión:** incluir las fuentes directamente en el repositorio, sin
submódulos. Se fijan los commits upstream: chadwm `7991ac8` y eww `v0.6.0`
(`d87c2fd`). Los metadatos `.git` de los repos anidados no forman parte del
proyecto.

**Consecuencias:** un `git clone` es autocontenido para chadwm y eww; solo
Zig, Ly y la Nerd Font se descargan durante la instalación. Actualizar una
fuente implica reemplazar el árbol vendorizado y anotar el nuevo commit.

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
