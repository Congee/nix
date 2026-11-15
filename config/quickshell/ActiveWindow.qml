import QtQuick
import Quickshell.Wayland

// Bold app name + title of the focused window (wlr-foreign-toplevel)
Row {
    readonly property var tl: ToplevelManager.activeToplevel
    spacing: 8
    Label { text: tl ? tl.appId : ""; font.bold: true }
    Label { text: tl ? tl.title : ""; color: Theme.dim; width: Math.min(implicitWidth, 560) }
}
