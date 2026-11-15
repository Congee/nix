import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell-bar"  // matched by wayfire [blur]
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: Theme.bar

    Row {
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 14
        Caffeine { window: bar; anchors.verticalCenter: parent.verticalCenter }
        Workspaces { output: bar.screen ? bar.screen.name : ""; anchors.verticalCenter: parent.verticalCenter }
        ActiveWindow { anchors.verticalCenter: parent.verticalCenter }
    }

    Weather { anchors.centerIn: parent }

    Row {
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 4
        Media { anchors.verticalCenter: parent.verticalCenter }
        Wifi { anchors.verticalCenter: parent.verticalCenter }
        Tray { window: bar; anchors.verticalCenter: parent.verticalCenter }
        Volume { anchors.verticalCenter: parent.verticalCenter }
        Battery { anchors.verticalCenter: parent.verticalCenter }
        Clock { anchors.verticalCenter: parent.verticalCenter }
    }
}
