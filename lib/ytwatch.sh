#!/usr/bin/env bash
# lib/ytwatch.sh — buscador TUI de YouTube (binario + miniaturas con ueberzugpp).
#
# yt-dlp sigue siendo el motor de búsqueda y mpv el reproductor: ytwatch es
# una capa TUI sobre ellos, así que depende del binario oficial de yt-dlp
# que instala lib/music.sh en ~/.local/bin.

# Se puede omitir el bloque con --no-ytwatch.
INSTALL_YTWATCH="${INSTALL_YTWATCH:-yes}"

# Versiones fijadas para instalaciones reproducibles. Para actualizar en
# una máquina existente: ytwatch-check / ytwatch-update.
YTWATCH_VERSION="v0.1.0"
# SHA-256 del tarball amd64 (checksums.txt de la propia release).
YTWATCH_SHA256="9e8914fc6af09dba7a728e08b0f9c119a075bd8e7471cf54dcb04eab30bd87c3"

UEBERZUGPP_VERSION="2.9.10"
# Build Debian 13 del proyecto (OBS build service, repo home:justkidding).
# Se baja el .deb directo: NO se añade ningún repositorio APT.
UEBERZUGPP_SHA256="6c68dfbc2dc2f4a29376dd9e6a3b10e95e1f26e5a9bf2e37bcd026f8f2002aa3"

YTARCH="amd64"

ytwatch_download_tarball_url() {
  printf 'https://github.com/geovannewashington/ytwatch/releases/download/%s/ytwatch_%s_linux_%s.tar.gz' \
    "$YTWATCH_VERSION" "${YTWATCH_VERSION#v}" "$YTARCH"
}

ueberzugpp_deb_url() {
  printf 'https://download.opensuse.org/repositories/home:/justkidding/Debian_13/amd64/ueberzugpp_%s_%s.deb' \
    "$UEBERZUGPP_VERSION" "$YTARCH"
}

install_ytwatch() {
  if [[ "$INSTALL_YTWATCH" != "yes" ]]; then
    section "Omitiendo ytwatch (--no-ytwatch)"
    return 0
  fi

  if dry_run; then
    section "Configurando ytwatch (buscador TUI de YouTube)"
    log "[dry-run] descargar $(ytwatch_download_tarball_url) (SHA-256 verificado)"
    log "[dry-run] instalar ~/.local/bin/ytwatch 0755 (usuario)"
    log "[dry-run] render ~/.config/ytwatch/config.toml desde templates/ytwatch"
    log "[dry-run] descargar $(ueberzugpp_deb_url) (SHA-256 verificado) y 'sudo dpkg -i'"
    log "[dry-run] si dpkg falla por dependencias: apt-get -y -f install"
    return 0
  fi

  section "Configurando ytwatch (buscador TUI de YouTube)"
  install_ytwatch_binary
  install_ytwatch_config
  install_ueberzugpp
  ok "ytwatch listo: escribe ytwatch en una kitty (audio por defecto)"
  info "Estado y actualizaciones: ytwatch-check · ytwatch-update"
}

# Versión del binario ytwatch en ~/.local/bin (vacía si no está).
ytwatch_installed_version() {
  local bin="$TARGET_HOME/.local/bin/ytwatch"
  [[ -x "$bin" ]] || return 0
  "$bin" --version 2>/dev/null | head -1 | awk '{print $NF}'
}

# Descarga el binario de la release con checksum verificado y lo deja en
# ~/.local/bin/ytwatch (usuario; sin sudo). Sin red queda el binario previo.
install_ytwatch_binary() {
  local home="$TARGET_HOME"
  local dir="$home/.local/bin"
  local bin="$dir/ytwatch"
  local want="${YTWATCH_VERSION#v}"
  local installed

  make_user_dir "$dir"

  installed=$(ytwatch_installed_version)
  if [[ "$installed" == "$want" ]]; then
    info "ytwatch ya instalado: $installed (no se descarga de nuevo)"
    return 0
  fi
  if [[ -n "$installed" ]]; then
    info "ytwatch instalado: $installed; el repo fija $want"
  fi

  if ! cmd_exists curl; then
    warn "curl no está instalado; ytwatch no se puede descargar"
    return 0
  fi

  if ! fetch_ytwatch_tarball; then
    warn "Sin binario nuevo de ytwatch; queda ${installed:-ninguno}"
    return 0
  fi
  installed=$(ytwatch_installed_version)

  if ! "$YT_TMP_DIR/ytwatch" --version >/dev/null 2>&1; then
    warn "El binario descargado no arranca; no se instaló nada"
    rm -rf -- "$YT_TMP_DIR"
    return 0
  fi

  if [[ -n "$installed" ]]; then
    backup_user_path "$bin"
  fi
  run_user install -m 0755 -- "$YT_TMP_DIR/ytwatch" "$bin"
  installed=$(ytwatch_installed_version)

  ok "ytwatch: ${installed:-desconocida} ($bin)"
  info "Para comprobar si hay versión nueva: ytwatch-check"
  rm -rf -- "$YT_TMP_DIR"
}

