#!/usr/bin/env bash
# lib/brave.sh — Brave como navegador del escritorio (ADR-113).
# Instala el repo APT oficial, policies de privacidad, atajos nativos y
# genera la config de SurfingKeys (se pega a mano en la extensión).
# Brave usa «Usar GTK» (ADR-115): el tema lo publica xsettingsd y cambia
# en caliente con theme-mode.

install_brave() {
  section "Configurando Brave"

  if dry_run; then
    log "[dry-run] configurar repo APT oficial de Brave"
    log "[dry-run] instalar brave-browser"
    log "[dry-run] escribir /etc/brave/policies/managed/luc-workspace.json"
    log "[dry-run] instalar el helper ~/.local/bin/brave-theme"
    log "[dry-run] escribir atajos en el perfil de Brave"
    log "[dry-run] limpiar la interfaz de Brave (NTP, iconos, verticales)"
    log "[dry-run] activar VA-API en Brave (VaapiVideoDecoder)"
    log "[dry-run] instalar ~/.local/share/luc-workspace/newtab.html y su symlink (NTP del modo)"
    log "[dry-run] generar ~/.config/luc-workspace/surfingkeys.js (si falta)"
    log "[dry-run] purgar firefox-esr y limpiar su configuración"
    return 0
  fi

  install_brave_repo
  run_root env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends brave-browser \
    || die "No se pudo instalar brave-browser"

  install_brave_newtab
  install_brave_policies
  install_brave_theme_helper
  install_brave_shortcuts
  install_brave_minimal
  install_brave_vaapi
  install_surfingkeys_config
  remove_firefox
  ok "Brave configurado (atajos, policies, temas Catppuccin y SurfingKeys pendiente de pegar)"
}

# Repo APT oficial de Brave (autorizado explícitamente por el usuario, regla 8).
install_brave_repo() {
  local keyring=/usr/share/keyrings/brave-browser-archive-keyring.gpg
  local source=/etc/apt/sources.list.d/brave-browser-release.list
  local tmp

  if [[ ! -f "$keyring" ]]; then
    tmp=$(mktemp "${TMPDIR:-/tmp}/brave-keyring.XXXXXX")
    if ! curl -fsSL --max-time 60 \
      "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" \
      -o "$tmp"; then
      rm -f -- "$tmp"
      die "No se pudo descargar la llave del repo de Brave"
    fi
    run_root install -D -m 0644 "$tmp" "$keyring"
    rm -f -- "$tmp"
  fi

  tmp=$(mktemp "${TMPDIR:-/tmp}/brave-source.XXXXXX")
  printf 'deb [signed-by=%s] https://brave-browser-apt-release.s3.brave.com/ stable main\n' \
    "$keyring" >"$tmp"
  run_root install -D -m 0644 "$tmp" "$source"
  rm -f -- "$tmp"

  run_root apt-get update -qq || die "apt update falló tras añadir el repo de Brave"
  ok "Brave: repo APT oficial configurado"
}

# Página de nueva pestaña propia: fondo liso del modo activo, sin buscador
# ni sitios. Se instala en ~/.local/share/luc-workspace/newtab.html (usuario) y
# /usr/share/luc-workspace/newtab.html es un symlink; theme-mode la re-renderiza
# sin sudo al cambiar de modo. Las pestañas ya abiertas necesitan recarga.
install_brave_newtab() {
  local user_target="$TARGET_HOME/.local/share/luc-workspace/newtab.html"
  local link=/usr/share/luc-workspace/newtab.html

  make_user_dir "$(dirname "$user_target")"
  render_theme_template "$PROJECT_ROOT/templates/brave/newtab.html.in" \
    "$user_target" 0644

  run_root install -d -m 0755 "$(dirname "$link")"
  backup_root "$link"
  run_root rm -f -- "$link"
  run_root ln -s -- "$user_target" "$link"
  ok "Brave: página de nueva pestaña en $user_target ($link)"
}

