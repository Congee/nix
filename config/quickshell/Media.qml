import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets

// Now playing: title in the bar, artwork + controls in the popover
BarButton {
    id: root
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null

    visible: !!player && !!player.trackTitle
    active: pop.visible
    onClicked: mouse => mouse.button === Qt.MiddleButton ? player.togglePlaying() : pop.toggle()

    Label { icon: true; text: root.player && root.player.isPlaying ? "󰏤" : "󰐊" }
    Label {
        text: root.player ? root.player.trackTitle : ""
        width: Math.min(implicitWidth, 380)
    }

    Popover {
        id: pop
        anchorItem: root
        RowLayout {
            spacing: 14
            ClippingRectangle {
                radius: 8
                implicitWidth: 120; implicitHeight: 120
                color: Theme.hover
                Image {
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(192, 192)
                }
            }
            ColumnLayout {
                spacing: 4
                Layout.preferredWidth: 320
                Label { text: root.player ? root.player.trackTitle : ""; font.bold: true; Layout.fillWidth: true }
                Label { text: root.player ? root.player.trackArtist : ""; color: Theme.dim; Layout.fillWidth: true }
                Label { text: root.player ? root.player.identity : ""; color: Theme.dim; font.pixelSize: 14; Layout.fillWidth: true }
                Row {
                    spacing: 4
                    BarButton { enabled: root.player && root.player.canGoPrevious; onClicked: root.player.previous(); Label { icon: true; text: "󰒮"; font.pixelSize: 18 } }
                    BarButton { onClicked: root.player.togglePlaying(); Label { icon: true; text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"; font.pixelSize: 18 } }
                    BarButton { enabled: root.player && root.player.canGoNext; onClicked: root.player.next(); Label { icon: true; text: "󰒭"; font.pixelSize: 18 } }
                }
            }
        }
    }
}
