#!/usr/bin/env bash
# lib/ranger.sh — ranger, zathura, VLC y previsualizaciones

RANGER_ZATHURA_PLUGIN_VERSION="0.4.6"
RANGER_ZATHURA_PLUGIN_SHA256="2adb306c6fe8101b7f4d54c9ad31dbb0121046513aa0b61b24d09f34c0ffe147"
RANGER_ZATHURA_PLUGIN_URL="https://github.com/pwmt/zathura-pdf-mupdf/archive/refs/tags/${RANGER_ZATHURA_PLUGIN_VERSION}.tar.gz"

install_ranger() {
  local home="$TARGET_HOME"
  local tmp=""
  local plugin=""

  section "Instalando ranger, zathura y VLC"

  if dry_run; then
    log "[dry-run] instalar configs de ranger en $home/.config/ranger"
    log "[dry-run] compilar zathura-pdf-mupdf ${RANGER_ZATHURA_PLUGIN_VERSION} si falta"
    log "[dry-run] verificar EPUB en zathura"
    return 0
  fi

  make_user_dir "$home/.config/ranger"

  render_theme_template "$PROJECT_ROOT/templates/ranger/rc.conf.in" \
    "$home/.config/ranger/rc.conf" 0644 "HOME=$TARGET_HOME"
  render_theme_template "$PROJECT_ROOT/templates/ranger/rifle.conf.in" \
    "$home/.config/ranger/rifle.conf" 0644 "HOME=$TARGET_HOME"
  render_theme_template "$PROJECT_ROOT/templates/ranger/scope.sh.in" \
    "$home/.config/ranger/scope.sh" 0755 "HOME=$TARGET_HOME"
  render_theme_template "$PROJECT_ROOT/templates/ranger/epub-cover.sh.in" \
    "$home/.config/ranger/epub-cover.sh" 0755 "HOME=$TARGET_HOME"

  plugin=$(find /usr/lib /usr/local/lib -path '*/zathura/*' -name '*pdf-mupdf.so' -print -quit 2>/dev/null || true)
  if [[ -n "$plugin" ]]; then
    info "zathura-pdf-mupdf ya instalado: $plugin"
    ok "ranger instalado"
    return 0
  fi

  command -v meson >/dev/null 2>&1 || die "Falta meson para compilar zathura-pdf-mupdf"
  command -v ninja >/dev/null 2>&1 || die "Falta ninja para compilar zathura-pdf-mupdf"

  tmp=$(mktemp -d) || die "No se pudo crear directorio temporal"
  trap 'if [ -n "${tmp:-}" ]; then run_root rm -rf "$tmp"; fi' EXIT HUP INT TERM

  local tarball="$tmp/zathura-pdf-mupdf-${RANGER_ZATHURA_PLUGIN_VERSION}.tar.gz"
  local srcdir="$tmp/zathura-pdf-mupdf-${RANGER_ZATHURA_PLUGIN_VERSION}"
  local builddir="$tmp/build"

  log "Descargando zathura-pdf-mupdf ${RANGER_ZATHURA_PLUGIN_VERSION}"
  run_root curl -fsSL "$RANGER_ZATHURA_PLUGIN_URL" -o "$tarball"
  printf '%s  %s\n' "$RANGER_ZATHURA_PLUGIN_SHA256" "$tarball" | sha256sum -c - >/dev/null \
    || die "Checksum inválido para zathura-pdf-mupdf"

  run_root tar -xzf "$tarball" -C "$tmp"

  # El plugin 0.4.6 pide MuPDF >= 1.26, pero Debian 13 trae 1.25.1;
  # la API usada es compatible, así que se relaja solo el mínimo.
  run_root sed -i 's/mupdf_required_version_minor = 26/mupdf_required_version_minor = 24/' "$srcdir/meson.build"

  run_root meson setup "$builddir" "$srcdir" \
    --prefix=/usr --buildtype=release -Dpdf=disabled
  run_root ninja -C "$builddir"
  run_root ninja -C "$builddir" install
  run_root ldconfig

  run_root rm -rf "$tmp"
  tmp=""
  trap - EXIT HUP INT TERM

  ok "zathura-pdf-mupdf instalado"
  ok "ranger instalado"
}
