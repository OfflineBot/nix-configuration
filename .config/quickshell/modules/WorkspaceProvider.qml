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
        : Quickshell.env("MANGO_INSTANCE_SIGNATURE") ? "mango"
        : "none"

    // Switch to a workspace (called from the view on click).
    function focus(ws) {
        if (root.backend === "niri") {
            // Prefer the name when set, else the per-output index.
            const ref = (ws.name && ws.name.length) ? ws.name : String(ws.idx)
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", ref])
        } else if (root.backend === "hyprland") {
            Hyprland.dispatch("workspace " + ws.id)
        } else if (root.backend === "mango") {
            // mango (dwl-style tags): `view,<n>` switches to tag n on the
            // focused monitor. acts on selmon, so clicking a tag on another
            // output focuses that tag on the currently active monitor.
            Quickshell.execDetached(["mmsg", "dispatch", "view," + String(ws.idx)])
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

    // --------------------------------------------------------------- mango ---
    // `mmsg watch all-tags` emits one compact JSON object per line:
    //   {"all_tags":[{"monitor":"eDP-1","tags":[
    //       {"index":1,"is_active":false,"is_urgent":false,"layout":"T","client_count":0}, ...]}, ...]}
    // mango is tag-based (dwm/dwl): a fixed set of tags per output, several of
    // which can be "active" (visible) at once. There's no per-tag name, and the
    // stream doesn't say which monitor is selected, so `focused` mirrors
    // `is_active` per output.
    Process {
        id: mangoProc
        running: root.backend === "mango"
        command: ["mmsg", "watch", "all-tags"]
        stdout: SplitParser { onRead: line => root._onMangoLine(line) }
    }

    function _onMangoLine(line) {
        let ev
        try { ev = JSON.parse(line) } catch (e) { return }
        if (!ev.all_tags) return

        const ws = []
        for (const mon of ev.all_tags) {
            for (const t of mon.tags) {
                // Only surface tags that are visible or hold a window; empty
                // unused tags stay hidden (drop the filter to show all of them).
                if (!t.is_active && t.client_count <= 0) continue
                ws.push({
                    id: mon.monitor + ":" + t.index,
                    idx: t.index,
                    name: "",
                    output: mon.monitor,
                    active: t.is_active,
                    focused: t.is_active,
                    urgent: t.is_urgent,
                    occupied: t.client_count > 0
                })
            }
        }
        ws.sort((a, b) => (a.output || "").localeCompare(b.output || "") || a.idx - b.idx)
        root.workspaces = ws
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
