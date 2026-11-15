// Top bar; ~/.config/quickshell is a live symlink, so saving any file here
// reloads the shell instantly.
import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }
}
