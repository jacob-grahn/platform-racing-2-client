#!/usr/bin/env python3
"""
pr2driver.py — drive the Platform Racing 2 Flash projector for parity testing.

Commands:
  --app <path>                  launch a specific Flash projector/SWF app
  launch                        open PR2 and wait for window
  shot <out.jpg>                window-only screenshot (auto-crops to game rect)
  click <x> <y>                 click at stage coords (focus-click + action-click)
  tap <key>                     single keypress (key name: left right up down space)
  hold <key> <seconds>          key held for N seconds
  sequence <script.json>        replay a JSON input timeline (see format below)

Sequence script format:
  [
    {"time": 0.0, "action": "click", "x": 275, "y": 200},
    {"time": 0.4, "action": "hold",  "key": "right", "seconds": 1.0},
    {"time": 2.0, "action": "shot",  "out": "run.jpg"}
  ]
  Actions fire at their time in seconds, relative to sequence start.

Key names: left right up down space
"""

import subprocess, sys, os, json, time, tempfile, shutil, textwrap

APP_NAME   = "Platform Racing 2"
APP_PATH   = None        # overridden by --app flag
PROC_NAME  = "Flash Player"
TITLE_H    = 28          # Flash Projector title bar height (points)

KEY_MAP = {
    "left":  123,
    "right": 124,
    "up":    126,
    "down":  125,
    "space":  49,
}

XCODE_SWIFT = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"

# ---------------------------------------------------------------------------
# Window geometry (always queried live — window can move)
# ---------------------------------------------------------------------------

def _win_rect():
    """Return (x, y, w, h) of the Flash Player window in screen points."""
    script = (
        'tell application "System Events" to tell process "' + PROC_NAME + '" '
        'to get {position, size} of window 1'
    )
    raw = subprocess.check_output(["osascript", "-e", script], text=True).strip()
    nums = [int(n.strip()) for n in raw.split(",")]
    return nums[0], nums[1], nums[2], nums[3]  # x, y, w, h

def _stage_to_screen(sx, sy):
    """Convert PR2 stage coords (origin = top-left of SWF canvas) to screen points."""
    wx, wy, _, _ = _win_rect()
    return wx + sx, wy + TITLE_H + sy

# ---------------------------------------------------------------------------
# Swift one-liners compiled on the fly
# ---------------------------------------------------------------------------

_SWIFT_CLICK = textwrap.dedent("""\
    import CoreGraphics
    import Foundation
    let x = Double(CommandLine.arguments[1])!
    let y = Double(CommandLine.arguments[2])!
    let p = CGPoint(x: x, y: y)
    let src = CGEventSource(stateID: .hidSystemState)
    CGEvent(mouseEventSource: src, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
    usleep(60_000)
    CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
    usleep(60_000)
    CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
""")

_SWIFT_KEYDOWN = textwrap.dedent("""\
    import CoreGraphics
    import Foundation
    let kc = CGKeyCode(CommandLine.arguments[1])!
    let src = CGEventSource(stateID: .hidSystemState)
    CGEvent(keyboardEventSource: src, virtualKey: kc, keyDown: true)?.post(tap: .cghidEventTap)
""")

_SWIFT_KEYUP = textwrap.dedent("""\
    import CoreGraphics
    import Foundation
    let kc = CGKeyCode(CommandLine.arguments[1])!
    let src = CGEventSource(stateID: .hidSystemState)
    CGEvent(keyboardEventSource: src, virtualKey: kc, keyDown: false)?.post(tap: .cghidEventTap)
""")

_SWIFT_FOCUS = textwrap.dedent("""\
    import AppKit
    let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.macromedia.Flash Player.app")
    apps.first?.activate(options: .activateIgnoringOtherApps)
    usleep(200_000)
""")

def _write_swift(code):
    f = tempfile.NamedTemporaryFile(suffix=".swift", mode="w", delete=False)
    f.write(code); f.close()
    return f.name

def _run_swift(code, *args):
    path = _write_swift(code)
    try:
        swift = os.environ.get("PR2DRIVER_SWIFT")
        if not swift:
            swift = XCODE_SWIFT if os.path.exists(XCODE_SWIFT) else "swift"
        result = subprocess.run([swift, path, *[str(a) for a in args]], text=True, capture_output=True)
        if result.returncode != 0:
            if result.stderr:
                print(result.stderr, file=sys.stderr, end="")
            if result.stdout:
                print(result.stdout, file=sys.stderr, end="")
            result.check_returncode()
    finally:
        os.unlink(path)

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_launch():
    # Kill any existing instance so we always start from a clean state
    subprocess.run(["killall", PROC_NAME], capture_output=True)
    time.sleep(1)
    if APP_PATH:
        subprocess.run(["open", APP_PATH], check=True)
    else:
        subprocess.run(["open", "-a", APP_NAME], check=True)
    print("Waiting for window...", end="", flush=True)
    for _ in range(30):
        time.sleep(0.5)
        try:
            _win_rect(); print(" ready."); return
        except Exception:
            print(".", end="", flush=True)
    print("\nTimeout waiting for Flash Player window.")
    sys.exit(1)

