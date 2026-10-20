# Progreso — fase 1

Última actualización: 2026-10-20

## Resumen

El código de la fase 1 está implementado. Los checks estáticos y de configuración
locales han pasado, pero la instalación **no** se ha ejecutado todavía en una VM
Debian 13 minimal ni en el hardware de referencia. Por tanto:

- Estado del código: implementado; `bash -n`, `--dry-run` y validaciones locales
  de configuración pasan.
- Estado de validación real: pendiente.
- Destino recomendado para la primera prueba: VM Debian 13 minimal con
  snapshot, no el host actual con XFCE/LightDM.

## Validación local sin modificar el host

- `bash -n` / `sh -n` sobre `install.sh`, `lib/*.sh` y los scripts de sesión.
- Dry-run real con `./install.sh --dry-run` y comprobación de residuos en un
  home de prueba: sin rutas `/home/luc` ni placeholders sin renderizar.
- `src/chadwm` y `src/eww` verificados como directorios normales, no gitlinks.
- chadwm `config.h.in`: verificado con headers extraídos en `tmp/devroot`.
- eww v0.6.0: `cargo check --locked --no-default-features --features x11`
  con Debian Rust 1.85 tras fijar `time 0.3.35`; añade `libdbusmenu-glib-dev`
  y `libdbusmenu-gtk3-dev`.
- Ly: compilación local del commit fixado con Zig 0.17.0. Se añadió
  `libaudit-dev` porque `pam.pc` exige `audit.pc`; sin ese paquete Zig falla
  al resolver dependencias. El fallo final fue solo de linking contra libs
  estáticas extraídas, no del código fuente.
- Xorg lanzado por Ly corre como usuario y necesita escribir
  `~/.local/share/xorg/Xorg.0.log`; el instalador crea ese directorio con modo
  `0700` y la verificación comprueba que sea escribible.
- dunst `1.12.2`, picom `12.5`, rofi `1.7.5` y kitty:
  parseo/dry-run/config check sin errores.
- Preflight APT probado con componentes simulados: detecta `non-free`,
  `non-free-firmware` y `contrib` ausentes, aborta si falta `main`, y no
  pregunta ni modifica nada en `--dry-run`/`--yes`.
- Auto-add de repositorios probado solo con fixtures temporales `.list` y
  `.sources`: backup, edición de entradas Debian 13, respeto a repos de
  terceros y entradas deshabilitadas, recheck e idempotencia.

## Checklist de implementación

- [x] Estructura del proyecto (`install.sh`, `lib/`, `bin/`, `templates/`).
- [x] Detección de Debian/arquitectura/VM/CPU/GPU/Secure Boot/resolución.
- [x] Detección de cámara, batería, backlight, WiFi, audio y raíz.
- [x] Resolución automática de usuario/home y validación de `sudo`.
- [x] Uso normal `./install.sh`, con solo `--dry-run`/`--yes` como opciones simples.
- [x] Grupos de paquetes Debian 13.
- [x] Preflight de componentes APT con menú genérico: añadir, continuar o
      cancelar; `main` ausente aborta y nunca se auto-añade.
- [x] Auto-add autorizado de componentes: backup, edición limitada a Debian 13,
      `apt update` y recheck.
- [x] Instalación de Nerd Font con versión y checksum fijos, con fallback
      configurable al empaquetado Debian.
- [x] Compilación e instalación de chadwm.
- [x] Compilación e instalación de eww v0.6.0, con ajuste `time 0.3.35`
      para Rust 1.85.
- [x] Compilación de Ly con Zig 0.17.0 y commit fijo, con `libpam0g-dev` y
      `libaudit-dev`.
- [x] Configuración de Ly (Gruvbox, español, sin shell/xinitrc).
- [x] Directorio `~/.local/share/xorg` (0700) para el log de Xorg sin root.
- [x] Servicio `ly@tty2` y deshabilitado de otros display managers.
- [x] Configuración de usuario, backups, wallpaper y sesión X11.
- [x] `run.sh` con barra, eww, dunst, picom, udiskie y xss-lock.
- [x] `dwm-safe` para lock/suspend/logout/power.
- [x] `dwm-doctor`, incluida prueba real de cámara.
- [x] Verificación estática final.
- [x] Documentación base (`README.md`, `AGENTS.md`, `DECISIONS.md`).
- [x] `--dry-run` sin modificaciones y con plan completo.
- [x] Backups de sistema y usuario.
- [x] `PLAN.md` marcado como obsoleto.
- [x] Prototipo antiguo movido a `legacy/`.
- [x] Fuentes de chadwm y eww vendorizadas en el repositorio, sin submódulos.

