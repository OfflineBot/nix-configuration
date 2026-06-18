// Right section: microphone-muted indicator. Only visible while the default
// audio SOURCE is muted — appears as a red mic-off glyph, disappears when live.
// Click toggles mute.
//
// Backed by `wpctl` (PipeWire / WirePlumber) on @DEFAULT_AUDIO_SOURCE@:
//   - read -> `wpctl get-volume`  (looks for "[MUTED]")
//   - mute -> `wpctl set-mute … toggle`
//
// wpctl has no event stream, so state is polled (1s) — this also catches the
// XF86AudioMicMute key.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property color textColor: "#d5dde8"
    property color mutedColor: "#fb4833"

    property bool muted: false

    // collapse entirely when not muted (Row skips !visible children)
    visible: muted
    implicitWidth: visible ? indicator.implicitWidth : 0
    implicitHeight: 18

    function toggleMute() {
        if (muteProc.running) return
        root.muted = !root.muted    // optimistic
        muteProc.running = true
    }

    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        onExited: volProc.running = true
    }

    Text {
        id: indicator
        anchors.verticalCenter: parent.verticalCenter
        text: "󰍭"                                   // mic-off
        font.family: "MesloLGS Nerd Font Mono"
        font.pixelSize: 16
        color: root.mutedColor
    }

    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMute()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: { root.muted = this.text.indexOf("[MUTED]") !== -1 }
        }
    }
}
