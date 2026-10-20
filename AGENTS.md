# AGENTS.md — instrucciones persistentes

Este archivo es la guía para cualquier modelo o persona que continúe el
proyecto. Leer primero `README.md`, `PROGRESS.md` y `DECISIONS.md`.

## Objetivo

Construir y validar un instalador reproducible de un escritorio mínimo para
**Debian 13 (trixie)** con Xorg, Ly, chadwm, eww, barra status2d, picom,
dunst, rofi, feh, kitty, flameshot, i3lock/xss-lock, PipeWire, cámara UVC y
almacenamiento extraíble con notificación.

La fase 1 termina en el escritorio. No implementar todavía:

- Neovim/IDE, VS Code, Node/nvm.
- Firefox, Brave/Chromium u otros navegadores.
- Correo, Teams.
- Reproductores de música, mpv, cava o widgets de música.
- Bluetooth, zathura, htop, lsd, ripgrep, nvitop/nvtop.
- XFCE, LightDM, Thunar o un entorno de escritorio completo.

## Reglas de trabajo

1. **No ejecutar la instalación real en el host actual**
   (`/home/luc`, XFCE/LightDM) sin backup y sin una VM validada. Para pruebas
   usar una VM Debian 13 minimal con snapshot.
2. **Mantener la idempotencia.** Volver a ejecutar el instalador no debe
   romper el sistema. Usar backups y `--rebuild` para forzar compilaciones.
3. **Mantener `--dry-run` libre de modificaciones.** No debe descargar,
   instalar, escribir configuraciones ni habilitar servicios. Solo puede leer
   hardware y mostrar el plan.
4. **No guardar contraseñas.** El instalador usa `sudo -v` y `sudo`; nunca
   escribe credenciales ni crea archivos con contraseñas. Debian 13 y x86_64
   se validan antes de pedir `sudo`.
5. **Backups antes de reemplazar.** Sistema:
   `/var/backups/dwm-setup/<timestamp>/`; usuario:
   `~/.config-backup/dwm-setup/<timestamp>/`.
6. **Fallos visibles.** No ocultar errores de compilación, paquetes o
   servicios. Los grupos opcionales pueden avisar y continuar; los
   obligatorios deben detener la instalación.
7. **No añadir repositorios APT** ni modificar `sources.list`. El preflight
   solo lee los componentes habilitados (`main`, `contrib`, `non-free`,
   `non-free-firmware`) y avisa antes de instalar. Los paquetes de
   `non-free`/`non-free-firmware`/`contrib` son opcionales y se detectan con
   `apt-cache`.
8. **No introducir PulseAudio como servidor.** PipeWire es el servidor;
   `pulseaudio-utils` solo aporta `pactl`.
9. **No introducir NVIDIA/CUDA incondicionalmente.** La GPU se detecta; el
   driver propietario es opcional y se omite con Secure Boot activo salvo
   `--nvidia`.
10. **No abrir gestores de archivos automáticamente** al montar USB.
    `udiskie` solo monta y notifica; `pcmanfm` se abre con Mod+E.
11. **Mantener las rutas portables.** Las plantillas usan `@HOME@`, `@FONT@`,
    `@FONT_SIZE@`, `@KEYMAP@`, `@WALLPAPER@`, `@RESOLUTION@`. No hardcodear
    `/home/luc`.
12. **No renderizar `@DEFAULT_SINK@`.** Es una cadena literal de
    `pactl` dentro de `config.h.in`, no una variable de plantilla.
13. **Actualizar la documentación** (`PROGRESS.md`, `DECISIONS.md`,
    `docs/testing.md`) cuando cambie el diseño o se valide una prueba.
14. **Estilo:** Bash con `#!/usr/bin/env bash`, `set -Eeuo pipefail` en la
    entrada, funciones pequeñas, `printf`, arrays citados y `shellcheck` si
    está disponible. Los scripts instalados que corren en sesión usan
    `#!/bin/sh` POSIX.

## Estructura relevante

| Archivo | Responsabilidad |
|---|---|
| `install.sh` | Flags, orden, confirmación, backups y resumen |
| `lib/common.sh` | Logs, sudo, render, backups, helpers |
| `lib/detect.sh` | Detección de sistema/hardware y usuario |
| `lib/packages.sh` | Preflight APT, paquetes y Nerd Font |
| `lib/dwm.sh` | chadwm |
| `lib/eww.sh` | eww v0.6.0 y ajuste `time 0.3.35` (Rust 1.85) |
| `lib/ly.sh` | Zig, Ly, config y `ly@tty2` |
| `lib/config.sh` | Configs de usuario, `/usr/share/xsessions` |
| `lib/verify.sh` | Verificación estática |
| `bin/dwm-safe` | Acciones de sesión |
| `bin/dwm-doctor` | Diagnóstico y cámara |
| `templates/dwm/` | dwm/eww/barra/dunst/rofi/picom/sesión |
| `templates/kitty/` | kitty |
| `assets/wallpaper.jpg` | Wallpaper |
| `src/chadwm/chadwm` | Fuente chadwm, vendorizada (commit `7991ac8`) |
| `src/eww` | Fuente eww v0.6.0, vendorizada (commit `d87c2fd`) |
| `legacy/` | Prototipo antiguo, no usado |

## Comandos de validación

```sh
cd ~/dwm-setup

# Sintaxis
for f in install.sh lib/*.sh bin/dwm-safe bin/dwm-doctor \
  templates/dwm/run.sh templates/dwm/scripts/bar.sh; do
  bash -n "$f" || exit 1
done

# Plan sin cambios
./install.sh --dry-run --yes --user "$USER" --no-nvidia

# Comprobar atajos, sesión, tema y dunst del repo
grep -RInE 'xss-lock|rofi|eww -c .*open --toggle|pcmanfm|--config.*rofi|dunstrc' templates

# ShellCheck (si está instalado)
shellcheck install.sh lib/*.sh bin/dwm-safe bin/dwm-doctor

# Diagnóstico en una sesión instalada
dwm-doctor
dwm-doctor --camera
```

## Registro de decisiones

Antes de cambiar una decisión importante (display manager, WM, servidor de
audio, gestor de archivos, política NVIDIA, fases), añadir una entrada en
`DECISIONS.md` con contexto, decisión y consecuencias. No reescribir la
historia de `PLAN.md`; está marcado como obsoleto.

## Estado esperado al retomar

- El código de fase 1 está implementado y los checks estáticos pasan.
- Las fuentes de chadwm y eww están vendorizadas; el repo no usa submódulos.
- Hay backups y dry-run; falta validación real y subir el repo.
- `PROGRESS.md` contiene la lista de pruebas y bloqueos.
- Si se completa una prueba real, actualizar `PROGRESS.md` y
  `docs/testing.md` con fecha, hardware, fuentes y resultados. Si no hay
  resultado real, marcarlo como pendiente; no confundir con un check local.