## Checklist de validación

Estas tareas requieren una instalación real:

- [ ] Instalar Debian 13 minimal en VM con UEFI y snapshot.
- [ ] Ejecutar `./install.sh --dry-run` en la VM.
- [ ] Ejecutar la instalación real con `./install.sh`.
- [ ] Verificar que la instalación termina con `dwm-doctor` estático correcto.
- [ ] Reiniciar y comprobar que Ly aparece en `tty2`.
- [ ] Iniciar sesión en la sesión `dwm`.
- [ ] Confirmar que `dwm` y la barra arrancan.
- [ ] Confirmar que eww abre dashboard/control/power.
- [ ] Confirmar que picom y dunst están activos.
- [ ] Confirmar que rofi, kitty, pcmanfm, flameshot e i3lock funcionan.
- [ ] Confirmar audio PipeWire/WirePlumber y `pavucontrol`.
- [ ] Reproducir un vídeo H.264/HEVC y comprobar VA-API si hay GPU.
- [ ] Ejecutar `dwm-doctor --camera` con una cámara real o virtual.
- [ ] Conectar un USB exFAT/NTFS/FAT y comprobar montaje + notificación sin
      apertura automática.
- [ ] Probar suspensión y bloqueo con xss-lock.
- [ ] Probar el fallback `startx`.
- [ ] Probar en hardware de referencia (Intel + NVIDIA MX330).
- [ ] Probar NVIDIA con Secure Boot desactivado y documentar MOK si aplica.
- [ ] Repetir la instalación para comprobar idempotencia.
- [ ] Revisar logs y backups.

## Bloqueos actuales

- No hay una VM Debian 13 minimal preparada en este entorno.
- El host actual tiene XFCE/LightDM y no debe modificarse de forma destructiva.
- La compilación local completa de chadwm/eww/Ly depende de headers/librerías
  extraídas en temp; el destino real no tiene ese bloqueo porque instala los
  paquetes de desarrollo.
- La cámara, el montaje USB, el audio/códecs y NVIDIA/PRIME necesitan hardware
  real o pass-through de VM.
- No ha habido ninguna instalación real todavía.
- El repositorio Git ya incluye las fuentes vendorizadas de chadwm y eww; falta
  subirlo y validar el clon limpio en la VM.

## Riesgos conocidos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| eww v0.6.0 falla con Rust 1.85 por `time 0.3.34` | Alto | Se ajusta a `time 0.3.35` antes de compilar y se comprueba `--version` |
| Falta una dependencia nativa de eww en el destino | Alto | Instalación se detiene con log visible; grupos obligatorios incluyen `libdbusmenu-*` |
| Ly cambia y el commit fijo no compila con Zig 0.17 | Alto | Commit y versión fijos; fallback `startx` |
| NVIDIA DKMS falla | Medio | Grupo GPU es opcional; se continúa con Intel/mesa |
| Secure Boot `enabled` o no detectable | Medio | Se omite NVIDIA por defecto y se avisa; `--nvidia` avanzado permite forzar |
| Falta `non-free-firmware` | Medio | El preflight ofrece añadirlo con backup o continuar; el usuario decide |
| Falta `non-free` | Medio | El preflight avisa de la pérdida de VA-API Intel/NVIDIA y ofrece añadirlo |
| Falta `contrib` | Bajo | El preflight avisa; solo se omite `nvidia-settings`; se puede añadir con autorización |
| Nerd Font no descarga | Bajo | Fallback a `JetBrains Mono` / `monospace`; iconos pueden fallar |
| `udiskie` no arranca en la sesión | Medio | `run.sh` lo inicia; `dwm-doctor` avisa |
| El usuario no cierra sesión tras `usermod` | Medio | Se avisa; grupos video/audio/render se aplican al reentrar |

## Próximos pasos

1. Preparar VM Debian 13 minimal con snapshot (ver `docs/testing.md`).
2. Ejecutar `./install.sh --dry-run` y revisar el plan en la VM.
3. Ejecutar `./install.sh` y corregir cualquier fallo de compilación.
4. Validar Ly/dwm/eww/barra.
5. Validar audio, cámara, USB y NVIDIA en hardware.
6. Actualizar este archivo con resultados reales y fecha.
