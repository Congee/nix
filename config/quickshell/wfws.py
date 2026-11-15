#!/usr/bin/env python3
"""Wayfire IPC bridge for quickshell (Wayfire has no ext-workspace protocol).

  wfws.py          print {"<output name>": {id, x, y, w, h}} as one JSON line
                   now and on every workspace/output change
  wfws.py goto ID X Y   switch output ID to workspace (X, Y)

Needs the `ipc` and `ipc-rules` plugins in wayfire.conf.
"""
import glob, json, os, socket, struct, sys


def sock_path():
    if p := os.environ.get("WAYFIRE_SOCKET"):
        return p
    rt = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    disp = os.environ.get("WAYLAND_DISPLAY", "wayland-1")
    # Processes not spawned by wayfire lack WAYFIRE_SOCKET
    hits = sorted(glob.glob(f"{rt}/wayfire-{disp}-*.socket"), key=os.path.getmtime)
    if not hits:
        sys.exit("wfws: no wayfire IPC socket (enable the ipc plugin)")
    return hits[-1]


class Ipc:
    def __init__(self):
        self.s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.s.connect(sock_path())

    def _read(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.s.recv(n - len(buf))
            if not chunk:
                raise EOFError
            buf += chunk
        return buf

    def recv(self):
        (n,) = struct.unpack("<I", self._read(4))
        return json.loads(self._read(n))

    def call(self, method, data=None):
        msg = json.dumps({"method": method, "data": data or {}}).encode()
        self.s.sendall(struct.pack("<I", len(msg)) + msg)
        return self.recv()


def state(ipc):
    out = {}
    for o in ipc.call("window-rules/list-outputs"):
        ws = o["workspace"]
        out[o["name"]] = {"id": o["id"], "x": ws["x"], "y": ws["y"],
                          "w": ws["grid_width"], "h": ws["grid_height"]}
    return out


def main():
    if sys.argv[1:2] == ["goto"]:
        oid, x, y = map(int, sys.argv[2:5])
        Ipc().call("vswitch/set-workspace", {"output-id": oid, "x": x, "y": y})
        return
    query, events = Ipc(), Ipc()
    events.call("window-rules/events/watch", {"events": [
        "wset-workspace-changed", "output-wset-changed",
        "output-added", "output-removed"]})
    while True:
        print(json.dumps(state(query)), flush=True)
        events.recv()


if __name__ == "__main__":
    try:
        main()
    except (EOFError, BrokenPipeError, KeyboardInterrupt):
        pass
