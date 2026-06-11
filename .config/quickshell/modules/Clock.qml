// Center section: date + time, single line, understated.
import QtQuick

Row {
    id: root
    property color textColor: "#d5dde8"
    spacing: 10

    Text {
        id: dateText
        color: root.textColor
        opacity: 0.6
        font.pixelSize: 13
        font.family: "FiraCode Nerd Font Mono"
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: timeText
        color: root.textColor
        font.pixelSize: 13
        font.family: "FiraCode Nerd Font Mono"
        anchors.verticalCenter: parent.verticalCenter
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            dateText.text = Qt.formatDateTime(now, "ddd dd MMM")
            timeText.text = Qt.formatDateTime(now, "HH:mm")
        }
    }
}
