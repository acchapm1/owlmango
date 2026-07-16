#!/usr/bin/env bash
# owlmango — Mango autostart
# Launched once by Mango (exec-once in config.conf) after the compositor starts.
# Brings up the Wayle shell and supporting daemons.

set -u

have() { command -v "$1" >/dev/null 2>&1; }

# Wallpaper (Wayle can manage this too; swaybg is a lightweight fallback).
if have swaybg && [ -f "$HOME/.config/mango/wallpaper" ]; then
  swaybg -m fill -i "$HOME/.config/mango/wallpaper" &
fi

# Desktop portals (some setups need an explicit nudge under Mango).
if have /usr/lib/xdg-desktop-portal; then
  /usr/lib/xdg-desktop-portal -r &
fi

# Polkit authentication agent.
if have /usr/lib/polkit-kde-authentication-agent-1; then
  /usr/lib/polkit-kde-authentication-agent-1 &
fi

# Clipboard persistence.
if have wl-paste; then
  wl-paste --watch true >/dev/null 2>&1 &
fi

# XWayland bridge for X11 apps.
if have xwayland-satellite; then
  xwayland-satellite &
fi

# Application launcher daemons (walker + elephant backend) for fast startup.
if have elephant; then
  elephant --debug >/dev/null 2>&1 &
fi
if have walker; then
  walker --gapplication-service &
fi

# Idle + lock management.
if have swayidle; then
  swayidle -w &
fi

# Wayle shell — bar, notifications, OSD, device controls, wallpaper.
# Provides the mango-workspaces module (this is the wayle-mango fork).
if have wayle; then
  wayle panel start &
fi

wait
