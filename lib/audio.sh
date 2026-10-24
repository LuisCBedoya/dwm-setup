#!/usr/bin/env bash
# lib/audio.sh — quirk específico del ASUS FX504GE / Realtek ALC255.
#
# El micrófono del jack combo de 3.5 mm no aparece con el codec ALC255 de
# este portátil. El fixup alc255-asus lo habilita. Solo se aplica cuando el
# DMI y el codec coinciden; en cualquier otro PC se omite.

HEADSET_QUIRK_MODE="${HEADSET_QUIRK_MODE:-auto}"
HEADSET_QUIRK_MODEL=0
HEADSET_QUIRK_CODEC=0
HEADSET_QUIRK_INSTALLED=0
REBOOT_REQUIRED="${REBOOT_REQUIRED:-0}"

detect_headset_quirk() {
  HEADSET_QUIRK_MODEL=0
  HEADSET_QUIRK_CODEC=0

  if [[ -r /sys/class/dmi/id/product_name ]]; then
    local product
    product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
    case "$product" in
      *FX504GE*|*FX504*) HEADSET_QUIRK_MODEL=1 ;;
    esac
  fi

  if grep -qs -m1 '^Codec: Realtek ALC255' /proc/asound/card*/codec#* 2>/dev/null; then
    HEADSET_QUIRK_CODEC=1
  fi
}

install_headset_quirk() {
  detect_headset_quirk

  if [[ "$HEADSET_QUIRK_MODE" == "no" ]]; then
    info "Quirk ALC255 omitido por --no-headset-quirk"
    return 0
  fi

  if [[ "$HEADSET_QUIRK_MODEL" -ne 1 ]]; then
    if [[ "$HEADSET_QUIRK_MODE" != "yes" ]]; then
      info "Quirk ALC255 no aplicable: no es un ASUS FX504 detectado"
      return 0
    fi
    warn "Forzando quirk ALC255 en un modelo no detectado"
  fi

  if [[ "$HEADSET_QUIRK_CODEC" -ne 1 && "$HEADSET_QUIRK_MODE" != "yes" ]]; then
    info "Quirk ALC255 no aplicable: no se detectó el códec ALC255"
    return 0
  fi

  if [[ "$HEADSET_QUIRK_MODEL" -eq 1 && "$HEADSET_QUIRK_CODEC" -eq 1 ]]; then
    info "Detectado ASUS FX504GE + ALC255: quirk de micrófono disponible"
  fi

  if [[ "$HEADSET_QUIRK_MODE" == "auto" && "$ASSUME_YES" != "1" && "$DRY_RUN" != "1" && -t 0 ]]; then
    local answer
    read -r -p "Se detectó ASUS FX504GE/ALC255. ¿Aplicar quirk alc255-asus para el micrófono? [Y/n] " answer || answer=""
    case "$answer" in
      n|N|no|NO) info "Quirk ALC255 omitido por el usuario"; return 0 ;;
    esac
  fi

  if dry_run; then
    log "[dry-run] instalaría /etc/modprobe.d/alsa-fx504.conf"
    log "[dry-run] ejecutaría update-initramfs -u (requiere reinicio)"
    return 0
  fi

  backup_root "/etc/modprobe.d/alsa-fx504.conf"
  install_template_root 0644 "$PROJECT_ROOT/templates/modprobe/alsa-fx504.conf" \
    "/etc/modprobe.d/alsa-fx504.conf"

  if cmd_exists update-initramfs; then
    if ! run_root update-initramfs -u; then
      warn "update-initramfs falló; el quirk podría no aplicarse hasta regenerar el initramfs"
    fi
  else
    warn "update-initramfs no está disponible; el quirk se aplicará al cargar el módulo en el próximo arranque"
  fi

  HEADSET_QUIRK_INSTALLED=1
  REBOOT_REQUIRED=1
  ok "Quirk ALC255 instalado; reinicia para aplicar el micrófono del jack combo"
}
