import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property color backgroundColor: "#111214"
    property color borderColor: "#ffffff"
    property color textColor: "#d5dde8"
    property int borderWidth: 1
    property int cornerRadius: 40

    property color logoutHoverColor: "#8ec07b"
    property color poweroffHoverColor: "#fb4833"
    property color rebootHoverColor: "#83a597"

    property bool shown: false

    function toggle() { root.shown = !root.shown }
    function show()   { root.shown = true }
    function hide()   { root.shown = false }

    IpcHandler {
        target: "logout"
        function toggle() { root.toggle() }
        function show()   { root.show() }
        function hide()   { root.hide() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            visible: root.shown
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Row {
                anchors.centerIn: parent
                spacing: 40

                LogoutButton {
                    icon: "󰍃"
                    hoverColor: root.logoutHoverColor
                    iconOffsetX: 10
                    onActivated: Quickshell.execDetached(
                        ["sh", "-c", "hyprctl dispatch exit; niri msg action quit --skip-confirmation; mmsg -s -d quit"]
                    )
                }

                LogoutButton {
                    icon: "󰐥"
                    hoverColor: root.poweroffHoverColor
                    onActivated: Quickshell.execDetached(["systemctl", "poweroff"])
                }

                LogoutButton {
                    icon: "󰁪"
                    hoverColor: root.rebootHoverColor
                    onActivated: Quickshell.execDetached(["systemctl", "reboot"])
                }
            }

            component LogoutButton: Rectangle {
                id: btn
                required property string icon
                required property color hoverColor
                property int iconOffsetX: 0
                property int iconOffsetY: 0
                signal activated()

                width: 240
                height: 240
                radius: hover.containsMouse ? root.cornerRadius * 2 : root.cornerRadius
                color: root.backgroundColor
                border.color: root.borderColor
                border.width: root.borderWidth

                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: btn.iconOffsetX
                    anchors.topMargin: btn.iconOffsetY
                    text: btn.icon
                    font.family: "MesloLGS Nerd Font Mono"
                    font.pixelSize: 160
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: hover.containsMouse ? btn.hoverColor : root.textColor
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        btn.activated()
                        root.hide()
                    }
                }
            }
        }
    }
}
