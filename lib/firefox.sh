#!/usr/bin/env bash
# lib/firefox.sh — Firefox ESR, OpenH264, uBlock Origin y tema del perfil.

install_firefox() {
  local pref_src="$PROJECT_ROOT/templates/firefox/zz-dwm-setup.js"
  local pref_dst="/etc/firefox-esr/zz-dwm-setup.js"
  local policy_src="$PROJECT_ROOT/templates/firefox/policies.json"
  local policy_dst="/etc/firefox/policies/policies.json"

  section "Configurando Firefox"

  if dry_run; then
    log "[dry-run] install $pref_src -> $pref_dst"
    log "[dry-run] merge $policy_src -> $policy_dst"
    log "[dry-run] instalar userChrome.css y user.js en el perfil de Firefox"
    log "[dry-run] generar ~/.config/dwm-setup/surfingkeys.js (si falta)"
    return 0
  fi

  backup_root "$pref_dst"
  install_template_root 0644 "$pref_src" "$pref_dst"
  ok "Firefox: OpenH264 habilitado para WebRTC/Teams"

  backup_root "$policy_dst"
  merge_firefox_policies "$policy_src" "$policy_dst"
  ok "Firefox: uBlock Origin force-installed"

  install_firefox_theme
  install_surfingkeys_config
}

