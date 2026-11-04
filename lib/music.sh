#!/usr/bin/env bash
# lib/music.sh — streaming de YouTube: yt-play, yt-dlp y teclas multimedia.

# Destino de los scripts de usuario (se puede sobrescribir para pruebas).
MUSIC_BIN_ROOT="${MUSIC_BIN_ROOT:-/usr/local/bin}"

install_music() {
  section "Configurando streaming (YouTube)"

  if dry_run; then
    log "[dry-run] instalar $MUSIC_BIN_ROOT/{yt-play,yt-preview,ytdlp-check,ytdlp-update,ytdlp-rollback,music-ctl}"
    log "[dry-run] descargar yt-dlp oficial en ~/.local/bin/yt-dlp"
    return 0
  fi

  local bin
  for bin in yt-play yt-preview ytdlp-check ytdlp-update ytdlp-rollback music-ctl; do
    run_root install -D -m 0755 "$PROJECT_ROOT/bin/$bin" "$MUSIC_BIN_ROOT/$bin"
  done

  install_ytdlp_binary

  ok "Streaming listo: yt-play, yt-preview, ytdlp-check, ytdlp-update, ytdlp-rollback, music-ctl"
  info "Uso: yt-play [--audio|--video] <url | búsqueda>  ·  teclas multimedia controlan mpv"
}

# Instala el binario oficial de yt-dlp (autoactualizable, sin sudo).
# Si falla la descarga se conserva el paquete de Debian como respaldo.
install_ytdlp_binary() {
  local home="$TARGET_HOME"
  local dir="$home/.local/bin"
  local bin="$dir/yt-dlp"
  local tmp="$dir/yt-dlp.tmp"
  local url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
  local version

  make_user_dir "$dir"

  # Si ya hay un binario que funciona, no se descarga otra vez.
  if [[ -x "$bin" ]] && run_user "$bin" --version >/dev/null 2>&1; then
    version=$(run_user "$bin" --version 2>/dev/null | head -1)
    info "yt-dlp ya instalado: ${version:-desconocida} (no se descarga de nuevo)"
    info "Para actualizarlo: ytdlp-update"
    return 0
  fi

  if ! cmd_exists curl; then
    warn "curl no está instalado; yt-play usará el yt-dlp de Debian y puede fallar"
    return 0
  fi

  if ! run_user curl -fsSL --max-time 180 -o "$tmp" "$url"; then
    warn "No se pudo descargar yt-dlp oficial; yt-play usará el de Debian y puede fallar"
    warn "Con red, ejecuta: ytdlp-update"
    run_user rm -f -- "$tmp" 2>/dev/null || true
    return 0
  fi

  run_user chmod 0755 -- "$tmp"

  if ! run_user "$tmp" --version >/dev/null 2>&1; then
    warn "El yt-dlp descargado no arranca; se conserva el de Debian"
    run_user rm -f -- "$tmp" 2>/dev/null || true
    return 0
  fi

  version=$(run_user "$tmp" --version 2>/dev/null | head -1)

  if [[ -x "$bin" ]]; then
    run_user cp -f -- "$bin" "$bin.bak" 2>/dev/null || true
  fi
  run_user mv -f -- "$tmp" "$bin"
  run_root chown "$TARGET_USER:$TARGET_GROUP" -- "$bin" 2>/dev/null || true
  run_user chmod 0755 -- "$bin"

  ok "yt-dlp oficial: ${version:-desconocida}"
  info "Actualízalo cuando quieras con: ytdlp-update"
}
