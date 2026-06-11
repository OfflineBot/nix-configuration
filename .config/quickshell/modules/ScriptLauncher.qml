// Fuzzy launcher for personal scripts in ~/.local/bin.
//
// Same look/behaviour as the app Launcher, but the list is the executable files
// in ~/.local/bin (symlinks followed). Each entry gets a type icon derived from
// its extension (.sh / .py / … each distinct; no extension = generic terminal).
//
// Open it from a keybind via IPC:
//   qs ipc call scriptlauncher toggle

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.local/bin"

    // Scripts here are mostly CLI tools (and some need a sudo prompt), so they're
    // run inside a terminal. `--hold` keeps the window open after exit so you can
    // read the output. Change this to launch them differently / in another term.
    property var terminalCmd: ["kitty", "--hold"]

    property bool shown: false

    function toggle() { root.shown = !root.shown }
    function show()   { root.shown = true }
    function hide()   { root.shown = false }

    IpcHandler {
        target: "scriptlauncher"
        function toggle() { root.toggle() }
        function show()   { root.show() }
        function hide()   { root.hide() }
    }

    // ---- extension -> icon / colour --------------------------------------
    function extOf(name) {
        const i = name.lastIndexOf(".")
        if (i <= 0) return ""        // no dot, or a dotfile -> "no extension"
        return name.slice(i + 1).toLowerCase()
    }
    function scriptIcon(name) {
        switch (root.extOf(name)) {
            case "sh": case "bash": case "zsh": case "fish": return "󰆍"  // console
            case "py":                                        return "󰌠"  // python
            case "js": case "mjs": case "cjs": case "ts":     return "󰌞"  // javascript
            case "lua":                                       return "󰢱"  // lua
            case "rb":                                        return "󰴭"  // ruby
            case "go":                                        return "󰟓"  // go
            case "php":                                       return "󰌟"  // php
            case "":                                          return "󰒓"  // no ext -> cog/tool
            default:                                          return "󰈔"  // generic file
        }
    }
    function scriptColor(name) {
        switch (root.extOf(name)) {
            case "sh": case "bash": case "zsh": case "fish": return "#8ec07b"
            case "py":                                        return "#4b8bbe"
            case "js": case "mjs": case "cjs": case "ts":     return "#f1e05a"
            case "lua":                                       return "#51a0cf"
            case "rb":                                        return "#cc342d"
            case "go":                                        return "#00add8"
            case "php":                                       return "#8892bf"
            default:                                          return root.textColor
        }
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

        property var scripts: []     // all script filenames in ~/.local/bin
        property var results: []     // filtered/sorted view
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

        function score(q, name) {
            if (name === q) return 10000
            if (name.startsWith(q)) return 9000 - name.length
            const idx = name.indexOf(q)
            if (idx >= 0) return 7000 - idx * 5 - name.length
            const f = panel.fuzzyScore(q, name)
            if (f >= 0) return 4000 + f
            return -1
        }

        function updateResults() {
            const q = search.text.toLowerCase().trim()
            const all = panel.scripts
            if (q === "") {
                panel.results = all.slice().sort((a, b) => a.localeCompare(b))
                panel.selectedIndex = 0
                return
            }
            const scored = []
            for (let i = 0; i < all.length; i++) {
                const s = panel.score(q, all[i].toLowerCase())
                if (s > -1) scored.push({ n: all[i], s: s })
            }
            scored.sort((a, b) => b.s - a.s || a.n.localeCompare(b.n))
            panel.results = scored.map(x => x.n)
            panel.selectedIndex = 0
        }

        function move(delta) {
            if (panel.results.length === 0) return
            panel.selectedIndex = Math.max(0, Math.min(panel.selectedIndex + delta, panel.results.length - 1))
            list.positionViewAtIndex(panel.selectedIndex, ListView.Contain)
        }

        function launchSelected() {
            if (panel.results.length === 0) return
            const path = root.scriptsDir + "/" + panel.results[panel.selectedIndex]
            // run from $HOME, not whatever cwd quickshell happens to have inherited
            Quickshell.execDetached({
                command: root.terminalCmd.concat([path]),
                workingDirectory: Quickshell.env("HOME")
            })
            root.hide()
        }

        // load the script list from ~/.local/bin (executables, symlinks followed)
        Process {
            id: loadProc
            command: ["sh", "-c",
                "find -L \"$HOME/.local/bin\" -maxdepth 1 -type f -executable -printf '%f\\n' 2>/dev/null | sort"]
            stdout: StdioCollector {
                onStreamFinished: {
                    panel.scripts = this.text.split("\n").filter(l => l.length > 0)
                    panel.updateResults()
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                search.text = ""
                loadProc.running = true   // refresh on every open
                search.forceActiveFocus()
            }
        }

        Component.onCompleted: loadProc.running = true

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
                    placeholderText: "Run script…"
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
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                horizontalAlignment: Text.AlignHCenter
                                text: root.scriptIcon(item.modelData)
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 16
                                color: item.index === panel.selectedIndex
                                       ? root.backgroundColor : root.scriptColor(item.modelData)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData
                                font.pixelSize: 14
                                font.family: "FiraCode Nerd Font Mono"
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
