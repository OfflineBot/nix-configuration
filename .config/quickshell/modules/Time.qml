import Quickshell
import QtQuick

Variants {
    id: root
    model: Quickshell.screens

    property color textColor: "#d5dde8"

    PanelWindow {
        required property var modelData
        screen: modelData

        color: "transparent"
        implicitWidth: 650
        implicitHeight: 300
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: false

        anchors.right: true
        anchors.bottom: true

        Column {
            anchors.centerIn: parent
            spacing: -20

            Text {
                id: dateText
                color: root.textColor
                font.pixelSize: 80
                horizontalAlignment: Text.AlignRight
            }

            Text {
                id: timeText
                font.family: "FiraCode Nerd Font Mono"
                font.bold: false
                font.pixelSize: 150
                color: root.textColor
                horizontalAlignment: Text.AlignRight
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                dateText.text = Qt.formatDateTime(new Date(), "ddd MMM dd")
                timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
    }
}