def cmd_shot(out_path):
    wx, wy, ww, wh = _win_rect()
    # Crop to the SWF stage only (exclude title bar)
    sx, sy = wx, wy + TITLE_H
    sw, sh = ww, wh - TITLE_H
    raw = out_path + ".raw.png"
    subprocess.run(
        ["screencapture", "-x", "-R", f"{sx},{sy},{sw},{sh}", raw],
        check=True
    )
    # Downscale to logical resolution (screencapture is 2x on Retina)
    subprocess.run(
        ["sips", "-Z", str(sw), "-s", "format", "jpeg", raw, "--out", out_path],
        check=True, capture_output=True
    )
    os.unlink(raw)
    print(f"Shot saved: {out_path}")

def _flash_is_frontmost():
    script = 'tell application "System Events" to get frontmost of process "' + PROC_NAME + '"'
    return subprocess.check_output(["osascript", "-e", script], text=True).strip() == "true"

def cmd_click(sx, sy):
    scx, scy = _stage_to_screen(sx, sy)
    if not _flash_is_frontmost():
        # focus-click first to activate the window, then the real click
        _run_swift(_SWIFT_CLICK, scx, scy)
        time.sleep(0.1)
    _run_swift(_SWIFT_CLICK, scx, scy)
    print(f"Clicked stage ({sx},{sy}) → screen ({scx},{scy})")

def _ensure_flash_focus():
    if not _flash_is_frontmost():
        _run_swift(_SWIFT_FOCUS)

def cmd_tap(key):
    kc = _resolve_key(key)
    _ensure_flash_focus()
    _run_swift(_SWIFT_KEYDOWN, kc)
    time.sleep(0.04)
    _run_swift(_SWIFT_KEYUP, kc)
    print(f"Tapped {key}")

def cmd_hold(key, seconds):
    kc = _resolve_key(key)
    if seconds < 0:
        print("Hold duration must be non-negative.", file=sys.stderr)
        sys.exit(1)
    _ensure_flash_focus()
    _run_swift(_SWIFT_KEYDOWN, kc)
    time.sleep(seconds)
    _run_swift(_SWIFT_KEYUP, kc)
    print(f"Held {key} for {seconds:.3f}s")

def cmd_sequence(script_path):
    with open(script_path) as f:
        steps = json.load(f)
    steps = sorted(steps, key=lambda s: s["time"])
    t0 = None  # set on first non-launch action
    for step in steps:
        action = step["action"]
        if action == "launch":
            cmd_launch()
            t0 = time.monotonic()
            continue
        if t0 is None:
            t0 = time.monotonic()
        target = t0 + step["time"]
        wait = target - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        if action == "click":
            cmd_click(step["x"], step["y"])
        elif action == "tap":
            cmd_tap(step["key"])
        elif action == "hold":
            cmd_hold(step["key"], step["seconds"])
        elif action == "shot":
            cmd_shot(step["out"])
        else:
            print(f"Unknown action: {action}", file=sys.stderr)

def _resolve_key(name):
    kc = KEY_MAP.get(name.lower())
    if kc is None:
        print(f"Unknown key '{name}'. Valid: {', '.join(KEY_MAP)}", file=sys.stderr)
        sys.exit(1)
    return kc

def _parse_seconds(value):
    try:
        seconds = float(value)
    except ValueError:
        print(f"Invalid seconds value: {value}", file=sys.stderr)
        sys.exit(1)
    if seconds < 0:
        print("Seconds value must be non-negative.", file=sys.stderr)
        sys.exit(1)
    return seconds

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    global APP_PATH
    args = sys.argv[1:]
    if not args:
        print(__doc__); sys.exit(0)

    while args and args[0].startswith("--"):
        flag = args[0]
        if flag == "--app" and len(args) >= 2:
            APP_PATH = args[1]
            args = args[2:]
        else:
            print(__doc__); sys.exit(1)
    if not args:
        print(__doc__); sys.exit(0)

    cmd = args[0]
    if cmd == "launch":
        cmd_launch()
    elif cmd == "shot" and len(args) == 2:
        cmd_shot(args[1])
    elif cmd == "click" and len(args) == 3:
        cmd_click(int(args[1]), int(args[2]))
    elif cmd == "tap" and len(args) == 2:
        cmd_tap(args[1])
    elif cmd == "hold" and len(args) == 3:
        cmd_hold(args[1], _parse_seconds(args[2]))
    elif cmd == "sequence" and len(args) == 2:
        cmd_sequence(args[1])
    else:
        print(__doc__); sys.exit(1)

if __name__ == "__main__":
    main()
