import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Open-Meteo forecast. Location: ~/.local/state/quickshell/location.json
// ({"lat", "lon", "name"}; kept out of the repo) or else geoclue's IP guess.
// Bar: icon + temperature. Popover: now, next 12 hours, 7 days.
BarButton {
    id: root
    property real lat: NaN
    property real lon: NaN
    property string place: ""
    property var data: null  // Open-Meteo response

    readonly property var cur: data ? data.current : null
    readonly property var daily: data ? data.daily : null
    // Next 12 hours, starting at the current hour
    readonly property var hours: {
        if (!data) return [];
        const h = data.hourly, now = new Date(), out = [];
        for (let i = 0; i < h.time.length && out.length < 12; i++) {
            const t = new Date(h.time[i]);
            if (t.getTime() + 3600e3 > now.getTime())
                out.push({ t, temp: h.temperature_2m[i], code: h.weather_code[i],
                           day: h.is_day[i], rain: h.precipitation_probability[i] });
        }
        return out;
    }
    // Week-wide range, so the daily bars share one scale like macOS
    readonly property real weekMin: daily ? Math.min(...daily.temperature_2m_min) : 0
    readonly property real weekMax: daily ? Math.max(...daily.temperature_2m_max) : 1

    // WMO weather code -> [nerd-font icon (day, night), description]
    function wmo(code, day) {
        const m = {
            0: ["", "", "Clear"],
            1: ["", "", "Mostly clear"],
            2: ["", "", "Partly cloudy"],
            3: ["", "", "Overcast"],
            45: ["", "", "Fog"], 48: ["", "", "Freezing fog"],
            51: ["", "", "Light drizzle"], 53: ["", "", "Drizzle"],
            55: ["", "", "Heavy drizzle"], 56: ["", "", "Freezing drizzle"],
            57: ["", "", "Freezing drizzle"],
            61: ["", "", "Light rain"], 63: ["", "", "Rain"],
            65: ["", "", "Heavy rain"], 66: ["", "", "Freezing rain"],
            67: ["", "", "Freezing rain"],
            71: ["", "", "Light snow"], 73: ["", "", "Snow"],
            75: ["", "", "Heavy snow"], 77: ["", "", "Snow grains"],
            80: ["", "", "Showers"], 81: ["", "", "Showers"],
            82: ["", "", "Heavy showers"],
            85: ["", "", "Snow showers"], 86: ["", "", "Snow showers"],
            95: ["", "", "Thunderstorm"], 96: ["", "", "Thunderstorm, hail"],
            99: ["", "", "Thunderstorm, hail"],
        }[code] || ["", "", "Unknown"];
        return { icon: day === 0 ? m[1] : m[0], text: m[2] };
    }
    function deg(v) { return Math.round(v) + "°" }
    function hm(iso) { return Qt.formatTime(new Date(iso), "h:mm AP") }

    visible: !!cur
    active: pop.visible
    onClicked: pop.toggle()

    Label { icon: true; text: root.cur ? root.wmo(root.cur.weather_code, root.cur.is_day).icon : "" }
    Label { text: root.cur ? root.deg(root.cur.temperature_2m) : "" }

    function setLocation(la, lo, name) {
        lat = la;
        lon = lo;
        place = name || "";
        fetch.running = true;
        if (!place) geocode.running = true;
    }

    // Edits apply live; delete the file to go back to geoclue
    FileView {
        id: locFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/location.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const l = JSON.parse(text());
                if (typeof l.lat === "number" && typeof l.lon === "number")
                    return root.setLocation(l.lat, l.lon, l.name);
            } catch (e) {}
            console.warn("weather: invalid " + path + ", using geoclue");
            locate.running = true;
        }
        onLoadFailed: locate.running = true
    }

    // geoclue fallback, re-located every 3 hours
    Process {
        id: locate
        command: ["whereami", "-t", "30", "-a", "8"]
        property real la: NaN
        // whereami keeps watching until -t; take the first fix and stop it
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^(Latitude|Longitude):\s*(-?[\d.]+)/);
                if (!m) return;
                if (m[1] === "Latitude") { locate.la = parseFloat(m[2]); return; }
                locate.running = false;
                root.setLocation(locate.la, parseFloat(m[2]), "");
            }
        }
    }
    Timer { interval: 3 * 3600e3; running: !locFile.loaded; repeat: true; onTriggered: locate.running = true }

    Process {
        id: fetch
        command: ["curl", "-sf", "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + root.lat + "&longitude=" + root.lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"
            + "&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&forecast_days=7"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.data = JSON.parse(text) } catch (e) {} }
        }
    }
    Timer { interval: 15 * 60e3; running: !isNaN(root.lat); repeat: true; onTriggered: fetch.running = true }

    // City name for the popover header (OpenStreetMap reverse geocoding)
    Process {
        id: geocode
        command: ["curl", "-sf", "-A", "quickshell-bar",
            "https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=10&lat=" + root.lat + "&lon=" + root.lon]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const a = JSON.parse(text).address;
                    root.place = a.city || a.town || a.village || a.county || a.state || "";
                } catch (e) {}
            }
        }
    }

    Popover {
        id: pop
        anchorItem: root

        // Now
        RowLayout {
            spacing: 16
            Label { icon: true; text: root.cur ? root.wmo(root.cur.weather_code, root.cur.is_day).icon : ""; font.pixelSize: 52 }
            ColumnLayout {
                spacing: 0
                Label { text: root.place || "Weather"; font.bold: true }
                Label { text: root.cur ? root.deg(root.cur.temperature_2m) : ""; font.pixelSize: 40 }
                Label {
                    color: Theme.dim
                    text: root.cur && root.daily
                        ? root.wmo(root.cur.weather_code, 1).text + "   H:" + root.deg(root.daily.temperature_2m_max[0])
                          + "  L:" + root.deg(root.daily.temperature_2m_min[0])
                        : ""
                }
            }
        }

        // Next 12 hours
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }
        Row {
            spacing: 4
            Repeater {
                model: root.hours
                Column {
                    required property var modelData
                    required property int index
                    width: 52
                    spacing: 4
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.index === 0 ? "Now" : Qt.formatTime(parent.modelData.t, "h AP")
                        color: Theme.dim; font.pixelSize: 14
                    }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; icon: true; text: root.wmo(parent.modelData.code, parent.modelData.day).icon }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.modelData.rain >= 20 ? parent.modelData.rain + "%" : " "
                        color: "#8be9fd"; font.pixelSize: 12
                    }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.deg(parent.modelData.temp); font.pixelSize: 16 }
                }
            }
        }

        // 7 days
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }
        Repeater {
            model: root.daily ? root.daily.time.length : 0
            RowLayout {
                required property int index
                readonly property real lo: root.daily.temperature_2m_min[index]
                readonly property real hi: root.daily.temperature_2m_max[index]
                readonly property int rain: root.daily.precipitation_probability_max[index]
                spacing: 12
                Label { text: index === 0 ? "Today" : Qt.formatDate(new Date(root.daily.time[index] + "T00:00"), "ddd"); Layout.preferredWidth: 64 }
                Label { icon: true; text: root.wmo(root.daily.weather_code[index], 1).icon; Layout.preferredWidth: 30 }
                Label { text: rain >= 20 ? rain + "%" : ""; color: "#8be9fd"; font.pixelSize: 14; Layout.preferredWidth: 44 }
                Label { text: root.deg(lo); color: Theme.dim; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }
                // Range bar on the week's shared scale
                Rectangle {
                    Layout.preferredWidth: 180
                    implicitHeight: 6
                    radius: 3
                    color: Theme.hover
                    Rectangle {
                        readonly property real span: Math.max(1, root.weekMax - root.weekMin)
                        x: (parent.parent.lo - root.weekMin) / span * parent.width
                        width: Math.max(6, (parent.parent.hi - parent.parent.lo) / span * parent.width)
                        height: parent.height
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#8be9fd" }
                            GradientStop { position: 1; color: "#ffb86c" }
                        }
                    }
                }
                Label { text: root.deg(hi); Layout.preferredWidth: 44 }
            }
        }

        // Details
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }
        GridLayout {
            columns: 4
            columnSpacing: 16
            rowSpacing: 4
            Label { text: "Feels like"; color: Theme.dim } Label { text: root.cur ? root.deg(root.cur.apparent_temperature) : "" }
            Label { text: "Sunrise"; color: Theme.dim } Label { text: root.daily ? root.hm(root.daily.sunrise[0]) : "" }
            Label { text: "Humidity"; color: Theme.dim } Label { text: root.cur ? root.cur.relative_humidity_2m + "%" : "" }
            Label { text: "Sunset"; color: Theme.dim } Label { text: root.daily ? root.hm(root.daily.sunset[0]) : "" }
            Label { text: "Wind"; color: Theme.dim } Label { text: root.cur ? Math.round(root.cur.wind_speed_10m) + " mph" : "" }
        }
    }
}
