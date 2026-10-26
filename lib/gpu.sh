#!/usr/bin/env bash
# lib/gpu.sh — configuración Xorg/i915 según el hardware detectado

install_gpu_configs() {
  local connected=""
  local edp=0
  local changed_modprobe=0
  local i915_opts="enable_fbc=0"
  local d

  section "Configuración gráfica"

  for d in /sys/class/drm/card*-*; do
    [[ -r "$d/status" ]] || continue
    [[ "$(cat "$d/status" 2>/dev/null)" == "connected" ]] || continue
    connected+="${connected:+ }$(basename "$d")"
    case "$(basename "$d")" in
      *eDP*|*LVDS*) edp=1 ;;
    esac
  done

  if [[ "$HAS_INTEL" -eq 1 ]]; then
    info "Intel detectada; perfil recomendado: modesetting + glamor + DRI3"
  fi
  if [[ "$HAS_NVIDIA" -eq 1 ]]; then
    info "NVIDIA detectada; se mantiene como PRIME/offload, no como GPU primaria"
  fi
  [[ -n "$connected" ]] && info "Salidas conectadas: $connected"

  if [[ "$HAS_INTEL" -eq 0 ]]; then
    if [[ "$INTEL_GLITCH" -eq 1 ]]; then
      warn "--intel-glitch no se aplica: no se detectó GPU Intel"
    fi
    if [[ "$HAS_NVIDIA" -eq 1 ]]; then
      info "No se escribe configuración Xorg NVIDIA primaria; requiere un perfil específico"
    else
      info "No se detectó una GPU Intel/NVIDIA compatible; no se escribe configuración"
    fi
    return 0
  fi

  if dry_run; then
    log "[dry-run] escribir /etc/X11/xorg.conf.d/20-modesetting.conf"
    if [[ "$INTEL_GLITCH" -eq 1 ]]; then
      log "[dry-run] escribir /etc/modprobe.d/dwm-setup-i915.conf ($i915_opts)"
    fi
    if [[ "$HAS_NVIDIA" -eq 1 ]]; then
      log "[dry-run] escribir /etc/modprobe.d/dwm-setup-nvidia.conf"
    fi
    return 0
  fi

  run_root install -D -m 0644 \
    "$PROJECT_ROOT/templates/xorg/20-modesetting.conf.in" \
    /etc/X11/xorg.conf.d/20-modesetting.conf
  ok "Xorg Intel: /etc/X11/xorg.conf.d/20-modesetting.conf"

  if [[ "$INTEL_GLITCH" -eq 1 ]]; then
    if [[ "$edp" -eq 1 ]]; then
      i915_opts="$i915_opts enable_psr=0"
      printf '# Mitiga parpadeos/corrupción de Intel en X11.\noptions i915 %s\n' "$i915_opts" |
        run_root install -D -m 0644 /dev/stdin /etc/modprobe.d/dwm-setup-i915.conf
    else
      run_root install -D -m 0644 \
        "$PROJECT_ROOT/templates/modprobe/i915.conf" \
        /etc/modprobe.d/dwm-setup-i915.conf
    fi
    changed_modprobe=1
    ok "i915: $i915_opts"
  fi

  if [[ "$HAS_NVIDIA" -eq 1 ]]; then
    run_root install -D -m 0644 \
      "$PROJECT_ROOT/templates/modprobe/nvidia.conf" \
      /etc/modprobe.d/dwm-setup-nvidia.conf
    changed_modprobe=1
    ok "NVIDIA: nvidia_drm.modeset=1 (PRIME/offload)"
  fi

  if [[ "$changed_modprobe" -eq 1 ]]; then
    run_root update-initramfs -u
    info "Reinicia para aplicar los parámetros del kernel"
  fi
}
