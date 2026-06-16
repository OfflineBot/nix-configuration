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

    // Tray items to hide from the bar, matched on their StatusNotifier Id.
    // The owning app/daemon keeps running and checking — we just don't draw it.
    // (Arch-Update = the CachyOS update notifier, /usr/share/arch-update/lib/tray.py)
    property var hiddenIds: ["Arch-Update"]

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: entry
            required property var modelData

            // QML positioners skip children with visible:false, so no gap is left.
            visible: root.hiddenIds.indexOf(entry.modelData.id) === -1
            implicitWidth: visible ? 18 : 0
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
