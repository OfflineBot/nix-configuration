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
        : (Quickshell.env("XDG_SESSION_DESKTOP") === "mango"
           || Quickshell.env("DESKTOP_SESSION") === "mango") ? "mango"
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
            // mango (dwl-style tags): the `view` dispatch switches to a tag on
            // the focused monitor. acts on selmon, so clicking a tag on another
            // output focuses that tag on the currently active monitor.
            Quickshell.execDetached(["mmsg", "-s", "-d", "view," + String(ws.idx)])
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
    // `mmsg -w -t -o` streams plain-text status blocks, one line each:
    //   eDP-1 selmon 1
    //   eDP-1 tag 2 1 1 1          <- tag <idx> <state> <clients> <focused>
    //   eDP-1 clients 2
    //   eDP-1 tags 3 2 0           <- occ/sel/urg masks (decimal, then binary)
    // state is a bitmask: 1 = active (visible), 2 = urgent.
    // mango is tag-based (dwm/dwl): a fixed set of tags per output, several of
    // which can be "active" (visible) at once. Tags have no names. `focused`
    // is the active tag on the selected monitor (selmon).
    Process {
        id: mangoProc
        running: root.backend === "mango"
        command: ["mmsg", "-w", "-t", "-o"]
        stdout: SplitParser { onRead: line => root._onMangoLine(line) }
    }

    // mon -> { selmon: bool, tags: { idx: {active, urgent, clients} } }
    property var _mangoMons: ({})

    function _onMangoLine(line) {
        const p = line.trim().split(/\s+/)
        if (p.length < 3) return
        const mons = root._mangoMons
        const m = mons[p[0]] || (mons[p[0]] = { selmon: false, tags: {} })

        if (p[1] === "selmon") {
            m.selmon = p[2] === "1"
        } else if (p[1] === "tag" && p.length >= 5) {
            const state = parseInt(p[3])
            m.tags[parseInt(p[2])] = {
                active: (state & 1) !== 0,
                urgent: (state & 2) !== 0,
                clients: parseInt(p[4])
            }
        } else if (p[1] === "tags") {
            // mask lines close a monitor's block -> publish the new state
            root._rebuildMango()
        }
    }

    function _rebuildMango() {
        const ws = []
        for (const mon in root._mangoMons) {
            const m = root._mangoMons[mon]
            for (const key in m.tags) {
                const t = m.tags[key]
                // Only surface tags that are visible or hold a window; empty
                // unused tags stay hidden (drop the filter to show all of them).
                if (!t.active && t.clients <= 0) continue
                const idx = parseInt(key)
                ws.push({
                    id: mon + ":" + idx,
                    idx: idx,
                    name: "",
                    output: mon,
                    active: t.active,
                    focused: t.active && m.selmon,
                    urgent: t.urgent,
                    occupied: t.clients > 0
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
