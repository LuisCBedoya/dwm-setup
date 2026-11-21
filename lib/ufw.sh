#!/usr/bin/env bash
# lib/ufw.sh — Firewall UFW: helper root, sudoers acotado y reglas base.
#
# El módulo polybar "ufw" consulta el estado con sudo -n; el helper raíz
# solo expone status/enable/disable/reload/rules. La regla 22/tcp se
# asegura antes de activar para no romper SSH.

install_ufw() {
  section "Firewall UFW"

  local helper_src="$PROJECT_ROOT/bin/luc-workspace-ufw"
  local helper_dst="/usr/local/bin/luc-workspace-ufw"
  local sudoers_src="$PROJECT_ROOT/templates/sudoers/luc-workspace-ufw.in"
  local sudoers_dst="/etc/sudoers.d/luc-workspace-ufw"
  local ufw="${LUC_WORKSPACE_UFW_BIN:-/usr/sbin/ufw}"

  if dry_run; then
    log "[dry-run] instalar helper root $helper_dst (0755)"
    log "[dry-run] instalar sudoers $sudoers_dst (0440) con visudo -cf"
    log "[dry-run] configurar UFW: deny incoming, allow outgoing, allow 22/tcp"
    log "[dry-run] activar UFW y habilitarlo al arranque"
    return 0
  fi

  if [[ ! -x "$ufw" ]]; then
    warn "ufw no está instalado; se omite el firewall"
    return 0
  fi

  # Helper raíz: operaciones acotadas sobre UFW.
  backup_root "$helper_dst"
  run_root install -D -m 0755 "$helper_src" "$helper_dst"

  # Sudoers: fragmento con el usuario real. Se valida con visudo en un
  # archivo provisional (nombre con punto: sudoers.d lo ignora hasta que
  # se mueve a su destino definitivo).
  local tmp pending="/etc/sudoers.d/.luc-workspace-ufw.check"
  tmp=$(mktemp "${TMPDIR:-/tmp}/luc-workspace-sudoers.XXXXXX")
  sed "s|@USER@|$TARGET_USER|g" "$sudoers_src" >"$tmp"
  run_root install -D -m 0440 "$tmp" "$pending"
  if ! run_root visudo -cf "$pending" >/dev/null 2>&1; then
    run_root rm -f -- "$pending"
    rm -f -- "$tmp"
    die "Fragmento sudoers de UFW inválido; no se aplicó nada"
  fi

  backup_root "$sudoers_dst"
  run_root mv -f -- "$pending" "$sudoers_dst"
  rm -f -- "$tmp"
  run_root visudo -cf "$sudoers_dst" >/dev/null 2>&1 ||
    die "sudoers final de UFW inválido: $sudoers_dst"
  ok "sudoers de UFW instalado (NOPASSWD solo para $helper_dst)"

  # Reglas base: SSH se mantiene como está (22/tcp).
  backup_root /etc/ufw
  run_root "$ufw" --force default deny incoming
  run_root "$ufw" --force default allow outgoing
  run_root "$ufw" allow 22/tcp
  run_root "$ufw" --force enable
  # ufw --force enable aplica las reglas directamente; asegurar además que
  # la unidad systemd quede activa y habilitada en el arranque.
  run_root systemctl enable --now ufw

  if ! systemctl is-active --quiet ufw 2>/dev/null; then
    die "UFW no quedó activo como servicio (systemctl is-active ufw)"
  fi
  if ! run_root env LC_ALL=C "$ufw" status 2>/dev/null |
       grep -q '^Status: active'; then
    die "UFW no reporta Status: active tras habilitarlo"
  fi
  ok "UFW activo y habilitado (deny incoming, allow outgoing, SSH 22/tcp)"
}
