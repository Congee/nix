pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Workspace state per output name, fed by wfws.py over Wayfire IPC
Singleton {
    id: root
    property var outputs: ({})

    function goto(name, x, y) {
        const o = outputs[name];
        if (o) Quickshell.execDetached(["python3", Quickshell.shellDir + "/wfws.py",
                                        "goto", String(o.id), String(x), String(y)]);
    }

    Process {
        id: proc
        running: true
        command: ["python3", Quickshell.shellDir + "/wfws.py"]
        stdout: SplitParser {
            onRead: line => root.outputs = JSON.parse(line)
        }
        stderr: SplitParser { onRead: line => console.warn(line) }
        onExited: retry.start()  // e.g. wayfire ipc plugin not loaded yet
    }
    Timer { id: retry; interval: 3000; onTriggered: proc.running = true }
}
