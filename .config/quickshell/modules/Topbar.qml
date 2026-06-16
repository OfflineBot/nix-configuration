// Slim top bar, one per monitor, each independently toggleable.
//
// Toggle from a keybind (pass the focused monitor's name):
//   qs ipc call topbar toggle DP-1
//   niri:     qs ipc call topbar toggle (niri msg --json focused-output | jq -r .name)
//   hyprland: qs ipc call topbar toggle (hyprctl monitors -j | jq -r '.[]|select(.focused).name')
//
// Clicking the clock toggles ClockPopup — a separate rounded box below the bar.
//
// Layout: [workspaces]  ……  [date · time]  ……  [tray · wlan · volume · battery]

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    property color backgroundColor: "#11121a"
    property color borderColor: "#d5dde8"
    property color textColor: "#d5dde8"
    property color accentColor: "#8ec07b"
    property real backgroundOpacity: 0.65     // < 1 so niri's blur shows through
    property int barHeight: 30
    // float gap on every side — matches niri's window inset (struts 5 + gaps 5)
    // so the bar lines up with the tiled windows below it
    property int barMargin: 10
    property int barRadius: 14                 // MUST match geometry-corner-radius in niri
    property int barPadding: 12                // uniform inner padding (left/right)

    // per-monitor visibility, default visible
    property var shownScreens: ({})
    function _set(name, val) {
        const next = Object.assign({}, root.shownScreens)
        next[name] = val
        root.shownScreens = next
    }
    function toggle(name) { root._set(name, !(root.shownScreens[name] ?? true)) }
    function show(name)   { root._set(name, true) }
    function hide(name)   { root._set(name, false) }

    // name of the screen whose clock popup is open ("" = none)
    property string clockOpenOn: ""
    function toggleClock(name) {
        root.clockOpenOn = (root.clockOpenOn === name ? "" : name)
    }

    IpcHandler {
        target: "topbar"
        // params MUST be typed — untyped args can't cross Quickshell IPC
        function toggle(name: string) { root.toggle(name) }
        function show(name: string)   { root.show(name) }
        function hide(name: string)   { root.hide(name) }
    }

    WorkspaceProvider { id: workspaceProvider }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            visible: root.shownScreens[modelData.name] ?? true
            color: "transparent"
            implicitHeight: root.barHeight

            // float with margins on every side
            anchors.top: true
            anchors.left: true
            anchors.right: true
            margins.top: root.barMargin
            margins.left: root.barMargin
            margins.right: root.barMargin

            // reserve only the bar's own height — niri adds margins.top on top of
            // the exclusive zone, so including barMargin here double-counts it
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.barHeight

            // distinct layer namespace so a niri `layer-rule` can blur/round the bar
            WlrLayershell.namespace: "quickshell-bar"

            Rectangle {
                anchors.fill: parent
                radius: root.barRadius
                color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g,
                               root.backgroundColor.b, root.backgroundOpacity)
                border.width: 1
                border.color: Qt.rgba(root.borderColor.r, root.borderColor.g,
                                      root.borderColor.b, 0.3)

                // left
                Workspaces {
                    anchors.left: parent.left
                    anchors.leftMargin: root.barPadding
                    anchors.verticalCenter: parent.verticalCenter
                    provider: workspaceProvider
                    screenName: bar.modelData.name
                    textColor: root.textColor
                    activeColor: root.accentColor
                }

                // center
                Clock {
                    anchors.centerIn: parent
                    textColor: root.textColor
                    onClicked: root.toggleClock(bar.modelData.name)
                }

                // right
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: root.barPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Tray {
                        anchors.verticalCenter: parent.verticalCenter
                        textColor: root.textColor
                    }
                    Network {
                        anchors.verticalCenter: parent.verticalCenter
                        screen: bar.modelData
                        barHeight: root.barHeight
                        barMargin: root.barMargin
                        backgroundOpacity: root.backgroundOpacity
                        textColor: root.textColor
                        accentColor: root.accentColor
                        backgroundColor: root.backgroundColor
                        borderColor: root.borderColor
                    }
                    Volume {
                        anchors.verticalCenter: parent.verticalCenter
                        textColor: root.textColor
                    }
                    Battery {
                        anchors.verticalCenter: parent.verticalCenter
                        textColor: root.textColor
                        accentColor: root.accentColor
                    }
                }
            }
        }
    }

    // separate rounded, blurred box that pops up below the bar
    Variants {
        model: Quickshell.screens

        ClockPopup {
            active: root.clockOpenOn === modelData.name
            barHeight: root.barHeight
            barMargin: root.barMargin
            backgroundColor: root.backgroundColor
            borderColor: root.borderColor
            textColor: root.textColor
            backgroundOpacity: root.backgroundOpacity
            onDismissed: root.clockOpenOn = ""
        }
    }
}
