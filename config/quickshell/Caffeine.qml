import QtQuick
import Quickshell.Wayland

// Keep the screen awake (waybar's idle_inhibitor)
BarButton {
    id: root
    required property var window
    property bool on: false
    pad: 6
    active: on
    onClicked: on = !on

    IdleInhibitor { window: root.window; enabled: root.on }
    Label { icon: true; text: root.on ? "" : ""; color: root.on ? Theme.accent : Theme.fg }  // eye / eye-slash
}
