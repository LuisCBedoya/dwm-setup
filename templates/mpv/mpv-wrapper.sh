#!/bin/sh
# dwm-setup: usa la iGPU Intel para mpv (VA-API + EGL/Mesa) salvo que se
# esté pidiendo la dGPU con prime-run o similar.
case "${__NV_PRIME_RENDER_OFFLOAD:-}${VK_LAYER_NV_optimus:-}${DRI_PRIME:-}${__GLX_VENDOR_LIBRARY_NAME:-}" in
  "")
    if [ -z "${__EGL_VENDOR_LIBRARY_FILENAMES:-}" ]; then
      export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
    fi
    ;;
esac
exec /usr/bin/mpv "$@"
