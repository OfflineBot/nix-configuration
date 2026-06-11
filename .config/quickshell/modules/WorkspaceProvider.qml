// Non-visual workspace backend. Detects the running compositor and exposes a
// normalized `workspaces` array so the visual Workspaces.qml stays DE-agnostic.
//
// Each entry: { id, idx, name, output, active, focused }
//   - output  = monitor/connector name (matches Quickshell screen.name)
//   - active  = the visible workspace on its output
//   - focused = the one the user is currently on
//
// Adding another DE = add a branch in `backend`, a runner, and a `focus()` case.

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root

    property var workspaces: []

    readonly property string backend:
        Quickshell.env("NIRI_SOCKET") ? "niri"
        : Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "hyprland"
        : "none"

    // Switch to a workspace (called from the view on click).
    function focus(ws) {
        if (root.backend === "niri") {
            // Prefer the name when set, else the per-output index.
            const ref = (ws.name && ws.name.length) ? ws.name : String(ws.idx)
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", ref])
        } else if (root.backend === "hyprland") {
            Hyprland.dispatch("workspace " + ws.id)
        }
    }

    // ---------------------------------------------------------------- niri ---
    // `niri msg --json event-stream` emits one JSON event per line.
    Process {
        id: niriProc
        running: root.backend === "niri"
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser { onRead: line => root._onNiriLine(line) }
    }

    function _onNiriLine(line) {
        let ev
        try { ev = JSON.parse(line) } catch (e) { return }

        if (ev.WorkspacesChanged) {
            const ws = ev.WorkspacesChanged.workspaces.map(w => ({
                id: w.id, idx: w.idx, name: w.name, output: w.output,
                active: w.is_active, focused: w.is_focused
            }))
            ws.sort((a, b) => (a.output || "").localeCompare(b.output || "") || a.idx - b.idx)
            root.workspaces = ws
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id
            const focused = ev.WorkspaceActivated.focused
            const cur = root.workspaces.slice()
            const target = cur.find(w => w.id === id)
            if (!target) return
            for (let w of cur) {
                if (w.output === target.output) {
                    w.active = (w.id === id)
                    if (focused) w.focused = (w.id === id)
                }
            }
            root.workspaces = cur   // reassign so bindings re-evaluate
        }
    }

    // ------------------------------------------------------------ hyprland ---
    // Best-effort: driven by the built-in Hyprland module. May need tuning.
    Connections {
        enabled: root.backend === "hyprland"
        target: Hyprland.workspaces
        function onValuesChanged() { root._syncHyprland() }
    }
    Connections {
        enabled: root.backend === "hyprland"
        target: Hyprland
        function onFocusedWorkspaceChanged() { root._syncHyprland() }
    }
    Component.onCompleted: if (root.backend === "hyprland") root._syncHyprland()

    function _syncHyprland() {
        const focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
        const ws = [...Hyprland.workspaces.values].map(w => ({
            id: w.id,
            idx: w.id,
            name: w.name,
            output: w.monitor ? w.monitor.name : "",
            active: w.monitor && w.monitor.activeWorkspace
                    ? w.monitor.activeWorkspace.id === w.id : false,
            focused: w.id === focusedId
        }))
        ws.sort((a, b) => (a.output || "").localeCompare(b.output || "") || a.idx - b.idx)
        root.workspaces = ws
    }
}
