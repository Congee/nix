import QtQuick

Text {
    property bool icon: false  // Nerd Font glyph
    color: Theme.fg
    font.family: icon ? Theme.iconFont : Theme.font
    font.pixelSize: icon ? Theme.fontSize + 2 : Theme.fontSize
    elide: Text.ElideRight
}
