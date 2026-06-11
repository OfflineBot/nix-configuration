#!/usr/bin/env bash

ROFI_CMD="rofi -dmenu -theme ~/.config/rofi/config.rasi -p 'WireGuard'"

# Get all available configs
get_configs() {
    ls /etc/wireguard/*.conf 2>/dev/null | xargs -I{} basename {} .conf
}

# Get active tunnels
get_active() {
    sudo wg show interfaces 2>/dev/null | tr ' ' '\n'
}

# Build menu entries
build_menu() {
    while IFS= read -r conf; do
        if echo "$(get_active)" | grep -q "^${conf}$"; then
            echo " ${conf} (connected)"
        else
            echo "󰌾 ${conf}"
        fi
    done <<< "$(get_configs)"
}

# Show menu
chosen=$(build_menu | rofi -dmenu \
    -theme ~/.config/rofi/config.rasi \
    -p "WireGuard" \
    -mesg "Select tunnel to toggle")

[ -z "$chosen" ] && exit 0

# Extract config name (strip icon and status)
conf=$(echo "$chosen" | sed 's/^[^ ]* //' | sed 's/ (connected)//')

# Toggle
if echo "$(get_active)" | grep -q "^${conf}$"; then
    notify-send "WireGuard" "Disconnecting ${conf}..." -i network-vpn
    sudo wg-quick down "$conf" && notify-send "WireGuard" "Disconnected from ${conf}" -i network-vpn-symbolic
else
    notify-send "WireGuard" "Connecting to ${conf}..." -i network-vpn
    sudo wg-quick up "$conf" && notify-send "WireGuard" "Connected to ${conf}" -i network-vpn-acquiring-symbolic
fi