# Devuelve la ruta del perfil de Firefox que usa de verdad la instalación.
# Orden: installs.ini → profiles.ini [Install*] → [Profile*] Default=1 →
# el *.default-esr / *.default* más reciente. `[Profile*] Default=1` no basta:
# puede apuntar a un perfil legacy distinto del que abre Firefox.
detect_firefox_profile() {
  local home="${1:-$TARGET_HOME}"
  local base ini installs path pattern

  for base in "$home/.config/mozilla/firefox" "$home/.mozilla/firefox"; do
    [[ -d "$base" ]] || continue

    # 1) installs.ini: perfil asociado a esta instalación.
    installs="$base/installs.ini"
    if [[ -f "$installs" ]]; then
      path=$(awk -F= '/^Default=/ { gsub(/\r$/, "", $2); print $2; exit }' "$installs")
      if [[ -n "$path" && -d "$base/$path" ]]; then
        printf '%s\n' "$base/$path"
        return 0
      fi
    fi

    ini="$base/profiles.ini"
    if [[ -f "$ini" ]]; then
      # 2) [Install...] Default=...
      path=$(awk -F= '
        /^\[/       { sec = $0 }
        /^Default=/ { if (sec ~ /^\[Install/) { gsub(/\r$/, "", $2); print $2; exit } }
      ' "$ini")
      if [[ -n "$path" && -d "$base/$path" ]]; then
        printf '%s\n' "$base/$path"
        return 0
      fi

      # 3) [Profile...] con Default=1
      path=$(awk -F= '
        /^\[Profile/ { rel="1"; p="" }
        /^Path=/      { p=$2 }
        /^IsRelative=/ { rel=$2 }
        /^Default=1/  { if (p != "") { gsub(/\r$/, "", p); print (rel == "0" ? p : "'"$base"'/" p); exit } }
      ' "$ini")
      if [[ -n "$path" && -d "$path" ]]; then
        printf '%s\n' "$path"
        return 0
      fi
    fi

    # 4) El perfil más reciente, prefiriendo ESR.
    for pattern in '*.default-esr' '*.default*'; do
      path=$(find "$base" -maxdepth 1 -type d -name "$pattern" -printf '%T@ %p\n' 2>/dev/null |
        sort -nr | head -1 | cut -d' ' -f2-)
      if [[ -n "$path" && -d "$path" ]]; then
        printf '%s\n' "$path"
        return 0
      fi
    done
  done

  return 1
}

# Instala userChrome.css y user.js del modo activo en el perfil.
install_firefox_theme() {
  local home="$TARGET_HOME"
  local profile

  if ! profile=$(detect_firefox_profile "$home"); then
    warn "No se encontró un perfil de Firefox; el tema se aplicará al abrir Firefox por primera vez"
    info "Después de abrir Firefox, ejecuta: theme-mode $( [[ "$THEME_NAME" == "latte" ]] && echo light || echo dark )"
    return 0
  fi

  make_user_dir "$profile/chrome"
  render_theme_template "$PROJECT_ROOT/templates/firefox/userChrome.css.in" \
    "$profile/chrome/userChrome.css" 0644
  render_theme_template "$PROJECT_ROOT/templates/firefox/user.js.in" \
    "$profile/user.js" 0644

  run_root chown -R "$TARGET_USER:$TARGET_GROUP" "$profile/chrome" "$profile/user.js" 2>/dev/null || true
  ok "Firefox: tema del perfil instalado ($(basename "$profile"))"
}

# Lee una paleta en un subshell y emite sus colores como KEY=VALUE.
palette_css_values() {
  local theme="$1"

  (
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/templates/colors/base.sh"
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/templates/colors/palette-$theme.sh"
    printf '%s\n' \
      "BG=$COLOR_BG" \
      "BG_DEEP=$COLOR_BG_DEEP" \
      "SURFACE0=$COLOR_BG_ELEV" \
      "SURFACE1=$COLOR_BG_HOVER" \
      "BORDER=$COLOR_BORDER" \
      "FG=$COLOR_FG" \
      "MUTED=$COLOR_FG_MUTED" \
      "ACCENT=$COLOR_ACCENT" \
      "BLUE=$COLOR_BLUE" \
      "TEAL=$COLOR_CYAN" \
      "RED=$COLOR_RED" \
      "PEACH=$COLOR_ORANGE" \
      "GREEN=$COLOR_GREEN"
  )
}

# Bloque CSS de SurfingKeys con los dos modos. El tema usa
# prefers-color-scheme, así que un solo archivo sirve para dark y light.
build_surfingkeys_theme() {
  local -A dark=() light=()
  local key val

  while IFS='=' read -r key val; do
    [[ -n "$key" ]] && dark["$key"]="$val"
  done < <(palette_css_values mocha-black)

  while IFS='=' read -r key val; do
    [[ -n "$key" ]] && light["$key"]="$val"
  done < <(palette_css_values latte)

  cat <<EOF
.sk_theme, #sk_status, #sk_find {
  --sk-bg: ${dark[BG]:-};
  --sk-bg-deep: ${dark[BG_DEEP]:-};
  --sk-surface: ${dark[SURFACE0]:-};
  --sk-surface-1: ${dark[SURFACE1]:-};
  --sk-border: ${dark[BORDER]:-};
  --sk-fg: ${dark[FG]:-};
  --sk-muted: ${dark[MUTED]:-};
  --sk-accent: ${dark[ACCENT]:-};
  --sk-blue: ${dark[BLUE]:-};
  --sk-teal: ${dark[TEAL]:-};
  --sk-red: ${dark[RED]:-};
  --sk-peach: ${dark[PEACH]:-};
  --sk-green: ${dark[GREEN]:-};
}

@media (prefers-color-scheme: light) {
  .sk_theme, #sk_status, #sk_find {
    --sk-bg: ${light[BG]:-};
    --sk-bg-deep: ${light[BG_DEEP]:-};
    --sk-surface: ${light[SURFACE0]:-};
    --sk-surface-1: ${light[SURFACE1]:-};
    --sk-border: ${light[BORDER]:-};
    --sk-fg: ${light[FG]:-};
    --sk-muted: ${light[MUTED]:-};
    --sk-accent: ${light[ACCENT]:-};
    --sk-blue: ${light[BLUE]:-};
    --sk-teal: ${light[TEAL]:-};
    --sk-red: ${light[RED]:-};
    --sk-peach: ${light[PEACH]:-};
    --sk-green: ${light[GREEN]:-};
  }
}
EOF
}

# Genera la configuración de SurfingKeys en ~/.config/dwm-setup.
# No la pisa si ya existe: es el archivo que el usuario edita.
install_surfingkeys_config() {
  local home="$TARGET_HOME"
  local target="$home/.config/dwm-setup/surfingkeys.js"
  local sk_theme

  if [[ -f "$target" ]]; then
    info "SurfingKeys: se conserva $target"
    return 0
  fi

  sk_theme=$(build_surfingkeys_theme)
  make_user_dir "$home/.config/dwm-setup"
  render_theme_template "$PROJECT_ROOT/templates/firefox/surfingkeys.js.in" \
    "$target" 0644 "FONT=$DWM_FONT" "SK_THEME=$sk_theme"

  ok "SurfingKeys: configuración en $target"
  info "Pégala una vez en SurfingKeys → Ajustes → Advanced mode (no hay botón Import)"
}

# Fusiona la política de uBlock con las políticas existentes, sin borrar
# otras reglas que ya tenga el sistema.
merge_firefox_policies() {
  local src="$1"
  local dst="$2"
  local tmp

  tmp=$(mktemp "${TMPDIR:-/tmp}/dwm-policies.XXXXXX")
  run_root mkdir -p -- "$(dirname -- "$dst")"

  if [[ -f "$dst" ]]; then
    run_root cat -- "$dst" > "$tmp"
  else
    printf '{"policies":{}}\n' > "$tmp"
  fi

  if ! python3 - "$tmp" "$src" <<'PY'
import json
import sys

base_path, src_path = sys.argv[1], sys.argv[2]

try:
    with open(base_path, encoding="utf-8") as fh:
        data = json.load(fh)
except json.JSONDecodeError as exc:
    print(f"JSON inválido en {base_path}: {exc}", file=sys.stderr)
    sys.exit(1)

if not isinstance(data, dict):
    print(f"{base_path} no contiene un objeto JSON", file=sys.stderr)
    sys.exit(1)

with open(src_path, encoding="utf-8") as fh:
    add = json.load(fh)

policies = data.setdefault("policies", {})
if not isinstance(policies, dict):
    print(f"{base_path}: 'policies' no es un objeto", file=sys.stderr)
    sys.exit(1)

ext = policies.setdefault("ExtensionSettings", {})
if not isinstance(ext, dict):
    print(f"{base_path}: 'ExtensionSettings' no es un objeto", file=sys.stderr)
    sys.exit(1)

ext.update(add.get("policies", {}).get("ExtensionSettings", {}))

with open(base_path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY
  then
    rm -f -- "$tmp"
    die "No se pudo fusionar /etc/firefox/policies/policies.json"
  fi

  run_root install -D -m 0644 "$tmp" "$dst"
  rm -f -- "$tmp"
}
