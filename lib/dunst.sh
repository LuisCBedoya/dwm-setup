#!/usr/bin/env bash
# lib/dunst.sh — Instalación de dunst

install_dunst() {
  local home="$TARGET_HOME"

  section "Instalando dunst"

  make_user_dir "$home/.config/dunst"
  make_user_dir "$home/.config/dunst/scripts"
  log "Renderizando dunstrc desde template"
  render_dunst_template "dunst/dunstrc" "$home/.config/dunst/dunstrc"

  render_theme_template "$PROJECT_ROOT/templates/dunst/notification-sound.sh.in" \
    "$home/.config/dunst/scripts/notification-sound.sh" 0755 \
    "HOME=$TARGET_HOME"

  restart_dunst_session
  ok "dunst instalado"
}

# Valor de una variable del entorno de la sesión gráfica (sxhkd/bspwm/polybar).
session_env_value() {
  local var="$1" pid val

  for pid in $(pgrep -u "$TARGET_USER" -x sxhkd 2>/dev/null) \
             $(pgrep -u "$TARGET_USER" -x bspwm 2>/dev/null) \
             $(pgrep -u "$TARGET_USER" -x polybar 2>/dev/null); do
    val=$(tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null |
      sed -n "s/^${var}=//p" | head -1)
    if [[ -n "$val" ]]; then
      printf '%s\n' "$val"
      return 0
    fi
  done
  return 1
}

# Reinicia dunst para que tome la paleta recién renderizada. Mata cualquier
# instancia (incluidos restos de root) y lo arranca como el usuario destino,
# con el entorno de la sesión. Sin sesión gráfica no se toca nada.
restart_dunst_session() {
  dry_run && return 0
  pgrep -x dunst >/dev/null 2>&1 || return 0

  local display bus xauthority runtime
  display=$(session_env_value DISPLAY 2>/dev/null || true)
  if [[ -z "$display" ]]; then
    info "dunst se aplicará al entrar en la sesión (no hay DISPLAY disponible)"
    return 0
  fi
  bus=$(session_env_value DBUS_SESSION_BUS_ADDRESS 2>/dev/null || true)
  xauthority=$(session_env_value XAUTHORITY 2>/dev/null || true)
  runtime=$(session_env_value XDG_RUNTIME_DIR 2>/dev/null || true)

  run_root pkill -x dunst 2>/dev/null || true
  sleep 0.4

  local -a envs=("DISPLAY=$display")
  [[ -n "$bus" ]] && envs+=("DBUS_SESSION_BUS_ADDRESS=$bus")
  [[ -n "$xauthority" ]] && envs+=("XAUTHORITY=$xauthority")
  [[ -n "$runtime" ]] && envs+=("XDG_RUNTIME_DIR=$runtime")

  run_user env "${envs[@]}" setsid dunst </dev/null >/dev/null 2>&1 &
}

render_dunst_template() {
  local template_rel="$1"
  local output="$2"
  local perms="${3:-0644}"
  local template="$PROJECT_ROOT/templates/$template_rel.in"

  if [[ ! -f "$template" ]]; then
    die "Template no encontrado: $template"
  fi

  if dry_run; then
    log "[dry-run] render $template -> $output"
    return 0
  fi

  render_theme_template "$template" "$output" "$perms" \
    "HOME=$TARGET_HOME" \
    "FONT=$DWM_FONT" \
    "FONT_SIZE=$DWM_FONT_SIZE" \
    "KEYMAP=$DWM_KEYMAP" \
    "THEME_NAME=$THEME_NAME"
}
