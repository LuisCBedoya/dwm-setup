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

**Consecuencias:** se descargan Zig y Ly; el commit/versión están fijados. No
se inicia Ly durante la instalación para no matar la sesión actual. `startx`
sigue siendo una vía de recuperación.

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

**Decisión:** detectar GPU. Instalar `nvidia-driver` solo si hay NVIDIA y:
- no se pasó `--no-nvidia`;
- Secure Boot está desactivado, o se pasó `--nvidia`;
- no es una VM, o se pasó `--nvidia`.

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

## ADR-018 — Preflight de componentes APT antes de confirmar

**Contexto:** el instalador no añade repositorios y los grupos opcionales
(firmware, GPU, microcódigo, cámara) podían omitir paquetes sin que el usuario
viera las consecuencias hasta después de confirmar y empezar la instalación.

**Decisión:** leer los componentes APT habilitados con
`apt-get indextargets` antes de instalar, mostrar qué falta y qué funciones se
pierden, y pedir confirmación en instalación interactiva. En `--dry-run` solo
se muestra el aviso. El instalador no habilita repositorios ni modifica
`sources.list`.

**Consecuencias:** el usuario decide con información antes de tocar el sistema.
`contrib` se trata aparte: solo afecta a `nvidia-settings`, no al driver NVIDIA.
Los grupos obligatorios siguen abortando si falta un paquete; los opcionales
avisan y continúan.
