#!/usr/bin/env bash
# lib/herdr.sh — Herdr TUI: binario fijado y configuración reproducible.
#
# Herdr no está en los repos de Debian: se instala el binario oficial en
# ~/.local/bin (usuario, sin sudo). El config se renderiza desde
# templates/herdr/config.toml.in con el tema activo; theme-mode sigue
# actualizando el tema en caliente.

INSTALL_HERDR="${INSTALL_HERDR:-yes}"

HERDR_VERSION="v0.9.5"
HERDR_SHA256_X86_64="14d9e8bc8b4a9e0118d77c32266f76d461f09b40342eb23752960bd89f59929d"
HERDR_SHA256_AARCH64="17d7536f2da50859523680ef279dffcac8e4a235f4e46fe8da6c2ec44141897c"

herdr_asset() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'herdr-linux-x86_64' ;;
    aarch64|arm64) printf 'herdr-linux-aarch64' ;;
    *) return 1 ;;
  esac
}

herdr_sha256() {
  case "$(uname -m)" in
    x86_64|amd64) printf '%s' "$HERDR_SHA256_X86_64" ;;
    aarch64|arm64) printf '%s' "$HERDR_SHA256_AARCH64" ;;
    *) return 1 ;;
  esac
}

herdr_download_url() {
  printf 'https://github.com/herdrdev/herdr/releases/download/%s/%s' \
    "$HERDR_VERSION" "$(herdr_asset)"
}

install_herdr() {
  if [[ "$INSTALL_HERDR" != "yes" ]]; then
    section "Omitiendo Herdr (--no-herdr)"
    return 0
  fi

  if dry_run; then
    section "Configurando Herdr (TUI de terminal)"
    log "[dry-run] descargar $(herdr_download_url) (SHA-256 verificado)"
    log "[dry-run] instalar ~/.local/bin/herdr 0755 (usuario, sin sudo)"
    log "[dry-run] renderizar ~/.config/herdr/config.toml desde templates/herdr"
    log "[dry-run] instalar ~/.local/lib/dwm-setup/preview_tag.py (etiqueta de previews)"
    return 0
  fi

  section "Configurando Herdr (TUI de terminal)"
  install_herdr_binary
  install_herdr_config
  install_herdr_preview_tag
  ok "Herdr listo: escribe 'herdr' en una kitty"
}

# Versión del binario en ~/.local/bin (vacía si no está).
herdr_installed_version() {
  local bin="$TARGET_HOME/.local/bin/herdr"
  [[ -x "$bin" ]] || return 0
  "$bin" --version 2>/dev/null | head -1 | awk '{print $NF}'
}

# Instala el binario de la release con el SHA-256 fijado. Sin red queda el
# binario anterior; nunca se retrocede a una versión más vieja.
install_herdr_binary() {
  local home="$TARGET_HOME"
  local dir="$home/.local/bin"
  local bin="$dir/herdr"
  local want="${HERDR_VERSION#v}"
  local installed sha tmp got

  make_user_dir "$dir"

  installed=$(herdr_installed_version)
  if [[ "$installed" == "$want" ]]; then
    info "Herdr ya instalado: $installed (no se descarga de nuevo)"
    return 0
  fi
  if [[ -n "$installed" ]]; then
    if [[ "$(printf '%s\n%s\n' "$installed" "$want" | sort -V | tail -1)" == "$installed" ]]; then
      info "Herdr instalado ($installed) es más nuevo que el fijado ($want); no se toca"
      return 0
    fi
    info "Herdr instalado: $installed; el repo fija $want"
  fi

  if ! cmd_exists curl; then
    warn "curl no está instalado; Herdr no se puede descargar"
    return 0
  fi
  if ! herdr_asset >/dev/null; then
    warn "Arquitectura no soportada para Herdr ($(uname -m))"
    return 0
  fi
  sha=$(herdr_sha256)

  tmp=$(run_user mktemp -d "${TMPDIR:-/tmp}/herdr.XXXXXX") || {
    warn "No se pudo crear el directorio temporal de Herdr"
    return 0
  }

  if ! run_user curl -fsSL --max-time 180 -o "$tmp/herdr" "$(herdr_download_url)"; then
    rm -rf -- "$tmp"
    warn "Fallo descargando Herdr $HERDR_VERSION; queda ${installed:-ninguno}"
    return 0
  fi

  got=$(sha256sum "$tmp/herdr" 2>/dev/null | awk '{print $1}')
  if [[ "$got" != "$sha" ]]; then
    rm -rf -- "$tmp"
    warn "Checksum de Herdr no coincide (esperado $sha, obtenido ${got:-ninguno}); se descarta"
    return 0
  fi

  run_user chmod 0755 "$tmp/herdr" 2>/dev/null || true
  if ! "$tmp/herdr" --version >/dev/null 2>&1; then
    rm -rf -- "$tmp"
    warn "El binario de Herdr no arranca; no se instaló nada"
    return 0
  fi

  if [[ -f "$bin" ]]; then
    backup_user_path "$bin"
  fi
  run_user install -m 0755 -- "$tmp/herdr" "$bin"
  rm -rf -- "$tmp"

  installed=$(herdr_installed_version)
  ok "Herdr: ${installed:-desconocida} ($bin)"
}

# Config de Herdr con los atajos actuales y el tema de la paleta activa.
install_herdr_config() {
  local dir="$TARGET_HOME/.config/herdr"

  make_user_dir "$dir"
  render_theme_template "$PROJECT_ROOT/templates/herdr/config.toml.in" \
    "$dir/config.toml" 0644
  ok "Herdr: config en $dir/config.toml"
}

# Módulo compartido por los wrappers de ueberzug: aprende la base X11 de su
# hijo y etiqueta cada ventana con la pestaña real de Herdr (HERDR_TAB_ID).
install_herdr_preview_tag() {
  local dir="$TARGET_HOME/.local/lib/dwm-setup"
  local src="$PROJECT_ROOT/templates/herdr/preview_tag.py"
  local dst="$dir/preview_tag.py"

  [[ -f "$src" ]] || { warn "Falta $src; se omite el etiquetado de previews"; return 0; }
  make_user_dir "$dir"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    return 0
  fi
  if [[ -f "$dst" ]]; then
    backup_user_path "$dst"
  fi
  run_user install -m 0644 -- "$src" "$dst"
  ok "Herdr: etiquetado de previews en $dst"
}
