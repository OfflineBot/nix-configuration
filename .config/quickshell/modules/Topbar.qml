// Slim top bar, one per monitor, each independently toggleable.
//
// Toggle from a keybind (pass the focused monitor's name):
//   qs ipc call topbar toggle DP-1
//   niri:     qs ipc call topbar toggle (niri msg --json focused-output | jq -r .name)
//   hyprland: qs ipc call topbar toggle (hyprctl monitors -j | jq -r '.[]|select(.focused).name')
//
// Layout: [workspaces]  ……  [date · time]  ……  [tray · wlan · battery]

import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property color backgroundColor: "#11121a"
    property color borderColor: "#d5dde8"
    property color textColor: "#d5dde8"
    property color accentColor: "#8ec07b"
    property int barHeight: 30

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
            exclusionMode: ExclusionMode.Auto      // reserve space so windows sit below

            anchors.top: true
            anchors.left: true
            anchors.right: true

            Rectangle {
                anchors.fill: parent
                color: root.backgroundColor

                // dezente Unterkante statt vollem Rahmen
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: root.borderColor
                    opacity: 0.25
                }

                // left
                Workspaces {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
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
                }

                // right
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
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
                        textColor: root.textColor
                        accentColor: root.accentColor
                        backgroundColor: root.backgroundColor
                        borderColor: root.borderColor
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
}
