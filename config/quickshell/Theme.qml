pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bar: Qt.rgba(0.12, 0.12, 0.14, 0.55)  // blurred by wayfire
    readonly property color popup: Qt.rgba(0.16, 0.16, 0.19, 0.92)
    readonly property color border: Qt.rgba(1, 1, 1, 0.12)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.12)
    readonly property color fg: "#f2f2f2"
    readonly property color dim: "#a0a0a8"
    readonly property color accent: "#bd93f9"  // dracula purple, matches gtk theme
    readonly property int barHeight: 36
    readonly property int fontSize: 18  // matches waybar
    readonly property string font: "DejaVu Sans"  // what waybar resolves to
    readonly property string iconFont: "CaskaydiaCove Nerd Font"  // Noto lacks the glyphs
}
