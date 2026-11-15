import QtQuick
import QtQuick.Controls as C  // aliased: its Label would shadow ours
import QtQuick.Layouts
import Quickshell

BarButton {
    id: root
    SystemClock { id: clock; precision: SystemClock.Minutes }
    onClicked: pop.toggle()
    active: pop.visible

    Label { text: Qt.formatDateTime(clock.date, "ddd MMM d   h:mm AP"); font.bold: true }

    Popover {
        id: pop
        anchorItem: root
        property date shown: clock.date

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: Qt.formatDate(pop.shown, "MMMM yyyy")
                font.bold: true
                font.pixelSize: 20
                Layout.fillWidth: true
            }
            BarButton { onClicked: pop.shown = new Date(pop.shown.getFullYear(), pop.shown.getMonth() - 1, 1); Label { text: "‹" } }
            BarButton { onClicked: pop.shown = clock.date; Label { text: "Today" } }
            BarButton { onClicked: pop.shown = new Date(pop.shown.getFullYear(), pop.shown.getMonth() + 1, 1); Label { text: "›" } }
        }
        C.DayOfWeekRow {
            Layout.fillWidth: true
            delegate: Label { required property string shortName; text: shortName; color: Theme.dim; horizontalAlignment: Text.AlignHCenter }
        }
        C.MonthGrid {
            id: grid
            month: pop.shown.getMonth()
            year: pop.shown.getFullYear()
            Layout.preferredWidth: 360
            delegate: Rectangle {
                required property var model
                readonly property bool today: model.today
                implicitWidth: 44
                implicitHeight: 38
                radius: 19
                color: today ? Theme.accent : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: parent.model.day
                    color: parent.today ? "#1e1e24" : parent.model.month === grid.month ? Theme.fg : Theme.dim
                    opacity: parent.model.month === grid.month ? 1 : 0.5
                }
            }
        }
    }
}
