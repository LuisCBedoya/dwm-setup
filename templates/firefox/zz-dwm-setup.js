// dwm-setup — OpenH264 para WebRTC (Teams y H.264).
// Debian desactiva OpenH264 en firefox-esr.js; este archivo se carga
// después (zz-) desde /etc/firefox-esr y vuelve a activarlo.
pref("media.gmp-gmpopenh264.enabled", true);
pref("media.peerconnection.video.h264_enabled", true);
