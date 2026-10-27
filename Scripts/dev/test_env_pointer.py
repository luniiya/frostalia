#!/usr/bin/env python3
"""Move and click a virtual pointer on one Wayland compositor (the test environment's).

Usage: Scripts/dev/test_env_pointer.py X Y [left|right|middle|none] [--width W --height H]
  X, Y are layout coordinates on the compositor whose socket is $WAYLAND_DISPLAY.

Unlike Scripts/dev/click.py, which creates a kernel uinput mouse that every compositor
on the machine sees, this speaks zwlr_virtual_pointer_v1 to a single compositor over
its socket, so the real session's cursor never moves. Stdlib only: the few messages it
needs are written in the Wayland wire format by hand.
"""

import argparse
import os
import socket
import struct
import sys
import time

BUTTONS = {"left": 0x110, "right": 0x111, "middle": 0x112}


class Connection:
    def __init__(self, path):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect(path)
        self.next_id = 2
        self.buffer = b""

    def new_id(self):
        object_id = self.next_id
        self.next_id += 1
        return object_id

    def send(self, object_id, opcode, payload=b""):
        size = 8 + len(payload)
        self.sock.sendall(struct.pack("<II", object_id, (size << 16) | opcode) + payload)

    def events(self):
        """Yield (object_id, opcode, payload) for each event that has fully arrived."""
        while True:
            while len(self.buffer) < 8 or len(self.buffer) < (struct.unpack_from("<I", self.buffer, 4)[0] >> 16):
                chunk = self.sock.recv(65536)
                if not chunk:
                    return
                self.buffer += chunk
            object_id, word = struct.unpack_from("<II", self.buffer)
            size = word >> 16
            payload = self.buffer[8:size]
            self.buffer = self.buffer[size:]
            yield object_id, word & 0xFFFF, payload

    def roundtrip(self, handle=None):
        """wl_display.sync, handing every event before its done to `handle`."""
        callback = self.new_id()
        self.send(1, 0, struct.pack("<I", callback))
        for object_id, opcode, payload in self.events():
            if object_id == callback:
                return
            if object_id == 1 and opcode == 0:
                _, code = struct.unpack_from("<II", payload)
                message = string_at(payload, 8)[0]
                raise SystemExit("Wayland error %d: %s" % (code, message))
            if handle:
                handle(object_id, opcode, payload)
        raise SystemExit("The compositor closed the connection")


def wl_string(text):
    data = text.encode() + b"\0"
    return struct.pack("<I", len(data)) + data + b"\0" * (-len(data) % 4)


def string_at(payload, offset):
    (length,) = struct.unpack_from("<I", payload, offset)
    text = payload[offset + 4:offset + 4 + length - 1].decode()
    return text, offset + 4 + length + (-length % 4)


def millis():
    return int(time.monotonic() * 1000) & 0xFFFFFFFF


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("x", type=int)
    parser.add_argument("y", type=int)
    parser.add_argument("button", nargs="?", default="left", choices=[*BUTTONS, "none"])
    parser.add_argument("--width", type=int, default=1920, help="width of the layout")
    parser.add_argument("--height", type=int, default=1080, help="height of the layout")
    args = parser.parse_args()

    display = os.environ.get("WAYLAND_DISPLAY")
    if not display:
        raise SystemExit("WAYLAND_DISPLAY is not set")
    path = display if display.startswith("/") else os.path.join(os.environ["XDG_RUNTIME_DIR"], display)
    conn = Connection(path)

    registry = conn.new_id()
    conn.send(1, 1, struct.pack("<I", registry))
    globals_ = {}

    def on_global(object_id, opcode, payload):
        if object_id == registry and opcode == 0:
            (name,) = struct.unpack_from("<I", payload)
            interface, offset = string_at(payload, 4)
            (version,) = struct.unpack_from("<I", payload, offset)
            globals_[interface] = (name, version)

    conn.roundtrip(on_global)
    interface = "zwlr_virtual_pointer_manager_v1"
    if interface not in globals_:
        raise SystemExit("%s does not offer %s" % (display, interface))
    name, version = globals_[interface]
    manager = conn.new_id()
    conn.send(registry, 0, struct.pack("<I", name) + wl_string(interface) + struct.pack("<II", min(version, 1), manager))

    # create_virtual_pointer(seat: null, id)
    pointer = conn.new_id()
    conn.send(manager, 0, struct.pack("<II", 0, pointer))

    x = max(0, min(args.x, args.width - 1))
    y = max(0, min(args.y, args.height - 1))
    # motion_absolute(time, x, y, x_extent, y_extent), then frame
    conn.send(pointer, 1, struct.pack("<IIIII", millis(), x, y, args.width, args.height))
    conn.send(pointer, 4)
    conn.roundtrip()

    if args.button != "none":
        time.sleep(0.05)
        for state in (1, 0):
            conn.send(pointer, 2, struct.pack("<III", millis(), BUTTONS[args.button], state))
            conn.send(pointer, 4)
            conn.roundtrip()
            time.sleep(0.04)

    # The cursor stays where it was moved; destroy only drops the device
    conn.send(pointer, 8)
    conn.roundtrip()
    return 0


if __name__ == "__main__":
    sys.exit(main())
