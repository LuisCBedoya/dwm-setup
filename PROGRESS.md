# Progreso — fase 1b (bspwm + polybar)

Última actualización: 2026-10-21

## Resumen

La fase 1b (migración de chadwm/eww/Ly a bspwm/sxhkd/polybar + startx) está implementada.
El código pasa checks estáticos (`bash -n`) y `--dry-run`, pero la instalación **no** se ha
ejecutado todavía en una VM Debian 13 minimal ni en el hardware de referencia.

- Estado del código: implementado; `bash -n`, `--dry-run` y validaciones locales pasan.
- Estado de validación real: pendiente.
- Destino recomendado para la primera prueba: VM Debian 13 minimal con
  snapshot, no el host actual con XFCE/LightDM.

## Validación local sin modificar el host

- `bash -n` / `sh -n` sobre `install.sh`, `lib/*.sh` y los scripts de sesión.
- Dry-run real con `./install.sh --dry-run` y comprobación de residuos en un
  home de prueba: sin rutas `/home/luc` ni placeholders sin renderizar.
- Preflight APT probado con componentes simulados: detecta `non-free`,
  `non-free-firmware` y `contrib` ausentes, aborta si falta `main`, y no
  pregunta ni modifica nada en `--dry-run`/`--yes`.
- Auto-add de repositorios probado solo con fixtures temporales `.list` y
  `.sources`: backup, edición de entradas Debian 13, respeto a repos de
  terceros y entradas deshabilitadas, recheck e idempotencia.
- Paleta Nord vendorizada y templates renderizados correctamente en dry-run.
- `polybar/launch.sh` detecta batería y elige config con/sin módulo battery.
- `bspwmrc`, `sxhkdrc`, `polybar/config.ini`, `picom.conf`, `dunstrc`, `rofi/powermenu.rasi`,
  `kitty/kitty.conf` se renderizan con variables Nord.

## Checklist de implementación — fase 1b

- [x] Estructura del proyecto (`install.sh`, `lib/`, `bin/`, `templates/`).
- [x] Detección de Debian/arquitectura/VM/CPU/GPU/Secure Boot/resolución.
- [x] Detección de cámara, batería, backlight, WiFi, audio y raíz.
- [x] Resolución automática de usuario/home y validación de `sudo`.
- [x] Uso normal `./install.sh`, con solo `--dry-run`/`--yes` como opciones simples.
- [x] Grupos de paquetes Debian 13 (bspwm, sxhkd, polybar, sin compilación).
- [x] Preflight de componentes APT con menú genérico: añadir, continuar o
      cancelar; `main` ausente aborta y nunca se auto-añade.
- [x] Auto-add autorizado de componentes: backup, edición limitada a Debian 13,
      `apt update` y recheck.
- [x] Instalación de Nerd Font con versión y checksum fijos, con fallback
      configurable al empaquetado Debian.
- [x] **bspwm** instalado desde apt + configs renderizadas (bspwmrc, autostart, scripts).
- [x] **sxhkd** instalado desde apt + sxhkdrc renderizado (todos los atajos).
- [x] **polybar** instalado desde apt + config.ini, modules/, scripts/, launch.sh
      (detección batería condicional).
- [x] **picom** instalado desde apt + picom.conf renderizado (esquinas redondeadas, fade).
- [x] **dunst** instalado desde apt + dunstrc renderizado (top-center, colores Nord).
- [x] **rofi** instalado desde apt + powermenu.rasi renderizado (6 acciones).
- [x] **kitty** instalado desde apt + kitty.conf renderizado (opacidad, tabs, esquema Nord).
- [x] **Sesión:** `~/.xinitrc` → `bspwm` (autostart interno levanta todo).
- [x] **Dotfiles opcional:** prompt para repo Git HTTPS, clonado en `/tmp`,
      copia `config/.config/{7 carpetas}`, fallback a templates integrados.
- [x] `desktop-safe` para lock/suspend/logout/poweroff/reboot.
- [x] `desktop-doctor` para diagnóstico bspwm/sxhkd/polybar/cámara.
- [x] Verificación estática final (`verify_install`).
- [x] Documentación actualizada (`README.md`, `AGENTS.md`, `DECISIONS.md` ADR-022).
- [x] `--dry-run` sin modificaciones y con plan completo.
- [x] Backups de sistema y usuario.
- [x] `PLAN.md` marcado como obsoleto.
- [x] Prototipo antiguo movido a `legacy/`.
- [x] Fuentes vendorizadas mantenidas (ya no se usan pero quedan en repo).
- [x] **Sistema de temas** Nord (`templates/colors/palette-nord.sh`, `lib/theme.sh`,
      generadores rofi/dunst/picom/kitty).
