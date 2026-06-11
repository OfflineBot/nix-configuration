#!/bin/bash

export XDG_CURRENT_DESKTOP=wlroots
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

# make sure the compositor and user services see the variable
dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP

exit 0
