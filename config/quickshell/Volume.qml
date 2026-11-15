import QtQuick
import QtQuick.Controls as C  // aliased: its Label would shadow ours
import QtQuick.Layouts
import Quickshell.Services.Pipewire

BarButton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real vol: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : true

    PwObjectTracker { objects: [root.sink] }  // binds the sink's live properties

    visible: !!sink
    active: pop.visible
    onClicked: mouse => mouse.button === Qt.MiddleButton ? audio.muted = !audio.muted : pop.toggle()
    onWheel: wheel => audio.volume = Math.max(0, Math.min(1.5, vol + (wheel.angleDelta.y > 0 ? 0.02 : -0.02)))

    Label { icon: true; text: root.muted ? "󰝟" : root.vol < 0.34 ? "󰕿" : root.vol < 0.67 ? "󰖀" : "󰕾" }
    Label { text: Math.round(root.vol * 100) + "%" }

    Popover {
        id: pop
        anchorItem: root
        Label { text: "Sound"; font.bold: true }
        RowLayout {
            spacing: 10
            BarButton { onClicked: root.audio.muted = !root.audio.muted; Label { icon: true; text: root.muted ? "󰝟" : "󰕾"; font.pixelSize: 16 } }
            C.Slider {
                id: slider
                Layout.preferredWidth: 280
                from: 0; to: 1
                value: root.vol
                onMoved: root.audio.volume = value
                background: Rectangle {
                    x: slider.leftPadding; y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth; height: 6; radius: 3
                    color: Theme.hover
                    Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 3; color: Theme.accent }
                }
                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 16; height: 16; radius: 8; color: Theme.fg
                }
            }
            Label { text: Math.round(root.vol * 100) + "%"; Layout.preferredWidth: 56 }
        }
        Label { text: root.sink ? (root.sink.description || root.sink.name) : ""; color: Theme.dim; Layout.maximumWidth: 320 }
    }
}
