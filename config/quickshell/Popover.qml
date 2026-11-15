import QtQuick
import QtQuick.Layouts
import Quickshell

// macOS-style dropdown under a bar item; click outside to dismiss
PopupWindow {
    id: root
    required property Item anchorItem
    default property alias content: box.data
    property int pad: 14

    function toggle() { visible = !visible }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    grabFocus: true
    color: "transparent"
    implicitWidth: box.implicitWidth + pad * 2
    implicitHeight: box.implicitHeight + pad * 2 + 6

    Rectangle {
        id: bg
        y: 6
        width: parent.width
        height: parent.height - 6
        radius: 12
        color: Theme.popup
        border.color: Theme.border
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: box
            x: root.pad
            y: root.pad
            spacing: 10
        }
    }
}
