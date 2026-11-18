#!/usr/bin/env python3
# preview_tag.py — etiqueta las ventanas de ueberzug con su pestaña de Herdr.
#
# ueberzugpp crea una ventana X11 por cada `add`; todas las ventanas de un
# mismo proceso comparten la base de recurso de su conexión X11. El wrapper
# conoce HERDR_TAB_ID, así que observa las ventanas nuevas, aprende la base
# de su hijo y las marca con _DWM_SETUP_TAB. De este modo, una preview que
# se actualiza en una pestaña oculta no se atribuye a la pestaña con foco.
#
# WINDOWID (la kitty de Herdr, que el wrapper localiza con `kitty @ ls`)
# limita la observación a las ventanas hijas de esa kitty: una preview de
# otra kitty no puede contaminar la base que se aprende.

import glob
import json
import os
import re
import shutil
import subprocess
import threading

PROP = "_DWM_SETUP_TAB"
FALLBACK = "_DWM_SETUP_TAB_FALLBACK"
KITTY = shutil.which("kitty")
XWININFO = shutil.which("xwininfo")
XPROP = shutil.which("xprop")
WINDOW_RE = re.compile(
    r'^(\s*)(0x[0-9a-fA-F]+)\s+(?:"([^"]*)"|(\(has no name\))):'
)
BASE_MASK = ~0xFFFFF


def _run(cmd, timeout=2, env=None):
    try:
        return subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            timeout=timeout, text=True, env=env,
        ).stdout
    except Exception:
        return ""


def _kitty_sockets():
    paths = []
    listen = os.environ.get("KITTY_LISTEN_ON", "")
    if listen.startswith("unix:"):
        paths.append(listen[5:])
    paths.extend(glob.glob("/tmp/kitty-*"))
    paths.extend(glob.glob(os.path.expanduser("~/.cache/kitty-*")))
    return sorted(set(paths))


def _window_runs_herdr(os_window):
    for tab in os_window.get("tabs", []) or []:
        for win in tab.get("windows", []) or []:
            for proc in win.get("foreground_processes", []) or []:
                cmdline = proc.get("cmdline") or []
                if isinstance(cmdline, str):
                    cmdline = [cmdline]
                for part in cmdline:
                    if os.path.basename(str(part)) == "herdr":
                        return True
    return False


def herdr_kitty_windows():
    """IDs X11 (enteros) de las ventanas kitty que ejecutan Herdr."""
    if not KITTY:
        return set()
    result = set()
    for sock in _kitty_sockets():
        if not os.path.exists(sock):
            continue
        env = dict(os.environ, KITTY_LISTEN_ON="unix:" + sock)
        try:
            data = json.loads(_run([KITTY, "@", "ls"], timeout=3, env=env))
        except Exception:
            continue
        if not isinstance(data, list):
            continue
        for os_window in data:
            if not isinstance(os_window, dict) or not _window_runs_herdr(os_window):
                continue
            try:
                result.add(int(os_window["platform_window_id"]))
            except (KeyError, TypeError, ValueError):
                continue
    return result


def herdr_kitty_window():
    """Ventana X11 (decimal) de la kitty de Herdr, o None."""
    windows = herdr_kitty_windows()
    return str(min(windows)) if windows else None


def _window_id(value):
    if value is None:
        return None
    try:
        return hex(int(str(value), 0)).lower()
    except (TypeError, ValueError):
        return None


def _tree():
    """Ventanas de xwininfo -root -tree: {id: {parent, name}}."""
    windows = {}
    stack = []
    for line in _run([XWININFO, "-root", "-tree"]).splitlines():
        match = WINDOW_RE.match(line)
        if not match:
            continue
        indent = len(match.group(1))
        win = match.group(2).lower()
        name = match.group(3) if match.group(3) is not None else ""
        while stack and stack[-1][0] >= indent:
            stack.pop()
        windows[win] = {
            "parent": stack[-1][1] if stack else None,
            "name": name,
        }
        stack.append((indent, win))
    return windows


def _descends_from(win, root, windows):
    parent = windows.get(win, {}).get("parent")
    while parent:
        if parent == root:
            return True
        parent = windows.get(parent, {}).get("parent")
    return False


def _overlay_ids(window=None):
    windows = _tree()
    root = _window_id(window)
    return {
        win for win, info in windows.items()
        if info["name"] in ("ueberzugpp", "ueberzug")
        and (root is None or _descends_from(win, root, windows))
    }


def _base(win):
    return int(win, 16) & BASE_MASK


def _props(win):
    out = _run([XPROP, "-id", win, PROP, FALLBACK])
    tag = re.search(rf'{PROP}\(STRING\) = "(.*)"', out)
    fallback = re.search(rf'{FALLBACK}\(STRING\) = "(.*)"', out)
    return (tag.group(1) if tag else None, bool(fallback))


def _set_tag(win, tab):
    _run([XPROP, "-id", win, "-f", PROP, "8s", "-set", PROP, tab])


def _clear_fallback(win):
    _run([XPROP, "-id", win, "-remove", FALLBACK])


class Tagger(threading.Thread):
    """Marca con `tab` las ventanas X11 del ueberzug que lanza el wrapper.

    Se arranca antes que el hijo para que la foto inicial de ventanas no
    incluya las suyas. La base de recurso se aprende de la primera ventana
    nueva; si aparecen varias a la vez se elige la del ID más bajo. Una
    etiqueta puesta por otro wrapper (sin el marcador de fallback) no se
    toca.
    """

    def __init__(self, tab, window=None, interval=0.1):
        super().__init__(daemon=True)
        self.tab = tab
        self.window = window
        self.interval = interval
        self.base = None
        self.known = _overlay_ids(self.window)
        self._stop = threading.Event()

    def stop(self):
        self._stop.set()

    def run(self):
        if not XWININFO or not XPROP or not self.tab:
            return
        while not self._stop.is_set():
            current = _overlay_ids(self.window)
            new = current - self.known
            if self.base is None and new:
                self.base = _base(min(new, key=lambda w: int(w, 16)))
            if self.base is not None:
                for win in current:
                    if _base(win) != self.base:
                        continue
                    tag, fallback = _props(win)
                    if tag is None or fallback:
                        _set_tag(win, self.tab)
                        if fallback:
                            _clear_fallback(win)
            self.known = current
            self._stop.wait(self.interval)


def start(tab, window=None, interval=0.1):
    """Arranca un Tagger para `tab`; None si faltan herramientas o pestaña."""
    if not tab or not XWININFO or not XPROP:
        return None
    tagger = Tagger(tab, window=window, interval=interval)
    tagger.start()
    return tagger
