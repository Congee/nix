import QtQuick

// One dot per workspace in the vwidth x vheight grid; click to switch
Row {
    id: root
    required property string output
    readonly property var ws: Wayfire.outputs[output]
    spacing: 5
    visible: !!ws

    Repeater {
        model: root.ws ? root.ws.w * root.ws.h : 0
        MouseArea {
            required property int index
            readonly property int wx: index % root.ws.w
            readonly property int wy: Math.floor(index / root.ws.w)
            readonly property bool current: wx === root.ws.x && wy === root.ws.y
            width: current ? 22 : 8
            height: 8
            anchors.verticalCenter: parent.verticalCenter
            hoverEnabled: true
            onClicked: Wayfire.goto(root.output, wx, wy)
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Rectangle {
                anchors.fill: parent
                radius: 4
                color: parent.current ? Theme.accent : parent.containsMouse ? Theme.fg : Theme.dim
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }
}
