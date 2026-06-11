// Right section: battery level via UPower. Hidden on desktops (no battery).
import Quickshell.Services.UPower
import QtQuick

Row {
    id: root
    property color textColor: "#d5dde8"
    property color accentColor: "#8ec07b"
    property color warnColor: "#fb4833"

    spacing: 4
    visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery

    // Quickshell's UPower percentage is a fraction (0.0–1.0); some builds use
    // 0–100. Normalize: anything <= 1 is treated as a fraction.
    readonly property real _raw: UPower.displayDevice ? UPower.displayDevice.percentage : 0
    readonly property real pct: _raw <= 1.0 ? _raw * 100 : _raw
    readonly property bool charging:
        UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging

    function icon(p, ch) {
        if (ch) return "󰂄"
        if (p >= 90) return "󰁹"
        if (p >= 60) return "󰂁"
        if (p >= 35) return "󰁾"
        if (p >= 15) return "󰁻"
        return "󰂎"
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon(root.pct, root.charging)
        font.family: "MesloLGS Nerd Font Mono"
        font.pixelSize: 16
        color: (!root.charging && root.pct <= 15) ? root.warnColor
               : root.charging ? root.accentColor : root.textColor
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.pct) + "%"
        font.family: "FiraCode Nerd Font Mono"
        font.pixelSize: 13
        color: root.textColor
        opacity: 0.85
    }
}