# Policies: telemetría/ads fuera y SurfingKeys forzada. Los dos temas
# Catppuccin quedan normal_installed como opcionales: el escritorio usa
# «Usar GTK» y no depende de los packs de la CWS (ADR-115).
install_brave_policies() {
  local policy=/etc/brave/policies/managed/luc-workspace.json
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/brave-policy.XXXXXX")

  cat >"$tmp" <<'EOF'
{
  "BraveP3AEnabled": false,
  "BraveStatsPingEnabled": false,
  "BraveWebDiscoveryEnabled": false,
  "BraveRewardsDisabled": true,
  "BraveWalletDisabled": true,
  "BraveNewsDisabled": true,
  "BraveTalkDisabled": true,
  "BraveVPNDisabled": true,
  "BraveAIChatEnabled": false,
  "MetricsReportingEnabled": false,
  "UrlKeyedAnonymizedDataCollectionEnabled": false,
  "SearchSuggestEnabled": false,
  "FeedbackSurveysEnabled": false,
  "DomainReliabilityAllowed": false,
  "BookmarkBarEnabled": false,
  "NewTabPageLocation": "file:///usr/share/luc-workspace/newtab.html",
  "ExtensionSettings": {
    "gfbliohnnapiefjpjlpjnehglfpaknnc": {
      "installation_mode": "force_installed",
      "update_url": "https://clients2.google.com/service/update2/crx"
    },
    "bkkmolkhemgaeaeggcmfbghljjjoofoh": {
      "installation_mode": "normal_installed",
      "update_url": "https://clients2.google.com/service/update2/crx"
    },
    "jhjnalhegpceacdhbplhnakmkdliaddd": {
      "installation_mode": "normal_installed",
      "update_url": "https://clients2.google.com/service/update2/crx"
    }
  }
}
EOF

  backup_root "$policy"
  run_root install -D -m 0644 "$tmp" "$policy"
  rm -f -- "$tmp"
  ok "Brave: telemetría desactivada, SurfingKeys forzada y temas Mocha/Latte opcionales"
}

# Helper de usuario que asegura «Usar GTK» en el perfil de Brave.
# No escribe `user_color2`, `color_variant2` ni packs de la CWS: el color
# lo publica xsettingsd y theme-mode lo cambia en caliente.
# No necesita sudo: solo escribe el Preferences del perfil.
install_brave_theme_helper() {
  local helper="$TARGET_HOME/.local/bin/brave-theme"

  make_user_dir "$(dirname "$helper")"
  backup_user_path "$helper"
  run_root install -D -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$PROJECT_ROOT/bin/brave-theme" "$helper"
  ok "Brave: helper brave-theme en $helper"
}

# Aplica «Usar GTK» al perfil. Se llama después de install_user_configs
# para que ~/.config/luc-workspace/mode ya exista (status y validación).
install_brave_theme_state() {
  local helper="$TARGET_HOME/.local/bin/brave-theme"

  if dry_run; then
    log "[dry-run] asegurar «Usar GTK» en el perfil de Brave"
    return 0
  fi

  if [[ ! -x "$helper" ]]; then
    warn "Brave: falta $helper; no se aseguró «Usar GTK»"
    return 0
  fi
  if pgrep -x brave >/dev/null 2>&1; then
    warn "Brave está abierto: «Usar GTK» se aplicará al reiniciarlo"
    return 0
  fi

  if run_user "$helper" apply --quiet; then
    ok "Brave: «Usar GTK» preparado para seguir el tema del escritorio"
  else
    warn "Brave: no se pudo preparar «Usar GTK»; se reintentará al abrir Brave"
  fi
}

