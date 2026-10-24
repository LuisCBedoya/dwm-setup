# AGENTS.md — instrucciones persistentes

Este archivo es la guía para cualquier modelo o persona que continúe el
proyecto. Leer primero `README.md`, `PROGRESS.md` y `DECISIONS.md`.

## Objetivo

Instalador reproducible de un escritorio mínimo para **Debian 13 (trixie)**
con Xorg, **startx manual** (sin display manager), **bspwm**, **sxhkd**,
**polybar**, **picom**, **dunst**, **rofi**, **kitty**, **flameshot**,
**i3lock/xss-lock**, PipeWire, cámara UVC y almacenamiento extraíble con
notificación.

La barra final es la de la config viva: **13 módulos**, glifo del logo de
JetBrainsMono Nerd Font, sin `dots` y sin fuente `DesktopLogo`.

La fase 1 termina en el escritorio. No implementar todavía:

- Neovim/IDE, VS Code, Node/nvm.
- Firefox, Brave/Chromium u otros navegadores.
- Correo, Teams.
- Reproductores de música, mpv, cava o widgets de música.
- Bluetooth, zathura, htop, lsd, ripgrep, nvitop/nvtop.
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
    `--nvidia`.
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
    seguido de `h/j/k/l` redimensiona mediante cadena de sxhkd; `Escape` sale.
    `Print` captura pantalla completa al portapapeles; `Super+Print` abre el
    menú de capturas. No cambiar este mapa sin una decisión nueva.
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

## Estructura relevante

| Archivo | Responsabilidad |
|---|---|
| `install.sh` | Flujo, opciones, confirmación, backups y resumen |
| `lib/common.sh` | Logs, sudo, ownership, backups, render, helpers |
| `lib/detect.sh` | Detección de sistema/hardware y usuario |
| `lib/packages.sh` | Preflight APT, paquetes y Nerd Font |
| `lib/bspwm.sh` | bspwm, bspwmrc, autostart, scripts y `.xinitrc` |
| `lib/sxhkd.sh` | sxhkdrc |
| `lib/polybar.sh` | config.ini, módulos, scripts y launch.sh |
| `lib/picom.sh` | picom.conf |
| `lib/dunst.sh` | dunstrc |
| `lib/rofi.sh` | powermenu.rasi |
| `lib/kitty.sh` | kitty.conf |
| `lib/config.sh` | Configs de usuario, wallpaper, binarios y limpieza |
| `lib/verify.sh` | Verificación estática final |
| `lib/theme.sh` | Paleta Nord y render de plantillas |
| `lib/audio.sh` | Quirk ALC255 condicionado por DMI/códec |
| `bin/desktop-safe` | Acciones de sesión (lock/suspend/logout/poweroff) |
| `bin/desktop-doctor` | Diagnóstico y cámara (POSIX sh) |
| `templates/bspwm/` | bspwmrc, autostart y scripts de sesión |
| `templates/sxhkd/` | sxhkdrc |
| `templates/polybar/` | config.ini, modules/ y scripts/ |
| `templates/picom/` | picom.conf |
| `templates/dunst/` | dunstrc y notification-sound.sh |
| `templates/rofi/` | powermenu.rasi |
| `templates/kitty/` | kitty.conf |
| `templates/modprobe/` | alsa-fx504.conf (quirk ALC255) |
| `templates/colors/` | `palette-nord.sh` y helpers |
| `assets/wallpaper.jpg` | Wallpaper |

Ya no existen `src/chadwm`, `src/eww`, `legacy/`, `lib/dwm.sh`,
`lib/eww.sh`, `lib/ly.sh`, `templates/dwm/` ni la integración de dotfiles
externos. No reañadirlos sin una decisión nueva en `DECISIONS.md`.

## Comandos de validación

```sh
cd ~/dwm-setup

# Sintaxis
for f in install.sh lib/*.sh; do bash -n "$f" || exit 1; done
for f in bin/desktop-safe bin/desktop-doctor; do sh -n "$f" || exit 1; done
bash -n templates/bspwm/autostart.in templates/bspwm/bspwmrc.in

# Plan sin cambios
./install.sh --dry-run

# Comprobar restos y coherencia de la barra
grep -RInE '@[A-Z][A-Z0-9_]*@' ~/.config/bspwm ~/.config/sxhkd \
  ~/.config/polybar ~/.config/picom ~/.config/dunst ~/.config/rofi \
  ~/.config/kitty ~/.xinitrc
grep -nE 'modules-(left|right)' ~/.config/polybar/config.ini
stat -c '%A %n' ~/.config/bspwm/bspwmrc ~/.xinitrc

# ShellCheck (si está instalado)
shellcheck install.sh lib/*.sh bin/desktop-safe bin/desktop-doctor

# Diagnóstico en una sesión instalada
desktop-doctor
desktop-doctor --camera
```

## Estado esperado al retomar

- El código de fase 1b está implementado y los checks estáticos pasan.
- La sesión viva se validó el 2026-10-24: bspwm, sxhkd, polybar (13 módulos),
  picom, dunst, lxpolkit, udiskie y xss-lock activos; `startx` manual.
- Se corrigieron backups previos, ownership, `bspwmrc` 0755, picom,
  `desktop-doctor`, batería baja y polkit.
- Audio: watcher auriculares > HDMI > altavoces, sonido de dunst y quirk
  ALC255 condicionado a ASUS FX504GE. La validación del quirk requiere
  reinicio; el resto se probó en vivo el 2026-10-24.
- Falta validar una instalación desde cero en VM Debian 13 y subir el repo.
- `PROGRESS.md` contiene la lista de pruebas y bloqueos.
- Si se completa una prueba real, actualizar `PROGRESS.md` y
  `docs/testing.md` con fecha, hardware, fuentes y resultados. Si no hay
  resultado real, marcarlo como pendiente.
