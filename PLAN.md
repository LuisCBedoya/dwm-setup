> [!WARNING]
> **OBSOLETO — no usar como guía de instalación.** Este plan conserva el
> historial del prototipo. Contradice el diseño actual (habla de dwm 6.5 sin
> chadwm, XFCE/LightDM, Thunar, zathura, ranger, keepassxc, etc.).
>
> Documentación vigente: [`README.md`](README.md), [`PROGRESS.md`](PROGRESS.md),
> [`AGENTS.md`](AGENTS.md), [`DECISIONS.md`](DECISIONS.md),
> [`docs/hardware.md`](docs/hardware.md) y [`docs/testing.md`](docs/testing.md).
> El código actual está en `install.sh`, `lib/` y `templates/`.

# Plan: dwm estilo ev1/eve2/ev3 en Debian 13

## Decisiones

- **WM:** dwm 6.5 compilado desde fuente (no chadwm), con tus atajos.
- **Tags:** 6 con nombre y subrayado: `cmd`, `www`, `dev`, `chat`, `sys`, `med`.
- **Barra:** superior, status2d, iconos y colores Gruvbox Material.
- **Widgets:** eww completo (dashboard, calendario, census, control center).
- **Música:** sin widget por ahora.
- **Wallpaper:** costa rocosa oscura, adaptada a 1366x768.
- **XFCE se queda** como sesión de respaldo en LightDM.

## Stack

| Pieza | Elección |
|---|---|
| WM | dwm 6.5 + patches: systray, fullgaps, status2d, underlinetags, altags, statuspadding, alpha, cool-autostart, actualfullscreen |
| Barra | `bar.sh` con status2d (CPU, RAM, disco, volumen, red, reloj) |
| Tema | Gruvbox Material |
| Terminal | kitty + JetBrainsMono Nerd Font |
| Compositor | picom (rounded corners, sombras, blur) |
| Widgets | eww |
| Notificaciones | dunst |
| Lock | i3lock |
| Apps | zathura, ranger, feh, flameshot, thunar, keepassxc, gpicview |

## Fases

1. **Base**
   - Dependencias.
   - Compilar dwm 6.5 + parches.
   - Portar config: 6 tags, atajos, colores, gaps.
   - Barra status2d.
   - kitty, picom, dunst, wallpaper, lock.
   - Sesión en LightDM + prueba en Xephyr.

2. **eww**
   - Dashboard.
   - Calendario.
   - Census (gauges).
   - Control center.

3. **Extras**
   - Visualizador cava.
   - ranger/zathura integrados.
   - Power menu.

## Estado

- [ ] Dependencias instaladas
- [ ] dwm compilado
- [ ] Config portada
- [ ] Barra funcionando
- [ ] Tema y wallpaper
- [ ] Sesión LightDM
- [ ] eww compilado
- [ ] Widgets eww
- [ ] Pruebas y ajustes
