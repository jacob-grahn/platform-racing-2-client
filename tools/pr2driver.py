#!/usr/bin/env python3
"""
pr2driver.py — drive the Platform Racing 2 Flash projector for parity testing.

Commands:
  --app <path>                  launch a specific Flash projector/SWF app
  launch                        open PR2 and wait for window
  shot <out.jpg>                window-only screenshot (auto-crops to game rect)
  click <x> <y>                 click at stage coords (focus-click + action-click)
  tap <key>                     single keypress (key name: left right up down space)
  type <text>                   type a unicode string into the focused field
  hold <key> <seconds>          key held for N seconds
  quit                          kill the Flash projector
  sequence <script.json>        replay a JSON input timeline (see format below)

Sequence script format:
  {
    "steps": [
      {"time": 0.0, "action": "click", "x": 275, "y": 200},
      {"time": 0.4, "action": "hold",  "key": "right", "seconds": 1.0},
      {"time": 2.0, "action": "shot",  "out": "run.jpg"}
    ]
  }
  A bare list of steps is also accepted. Actions fire at their time in seconds,
  relative to sequence start.

Key names: left right up down space
"""

import subprocess, sys, os, time, tempfile, shutil, textwrap, contextlib, plistlib
from PIL import Image

from pr2_sequence import load_sequence as load_pr2_sequence

