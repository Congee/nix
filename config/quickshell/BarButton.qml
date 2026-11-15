import QtQuick

// Hover-highlighted pill; put content inside, handle onClicked
MouseArea {
    id: root
    default property alias content: row.data
    property bool active: false
    property int pad: 8
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: Theme.barHeight - 6

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: root.active || root.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}
