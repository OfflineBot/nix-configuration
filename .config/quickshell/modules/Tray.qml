// Right section: active background apps via the StatusNotifier system tray.
// Left click  = activate (Discord etc. raises its window / toggles).
// Right click = the app's own context menu action (secondary activate).
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Row {
    id: root
    property color textColor: "#d5dde8"
    spacing: 10

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: entry
            required property var modelData

            implicitWidth: 18
            implicitHeight: 18
            anchors.verticalCenter: parent.verticalCenter
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) entry.modelData.activate()
                else entry.modelData.secondaryActivate()
            }

            IconImage {
                anchors.fill: parent
                source: entry.modelData.icon
                opacity: entry.containsMouse ? 1.0 : 0.85
            }
        }
    }
}
