// Info popup: a separate rounded box that pops up below the topbar. It shows the
// big date/time, the currently-playing media (MPRIS) with cover + transport
// controls, and — only on devices that actually have a backlight — a brightness
// slider.
//
// It's its own box-sized layer surface with namespace "quickshell-clockpopup",
// so the matching niri layer-rule blurs it and clips that blur to its rounded
// corners. Translucent background so the blur shows through, plus a 1px border.
//
// A second, fullscreen, NON-blurred window sits below it only to catch clicks
// outside the box.
//
// Media: Quickshell.Services.Mpris — picks the playing player (or the first one).
//   Play/pause/prev/next drive the real player; cover/title/artist are live.
// Brightness: brightnessctl on the `backlight` class. Probed on open; if there's
//   no backlight device (e.g. a desktop with external monitors) the whole row is
//   hidden. The slider is a custom MouseArea control (reliable drag inside the
//   layer surface) — set with `brightnessctl set N%`, polled while open.
//
// One instance per screen (via Variants in Topbar). `active` shows it; clicking
// anywhere outside the box, or toggling again, dismisses it.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    required property var modelData

    property color backgroundColor: "#11121a"
    property color borderColor: "#d5dde8"
    property color textColor: "#d5dde8"
    property color accentColor: "#8ec07b"
    property color mutedColor: "#fb4833"       // mic-muted / red
    property real backgroundOpacity: 0.65     // match the bar so blur shows through
    property int barHeight: 30
    property int barMargin: 8                  // the bar's float gap
    property bool active: false

    property int boxW: 410
    property int gap: 8                        // gap between bar and box
    property int radius: 14                    // MUST match geometry-corner-radius in niri

    signal dismissed()

    // ---- brightness (brightnessctl, backlight class) ----------------------
    // Auto-hidden on devices without a backlight (probe sets brightnessAvailable).
    property bool brightnessAvailable: false
    property real brightness: 0       // 0.0 .. 1.0
    property bool brightnessDragging: false

    function setBrightness(v) {
        const pct = Math.round(Math.max(0, Math.min(1, v)) * 100)
        root.brightness = pct / 100   // optimistic
        setBrightProc.command = ["sh", "-c", "brightnessctl -c backlight set " + pct + "% >/dev/null 2>&1"]
        setBrightProc.running = true
    }

    Process { id: setBrightProc }     // command set in setBrightness()
    Process {
        id: brightProc
        // machine-readable: "name,class,current,percent,max"; empty if no device
        command: ["sh", "-c", "brightnessctl -m -c backlight 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim().split(",")
                if (f.length >= 5 && parseInt(f[4]) > 0) {
                    root.brightnessAvailable = true
                    if (!root.brightnessDragging)
                        root.brightness = (parseInt(f[3]) || 0) / 100   // percent field "50%"
                } else {
                    root.brightnessAvailable = false
                }
            }
        }
    }
    // ---- microphone (wpctl @DEFAULT_AUDIO_SOURCE@) ------------------------
    property bool micMuted: false

    function toggleMic() {
        if (micToggleProc.running) return
        root.micMuted = !root.micMuted   // optimistic
        micToggleProc.running = true
    }

    Process {
        id: micToggleProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        onExited: micProc.running = true
    }
    Process {
        id: micProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: { root.micMuted = this.text.indexOf("[MUTED]") !== -1 }
        }
    }

    // probe + poll while open (also catches the F5/F6 + mic-mute keys)
    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: { brightProc.running = true; micProc.running = true }
    }

    // ---- Claude usage --------------------------------------------------
    // Real rate-limit utilization (the % shown by the in-app `/usage`) from the
    // server via scripts/claude-usage.sh, plus an all-time local token total
    // from scripts/claude-tokens-total.sh.
    property bool usageOk: false
    property real uSession: 0          // five-hour window utilization %
    property real uWeek: 0             // seven-day window utilization %
    property real uOpus: -1            // -1 = not present
    property real uSonnet: -1
    property string uSessionResets: ""
    property string uWeekResets: ""

    property bool totalOk: false
    property real allTimeTokens: 0
    property int allTimeMsgs: 0

    function fmtTokens(n) {
        if (n >= 1e9) return (n / 1e9).toFixed(2) + "B"
        if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
        if (n >= 1e3) return Math.round(n / 1e3) + "K"
        return "" + Math.round(n)
    }
    function fmtCount(n) {
        if (n >= 1e3) return (n / 1e3).toFixed(1) + "k"
        return "" + n
    }
    // "↺ 5h" style hint for a reset ISO timestamp
    function resetHint(iso) {
        if (!iso) return ""
        const t = new Date(iso).getTime()
        if (isNaN(t)) return ""
        const s = Math.max(0, (t - Date.now()) / 1000)
        if (s < 3600)  return "↺ " + Math.max(1, Math.round(s / 60)) + "m"
        if (s < 86400) return "↺ " + Math.round(s / 3600) + "h"
        return "↺ " + Math.round(s / 86400) + "d"
    }
    function _num(v) { return (v === null || v === undefined) ? -1 : v }

    Process {
        id: usageProc
        command: ["sh", Quickshell.env("HOME") + "/.config/quickshell/scripts/claude-usage.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text.trim())
                    root.usageOk = d.ok === true
                    if (root.usageOk) {
                        root.uSession = d.session || 0
                        root.uWeek = d.week || 0
                        root.uOpus = root._num(d.opus)
                        root.uSonnet = root._num(d.sonnet)
                        root.uSessionResets = d.session_resets || ""
                        root.uWeekResets = d.week_resets || ""
                    }
                } catch (e) { root.usageOk = false }
            }
        }
    }
    Process {
        id: totalProc
        command: ["sh", Quickshell.env("HOME") + "/.config/quickshell/scripts/claude-tokens-total.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text.trim())
                    root.totalOk = d.ok === true
                    if (root.totalOk) { root.allTimeTokens = d.total; root.allTimeMsgs = d.msgs }
                } catch (e) { root.totalOk = false }
            }
        }
    }
    // server usage: refresh on open + every 30s
    Timer {
        interval: 30000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: usageProc.running = true
    }
    // all-time scan is heavier (~1.5s): on open + every 5 min
    Timer {
        interval: 300000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: totalProc.running = true
    }

    // ---- media (MPRIS) ----------------------------------------------------
    // prefer a player that's actually playing, else the first available one
    readonly property var player: {
        const ps = Mpris.players ? Mpris.players.values : []
        if (!ps || ps.length === 0) return null
        for (let i = 0; i < ps.length; i++)
            if (ps[i].playbackState === MprisPlaybackState.Playing) return ps[i]
        return ps[0]
    }
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing

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

    // Custom slider — a plain MouseArea drag (works reliably inside the layer
    // surface, unlike QtQuick.Controls.Slider here). `value` is 0..1; dragging
    // or clicking the track emits moved(v).
    component ThemeSlider: Item {
        id: sl
        property real value: 0
        property color fillColor: root.accentColor
        signal moved(real v)
        signal released()

        implicitHeight: 16

        Rectangle {                                  // track
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.15)
            Rectangle {                              // fill
                width: Math.max(0, Math.min(1, sl.value)) * parent.width
                height: parent.height
                radius: 2
                color: sl.fillColor
            }
        }
        Rectangle {                                  // handle
            width: 14
            height: 14
            radius: 7
            x: Math.max(0, Math.min(1, sl.value)) * (sl.width - width)
            anchors.verticalCenter: parent.verticalCenter
            color: sl.fillColor
            border.width: 1
            border.color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.6)
            scale: ma.pressed ? 1.2 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            cursorShape: Qt.PointingHandCursor
            function setFromX(mx) { sl.moved(Math.max(0, Math.min(1, mx / sl.width))) }
            onPressed: (m) => setFromX(m.x)
            onPositionChanged: (m) => { if (pressed) setFromX(m.x) }
            onReleased: sl.released()
        }
    }

    // Read-only usage bar — fill + colour scale with the percentage.
    component UsageBar: Item {
        id: bar
        property real percent: 0
        implicitHeight: 6
        readonly property color barColor: percent >= 90 ? "#fb4833"
                                         : percent >= 70 ? "#fabd2f"
                                         : root.accentColor
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.13)
            Rectangle {
                width: Math.max(0, Math.min(100, bar.percent)) / 100 * parent.width
                height: parent.height
                radius: 3
                color: bar.barColor
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
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
        implicitHeight: col.implicitHeight + 32
        Behavior on implicitHeight {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

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
                id: col
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                spacing: 16

                // ---- date / time -----------------------------------------
                Column {
                    width: parent.width
                    spacing: 2
                    Text {
                        id: bigTime
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.textColor
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 58
                    }
                    Text {
                        id: bigDate
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.textColor
                        opacity: 0.85
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 16
                    }
                    Text {
                        id: subLine
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.textColor
                        opacity: 0.5
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 13
                    }
                }

                // ---- separator -------------------------------------------
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
                }

                // ---- now playing -----------------------------------------
                Column {
                    width: parent.width
                    spacing: 12

                    // cover + title/artist
                    RowLayout {
                        width: parent.width
                        spacing: 12

                        // album art (or placeholder)
                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            radius: 8
                            clip: true
                            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)

                            Image {
                                anchors.fill: parent
                                source: root.hasPlayer && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !(root.hasPlayer && root.player.trackArtUrl)
                                text: "󰎈"                       // music note placeholder
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 30
                                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                            }
                        }

                        // title + artist (or "nothing playing")
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: root.hasPlayer && root.player.trackTitle
                                      ? root.player.trackTitle : "Nothing playing"
                                elide: Text.ElideRight
                                color: root.textColor
                                opacity: root.hasPlayer ? 1.0 : 0.5
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 15
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: root.hasPlayer && !!root.player.trackArtist
                                text: root.hasPlayer ? root.player.trackArtist : ""
                                elide: Text.ElideRight
                                color: root.textColor
                                opacity: 0.6
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                            }
                        }
                    }

                    // transport controls — fixed-size, vertically centred so the
                    // smaller prev/next sit on the same line as play/pause
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: ctlRow.implicitWidth
                        height: 40

                        Row {
                            id: ctlRow
                            anchors.centerIn: parent
                            spacing: 30

                            // prev
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰒮"
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 24
                                color: root.textColor
                                enabled: root.hasPlayer && root.player.canGoPrevious
                                opacity: enabled ? (prevHover.containsMouse ? 1.0 : 0.8) : 0.25
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                MouseArea {
                                    id: prevHover
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    enabled: parent.enabled
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.player.previous()
                                }
                            }

                            // play / pause
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.isPlaying ? "󰏤" : "󰐊"
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 34
                                color: root.hasPlayer ? root.accentColor : root.textColor
                                enabled: root.hasPlayer && root.player.canTogglePlaying
                                opacity: enabled ? (playHover.containsMouse ? 1.0 : 0.92) : 0.25
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                scale: playHover.containsMouse && enabled ? 1.12 : 1.0
                                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                                MouseArea {
                                    id: playHover
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    enabled: parent.enabled
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.player.togglePlaying()
                                }
                            }

                            // next
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰒭"
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 24
                                color: root.textColor
                                enabled: root.hasPlayer && root.player.canGoNext
                                opacity: enabled ? (nextHover.containsMouse ? 1.0 : 0.8) : 0.25
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                MouseArea {
                                    id: nextHover
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    enabled: parent.enabled
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.player.next()
                                }
                            }
                        }
                    }
                }

                // ---- separator -------------------------------------------
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
                }

                // ---- brightness (only shown when a backlight exists) ------
                RowLayout {
                    width: parent.width
                    spacing: 12
                    visible: root.brightnessAvailable

                    Text {
                        Layout.preferredWidth: 22
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰃟"
                        font.family: "MesloLGS Nerd Font Mono"
                        font.pixelSize: 18
                        color: root.textColor
                    }
                    ThemeSlider {
                        Layout.fillWidth: true
                        value: root.brightness
                        fillColor: root.accentColor
                        onMoved: (v) => { root.brightnessDragging = true; root.setBrightness(v) }
                        onReleased: root.brightnessDragging = false
                    }
                    Text {
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(root.brightness * 100) + "%"
                        color: root.textColor
                        opacity: 0.7
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 12
                    }
                }

                // ---- microphone (system default source) — click to toggle -
                Item {
                    width: parent.width
                    implicitHeight: 24

                    RowLayout {
                        anchors.fill: parent
                        spacing: 12

                        Text {
                            Layout.preferredWidth: 22
                            horizontalAlignment: Text.AlignHCenter
                            text: root.micMuted ? "󰍭" : "󰍬"
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 18
                            color: root.micMuted ? root.mutedColor : root.textColor
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Microphone"
                            color: root.textColor
                            opacity: 0.85
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            text: root.micMuted ? "Muted" : "Active"
                            color: root.micMuted ? root.mutedColor : root.accentColor
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleMic()
                    }
                }

                // ---- separator (Claude usage) ----------------------------
                Rectangle {
                    width: parent.width
                    height: 1
                    visible: root.usageOk || root.totalOk
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
                }

                // ---- Claude usage (real server limits) -------------------
                ColumnLayout {
                    width: parent.width
                    visible: root.usageOk || root.totalOk
                    spacing: 8

                    // header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "󰧑"
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 16
                            color: root.accentColor
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Claude usage"
                            color: root.textColor
                            opacity: 0.85
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                        Text {
                            text: root.usageOk ? "live" : "—"
                            color: root.accentColor
                            opacity: 0.6
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 10
                        }
                    }

                    // a labelled percentage bar
                    component UsageRow: RowLayout {
                        property string label: ""
                        property real pct: 0
                        property string resets: ""
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.preferredWidth: 60
                            text: parent.label
                            color: root.textColor
                            opacity: 0.6
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 12
                        }
                        UsageBar {
                            Layout.fillWidth: true
                            percent: parent.pct
                        }
                        Text {
                            Layout.preferredWidth: 34
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(parent.pct) + "%"
                            color: root.textColor
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                            text: root.resetHint(parent.resets)
                            color: root.textColor
                            opacity: 0.4
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 10
                        }
                    }

                    UsageRow {
                        visible: root.usageOk
                        label: "Session"
                        pct: root.uSession
                        resets: root.uSessionResets
                    }
                    UsageRow {
                        visible: root.usageOk
                        label: "Week"
                        pct: root.uWeek
                        resets: root.uWeekResets
                    }
                    UsageRow {
                        visible: root.usageOk && root.uOpus >= 0
                        label: "Opus 7d"
                        pct: root.uOpus
                        resets: root.uWeekResets
                    }

                    // all-time token total (local)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.totalOk
                        spacing: 8
                        Text {
                            Layout.preferredWidth: 60
                            text: "All-time"
                            color: root.textColor
                            opacity: 0.6
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.fmtTokens(root.allTimeTokens) + " tok"
                            color: root.accentColor
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            text: "· " + root.fmtCount(root.allTimeMsgs) + " msg"
                            color: root.textColor
                            opacity: 0.5
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // keep date/time fresh only while open
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