# Atajos nativos en brave.accelerators (Brave debe estar cerrado).
install_brave_shortcuts() {
  local profile="$TARGET_HOME/.config/BraveSoftware/Brave-Browser/Default"
  local prefs="$profile/Preferences"

  if pgrep -x brave >/dev/null 2>&1; then
    warn "Brave está abierto: cierra Brave y vuelve a ejecutar para escribir los atajos"
    return 0
  fi

  make_user_dir "$profile"
  python3 - "$prefs" <<'PY'
import json
import os
import sys

path = sys.argv[1]
data = {}
if os.path.isfile(path):
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        data = {}

brave = data.setdefault("brave", {})
acc = brave.setdefault("accelerators", {})

# Ctrl+N/Ctrl+P dejan de ser "ventana nueva"/"imprimir"; Alt+H deja de
# abrir el historial (pasa a ser "panel izquierdo") y Alt+L queda libre.
drop = ("Control+KeyN", "Control+KeyP", "Alt+KeyN", "Alt+KeyH", "Alt+KeyL")
for cid, keys in list(acc.items()):
    if isinstance(keys, list):
        acc[cid] = [k for k in keys if k not in drop]

ours = {
    "34016": ["Control+PageDown", "Control+KeyN"],  # pestaña siguiente
    "34017": ["Control+PageUp", "Control+KeyP"],    # pestaña anterior
    "34015": ["Control+KeyW", "Control+F4", "AppClose", "Alt+KeyQ"],  # cerrar
    "34002": ["Control+KeyR", "F5", "BrowserRefresh", "Alt+KeyO"],    # recargar
    "40010": ["Control+KeyH"],                      # historial (sin Alt+H)
    "34014": ["Control+KeyT", "AppNew", "Alt+KeyK"],  # nueva pestaña
    "34000": ["Alt+Shift+KeyN"],                    # ventana nueva
    "34057": ["Control+Alt+KeyT", "Control+Alt+KeyL"],  # split con actual
    "56325": ["Control+Alt+KeyH"],                  # nueva vista dividida
    "56215": ["Alt+KeyN"],                          # expandir verticales
    "39005": ["Alt+KeyH"],                          # panel anterior (izq.)
    "39004": ["Alt+KeyL"],                          # panel siguiente (der.)
    "35003": [],                                    # imprimir sin Ctrl+P
}
for cid, keys in ours.items():
    cur = acc.get(cid) or []
    for key in keys:
        if key not in cur:
            cur.append(key)
    acc[cid] = cur

with open(path + ".tmp", "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
os.replace(path + ".tmp", path)
PY
  run_root chown "$TARGET_USER:$TARGET_GROUP" "$prefs" 2>/dev/null || true
  ok "Brave: atajos nativos (Ctrl+N/P, Alt+Q/O/K, Alt+H/L paneles)"
}

# Interfaz minimalista: NTP limpia, sin iconos ni barra de marcadores.
# Brave debe estar cerrado (escribe el Preferences del perfil).
install_brave_minimal() {
  local profile="$TARGET_HOME/.config/BraveSoftware/Brave-Browser/Default"
  local prefs="$profile/Preferences"

  if pgrep -x brave >/dev/null 2>&1; then
    warn "Brave está abierto: cierra Brave y vuelve a ejecutar para limpiar la interfaz"
    return 0
  fi

  make_user_dir "$profile"
  python3 - "$prefs" <<'PY'
import json
import os
import sys

path = sys.argv[1]
data = {}
if os.path.isfile(path):
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        data = {}

# Preferencias planas "seccion.clave": se anidan al escribir.
minimal = {
    # Página de nueva pestaña limpia.
    "brave.new_tab_page.hide_all_widgets": True,
    "brave.new_tab_page.show_clock": False,
    "brave.new_tab_page.show_stats": False,
    "brave.new_tab_page.show_brave_news": False,
    "brave.new_tab_page.show_brave_vpn": False,
    "brave.new_tab_page.show_rewards": False,
    "brave.new_tab_page.show_sponsored_sites": False,
    "brave.new_tab_page.show_background_image": False,
    "brave.new_tab_page.show_branded_background_image": False,
    "brave.new_tab_page.custom_background_enabled": False,
    "brave.new_tab_page.show_binance": False,
    "brave.new_tab_page.show_gemini": False,
    "brave.new_tab_page.show_together": False,
    "brave.new_tab_page.shows_options": False,
    "brave.always_show_bookmark_bar_on_ntp": False,
    # Iconos y botones de la barra.
    "brave.show_brave_rewards_button": False,
    "brave.rewards.show_brave_rewards_button_in_location_bar": False,
    "brave.wallet.show_wallet_icon_on_toolbar": False,
    "brave.ai_chat.show_toolbar_button": False,
    "brave.today.should_show_toolbar_button": False,
    "brave.show_bookmarks_button": False,
    "brave.bookmarks.show_all_bookmarks_button": False,
    "brave.show_side_panel_button": False,
    "brave.tabs_search_show": False,
    "brave.show_screenshot_button": False,
    "brave.show_fullscreen_reminder": False,
    "browser.show_home_button": False,
    # Pestañas verticales sobrias.
    "brave.tabs.vertical_tabs_enabled": True,
    "brave.tabs.vertical_tabs_show_scrollbar": False,
    "brave.tabs.vertical_tabs_show_toggle_button": False,
    "brave.tabs.always_hide_tab_close_button": True,
    "brave.tabs.show_horizontal_tab_scroll_buttons": False,
}

for dotted, value in minimal.items():
    node = data
    parts = dotted.split(".")
    for key in parts[:-1]:
        cur = node.get(key)
        if not isinstance(cur, dict):
            cur = {}
            node[key] = cur
        node = cur
    node[parts[-1]] = value

with open(path + ".tmp", "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
os.replace(path + ".tmp", path)
PY
  run_root chown "$TARGET_USER:$TARGET_GROUP" "$prefs" 2>/dev/null || true
  ok "Brave: interfaz minimalista (NTP, iconos y pestañas verticales)"
}

# VA-API por flag de línea de comandos: Brave borra `VaapiVideoDecoder` de
# `Local State` al salir, así que se usa un wrapper y un .desktop propio.
install_brave_vaapi() {
  local wrapper="$TARGET_HOME/.local/bin/brave-browser"
  local sys_desktop=/usr/share/applications/brave-browser.desktop
  local user_desktop="$TARGET_HOME/.local/share/applications/brave-browser.desktop"
  local tmp

  tmp=$(mktemp "${TMPDIR:-/tmp}/brave-wrapper.XXXXXX")
  cat >"$tmp" <<'EOF'
#!/bin/sh
# Wrapper de luc-workspace: asegura «Usar GTK» y VA-API en la iGPU.
if [ -x "$HOME/.local/bin/brave-theme" ]; then
  "$HOME/.local/bin/brave-theme" apply --quiet || :
fi
exec /usr/bin/brave-browser --enable-features=VaapiVideoDecoder "$@"
EOF
  backup_root "$wrapper"
  run_root install -D -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$tmp" "$wrapper"
  rm -f -- "$tmp"

  if [[ -f "$sys_desktop" ]]; then
    make_user_dir "$(dirname "$user_desktop")"
    backup_user_path "$user_desktop"
    tmp=$(mktemp "${TMPDIR:-/tmp}/brave-desktop.XXXXXX")
    sed -E "s#^Exec=/usr/bin/brave-browser(-stable)?#Exec=${wrapper}#" \
      "$sys_desktop" >"$tmp"
    run_root install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
      "$tmp" "$user_desktop"
    rm -f -- "$tmp"
    ok "Brave: VA-API activo (wrapper + .desktop con --enable-features)"
  else
    warn "Sin $sys_desktop: solo el wrapper de VA-API (menú sin aceleración)"
  fi
}

# Config de SurfingKeys (se pega a mano: sin native host no se puede automatizar).
install_surfingkeys_config() {
  local home="$TARGET_HOME"
  local target="$home/.config/luc-workspace/surfingkeys.js"
  local sk_theme

  make_user_dir "$home/.config/luc-workspace"
  if [[ -f "$target" ]]; then
    info "SurfingKeys: se conserva $target"
    return 0
  fi

  sk_theme=$(build_surfingkeys_theme)
  render_theme_template "$PROJECT_ROOT/templates/brave/surfingkeys.js.in" \
    "$target" 0644 "FONT=$LUC_WORKSPACE_FONT" "SK_THEME=$sk_theme"
  ok "SurfingKeys: configuración en $target (pégala en la extensión)"
}

# Retira Firefox del sistema (con backup del perfil de usuario).
remove_firefox() {
  local home="$TARGET_HOME"

  if [[ -d "$home/.config/mozilla" ]]; then
    backup_user_path "$home/.config/mozilla" || true
  fi
  if [[ -d "$home/.mozilla" ]]; then
    backup_user_path "$home/.mozilla" || true
  fi

  run_root apt-get purge -y firefox-esr >/dev/null 2>&1 || true
  run_root rm -rf /etc/firefox /etc/firefox-esr /usr/lib/firefox-esr
  rm -f -- "$home/.config/bspwm/scripts/firefox-sidebar.sh"
  rm -rf -- "$home/.config/mozilla" "$home/.mozilla"
  info "Firefox retirado (backup del perfil en ~/.config-backup/luc-workspace)"
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

# Bloque CSS de SurfingKeys con los dos modos (prefers-color-scheme).
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
:root, .sk_theme, #sk_status, #sk_find {
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
  :root, .sk_theme, #sk_status, #sk_find {
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
