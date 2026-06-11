// Left section: the workspaces present on THIS monitor. Minimal pill style.
import QtQuick

Row {
    id: root

    property var provider                 // WorkspaceProvider instance
    property string screenName            // this bar's output name
    property color textColor: "#d5dde8"
    property color activeColor: "#8ec07b"

    spacing: 6

    Repeater {
        model: root.provider
               ? root.provider.workspaces.filter(w => (w.output || "") === root.screenName)
               : []

        delegate: Rectangle {
            id: chip
            required property var modelData

            readonly property bool isFocused: modelData.focused
            readonly property string label:
                (modelData.name && modelData.name.length) ? modelData.name : String(modelData.idx)

            width: Math.max(22, txt.implicitWidth + 14)
            height: 22
            radius: 6
            color: isFocused ? root.activeColor
                   : modelData.active ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
                   : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: txt
                anchors.centerIn: parent
                text: chip.label
                font.pixelSize: 13
                font.family: "FiraCode Nerd Font Mono"
                color: chip.isFocused ? "#11121a" : root.textColor
                opacity: chip.isFocused || chip.modelData.active ? 1.0 : 0.55
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.provider) root.provider.focus(chip.modelData)
            }
        }
    }
}