# Descarga el tarball a un tmpdir y verifica el SHA-256 fijado.
fetch_ytwatch_tarball() {
  local tmpdir
  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/ytwatch.XXXXXX")
  YT_TMP_DIR="$tmpdir"

  if ! run_user curl -fsSL --max-time 180 -o "$tmpdir/tarball.tar.gz" "$(ytwatch_download_tarball_url)"; then
    rm -rf -- "$tmpdir"
    warn "Fallo descargando ytwatch $YTWATCH_VERSION"
    return 1
  fi

  local got
  got=$(sha256sum "$tmpdir/tarball.tar.gz" 2>/dev/null | awk '{print $1}')
  if [[ "$got" != "$YTWATCH_SHA256" ]]; then
    warn "Checksum de ytwatch no coincide (esperado $YTWATCH_SHA256, obtenido ${got:-ninguno}); se descarta"
    rm -rf -- "$tmpdir"
    return 1
  fi

  if ! tar xzf "$tmpdir/tarball.tar.gz" -C "$tmpdir"; then
    warn "El tarball de ytwatch no se pudo extraer"
    rm -rf -- "$tmpdir"
    return 1
  fi
  return 0
}

# Config del usuario: plantilla copiada tal cual (sin placeholders de color:
# el tema "terminal" sigue la paleta viva de kitty que recolorea theme-mode).
install_ytwatch_config() {
  local home="$TARGET_HOME"
  local dst="$home/.config/ytwatch/config.toml"
  backup_user_path "$dst"
  install_template_user 0644 "$PROJECT_ROOT/templates/ytwatch/config.toml.in" "$dst"
  ok "Config: $dst"
}

# Versión del paquete ueberzugpp instalado (vacía si no está).
ueberzugpp_installed_version() {
  dpkg-query -W -f='${Version}' ueberzugpp 2>/dev/null || true
}

# Miniaturas: binario ueberzugpp vía .deb directo del proyecto (sin añadir
# repositorios). dpkg usa el sudo normal del instalador; si faltan
# dependencias, apt-get -f las resuelve de los repos oficiales de Debian 13.
install_ueberzugpp() {
  local installed rc=0 tmp got

  installed=$(ueberzugpp_installed_version)
  if [[ -n "$installed" ]] && dpkg --compare-versions "$installed" ge "$UEBERZUGPP_VERSION"; then
    info "ueberzugpp ya instalado: $installed (no se toca)"
    return 0
  fi
  if [[ -n "$installed" ]]; then
    info "ueberzugpp instalado: $installed; el repo fija $UEBERZUGPP_VERSION"
  fi

  tmp=$(mktemp "${TMPDIR:-/tmp}/ueberzugpp.XXXXXX.deb")
  if ! curl -fsSL --max-time 180 -o "$tmp" "$(ueberzugpp_deb_url)"; then
    warn "No se pudo descargar el .deb de ueberzugpp (ytwatch queda sin miniaturas)"
    warn "Reintenta con: ytwatch-update --ueberzugpp"
    rm -f -- "$tmp"
    return 0
  fi

  got=$(sha256sum "$tmp" 2>/dev/null | awk '{print $1}')
  if [[ "$got" != "$UEBERZUGPP_SHA256" ]]; then
    warn "Checksum de ueberzugpp no coincide (esperado $UEBERZUGPP_SHA256, obtenido ${got:-ninguno}); NO se instala"
    rm -f -- "$tmp"
    return 0
  fi

  # El paquete legado `ueberzug` (Python) es dueño de /usr/bin/ueberzug y
  # choca con el shim que trae ueberzugpp (drop-in). Se retira antes:
  # el shim mantiene el comando para ranger (preview_images_method
  # ueberzug) y en Debian 13 no arrastra dependientes.
  if dpkg-query -W -f='${Status}' ueberzug 2>/dev/null | grep -q 'install ok installed'; then
    info "Retirando ueberzug legado (ueberzugpp instala el shim /usr/bin/ueberzug)"
    run_root env DEBIAN_FRONTEND=noninteractive apt-get -y remove ueberzug ||
      warn "No se pudo retirar ueberzug; dpkg puede fallar por el binario en conflicto"
  fi

  if ! run_root dpkg -i "$tmp"; then
    info "dpkg pidió dependencias; apt-get -f las resuelve"
    run_root env DEBIAN_FRONTEND=noninteractive apt-get -y -f install || rc=1
  fi
  rm -f -- "$tmp"

  installed=$(ueberzugpp_installed_version)
  if [[ "$rc" -eq 0 && "$installed" == "$UEBERZUGPP_VERSION" ]]; then
    ok "ueberzugpp: $installed (miniaturas activas)"
  else
    warn "ueberzugpp no quedó instalado; ytwatch funciona sin miniaturas"
    warn "Revisa el log y reintenta con: ytwatch-update --ueberzugpp"
  fi
}
