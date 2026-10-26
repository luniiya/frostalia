#!/usr/bin/env python3
"""Clicks at a point on the Hyprland desktop through a virtual uinput mouse, so scripts
can open surfaces that only a click opens (tray menus, context menus).

Usage: Scripts/dev/click.py X Y [left|right|middle|none]
  X, Y are global layout coordinates, as `hyprctl cursorpos` prints them.
  "none" only moves the pointer there (to hover something).
Needs write access to /dev/uinput.
"""
import fcntl
import os
import struct
import subprocess
import sys
import time

EV_SYN, EV_KEY, EV_REL = 0, 1, 2
REL_X, REL_Y = 0, 1
BUTTONS = {"left": 0x110, "right": 0x111, "middle": 0x112}

UI_SET_EVBIT = 0x40045564
UI_SET_KEYBIT = 0x40045565
UI_SET_RELBIT = 0x40045566
UI_DEV_SETUP = 0x405C5503
UI_DEV_CREATE = 0x5501
UI_DEV_DESTROY = 0x5502


def event(fd, type_, code, value):
    os.write(fd, struct.pack("llHHi", 0, 0, type_, code, value))


def click(x, y, button="left"):
    code = BUTTONS.get(button)
    fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
    try:
        fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
        fcntl.ioctl(fd, UI_SET_EVBIT, EV_REL)
        for key in BUTTONS.values():
            fcntl.ioctl(fd, UI_SET_KEYBIT, key)
        fcntl.ioctl(fd, UI_SET_RELBIT, REL_X)
        fcntl.ioctl(fd, UI_SET_RELBIT, REL_Y)
        # struct uinput_setup: input_id (bustype, vendor, product, version), name[80], ff_effects_max
        setup = struct.pack("HHHH80sI", 0x06, 0x1234, 0x5678, 1, b"frostalia-click", 0)
        fcntl.ioctl(fd, UI_DEV_SETUP, setup)
        fcntl.ioctl(fd, UI_DEV_CREATE)
        # The compositor picks the new device up asynchronously
        time.sleep(0.4)
        subprocess.run(["hyprctl", "dispatch", f"hl.dsp.cursor.move({{x={x},y={y}}})"], check=True, capture_output=True)
        # A zero-length nudge from the device itself, so the surface under the cursor gets pointer focus
        event(fd, EV_REL, REL_X, 1)
        event(fd, EV_SYN, 0, 0)
        event(fd, EV_REL, REL_X, -1)
        event(fd, EV_SYN, 0, 0)
        time.sleep(0.1)
        if code is not None:
            event(fd, EV_KEY, code, 1)
            event(fd, EV_SYN, 0, 0)
            time.sleep(0.05)
            event(fd, EV_KEY, code, 0)
            event(fd, EV_SYN, 0, 0)
            time.sleep(0.1)
        fcntl.ioctl(fd, UI_DEV_DESTROY)
    finally:
        os.close(fd)


if __name__ == "__main__":
    if len(sys.argv) not in (3, 4) or (len(sys.argv) == 4 and sys.argv[3] not in (*BUTTONS, "none")):
        sys.exit(__doc__)
    click(int(float(sys.argv[1])), int(float(sys.argv[2])), sys.argv[3] if len(sys.argv) == 4 else "left")
