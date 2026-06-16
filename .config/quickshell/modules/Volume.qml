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

    function volIcon() {
        if (root.muted) return "󰖁"          // struck-through speaker
        if (root.volume < 0.34) return "󰕿"  // low
        if (root.volume < 0.67) return "󰖀"  // medium
        return "󰕾"                           // high
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
    Text {
        id: indicator
        anchors.verticalCenter: parent.verticalCenter
        text: root.volIcon()
        font.family: "MesloLGS Nerd Font Mono"
        font.pixelSize: 16
        color: root.textColor                       // white when on
        opacity: root.muted ? 0.4 : 1.0             // grayed out when muted
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    }

    // enlarge the hit area beyond the icon (full bar height + a bit on the sides)
    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        anchors.leftMargin: -6
        anchors.rightMargin: -6
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
