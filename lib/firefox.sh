#!/usr/bin/env bash
# lib/firefox.sh — Firefox ESR, OpenH264 y uBlock Origin.

install_firefox() {
  local pref_src="$PROJECT_ROOT/templates/firefox/zz-dwm-setup.js"
  local pref_dst="/etc/firefox-esr/zz-dwm-setup.js"
  local policy_src="$PROJECT_ROOT/templates/firefox/policies.json"
  local policy_dst="/etc/firefox/policies/policies.json"

  section "Configurando Firefox"

  if dry_run; then
    log "[dry-run] install $pref_src -> $pref_dst"
    log "[dry-run] merge $policy_src -> $policy_dst"
    return 0
  fi

  backup_root "$pref_dst"
  install_template_root 0644 "$pref_src" "$pref_dst"
  ok "Firefox: OpenH264 habilitado para WebRTC/Teams"

  backup_root "$policy_dst"
  merge_firefox_policies "$policy_src" "$policy_dst"
  ok "Firefox: uBlock Origin force-installed"
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
