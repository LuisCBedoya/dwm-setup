#!/usr/bin/env bash
# lib/fastfetch.sh — fastfetch con logo propio y módulos del escritorio.

install_fastfetch() {
  local home="$TARGET_HOME"
  local logo

  section "Configurando fastfetch"

  if dry_run; then
    log "[dry-run] instalar ~/.config/fastfetch/config.jsonc"
    log "[dry-run] instalar ~/.config/fastfetch/Neofet-{light,dark}.png"
    return 0
  fi

  make_user_dir "$home/.config/fastfetch"

  for logo in Neofet-light.png Neofet-dark.png; do
    run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
      "$PROJECT_ROOT/assets/fastfetch/$logo" \
      "$home/.config/fastfetch/$logo"
  done

  render_theme_template "$PROJECT_ROOT/templates/fastfetch/config.jsonc.in" \
    "$home/.config/fastfetch/config.jsonc" 0644 "HOME=$TARGET_HOME"

  ok "fastfetch instalado (logos Neofet light/dark)"
}
