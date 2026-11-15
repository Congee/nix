import QtQuick
import Quickshell.Services.UPower

// Hidden on machines without a laptop battery
Row {
    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev ? Math.round(dev.percentage * (dev.percentage <= 1 ? 100 : 1)) : 0
    visible: !!dev && dev.isLaptopBattery
    readonly property color tint: UPower.onBattery && pct <= 15 ? "#ff5555" : Theme.fg
    spacing: 5
    Label { icon: true; text: UPower.onBattery ? "󰁹" : "󰂄"; color: parent.tint }
    Label { text: parent.pct + "%"; color: parent.tint }
}
