import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

Scope {
    id: root

    property color backgroundColor: "#1a1b26"
    property color borderColor: "#d5dde8"
    property color searchBorderColor: "#858d98"
    property color textColor: "#d5dde8"
    property color selectionColor: "#8ec07b"
    property int borderWidth: 1
    property int cornerRadius: 20

    property bool shown: false

    function toggle() { root.shown = !root.shown }
    function show()   { root.shown = true }
    function hide()   { root.shown = false }

    IpcHandler {
        target: "launcher"
        function toggle() { root.toggle() }
        function show()   { root.show() }
        function hide()   { root.hide() }
    }

    PanelWindow {
        id: panel

        visible: root.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        property var results: []
        property int selectedIndex: 0

        function fuzzyScore(q, s) {
            let si = 0, score = 0, run = 0, prev = -2
            for (let qi = 0; qi < q.length; qi++) {
                let found = -1
                for (let k = si; k < s.length; k++) {
                    if (s[k] === q[qi]) { found = k; break }
                }
                if (found === -1) return -1
                if (found === prev + 1) { run++; score += 5 + run }
                else run = 0
                if (found === 0 || " -_.".includes(s[found - 1])) score += 10
                score -= (found - si)
                prev = found
                si = found + 1
            }
            return score
        }

        function score(q, e) {
            const name = (e.name || "").toLowerCase()
            if (name === q) return 10000
            if (name.startsWith(q)) return 9000 - name.length
            const words = name.split(/[\s\-_.]+/)
            for (let i = 0; i < words.length; i++)
                if (words[i].startsWith(q)) return 8000 - name.length
            const idx = name.indexOf(q)
            if (idx >= 0) return 7000 - idx * 5 - name.length
            const f = panel.fuzzyScore(q, name)
            if (f >= 0) return 4000 + f
            const extra = ((e.genericName || "") + " " + (e.comment || "") + " "
                          + ((e.keywords || []).join(" "))).toLowerCase()
            if (extra.includes(q)) return 2000
            return -1
        }

        function updateResults() {
            const q = search.text.toLowerCase().trim()
            const all = DesktopEntries.applications.values
            const scored = []
            for (let i = 0; i < all.length; i++) {
                const e = all[i]
                if (e.noDisplay) continue
                if (q === "") { scored.push({ e: e, s: 0 }); continue }
                const s = panel.score(q, e)
                if (s > -1) scored.push({ e: e, s: s })
            }
            if (q === "")
                scored.sort((a, b) => a.e.name.localeCompare(b.e.name))
            else
                scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            panel.results = scored.map(x => x.e)
            panel.selectedIndex = 0
        }

        function move(delta) {
            if (panel.results.length === 0) return
            panel.selectedIndex = Math.max(0, Math.min(panel.selectedIndex + delta, panel.results.length - 1))
            list.positionViewAtIndex(panel.selectedIndex, ListView.Contain)
        }

        function launchSelected() {
            if (panel.results.length === 0) return
            panel.results[panel.selectedIndex].execute()
            root.hide()
        }

        onVisibleChanged: {
            if (visible) {
                search.text = ""
                updateResults()
                search.forceActiveFocus()
            }
        }

        Component.onCompleted: panel.updateResults()

        Connections {
            target: DesktopEntries.applications
            function onValuesChanged() { panel.updateResults() }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        Rectangle {
            id: box
            anchors.centerIn: parent
            width: 460
            height: 440
            color: root.backgroundColor
            radius: 12
            border.color: root.borderColor
            border.width: root.borderWidth

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8

                TextField {
                    id: search
                    width: parent.width
                    placeholderText: "Search…"
                    placeholderTextColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                    color: root.textColor
                    font.pixelSize: 15
                    padding: 8

                    background: Rectangle {
                        color: "transparent"
                        border.color: root.searchBorderColor
                        border.width: root.borderWidth
                        radius: 8
                    }

                    onTextChanged: panel.updateResults()

                    Keys.onDownPressed:   panel.move(1)
                    Keys.onUpPressed:     panel.move(-1)
                    Keys.onReturnPressed: panel.launchSelected()
                    Keys.onEnterPressed:  panel.launchSelected()
                    Keys.onEscapePressed: root.hide()
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - search.height - parent.spacing
                    clip: true
                    model: panel.results

                    delegate: Rectangle {
                        id: item
                        required property var modelData
                        required property int index

                        width: list.width
                        height: 36
                        radius: 6
                        color: index === panel.selectedIndex ? root.selectionColor : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 8

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 20
                                source: Quickshell.iconPath(item.modelData.icon, true)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData.name
                                font.pixelSize: 14
                                color: item.index === panel.selectedIndex ? root.backgroundColor : root.textColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: panel.selectedIndex = item.index
                            onClicked: {
                                panel.selectedIndex = item.index
                                panel.launchSelected()
                            }
                        }
                    }
                }
            }
        }
    }
}
