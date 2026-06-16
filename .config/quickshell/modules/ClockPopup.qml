// Clock popup: a separate rounded box that pops up below the topbar with big
// date/time info. It floats with a gap below the bar (a distinct element, not
// attached to it).
//
// It's its own box-sized layer surface with namespace "quickshell-clockpopup",
// so the matching niri layer-rule blurs it and clips that blur to its rounded
// corners (geometry-corner-radius) — nothing spills past the edges. Translucent
// background so the blur shows through, plus a 1px border all around.
//
// A second, fullscreen, NON-blurred window sits below it only to catch clicks
// outside the box.
//
// One instance per screen (via Variants in Topbar). `active` shows it; clicking
// anywhere outside the box emits dismissed().

import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    required property var modelData

    property color backgroundColor: "#11121a"
    property color borderColor: "#d5dde8"
    property color textColor: "#d5dde8"
    property real backgroundOpacity: 0.65     // match the bar so blur shows through
    property int barHeight: 30
    property int barMargin: 8                  // the bar's float gap
    property bool active: false

    property int boxW: 300
    property int boxH: 150
    property int gap: 8                        // gap between bar and box
    property int radius: 14                    // MUST match geometry-corner-radius in niri

    signal dismissed()

    // ISO-8601 week number
    function isoWeek(d) {
        const date = new Date(d.getFullYear(), d.getMonth(), d.getDate())
        const day = (date.getDay() + 6) % 7
        date.setDate(date.getDate() - day + 3)            // Thursday of this week
        const firstThu = new Date(date.getFullYear(), 0, 4)
        const fday = (firstThu.getDay() + 6) % 7
        firstThu.setDate(firstThu.getDate() - fday + 3)
        return 1 + Math.round((date - firstThu) / (7 * 24 * 3600 * 1000))
    }

    // ---- fullscreen click-catcher (no blur) -------------------------------
    PanelWindow {
        id: dismissWin
        screen: root.modelData
        visible: root.active
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        WlrLayershell.layer: WlrLayer.Top           // below the box (Overlay)
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-clockpopup-catch"   // no blur rule

        anchors.top: true; anchors.bottom: true
        anchors.left: true; anchors.right: true

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    // ---- the box: own window so blur is clipped to its rounded shape -------
    PanelWindow {
        id: boxWin
        screen: root.modelData
        visible: root.active
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        WlrLayershell.layer: WlrLayer.Overlay       // above the catcher
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-clockpopup"   // niri blur + corner clip

        // anchor only to the top edge -> centered horizontally, below the bar
        anchors.top: true
        margins.top: root.barMargin + root.barHeight + root.gap

        implicitWidth: root.boxW
        implicitHeight: root.boxH

        Rectangle {
            id: content
            anchors.fill: parent
            radius: root.radius
            color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g,
                           root.backgroundColor.b, root.backgroundOpacity)
            border.width: 1
            border.color: Qt.rgba(root.borderColor.r, root.borderColor.g,
                                  root.borderColor.b, 0.3)

            // entrance pop — smooth
            opacity: 0
            scale: 0.96
            transformOrigin: Item.Top
            states: State {
                name: "on"; when: root.active
                PropertyChanges { target: content; opacity: 1; scale: 1 }
            }
            transitions: Transition {
                NumberAnimation { properties: "opacity,scale"; duration: 140; easing.type: Easing.OutQuad }
            }

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    id: bigTime
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.textColor
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 56
                }
                Text {
                    id: bigDate
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.textColor
                    opacity: 0.85
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 17
                }
                Text {
                    id: subLine
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.textColor
                    opacity: 0.5
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 12
                }
            }
        }

        // keep content fresh only while open
        Timer {
            interval: 1000
            running: root.active
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                const now = new Date()
                bigTime.text = Qt.formatDateTime(now, "HH:mm")
                bigDate.text = Qt.formatDateTime(now, "dddd, dd MMMM")
                subLine.text = "Week " + root.isoWeek(now) + " · " + Qt.formatDateTime(now, "yyyy")
            }
        }
    }
}
