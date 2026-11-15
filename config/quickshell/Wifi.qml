import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// SSID + signal from `iw` (iwd here; Quickshell.Networking needs NetworkManager)
BarButton {
    id: root
    property string iface: ""
    property var link: ({})  // parsed `iw dev <iface> link`
    readonly property bool up: !!link.SSID
    // waybar's scale: -100 dBm = 0%, -35 dBm = 100%
    readonly property int pct: up ? Math.max(0, Math.min(100, Math.round((parseFloat(link.signal) + 100) / 65 * 100))) : 0

    active: pop.visible
    onClicked: pop.toggle()

    Label { text: root.up ? root.link.SSID + " (" + root.pct + "%)" : "Disconnected"; color: root.up ? Theme.fg : "#ff5555" }
    Label { icon: true; text: !root.up ? "󰤮" : root.pct < 25 ? "󰤟" : root.pct < 50 ? "󰤢" : root.pct < 75 ? "󰤥" : "󰤨" }

    Process {
        id: iw
        command: root.iface ? ["iw", "dev", root.iface, "link"] : ["sh", "-c", "iw dev | awk '/Interface/{print \"Interface: \" $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const kv = {};
                for (const l of text.split("\n")) {
                    const m = l.match(/^\s*([^:]+):\s*(.*)$/);
                    if (m) kv[m[1]] = m[2];
                }
                if (!root.iface) { root.iface = kv.Interface || ""; iw.running = !!root.iface; }
                else root.link = kv;
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: iw.running = true }

    Popover {
        id: pop
        anchorItem: root
        Label { text: root.up ? root.link.SSID : "Wi-Fi disconnected"; font.bold: true }
        GridLayout {
            visible: root.up
            columns: 2
            columnSpacing: 16
            rowSpacing: 4
            Label { text: "Signal"; color: Theme.dim } Label { text: root.pct + "%  (" + root.link.signal + ")" }
            Label { text: "Band"; color: Theme.dim } Label { text: parseFloat(root.link.freq) > 5000 ? "5 GHz" : "2.4 GHz" }
            Label { text: "Rx"; color: Theme.dim } Label { text: (root.link["rx bitrate"] || "").split(" ").slice(0, 2).join(" ") }
            Label { text: "Tx"; color: Theme.dim } Label { text: (root.link["tx bitrate"] || "").split(" ").slice(0, 2).join(" ") }
            Label { text: "Interface"; color: Theme.dim } Label { text: root.iface }
        }
        BarButton { onClicked: { Quickshell.execDetached(["kitty", "impala"]); pop.visible = false } Label { text: "Network settings…" } }
    }
}