- [x] `pamixer`/`xwallpaper`/`playerctl` en lugar de `pactl`/`feh`.
- [x] `init_logging` con fallback a `~/.cache/dwm-setup` y validación de log.
- [x] **Barra polybar réplica exacta** (ADR-023): config.ini.in reescrita con colores
      `#0D1117`/`#C9D1D9`, altura 26px, arriba, `include-directory`, 13 módulos
      portados del repo Bspwm con glifos Nerd Font idénticos, logo U+F2DD en
      extremo izquierdo, workspaces 1-5 con dígitos árabes, sin subrayados,
      `bspc config top_padding = 26`, `polypomo` vendorizado, `updates` para apt,
      `launch.sh` simplificado, `python3` en BASE_PKGS.

## Checklist de validación

Estas tareas requieren una instalación real:

- [ ] Instalar Debian 13 minimal en VM con UEFI y snapshot.
- [ ] Ejecutar `./install.sh --dry-run` en la VM.
- [ ] Ejecutar la instalación real con `./install.sh` (probar con y sin repo dotfiles).
- [ ] Verificar que la instalación termina con `desktop-doctor` estático correcto.
- [ ] Reiniciar y comprobar que al entrar en TTY1, `startx` lanza bspwm.
- [ ] Confirmar que bspwm, sxhkd y polybar arrancan.
- [ ] Confirmar que polybar muestra workspaces, CPU, RAM, temp, red, audio, fecha, batería (si hay).
- [ ] **Confirmar que la barra polybar es visualmente idéntica al screenshot de referencia** (logo, workspaces, módulos, colores, espaciado, altura, posición arriba).
- [ ] Confirmar que picom y dunst están activos.
- [ ] Confirmar que rofi (Super+d), powermenu (Super+Shift+L), kitty (Super+Return) funcionan.
- [ ] Confirmar audio PipeWire/WirePlumber y `pavucontrol`.
- [ ] Reproducir un vídeo H.264/HEVC y comprobar VA-API si hay GPU.
- [ ] Ejecutar `desktop-doctor --camera` con una cámara real o virtual.
- [ ] Conectar un USB exFAT/NTFS/FAT y comprobar montaje + notificación sin
      apertura automática.
- [ ] Probar suspensión y bloqueo con xss-lock (Super+Shift+L).
- [ ] Probar en hardware de referencia (Intel + NVIDIA MX330).
- [ ] Probar NVIDIA con Secure Boot desactivado y documentar MOK si aplica.
- [ ] Repetir la instalación para comprobar idempotencia.
- [ ] Revisar logs y backups.

## Bloqueos actuales

- No hay una VM Debian 13 minimal preparada en este entorno.
- El host actual tiene XFCE/LightDM y no debe modificarse de forma destructiva.
- La cámara, el montaje USB, el audio/códecs y NVIDIA/PRIME necesitan hardware
  real o pass-through de VM.
- No ha habido ninguna instalación real todavía.
- El repositorio Git ya incluye las fuentes vendorizadas de chadwm y eww; falta
  subirlo y validar el clon limpio en la VM.

## Riesgos conocidos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Polybar módulo battery falla si no hay BAT* | Bajo | `launch.sh` detecta y omite módulo |
| Falta una dependencia nativa de polybar | Alto | Grupo `DESKTOP_PKGS` incluye `polybar` de apt (probado) |
| NVIDIA DKMS falla | Medio | Grupo GPU es opcional; se continúa con Intel/mesa |
| Secure Boot `enabled` o no detectable | Medio | Se omite NVIDIA por defecto y se avisa; `--nvidia` avanzado permite forzar |
| Falta `non-free-firmware` | Medio | El preflight ofrece añadirlo con backup o continuar; el usuario decide |
| Falta `non-free` | Medio | El preflight avisa de la pérdida de VA-API Intel/NVIDIA y ofrece añadirlo |
| Falta `contrib` | Bajo | El preflight avisa; solo se omite `nvidia-settings`; se puede añadir con autorización |
| Nerd Font no descarga | Bajo | Fallback a `JetBrains Mono` / `monospace`; iconos pueden fallar |
| `udiskie` no arranca en la sesión | Medio | `bspwm/autostart` lo inicia; `desktop-doctor` avisa |
| El usuario no cierra sesión tras `usermod` | Medio | Se avisa; grupos video/audio/render se aplican al reentrar |
| Repo dotfiles externo no disponible/estructura incorrecta | Medio | Fallback a templates integrados; prompt interactivo para decidir |

## Próximos pasos

1. Preparar VM Debian 13 minimal con snapshot (ver `docs/testing.md`).
2. Ejecutar `./install.sh --dry-run` y revisar el plan en la VM.
3. Ejecutar `./install.sh` (probar con y sin `--yes`, y con URL de dotfiles) y corregir cualquier fallo.
4. Validar bspwm/sxhkd/polybar/picom/dunst/rofi/kitty.
5. Validar audio, cámara, USB y NVIDIA en hardware.
6. Actualizar este archivo con resultados reales y fecha.