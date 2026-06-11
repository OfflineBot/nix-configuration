// Right section: volume indicator. Display only — click toggles mute.
//
// Backed by `wpctl` (PipeWire / WirePlumber) on @DEFAULT_AUDIO_SINK@:
//   - read -> `wpctl get-volume`  ("Volume: 0.29 [MUTED]")
//   - mute -> `wpctl set-mute toggle`
//
// wpctl has no event stream, so state is polled (1s) — this also catches the
// hardware volume keys.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property color textColor: "#d5dde8"

    implicitWidth: indicator.implicitWidth
    implicitHeight: 18

    // ---- live state -------------------------------------------------------
    property real volume: 0.0          // 0.0 .. 1.0 (can exceed 1 in PipeWire)
    property bool muted: false

    readonly property int pct: Math.round(root.volume * 100)

    function volIcon() {
        if (root.muted || root.volume <= 0.0) return "󰝟"   // muted / silent
        if (root.volume < 0.34) return "󰕿"                 // low
        if (root.volume < 0.67) return "󰖀"                 // medium
        return "󰕾"                                          // high
    }

    function toggleMute() {
        if (muteProc.running) return
        root.muted = !root.muted   // optimistic: instant feedback
        muteProc.running = true     // re-poll only AFTER set-mute applies
    }

    // Run set-mute as a tracked process so we can re-read state only once it has
    // actually applied — polling immediately would race the write and read the
    // stale (pre-toggle) value, flipping the icon back for a beat.
    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: volProc.running = true
    }

    // ---- indicator --------------------------------------------------------
    Row {
        id: indicator
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.volIcon()
            font.family: "MesloLGS Nerd Font Mono"
            font.pixelSize: 16
            color: root.textColor
            opacity: root.muted ? 0.5 : 1.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "muted" : (root.pct + "%")
            font.family: "FiraCode Nerd Font Mono"
            font.pixelSize: 13
            color: root.textColor
            opacity: root.muted ? 0.5 : 0.85
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMute()
    }

    // ---- polled state -----------------------------------------------------
    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "Volume: 0.29 [MUTED]"
                const m = this.text.match(/Volume:\s*([0-9.]+)/)
                if (m) root.volume = parseFloat(m[1])
                root.muted = this.text.indexOf("[MUTED]") !== -1
            }
        }
    }
}
