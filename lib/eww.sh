#!/usr/bin/env bash
# Compilación e instalación de eww v0.6.0 (X11).

EWW_SRC="$PROJECT_ROOT/src/eww"
EWW_SRC_CACHE="/var/cache/dwm-setup/eww-src"
EWW_BUILD="/var/cache/dwm-setup/eww-build"
EWW_TARGET="/var/cache/dwm-setup/eww-target"
EWW_CARGO_HOME="/var/cache/dwm-setup/cargo"
EWW_BIN="/usr/local/bin/eww"
EWW_VERSION="0.6.0"
# eww v0.6.0 fija time 0.3.34, que no compila con Rust >= 1.80.
EWW_TIME_OLD="0.3.34"
EWW_TIME_FIXED="0.3.35"

build_eww() {
  section "eww"
  local src="$EWW_SRC"
  if [[ ! -f "$src/Cargo.toml" ]]; then
    src="$EWW_SRC_CACHE"
  fi
  if dry_run; then
    log "[dry-run] compilar eww $EWW_VERSION desde $src"
    log "[dry-run] instalar binario en $EWW_BIN"
    return 0
  fi
  if [[ -x "$EWW_BIN" && "${FORCE_REBUILD:-0}" != "1" ]]; then
    if "$EWW_BIN" --version >/dev/null 2>&1; then
      ok "eww ya está instalado en $EWW_BIN (usa --rebuild para recompilar)"
      return 0
    fi
  fi
  if [[ ! -f "$src/Cargo.toml" ]]; then
    info "No hay código local completo de eww; clonando v$EWW_VERSION en $src"
    run_root install -d -m 0755 "$(dirname -- "$src")"
    if [[ -e "$src" ]]; then
      # Solo se elimina la copia de caché controlada por el instalador.
      run_root rm -rf "$src"
    fi
    if ! run_root git clone --depth 1 --branch "v$EWW_VERSION" \
      https://github.com/elkowar/eww "$src"; then
      die "No se pudo clonar eww v$EWW_VERSION. Revisa la conexión y el log."
    fi
  fi
  [[ -f "$src/Cargo.toml" ]] || die "No se encontró el código fuente de eww en $src"
  backup_root "$EWW_BIN"
  run_root rm -rf "$EWW_BUILD" "$EWW_TARGET"
  run_root install -d -m 0755 "$EWW_BUILD" "$EWW_TARGET" "$EWW_CARGO_HOME"
  run_root cp -a "$src/." "$EWW_BUILD/"
  info "Compilando eww (puede tardar varios minutos)..."
  local -a cargo_env=(
    "CARGO_HOME=$EWW_CARGO_HOME"
    "CARGO_TARGET_DIR=$EWW_TARGET"
    "CARGO_NET_GIT_FETCH_WITH_CLI=true"
  )
  # Rust 1.85 (Debian 13) no compila time 0.3.34; se fija la primera
  # versión compatible sin cambiar el resto del lockfile.
  if grep -A2 '^name = "time"$' "$EWW_BUILD/Cargo.lock" 2>/dev/null | grep -q "version = \"$EWW_TIME_OLD\""; then
    info "Ajustando time $EWW_TIME_OLD -> $EWW_TIME_FIXED para Rust de Debian 13"
    if ! run_root env "${cargo_env[@]}" cargo update \
      --manifest-path "$EWW_BUILD/Cargo.toml" \
      -p "time@$EWW_TIME_OLD" --precise "$EWW_TIME_FIXED"; then
      die "No se pudo ajustar la dependencia time de eww. Revisa el log."
    fi
  fi
  if ! run_root env "${cargo_env[@]}" cargo build --manifest-path "$EWW_BUILD/Cargo.toml" \
    --release --locked --no-default-features --features x11; then
    warn "La compilación con --locked falló; reintentando sin --locked"
    if ! run_root env "${cargo_env[@]}" cargo build --manifest-path "$EWW_BUILD/Cargo.toml" \
      --release --no-default-features --features x11; then
      die "Falló la compilación de eww. Revisa el log."
    fi
  fi
  run_root install -D -m 0755 "$EWW_TARGET/release/eww" "$EWW_BIN"
  if ! "$EWW_BIN" --version >/dev/null 2>&1; then
    die "eww se instaló pero no responde a --version"
  fi
  ok "eww instalado: $EWW_BIN"
}
