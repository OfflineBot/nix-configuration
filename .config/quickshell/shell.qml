import Quickshell
import QtQuick

import "./modules"

ShellRoot {
    id: root

    property color backgroundColor: "#11121a"
    property color borderColor: "#d5dde8"
    property color textColor: borderColor

    property int borderWidth: 1
    property int cornerRadius: 40

    Time {
        textColor: root.textColor
    }

    Topbar {
        backgroundColor: root.backgroundColor
        borderColor: root.borderColor
        textColor: root.textColor
    }

    Logout {
        backgroundColor: root.backgroundColor
        borderColor: root.borderColor
        textColor: root.textColor
        borderWidth: root.borderWidth
        cornerRadius: root.cornerRadius
    }

    Launcher {
        backgroundColor: root.backgroundColor
        borderColor: root.borderColor
        textColor: root.textColor
        borderWidth: root.borderWidth
        cornerRadius: root.cornerRadius
    }

    ScriptLauncher {
        backgroundColor: root.backgroundColor
        borderColor: root.borderColor
        textColor: root.textColor
        borderWidth: root.borderWidth
        cornerRadius: root.cornerRadius
    }

}
