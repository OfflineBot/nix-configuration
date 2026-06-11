// Right section: WLAN indicator + a click-to-open network widget.
//
// Backed by `nmcli` (NetworkManager). Handles the standard cases:
//   - open networks          -> connect immediately
//   - WPA/WPA2/WPA3 (PSK)    -> ask for a password
//   - WPA-Enterprise/eduroam -> ask for identity + password (PEAP/MSCHAPv2)
//   - captive portals        -> mark the connected net yellow + a Login button
//                               that opens the portal page in the browser
//
// The input fields live in a persistent panel (NOT inside the list delegate),
// so a background rescan/update never wipes what you typed. SSID/credentials
// are passed to sh as positional args ($1/$2/$3) — no quoting/injection issues.
//
// Requires: NetworkManager (`nmcli`), `xdg-open` for portals. eduroam uses a
// sensible default (PEAP + MSCHAPv2); some institutions need a different EAP
// method / CA cert — adjust _eapScript if yours does.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var screen
    property int barHeight: 30
    property color textColor: "#d5dde8"
    property color accentColor: "#8ec07b"
    property color warnColor: "#fabd2f"
    property color backgroundColor: "#11121a"
    property color borderColor: "#d5dde8"

    implicitWidth: indicator.implicitWidth
    implicitHeight: 18

    // ---- live state -------------------------------------------------------
    property string currentSsid: ""
    property int currentSignal: 0
    property bool wifiOn: true
    property string connectivity: "unknown"   // full | limited | portal | none
    property bool popupShown: false

    property string netType: "none"           // ethernet | wifi | none
    property string ethName: ""               // wired connection name

    property var networks: []   // [{ ssid, signal, inUse, security }]  security: open|psk|enterprise
    property string busySsid: ""
    property string errorText: ""

    // currently-selected network awaiting credentials
    property string selectedSsid: ""
    property string selectedSecurity: ""      // psk | enterprise
    property bool revealPw: false

    // enterprise (802.1X) options, configurable via the Advanced section
    property bool advancedOpen: false
    property int eapIdx: 0
    property int ph2Idx: 0
    readonly property var eapOpts: ["peap", "ttls"]
    readonly property var ph2Opts: ["mschapv2", "pap", "gtc"]

    // only NM's actual captive-portal verdict — "limited" just means
    // connected-without-internet (e.g. mid-handshake) and must NOT show "login".
    readonly property bool portal: connectivity === "portal"

    function wifiIcon() {
        if (!wifiOn || currentSsid === "") return "󰖪"
        if (currentSignal >= 75) return "󰤨"
        if (currentSignal >= 50) return "󰤥"
        if (currentSignal >= 25) return "󰤢"
        return "󰤟"
    }
    function sigIcon(s) {
        return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : "󰤟"
    }

    // a connection that is up but verified to have NO internet. Only "none"/
    // "limited" count — "unknown" (connectivity check disabled) and "full" are
    // treated as fine, so the wifi icon still reflects signal strength.
    readonly property bool noInternet:
        connectivity === "none" || connectivity === "limited"

    // single status icon: wifi signal / lan / "no internet" variants
    function netIcon() {
        if (root.netType === "ethernet")
            return root.noInternet ? "󰈂" : "󰈀"          // lan-no-internet / lan
        if (root.netType === "wifi")
            // signal strength drives the icon: 󰤨 full → 󰤟 weak (see sigIcon).
            return root.noInternet ? "󰤩"                 // connected, no internet
                   : root.sigIcon(root.currentSignal)
        return "󰤭"                                        // nothing connected
    }
    // tooltip shown on hover
    function statusText() {
        if (root.netType === "ethernet")
            return (root.ethName || "Ethernet") + (root.noInternet ? " — no internet" : "")
        if (root.netType === "wifi")
            return root.currentSsid + (root.portal ? " — login required"
                   : root.noInternet ? " — no internet" : "")
        return root.wifiOn ? "Disconnected" : "Wi-Fi off"
    }

    // nmcli -t escapes ':' and '\' — split on UNescaped ':'.
    function splitFields(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++ }
            else if (c === ":") { out.push(cur); cur = "" }
            else cur += c
        }
        out.push(cur)
        return out
    }

    // ---- indicator (icon only) --------------------------------------------
    Text {
        id: indicator
        anchors.verticalCenter: parent.verticalCenter
        text: root.netIcon()
        font.family: "MesloLGS Nerd Font Mono"
        font.pixelSize: 16
        color: root.portal ? root.warnColor : root.textColor
        opacity: root.netType === "none" ? 0.5 : 1.0
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.popupShown = !root.popupShown
            if (root.popupShown) root.scan()
        }
    }

    // hover tooltip: own overlay window BELOW the bar, so it isn't clipped by
    // the slim bar and never sits over the icon (clicks stay on the icon).
    property bool hovered: hoverArea.containsMouse
    onHoveredChanged: {
        if (!hovered) return
        const w = tipText.implicitWidth + 20
        let left = Math.round(indicator.mapToItem(null, 0, 0).x)
        const sw = root.screen ? root.screen.width : 1920
        if (left + w > sw - 6) left = sw - w - 6
        if (left < 6) left = 6
        tipWindow.margins.left = left
    }

    PanelWindow {
        id: tipWindow
        screen: root.screen
        visible: root.hovered && root.statusText().length > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.top: root.barHeight + 2
        implicitWidth: tipText.implicitWidth + 20
        implicitHeight: 28

        Rectangle {
            anchors.fill: parent
            color: root.backgroundColor
            radius: 8
            border.color: root.borderColor
            border.width: 1
            Text {
                id: tipText
                anchors.centerIn: parent
                text: root.statusText()
                color: root.portal ? root.warnColor : root.textColor
                font.family: "FiraCode Nerd Font Mono"
                font.pixelSize: 12
            }
        }
    }

    // ---- current connection / connectivity (polled) -----------------------
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["sh", "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null; " +
            "echo '---'; nmcli -t -f IN-USE,SSID,SIGNAL device wifi 2>/dev/null; " +
            "echo '---'; nmcli -t networking connectivity 2>/dev/null; " +
            "echo '---'; nmcli -t -f WIFI radio 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("---")

                // `device status` is authoritative for what is ACTUALLY connected.
                // (The wifi list's IN-USE '*' marker is unreliable — after roaming
                // it often isn't set even while connected, causing false "Disconnected".)
                let eth = false, ethName = "", wifiName = ""
                for (const l of (parts[0] || "").trim().split("\n").filter(x => x.length)) {
                    const f = root.splitFields(l)   // TYPE:STATE:CONNECTION
                    if (f[1] !== "connected") continue   // exact: excludes "connected (externally)" (vpn/lo)
                    if (f[0] === "ethernet") { eth = true; ethName = f[2] }
                    else if (f[0] === "wifi") wifiName = f[2]
                }

                // signal of the connected wifi, looked up in the scan list
                let sig = 0
                for (const l of (parts[1] || "").trim().split("\n").filter(x => x.length)) {
                    const f = root.splitFields(l)   // IN-USE:SSID:SIGNAL
                    if (f[1] === wifiName) { const s = parseInt(f[2]) || 0; if (s > sig) sig = s }
                }

                root.currentSsid = wifiName
                root.currentSignal = sig
                root.connectivity = (parts[2] || "").trim() || "unknown"
                root.wifiOn = ((parts[3] || "").trim() === "enabled")

                // ethernet wins as the primary indicator, then wifi, else none
                if (eth) { root.netType = "ethernet"; root.ethName = ethName }
                else if (wifiName) { root.netType = "wifi"; root.ethName = "" }
                else { root.netType = "none"; root.ethName = "" }
            }
        }
    }

    // ---- scan -------------------------------------------------------------
    // Signature of the current network SET (ignores fluctuating signal) so we
    // only rebuild the list — and thus only churn delegates — when networks
    // actually appear/disappear or the active connection changes. Clicking a
    // row stays reliable because the delegate under the cursor isn't recreated
    // on every signal tick.
    property string _netSig: ""

    // cached = instant (uses NM's existing scan); rescan = slow hardware scan.
    function loadNetworks(doRescan) {
        scanProc.command = doRescan
            ? ["sh", "-c", "nmcli device wifi rescan 2>/dev/null; sleep 2; " +
               "nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL device wifi list"]
            : ["nmcli", "-t", "-f", "IN-USE,SSID,SECURITY,SIGNAL", "device", "wifi", "list"]
        scanProc.running = true
    }
    function scan()   { root.errorText = ""; root.loadNetworks(false) }   // instant, on open
    function rescan() { root.errorText = ""; root.loadNetworks(true) }    // refresh button

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const bySsid = {}
                for (const l of this.text.trim().split("\n")) {
                    if (!l.length) continue
                    const f = root.splitFields(l)
                    const ssid = f[1]
                    if (!ssid) continue                 // skip hidden
                    const sec = (f[2] || "").trim()
                    const security = sec.length === 0 ? "open"
                                   : sec.indexOf("802.1X") !== -1 ? "enterprise" : "psk"
                    const sig = parseInt(f[3]) || 0
                    const entry = { ssid: ssid, signal: sig, security: security,
                                    inUse: (f[0] === "*") || (ssid === root.currentSsid) }
                    if (!bySsid[ssid] || sig > bySsid[ssid].signal) bySsid[ssid] = entry
                }
                const arr = Object.values(bySsid)
                arr.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal) || a.ssid.localeCompare(b.ssid))

                // only reassign the model if the network set/order changed
                const sig = arr.map(n => n.ssid + "|" + n.security + "|" + (n.inUse ? 1 : 0)).join("\n")
                if (sig !== root._netSig) {
                    root._netSig = sig
                    root.networks = arr
                }
            }
        }
    }

    // ---- connect ----------------------------------------------------------
    // PSK / open. Rescans the SSID first (fixes "failed to determine AP
    // security information"), prefers bringing up a saved profile.
    // -w 20 caps how long nmcli blocks, so a failure can't leave "Connecting…"
    // hanging for the default ~90s.
    readonly property string _pskScript:
        'ssid="$1"; pw="$2";' +
        'nmcli device wifi rescan ssid "$ssid" 2>/dev/null;' +
        'sleep 2;' +
        'if [ -z "$pw" ] && nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then' +
        '  nmcli -w 20 connection up id "$ssid" || nmcli -w 20 device wifi connect "$ssid";' +
        'elif [ -n "$pw" ]; then' +
        '  nmcli -w 20 device wifi connect "$ssid" password "$pw";' +
        'else' +
        '  nmcli -w 20 device wifi connect "$ssid";' +
        'fi'

    // WPA-Enterprise. Configurable: $4 anon-identity, $5 eap, $6 phase2, $7 ca-cert.
    // Empty creds -> reuse a saved profile. Optional args are only added when set.
    readonly property string _eapScript:
        'ssid="$1"; id="$2"; pw="$3"; anon="$4"; eap="$5"; ph2="$6"; ca="$7"; ' +
        'nmcli device wifi rescan ssid "$ssid" 2>/dev/null; sleep 2; ' +
        'if [ -z "$id" ] && [ -z "$pw" ]; then ' +
        '  nmcli -w 20 connection up id "$ssid"; ' +
        'else ' +
        '  nmcli connection delete id "$ssid" 2>/dev/null; ' +
        '  set -- type wifi con-name "$ssid" ssid "$ssid" wifi-sec.key-mgmt wpa-eap ' +
        '    802-1x.eap "$eap" 802-1x.phase2-auth "$ph2" 802-1x.identity "$id" ' +
        '    802-1x.password "$pw" 802-1x.password-flags 0 connection.autoconnect yes; ' +
        '  [ -n "$anon" ] && set -- "$@" 802-1x.anonymous-identity "$anon"; ' +
        '  [ -n "$ca" ] && set -- "$@" 802-1x.ca-cert "$ca"; ' +
        '  nmcli connection add "$@" && nmcli -w 20 connection up id "$ssid"; ' +
        'fi'

    function connectPsk(ssid, password) {
        root.errorText = ""
        root.busySsid = ssid
        connectProc.command = ["sh", "-c", root._pskScript, "_", ssid, password || ""]
        connectProc.running = true
    }
    function connectEnterprise(ssid, identity, password, anon, eap, phase2, ca) {
        root.errorText = ""
        root.busySsid = ssid
        connectProc.command = ["sh", "-c", root._eapScript, "_",
            ssid, identity || "", password || "", anon || "", eap, phase2, ca || ""]
        connectProc.running = true
    }
    function submit() {
        if (root.selectedSecurity === "enterprise")
            root.connectEnterprise(root.selectedSsid, idField.text, pwField.text,
                anonField.text, root.eapOpts[root.eapIdx], root.ph2Opts[root.ph2Idx], caField.text)
        else
            root.connectPsk(root.selectedSsid, pwField.text)
    }

    Process {
        id: connectProc
        property string err: ""
        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: connectProc.err = this.text }
        onExited: (code, status) => {
            if (code !== 0) {
                // nmcli errors are multi-line + verbose ("Hint: use journalctl…").
                // Keep just the first meaningful line, stripped and capped.
                let msg = (connectProc.err || "")
                    .split("\n")
                    .map(l => l.trim())
                    .filter(l => l.length && !l.startsWith("Hint:"))
                    [0] || "Connection failed"
                msg = msg.replace(/^Error:\s*/, "")
                if (msg.length > 90) msg = msg.slice(0, 90) + "…"
                root.errorText = msg
            } else {
                root.errorText = ""
                root.selectedSsid = ""
                idField.text = ""
                pwField.text = ""
                statusProc.running = true
                root.scan()
            }
            root.busySsid = ""
        }
    }

    function openPortal() { Quickshell.execDetached(["xdg-open", "http://neverssl.com"]) }
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"])
        statusProc.running = true
    }

    // pick a network from the list
    function pick(net) {
        if (root.busySsid.length) return
        if (net.inUse && root.portal) { root.openPortal(); return }   // connected but needs login
        if (net.security === "open") {
            root.selectedSsid = ""
            root.connectPsk(net.ssid, "")
        } else {
            root.selectedSsid = net.ssid
            root.selectedSecurity = net.security
            root.revealPw = false
            root.advancedOpen = false
            root.eapIdx = 0
            root.ph2Idx = 0
            idField.text = ""
            pwField.text = ""
            anonField.text = ""
            caField.text = ""
            // defer focus: the field is only laid out once the panel turns
            // visible this frame; focusing immediately is racy.
            const target = net.security === "enterprise" ? idField : pwField
            Qt.callLater(function() { target.forceActiveFocus() })
        }
    }

    // ---- popup ------------------------------------------------------------
    PanelWindow {
        id: popup
        screen: root.screen
        visible: root.popupShown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand   // don't grab all keyboard

        // Card-sized window (NOT full-screen) so the rest of the desktop stays
        // clickable — you can keep using terminals etc. while it's open. It
        // closes only on Escape or another click on the topbar icon.
        anchors.top: true
        anchors.right: true
        margins.top: root.barHeight + 2          // just below the topbar
        margins.right: 8
        implicitWidth: 330
        implicitHeight: 460

        onVisibleChanged: {
            if (visible) cardScope.forceActiveFocus()
            else { root.selectedSsid = ""; root.revealPw = false }
        }

        FocusScope {
            id: cardScope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.popupShown = false

            Rectangle {
                id: card
                anchors.fill: parent
                color: root.backgroundColor
                radius: 10
                border.color: root.borderColor
                border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // header ------------------------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Networks"
                        color: root.textColor
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 14
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.wifiOn ? "󰖩" : "󰖪"
                        color: root.textColor
                        font.family: "MesloLGS Nerd Font Mono"
                        font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWifi()
                        }
                    }
                    Text {
                        text: "󰑐"                          // rescan
                        color: root.textColor
                        font.family: "MesloLGS Nerd Font Mono"
                        font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.rescan()
                        }
                    }
                }

                // captive-portal login ----------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    visible: root.portal
                    radius: 6
                    color: "#3a2f1a"
                    border.color: root.warnColor
                    border.width: 1
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰒃  Login required — open portal"
                        color: root.warnColor
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPortal()
                    }
                }

                // error -------------------------------------------------
                Text {
                    Layout.fillWidth: true
                    visible: root.errorText.length > 0
                    text: root.errorText
                    color: "#fb4833"
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }

                // network list ------------------------------------------
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.networks

                    delegate: Rectangle {
                        id: netRow
                        required property var modelData
                        width: list.width
                        height: 34
                        radius: 6
                        readonly property bool selected: root.selectedSsid === modelData.ssid
                        readonly property bool needsLogin: modelData.inUse && root.portal
                        readonly property color rowColor:
                            needsLogin ? root.warnColor
                            : modelData.inUse ? root.accentColor : root.textColor

                        color: hover.containsMouse || selected
                               ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.10)
                               : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.sigIcon(netRow.modelData.signal)
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 15
                                color: netRow.rowColor
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 92
                                text: netRow.modelData.ssid
                                elide: Text.ElideRight
                                color: netRow.needsLogin ? root.warnColor : root.textColor
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                            }
                            // "login" hint on the connected-but-unauthenticated net
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: netRow.needsLogin
                                text: "Login"
                                color: root.warnColor
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 11
                            }
                            // enterprise / secured marker
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !netRow.needsLogin && netRow.modelData.security !== "open"
                                text: netRow.modelData.security === "enterprise" ? "󰒃" : "󰌾"
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 13
                                color: root.textColor
                                opacity: 0.6
                            }
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pick(netRow.modelData)
                        }
                    }
                }

                // persistent credentials panel (survives list rebuilds) -
                ColumnLayout {
                    id: credPanel
                    Layout.fillWidth: true
                    visible: root.selectedSsid.length > 0
                    spacing: 8

                    readonly property color fieldFill: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.06)
                    readonly property color fieldLine: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.16)
                    readonly property bool busy: root.busySsid === root.selectedSsid

                    // separator
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: 2
                        color: credPanel.fieldLine
                    }

                    // title + close
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: root.selectedSsid
                            elide: Text.ElideRight
                            color: root.textColor
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            text: "󰅖"
                            color: root.textColor
                            opacity: closeHover.containsMouse ? 1.0 : 0.5
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 14
                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedSsid = ""
                            }
                        }
                    }

                    // identity (enterprise/eduroam only)
                    TextField {
                        id: idField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        visible: root.selectedSecurity === "enterprise"
                        placeholderText: "Identity  (e.g. user@uni.de)"
                        placeholderTextColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                        color: root.textColor
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 13
                        leftPadding: 12
                        rightPadding: 12
                        verticalAlignment: TextInput.AlignVCenter
                        background: Rectangle {
                            radius: 8
                            color: credPanel.fieldFill
                            border.width: 1
                            border.color: idField.activeFocus ? root.accentColor : credPanel.fieldLine
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }
                        Keys.onReturnPressed: pwField.forceActiveFocus()
                        Keys.onEnterPressed:  pwField.forceActiveFocus()
                        Keys.onEscapePressed: root.popupShown = false
                    }

                    // password with reveal toggle
                    TextField {
                        id: pwField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        placeholderText: "Password"
                        placeholderTextColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                        echoMode: root.revealPw ? TextInput.Normal : TextInput.Password
                        color: root.textColor
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 13
                        leftPadding: 12
                        rightPadding: 38
                        verticalAlignment: TextInput.AlignVCenter
                        background: Rectangle {
                            radius: 8
                            color: credPanel.fieldFill
                            border.width: 1
                            border.color: pwField.activeFocus ? root.accentColor : credPanel.fieldLine
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.revealPw ? "󰈉" : "󰈈"
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 15
                            color: root.textColor
                            opacity: eyeHover.containsMouse ? 1.0 : 0.5
                            MouseArea {
                                id: eyeHover
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.revealPw = !root.revealPw
                            }
                        }
                        Keys.onReturnPressed: root.submit()
                        Keys.onEnterPressed:  root.submit()
                        Keys.onEscapePressed: root.popupShown = false
                    }

                    // advanced toggle (enterprise only)
                    Text {
                        visible: root.selectedSecurity === "enterprise"
                        text: (root.advancedOpen ? "󰅀  " : "󰅂  ") + "Advanced"
                        color: root.textColor
                        opacity: advHover.containsMouse ? 0.9 : 0.6
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 11
                        MouseArea {
                            id: advHover
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.advancedOpen = !root.advancedOpen
                        }
                    }

                    // advanced enterprise options
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.selectedSecurity === "enterprise" && root.advancedOpen
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // EAP method chip (click to cycle)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 8
                                color: credPanel.fieldFill
                                border.width: 1; border.color: credPanel.fieldLine
                                Text {
                                    anchors.centerIn: parent
                                    text: "EAP: " + root.eapOpts[root.eapIdx].toUpperCase()
                                    color: root.textColor
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.eapIdx = (root.eapIdx + 1) % root.eapOpts.length
                                }
                            }
                            // Phase-2 chip (click to cycle)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 8
                                color: credPanel.fieldFill
                                border.width: 1; border.color: credPanel.fieldLine
                                Text {
                                    anchors.centerIn: parent
                                    text: root.ph2Opts[root.ph2Idx].toUpperCase()
                                    color: root.textColor
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.ph2Idx = (root.ph2Idx + 1) % root.ph2Opts.length
                                }
                            }
                        }

                        TextField {
                            id: anonField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            placeholderText: "Anonymous identity (optional)"
                            placeholderTextColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                            color: root.textColor
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 12
                            leftPadding: 10; rightPadding: 10
                            background: Rectangle {
                                radius: 8; color: credPanel.fieldFill
                                border.width: 1
                                border.color: anonField.activeFocus ? root.accentColor : credPanel.fieldLine
                            }
                        }
                        TextField {
                            id: caField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            placeholderText: "CA certificate path (optional)"
                            placeholderTextColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                            color: root.textColor
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 12
                            leftPadding: 10; rightPadding: 10
                            background: Rectangle {
                                radius: 8; color: credPanel.fieldFill
                                border.width: 1
                                border.color: caField.activeFocus ? root.accentColor : credPanel.fieldLine
                            }
                        }
                    }

                    // full-width connect button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: credPanel.busy ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)
                               : btnHover.containsMouse ? Qt.lighter(root.accentColor, 1.12)
                               : root.accentColor
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: credPanel.busy ? "Connecting…" : "Connect"
                            color: "#11121a"
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        MouseArea {
                            id: btnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !credPanel.busy
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submit()
                        }
                    }

                    Text {
                        visible: root.selectedSecurity === "enterprise"
                        Layout.fillWidth: true
                        text: "Defaults (PEAP/MSCHAPv2) fit most. Tune under Advanced; empty creds reuse a saved profile."
                        color: root.textColor
                        opacity: 0.45
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }
            }
            }
        }
    }
}
