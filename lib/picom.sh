#!/usr/bin/env bash
# lib/picom.sh — picom (compositor) con config mínima validada en vivo.
#
# Adoptado tras prueba real (2026-11-04): quita el tearing arrastrando y
# haciendo scroll. Solo vsync + damage + fade sutil; SIN sombras, SIN blur
# y SIN transparencias de picom (la barra B translúcida la da su fondo
# #00000000 junto al compositor, no algo que toca picom).

install_picom_config() {
  section "Instalando picom"

  local home="$TARGET_HOME"

  make_user_dir "$home/.config/picom"

  log "Renderizando picom.conf desde template"
  render_theme_template "$PROJECT_ROOT/templates/picom/picom.conf.in" \
    "$home/.config/picom/picom.conf" 0644

  ok "Configuración de picom instalada (fade sutil, sin transparencias)"
}