APP_NAME   = "Platform Racing 2"
APP_PATH   = None        # overridden by --app flag
PROC_NAME  = "Flash Player"
TITLE_H    = 28          # Flash Projector title bar height (points)
TRACE_FLAG = "physics-trace.flag"

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
    try:
        raw = subprocess.check_output(["osascript", "-e", script], text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        raw = _run_swift_output(_SWIFT_WIN_RECT)
    nums = [int(n.strip()) for n in raw.split(",")]
    return nums[0], nums[1], nums[2], nums[3]  # x, y, w, h

def _stage_to_screen(sx, sy):
    """Convert PR2 stage coords (origin = top-left of SWF canvas) to screen points."""
    wx, wy, _, _ = _win_rect()
    return wx + sx, wy + TITLE_H + sy

def _window_id():
    return _run_swift_output(_SWIFT_WIN_ID)

# ---------------------------------------------------------------------------
# Swift one-liners compiled on the fly
# ---------------------------------------------------------------------------

_SWIFT_WIN_RECT = textwrap.dedent("""\
    import CoreGraphics
    import Foundation
    let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
    let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID)! as NSArray
    for case let window as NSDictionary in windows {
        let owner = window[kCGWindowOwnerName as String] as? String ?? ""
        let layer = window[kCGWindowLayer as String] as? Int ?? -1
        guard owner == "Flash Player", layer == 0 else { continue }
        guard let bounds = window[kCGWindowBounds as String] as? NSDictionary else { continue }
        let x = bounds["X"] as? Int ?? 0
        let y = bounds["Y"] as? Int ?? 0
        let width = bounds["Width"] as? Int ?? 0
        let height = bounds["Height"] as? Int ?? 0
        guard width > 0, height > 0 else { continue }
        print("\\(x),\\(y),\\(width),\\(height)")
        exit(0)
    }
    exit(1)
""")

_SWIFT_WIN_ID = textwrap.dedent("""\
    import CoreGraphics
    import Foundation

    let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
    let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID)! as NSArray
    for case let window as NSDictionary in windows {
        let owner = window[kCGWindowOwnerName as String] as? String ?? ""
        let layer = window[kCGWindowLayer as String] as? Int ?? -1
        guard owner == "Flash Player", layer == 0 else { continue }
        guard let number = window[kCGWindowNumber as String] as? Int else { continue }
        print(number)
        exit(0)
    }
    exit(1)
""")

_SWIFT_CLICK = textwrap.dedent("""\
    import AppKit
    import ApplicationServices
    import CoreGraphics
    import Foundation
    @_silgen_name("GetProcessForPID")
    func PR2GetProcessForPID(_ pid: pid_t, _ psn: UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus
    @_silgen_name("SetFrontProcessWithOptions")
    func PR2SetFrontProcessWithOptions(_ psn: UnsafePointer<ProcessSerialNumber>, _ options: UInt32) -> OSStatus
    let x = Double(CommandLine.arguments[1])!
    let y = Double(CommandLine.arguments[2])!
    let p = CGPoint(x: x, y: y)
    let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.macromedia.Flash Player.app").first!
    var psn = ProcessSerialNumber()
    let processResult = PR2GetProcessForPID(app.processIdentifier, &psn)
    let frontResult = processResult == noErr
        ? PR2SetFrontProcessWithOptions(&psn, 2)
        : processResult
    usleep(300_000)
    guard frontResult == noErr else {
        fputs("Unable to make Flash Player frontmost before click (process=\\(processResult), front=\\(frontResult), active=\\(app.isActive)).\\n", stderr)
        exit(2)
    }
    let frontWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)! as NSArray
    for case let window as NSDictionary in frontWindows {
        if (window[kCGWindowLayer as String] as? Int ?? -1) == 0 {
            let owner = window[kCGWindowOwnerName as String] as? String ?? ""
            if owner != "Flash Player" {
                fputs("Frontmost normal window is \\(owner), not Flash Player.\\n", stderr)
            }
            break
        }
    }
    CGWarpMouseCursorPosition(p)
    CGAssociateMouseAndMouseCursorPosition(1)
    usleep(100_000)
    let source = CGEventSource(stateID: .hidSystemState)
    let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: p, mouseButton: .left)!
    down.setIntegerValueField(.mouseEventButtonNumber, value: 0)
    down.setIntegerValueField(.mouseEventClickState, value: 1)
    down.setDoubleValueField(.mouseEventPressure, value: 1)
    down.post(tap: .cghidEventTap)
    usleep(80_000)
    let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: p, mouseButton: .left)!
    up.setIntegerValueField(.mouseEventButtonNumber, value: 0)
    up.setIntegerValueField(.mouseEventClickState, value: 1)
    up.setDoubleValueField(.mouseEventPressure, value: 0)
    up.post(tap: .cghidEventTap)
    usleep(100_000)
""")

_SWIFT_TYPE = textwrap.dedent("""\
    import CoreGraphics
    import Foundation
    let text = CommandLine.arguments[1]
    let src = CGEventSource(stateID: .hidSystemState)
    for scalar in text.unicodeScalars {
        var unit = UniChar(scalar.value & 0xFFFF)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true) {
            down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unit)
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false) {
            up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unit)
            up.post(tap: .cghidEventTap)
        }
        usleep(25_000)
    }
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

def _run_swift_output(code, *args):
    path = _write_swift(code)
    try:
        swift = os.environ.get("PR2DRIVER_SWIFT")
        if not swift:
            swift = XCODE_SWIFT if os.path.exists(XCODE_SWIFT) else "swift"
        return subprocess.check_output([swift, path, *[str(a) for a in args]], text=True).strip()
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
        launched = subprocess.run(["open", APP_PATH], capture_output=True)
        if launched.returncode != 0 and APP_PATH.endswith(".app"):
            info_path = os.path.join(APP_PATH, "Contents", "Info.plist")
            with open(info_path, "rb") as info_file:
                executable = plistlib.load(info_file)["CFBundleExecutable"]
            executable_path = os.path.join(APP_PATH, "Contents", "MacOS", executable)
            subprocess.Popen([executable_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif launched.returncode != 0:
            launched.check_returncode()
    else:
        subprocess.run(["open", "-a", APP_NAME], check=True)
    print("Waiting for window...", end="", flush=True)
    for _ in range(30):
        time.sleep(0.5)
        try:
            _win_rect()
            print(" ready.")
            return
        except Exception:
            print(".", end="", flush=True)
    print("\nTimeout waiting for Flash Player window.")
    sys.exit(1)

def cmd_quit():
    subprocess.run(["killall", PROC_NAME], capture_output=True)
    print("Quit Flash Player.")

def cmd_shot(out_path):
    out_path = out_path.replace("{target}", "flash")
    out_dir = os.path.dirname(os.path.abspath(out_path))
    os.makedirs(out_dir, exist_ok=True)
    _, _, ww, wh = _win_rect()
    # Capture by window ID so an edge-pinned projector and multi-display
    # coordinates cannot make screencapture reject the evidence rectangle.
    sw, sh = ww, wh - TITLE_H
    fmt = "png" if out_path.lower().endswith(".png") else "jpeg"
    raw = out_path + ".raw.png"
    subprocess.run(
        ["screencapture", "-x", "-o", "-l", _window_id(), raw],
        check=True
    )
    with Image.open(raw) as image:
        scale = image.width / ww
        title_pixels = round(TITLE_H * scale)
        stage = image.crop((0, title_pixels, image.width, image.height))
        stage = stage.resize((sw, sh), Image.Resampling.LANCZOS)
        stage.save(out_path, format=fmt.upper())
    os.unlink(raw)
    print(f"Shot saved: {out_path}")

def _series_out_path(pattern, label_second, index):
    return (
        pattern
        .replace("{elapsed}", str(label_second))
        .replace("{elapsed03}", f"{label_second:03d}")
        .replace("{index}", str(index))
        .replace("{index03}", f"{index:03d}")
    )

def cmd_shot_series(pattern, duration, interval=1.0, start_second=0):
    if duration < 0:
        print("Shot series duration must be non-negative.", file=sys.stderr)
        sys.exit(1)
    if interval <= 0:
        print("Shot series interval must be positive.", file=sys.stderr)
        sys.exit(1)
    started = time.monotonic()
    count = int(duration / interval) + 1
    for index in range(count):
        due = started + index * interval
        wait = due - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        label_second = int(round(start_second + index * interval))
        cmd_shot(_series_out_path(pattern, label_second, index))

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

def cmd_type(text):
    _ensure_flash_focus()
    _run_swift(_SWIFT_TYPE, text)
    print(f"Typed {text!r}")

def cmd_tap(key):
    cmd_key_down(key)
    time.sleep(0.04)
    cmd_key_up(key)
    print(f"Tapped {key}")

def cmd_hold(key, seconds):
    if seconds < 0:
        print("Hold duration must be non-negative.", file=sys.stderr)
        sys.exit(1)
    cmd_key_down(key)
    time.sleep(seconds)
    cmd_key_up(key)
    print(f"Held {key} for {seconds:.3f}s")

def cmd_key_down(key):
    kc = _resolve_key(key)
    _ensure_flash_focus()
    _run_swift(_SWIFT_KEYDOWN, kc)

def cmd_key_up(key):
    kc = _resolve_key(key)
    _ensure_flash_focus()
    _run_swift(_SWIFT_KEYUP, kc)

def cmd_sequence(script_path):
    _, steps = load_pr2_sequence(script_path, allow_query=False)
    trace_flag = flash_trace_flag_path() if sequence_uses_console_trace(steps) else None
    if trace_flag:
        os.makedirs(os.path.dirname(trace_flag), exist_ok=True)
        with open(trace_flag, "w", encoding="utf-8") as file:
            file.write("1\n")
        print(f"physics trace flag enabled: {trace_flag}")
    try:
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
            elif action == "click-display-object":
                # Flash projector automation cannot inspect the AS3 display list.
                # Shared parity sequences therefore provide authored stage
                # coordinates as a fallback while OpenFL resolves the named live
                # display object and clicks its measured center.
                cmd_click(step["x"], step["y"])
            elif action == "keyDown":
                cmd_key_down(step["key"])
            elif action == "keyUp":
                cmd_key_up(step["key"])
            elif action == "tap":
                cmd_tap(step["key"])
            elif action == "typeText":
                cmd_type(step["text"])
            elif action == "hold":
                cmd_hold(step["key"], step["seconds"])
            elif action == "shot":
                cmd_shot(step["out"])
            elif action == "shotSeries":
                cmd_shot_series(
                    step["out"],
                    _parse_seconds(step.get("duration", 0)),
                    _parse_seconds(step.get("interval", 1.0)),
                    int(step.get("startSecond", step["time"])),
                )
            elif action == "saveConsoleTrace":
                print("saveConsoleTrace: Flash PR2TRACE lines are captured by tools/dmjv_trace_server.py")
            elif action == "saveConsoleTraceWindow":
                seconds = _parse_seconds(step.get("duration", 5.0))
                print(f"saveConsoleTraceWindow: waiting {seconds:.3f}s; Flash PR2TRACE lines are captured by tools/dmjv_trace_server.py")
                time.sleep(seconds)
            elif action == "quit":
                cmd_quit()
            else:
                print(f"Unknown action: {action}", file=sys.stderr)
    finally:
        if trace_flag:
            with contextlib.suppress(FileNotFoundError):
                os.remove(trace_flag)
            print(f"physics trace flag disabled: {trace_flag}")

def sequence_uses_console_trace(steps):
    return any(step.get("action") in ("saveConsoleTrace", "saveConsoleTraceWindow") for step in steps)

def flash_trace_flag_path():
    if APP_PATH:
        if APP_PATH.endswith(".app"):
            return os.path.join(APP_PATH, "Contents", "Resources", TRACE_FLAG)
        return os.path.join(os.path.dirname(os.path.abspath(APP_PATH)), TRACE_FLAG)
    return os.path.abspath(TRACE_FLAG)

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
    elif cmd == "type" and len(args) == 2:
        cmd_type(args[1])
    elif cmd == "hold" and len(args) == 3:
        cmd_hold(args[1], _parse_seconds(args[2]))
    elif cmd == "quit" and len(args) == 1:
        cmd_quit()
    elif cmd == "sequence" and len(args) == 2:
        cmd_sequence(args[1])
    else:
        print(__doc__); sys.exit(1)

if __name__ == "__main__":
    main()
