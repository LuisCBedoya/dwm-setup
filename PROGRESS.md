# Progreso — fase 1b (bspwm + polybar)

Última actualización: 2026-10-24

## Resumen

La fase 1b está implementada y validada en la sesión viva del host de
referencia (Debian 13, Intel UHD 630 + NVIDIA GTX 1050 Ti Mobile,
1920x1080). El instalador se ha corregido para que los backups se hagan
antes de escribir, el home quede con el propietario correcto, `bspwmrc` sea
ejecutable, picom arranque y la verificación final no falle.

- Estado del código: implementado; `bash -n`, `sh -n`, `--dry-run` y
  verificación sobre home simulado pasan.
- Estado de validación real: **sesión viva validada**; falta la instalación
  desde cero en VM Debian 13 minimal.
- Sesión: `startx` manual desde TTY; sin display manager ni auto-login.
- Barra: 13 módulos, glifo JBM, sin `dots` y sin `DesktopLogo`.

## Validación viva (2026-10-24)

Host: Debian GNU/Linux 13 (trixie), kernel 6.12, Xorg 1920x1080, NVIDIA 550
instalado (Xorg usa Intel `modeset`), PipeWire 1.4.2.

Procesos comprobados:

- `bspwm 0.9.10`
- `sxhkd 0.6.2`
- `polybar 3.7.2` con **13 módulos**: `logo`, `bspwm`, `polypomo`, `temp`,
  `memory`, `cpu`, `xkeyboard`, `eth`, `wlan`, `battery`, `pipewire`,
  `date`, `updates`.
- `picom` 12.5 activo (config sin `glx-swap-method`).
- `dunst 1.12.2`, `lxpolkit`, `udiskie -N -a`, `xss-lock` activos.
- `BAT1`, `ACAD`, `enp3s0`, `wlo1`, teclado `latam`, batería y volumen
  visibles en la barra.
- `notify-send` funciona.

Comprobaciones:

- `~/.config/bspwm/bspwmrc` y `~/.xinitrc`: `0755`; `.xinitrc` termina en
  `exec bspwm` y ya no lanza `kitty`.
- Sin placeholders `@...@` en las configuraciones vivas.
- `low_bat_notifier.sh` contiene `BATTERY="BAT1"`.
- Sin ficheros root en `~/.config/{bspwm,sxhkd,polybar,picom,dunst,rofi,kitty}`.
- `desktop-doctor` (repo) muestra todos los binarios/configs/procesos OK;
  solo avisa de que no hay cámara.
- Home simulado (`/tmp/opencode/fakehome`) renderizado y `verify_install`
  pasa con código 0.

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
- **Picom**: se quitó `glx-swap-method` (eliminado en picom 12), `refresh-rate`
  y condiciones deprecadas; arranca sin errores.
- **Autostart**: sin `set -e`, log en `~/.local/state/dwm-setup/session.log`,
  `lxpolkit`, `udiskie -N -a` sin `-t`, aviso si picom no arranca.
- **Batería baja**: se pasa `BATTERY` al renderizar el script.
- **`desktop-doctor`**: reescrito en POSIX sh; ya no usa `[[`,
  `WAYLAND_DISPLAY` sin `:-` ni `ls BAT* | xargs basename`.
- **Barra**: font-0 pasa de `DesktopLogo` a JBM; se retiran
  `assets/desktop-logo.ttf`, `dots.ini.in`, la instalación de la fuente y
  las comprobaciones asociadas. Se añade limpieza idempotente de restos.
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
- [x] picom instalado desde apt + picom.conf moderno.
- [x] dunst instalado desde apt + dunstrc (Adwaita).
- [x] rofi instalado desde apt + powermenu.rasi (Adwaita).
- [x] kitty instalado desde apt + kitty.conf.
- [x] Sesión: `~/.xinitrc` → `bspwm`; autostart interno.
- [x] `desktop-safe` para lock/suspend/logout/poweroff/reboot.
- [x] `desktop-doctor` POSIX para bspwm/sxhkd/polybar/picom/cámara.
- [x] Verificación estática final (`verify_install`).
- [x] Backups de sistema y usuario antes de escribir.
- [x] Ownership automático del home y logs.
- [x] `--dry-run` sin modificaciones.
- [x] Limpieza de restos de la barra anterior.
- [x] Documentación actualizada.

## Checklist de validación

- [x] Sesión viva en Debian 13 (host de referencia).
- [x] `desktop-doctor` sin falsos `[FALTA]`.
- [x] Barra con 13 módulos y sin placeholders.
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
| Picom no arranca | Medio | Config sin `glx-swap-method`; log de sesión |
| Módulo battery/WiFi inexistente | Bajo | Render condicional y archivos siempre presentes |
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
