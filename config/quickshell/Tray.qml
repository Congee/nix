import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Left click activates, right click opens the app's own menu
Row {
    id: root
    required property var window
    spacing: 2
    Repeater {
        model: SystemTray.items
        BarButton {
            id: btn
            required property var modelData
            pad: 5
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) modelData.activate();
                else if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate();
                else if (modelData.hasMenu) {
                    const p = btn.mapToItem(root.window.contentItem, 0, btn.height);
                    modelData.display(root.window, p.x, p.y + 4);
                }
            }
            IconImage { source: btn.modelData.icon; implicitSize: 20 }
        }
    }
}
