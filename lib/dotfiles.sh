#!/usr/bin/env bash
# lib/dotfiles.sh — Gestión de repo dotfiles externo
# Clona, valida estructura y copia configs a ~/.config/

clone_dotfiles_repo() {
  local url="$1"
  local dest="${2:-/tmp/dotfiles-$(date +%s)}"
  
  log "Clonando dotfiles desde $url..."
  
  if dry_run; then
    log "[dry-run] git clone $url $dest"
    return 0
  fi
  
  git clone --depth 1 "$url" "$dest" 2>&1 | while IFS= read -r line; do
    debug "$line"
  done
  
  if [[ ! -d "$dest/.git" ]]; then
    die "Fallo al clonar repo: $url"
  fi
  
  ok "Repo clonado en $dest"
  echo "$dest"
}

validate_dotfiles_structure() {
  local dotfiles_dir="$1"
  local required_dirs=("bspwm" "sxhkd" "polybar" "picom" "dunst" "rofi" "kitty")
  local missing=()
  local found=()
  
  for d in "${required_dirs[@]}"; do
    if [[ -d "$dotfiles_dir/config/.config/$d" ]]; then
      found+=("$d")
      debug "Encontrado: config/.config/$d"
    else
      missing+=("$d")
      warn "Falta en repo: config/.config/$d"
    fi
  done
  
  if (( ${#found[@]} == 0 )); then
    die "El repo no tiene ninguna de las carpetas requeridas en config/.config/"
  fi
  
  log "Estructura detectada: ${found[*]}"
  if (( ${#missing[@]} > 0 )); then
    warn "Faltantes: ${missing[*]}"
  fi
  
  # Exportar arrays para uso posterior
  DOTFILES_FOUND=("${found[@]}")
  DOTFILES_MISSING=("${missing[@]}")
}

copy_dotfiles_configs() {
  local dotfiles_dir="$1"
  local target_home="$2"
  local missing_dirs=("${!3}")  # arrays passed by name reference
  
  if dry_run; then
    log "[dry-run] Copiando configs desde $dotfiles_dir a $target_home/.config/"
    return 0
  fi
  
  # Copiar carpetas encontradas
  for d in "${DOTFILES_FOUND[@]}"; do
    src="$dotfiles_dir/config/.config/$d"
    dst="$target_home/.config/$d"
    run_root cp -a "$src" "$dst"
    ok "Copiado: $d"
  done
  
  # Para carpetas faltantes, se usarán templates (manejado en install.sh)
  if (( ${#missing_dirs[@]} > 0 )); then
    log "Se usarán templates integrados para: ${missing_dirs[*]}"
  fi
}

prompt_dotfiles_repo() {
  local url=""
  local ans=""
  
  printf "\n"
  info "=== Configuración de dotfiles ==="
  printf "¿Tienes un repo Git (HTTPS) con tus configs?\n"
  printf "Estructura esperada: repo/config/.config/{bspwm,sxhkd,polybar,picom,dunst,rofi,kitty}\n"
  printf "Deja vacío para usar templates integrados (paleta Nord).\n"
  printf "URL: "
  
  if dry_run || [[ -n "${ASSUME_YES:-}" ]]; then
    log "[dry-run/assume-yes] Saltando prompt dotfiles, usando templates"
    echo ""
    return 1
  fi
  
  read -r url
  
  if [[ -z "$url" ]]; then
    info "Sin URL — usando templates integrados"
    return 1
  fi
  
  # Validar formato básico
  if [[ ! "$url" =~ ^https:// ]]; then
    warn "URL debe ser HTTPS. Usando templates integrados."
    return 1
  fi
  
  DOTFILES_URL="$url"
  return 0
}

prompt_missing_configs() {
  local missing=("$@")
  
  if (( ${#missing[@]} == 0 )); then
    return 0
  fi
  
  printf "\n"
  warn "El repo clonado NO tiene las siguientes carpetas:"
  for d in "${missing[@]}"; do
    printf "  - %s\n" "$d"
  done
  printf "\n"
  read -rp "¿Continuar con templates integrados (paleta Nord) para las que faltan? [y/N]: " ans
  
  if [[ "$ans" =~ ^[Ss]$ ]]; then
    return 0
  else
    die "Instalación abortada por el usuario"
  fi
}