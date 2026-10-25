#!/usr/bin/env bash
# lib/zsh.sh — Instalación de zsh, Oh My Zsh y lsd

install_zsh() {
  local home="$TARGET_HOME"

  section "Instalando zsh, Oh My Zsh y lsd"

  if dry_run; then
    log "[dry-run] instalar Oh My Zsh en $home/.oh-my-zsh si no existe"
    log "[dry-run] renderizar $home/.zshrc"
    log "[dry-run] instalar $home/.config/lsd/{config.yml,icons.yaml}"
    log "[dry-run] chsh -s /usr/bin/zsh $TARGET_USER"
    return 0
  fi

  if [ ! -d "$home/.oh-my-zsh" ]; then
    run_user git clone --depth=1 \
      https://github.com/ohmyzsh/ohmyzsh.git "$home/.oh-my-zsh"
  elif [ ! -f "$home/.oh-my-zsh/oh-my-zsh.sh" ]; then
    die "Existe $home/.oh-my-zsh pero está incompleto; revísalo antes de continuar"
  fi

  make_user_dir "$home/.config/lsd"

  render_theme_template "$PROJECT_ROOT/templates/zsh/zshrc.in" \
    "$home/.zshrc" 0644 "HOME=$TARGET_HOME"

  render_theme_template "$PROJECT_ROOT/templates/lsd/config.yml" \
    "$home/.config/lsd/config.yml" 0644

  render_theme_template "$PROJECT_ROOT/templates/lsd/icons.yaml" \
    "$home/.config/lsd/icons.yaml" 0644

  if command -v chsh >/dev/null 2>&1; then
    run_root chsh -s /usr/bin/zsh "$TARGET_USER"
  else
    die "No se encontró chsh; no se pudo cambiar la shell de $TARGET_USER"
  fi

  ok "zsh, Oh My Zsh y lsd instalados"
}
