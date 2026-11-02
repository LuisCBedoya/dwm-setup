#!/usr/bin/env bash
# lib/fastfetch.sh — fastfetch con logo propio y módulos del escritorio.

install_fastfetch() {
  local home="$TARGET_HOME"

  section "Configurando fastfetch"

  if dry_run; then
    log "[dry-run] instalar ~/.config/fastfetch/config.jsonc"
    log "[dry-run] instalar ~/.config/fastfetch/Neofet.png"
    return 0
  fi

  make_user_dir "$home/.config/fastfetch"

  run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$PROJECT_ROOT/assets/fastfetch/Neofet.png" \
    "$home/.config/fastfetch/Neofet.png"

  render_theme_template "$PROJECT_ROOT/templates/fastfetch/config.jsonc.in" \
    "$home/.config/fastfetch/config.jsonc" 0644 "HOME=$TARGET_HOME"

  ok "fastfetch instalado (logo Neofet.png)"
}
