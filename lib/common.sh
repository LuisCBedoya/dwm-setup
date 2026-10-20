#!/usr/bin/env bash
# Utilidades comunes del instalador. Se carga desde install.sh.
# No ejecutar directamente.

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
else
  C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
TARGET_USER="${TARGET_USER:-}"
TARGET_HOME="${TARGET_HOME:-}"
TARGET_GROUP="${TARGET_GROUP:-}"
TARGET_UID="${TARGET_UID:-}"
TARGET_GID="${TARGET_GID:-}"
LOG_FILE="${LOG_FILE:-}"

section() {
  printf '\n%s==> %s%s\n' "$C_BOLD$C_BLUE" "$*" "$C_RESET"
}

log() {
  printf '%s\n' "$*"
}

info() {
  printf '%s[info]%s %s\n' "$C_BLUE" "$C_RESET" "$*"
}

ok() {
  printf '%s[ ok ]%s %s\n' "$C_GREEN" "$C_RESET" "$*"
}

warn() {
  printf '%s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2
}

error() {
  printf '%s[error]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2
}

die() {
  error "$*"
  if [[ -n "$LOG_FILE" ]]; then
    error "Log: $LOG_FILE"
  fi
  exit 1
}

debug() {
  if [[ "${DWM_DEBUG:-0}" == "1" ]]; then
    printf '[debug] %s\n' "$*" >&2
  fi
}

dry_run() {
  [[ "$DRY_RUN" == "1" ]]
}

cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

print_cmd() {
  printf '[dry-run]'
  printf ' %q' "$@"
  printf '\n'
}

run_root() {
  if dry_run; then
    print_cmd "$@"
    return 0
  fi
  if [[ "$EUID" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

run_user() {
  if dry_run; then
    print_cmd "$@"
    return 0
  fi
  local env_args=(
    "HOME=$TARGET_HOME"
    "USER=$TARGET_USER"
    "LOGNAME=$TARGET_USER"
    "XDG_CONFIG_HOME=$TARGET_HOME/.config"
    "XDG_CACHE_HOME=$TARGET_HOME/.cache"
    "XDG_DATA_HOME=$TARGET_HOME/.local/share"
    "XDG_STATE_HOME=$TARGET_HOME/.local/state"
    "PATH=$TARGET_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  )
  if [[ "$EUID" -eq 0 ]]; then
    sudo -u "$TARGET_USER" -H env "${env_args[@]}" "$@"
  else
    env "${env_args[@]}" "$@"
  fi
}

confirm() {
  local prompt="$1"
  if [[ "$ASSUME_YES" == "1" ]] || dry_run; then
    return 0
  fi
  local answer
  read -r -p "$prompt [y/N] " answer
  case "$answer" in
    y|Y|yes|YES|sí|si|Sí|Si) return 0 ;;
    *) return 1 ;;
  esac
}

ask_cuda_toolkit() {
  local prompt="¿Instalar CUDA toolkit (nvcc, librerías desarrollo)?"
  if [[ "$ASSUME_YES" == "1" ]] || dry_run; then
    return 1
  fi
  local answer
  read -r -p "$prompt [s/N] " answer
  case "$answer" in
    s|S|sí|si|Sí|Si) return 0 ;;
    *) return 1 ;;
  esac
}

timestamp() {
  date +%Y%m%d-%H%M%S
}

escape_sed() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

# render_template origen destino CLAVE valor [CLAVE valor ...]
render_template() {
  local src="$1" dst="$2"
  shift 2
  [[ -r "$src" ]] || die "No existe la plantilla: $src"
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-render.XXXXXX")
  cp -- "$src" "$tmp"
  while (( $# >= 2 )); do
    local key="$1" value="$2"
    shift 2
    sed -i "s|@${key}@|$(escape_sed "$value")|g" "$tmp"
  done
  mkdir -p -- "$(dirname -- "$dst")"
  mv -- "$tmp" "$dst"
}

# Copia una plantilla renderizada y crea el destino como root.
install_template_root() {
  local mode="$1" src="$2" dst="$3"
  shift 3
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-template.XXXXXX")
  cp -- "$src" "$tmp"
  while (( $# >= 2 )); do
    local key="$1" value="$2"
    shift 2
    sed -i "s|@${key}@|$(escape_sed "$value")|g" "$tmp"
  done
  run_root install -D -m "$mode" "$tmp" "$dst"
  rm -f -- "$tmp"
}

# Copia una plantilla renderizada al home del usuario, con propietario correcto.
install_template_user() {
  local mode="$1" src="$2" dst="$3"
  shift 3
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-template.XXXXXX")
  cp -- "$src" "$tmp"
  while (( $# >= 2 )); do
    local key="$1" value="$2"
    shift 2
    sed -i "s|@${key}@|$(escape_sed "$value")|g" "$tmp"
  done
  run_root install -D -m "$mode" -o "$TARGET_USER" -g "$TARGET_GROUP" "$tmp" "$dst"
  rm -f -- "$tmp"
}

backup_root() {
  local src="$1"
  local dest="$ROOT_BACKUP_DIR/${src#/}"
  [[ -e "$src" ]] || return 0
  if [[ -e "$dest" ]]; then
    return 0
  fi
  run_root mkdir -p -- "$(dirname -- "$dest")"
  run_root cp -a -- "$src" "$dest"
  info "Backup: $src -> $dest"
}

backup_user_path() {
  local src="$1"
  local rel="${src#"$TARGET_HOME"/}"
  local dest="$USER_BACKUP_DIR/$rel"
  [[ -e "$src" ]] || return 0
  if [[ -e "$dest" ]]; then
    return 0
  fi
  run_root mkdir -p -- "$(dirname -- "$dest")"
  run_root cp -a -- "$src" "$dest"
  run_root chown -R "$TARGET_USER:$TARGET_GROUP" -- "$(dirname -- "$dest")" 2>/dev/null || true
  info "Backup: $src -> $dest"
}

make_user_dir() {
  run_root install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "$1"
}

make_root_dir() {
  run_root install -d -m 0755 "$1"
}

init_logging() {
  local log_home="${LOG_HOME:-$HOME}"
  local log_dir="$log_home/.local/state/dwm-setup"
  mkdir -p -- "$log_dir" 2>/dev/null || true
  if [[ "$EUID" -eq 0 && -n "$TARGET_USER" ]]; then
    chown -R "$TARGET_USER:$TARGET_GROUP" "$log_dir" 2>/dev/null || true
  fi
  LOG_FILE="$log_dir/install-$(timestamp).log"
  : >"$LOG_FILE"
  if [[ "$EUID" -eq 0 && -n "$TARGET_USER" ]]; then
    chown "$TARGET_USER:$TARGET_GROUP" "$LOG_FILE" 2>/dev/null || true
  fi
  exec > >(tee -a "$LOG_FILE") 2>&1
  info "Log: $LOG_FILE"
}

show_banner() {
  cat <<'EOF'
  dwm + eww · Debian 13 · fase 1 (escritorio)
  ------------------------------------------------
EOF
}
