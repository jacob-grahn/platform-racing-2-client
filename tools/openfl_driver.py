#!/usr/bin/env python3
"""
openfl_driver.py - drive the PR2 OpenFL HTML5 build for visual checks.

Commands:
  shot <out.png>                serve export/html5/bin and capture a screenshot
  fps                           run the build and validate logged FPS samples
  debug-state                   read and optionally validate harness debug state
  sequence <script.json>        replay timed screenshot actions

Shot options:
  --root <dir>                  HTML root, default export/html5/bin
  --delay <seconds>             wait before capture, default 1.5
  --query <query>               query string to append to index.html
  --browser <path>              Chrome/Chromium binary path
  --fps-duration <seconds>      FPS validation duration, default 30.0
  --fps-target <fps>            FPS validation target, default 27
  --fps-tolerance <fps>         FPS validation tolerance, default 5
  --expect <key=value>          expected debug-state field, repeatable

Sequence script format:
  {
    "query": "hat=16&render=composite",
    "steps": [
      {"time": 0.0, "action": "keyDown", "key": "right"},
      {"time": 1.0, "action": "keyUp", "key": "right"},
      {"time": 1.1, "action": "debug-state", "expect": {"grounded": "true"}},
      {"time": 1.2, "action": "shot", "out": "test/output/run.png"}
    ]
  }

  A bare list of steps is also accepted. Sequence actions: keyDown, keyUp,
  tap, hold, click, shot, debug-state, body-attribute.
"""

import argparse
import contextlib
import base64
import hashlib
import http.server
import json
import os
import re
import shutil
import socket
import socketserver
import struct
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request
import zlib

from pr2_sequence import load_sequence as load_pr2_sequence
from pr2_sequence import require_field

DEFAULT_ROOT = os.path.join("export", "html5", "bin")
DEFAULT_BROWSER_PATHS = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "google-chrome",
    "chromium",
    "chromium-browser",
]

KEY_DEFINITIONS = {
    "left": {"key": "ArrowLeft", "code": "ArrowLeft", "windowsVirtualKeyCode": 37},
    "right": {"key": "ArrowRight", "code": "ArrowRight", "windowsVirtualKeyCode": 39},
    "up": {"key": "ArrowUp", "code": "ArrowUp", "windowsVirtualKeyCode": 38},
    "down": {"key": "ArrowDown", "code": "ArrowDown", "windowsVirtualKeyCode": 40},
    "space": {"key": " ", "code": "Space", "windowsVirtualKeyCode": 32, "text": " "},
    "a": {"key": "a", "code": "KeyA", "windowsVirtualKeyCode": 65, "text": "a"},
    "d": {"key": "d", "code": "KeyD", "windowsVirtualKeyCode": 68, "text": "d"},
    "w": {"key": "w", "code": "KeyW", "windowsVirtualKeyCode": 87, "text": "w"},
    "s": {"key": "s", "code": "KeyS", "windowsVirtualKeyCode": 83, "text": "s"},
    "c": {"key": "c", "code": "KeyC", "windowsVirtualKeyCode": 67, "text": "c"},
}


class QuietHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def handle(self):
        try:
            super().handle()
        except BrokenPipeError:
            pass


@contextlib.contextmanager
def serve(root):
    abs_root = os.path.abspath(root)
    if not os.path.exists(os.path.join(abs_root, "index.html")):
        raise SystemExit(f"Missing OpenFL HTML export: {abs_root}/index.html")

    handler = lambda *args, **kwargs: QuietHTTPRequestHandler(*args, directory=abs_root, **kwargs)
    with socketserver.TCPServer(("127.0.0.1", 0), handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            yield f"http://127.0.0.1:{server.server_address[1]}/index.html"
        finally:
            server.shutdown()


def resolve_browser(explicit_path):
    if explicit_path:
        return explicit_path

    for candidate in DEFAULT_BROWSER_PATHS:
        if os.path.isabs(candidate) and os.path.exists(candidate):
            return candidate
        if not os.path.isabs(candidate):
            resolved = shutil_which(candidate)
            if resolved:
                return resolved

    raise SystemExit("Could not find a Chrome/Chromium binary. Pass --browser <path>.")


def shutil_which(command):
    for directory in os.environ.get("PATH", "").split(os.pathsep):
        path = os.path.join(directory, command)
        if os.path.exists(path) and os.access(path, os.X_OK):
            return path
    return None


def capture_shot(out_path, root, delay, browser_path, query=""):
    browser = resolve_browser(browser_path)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    virtual_time_ms = max(0, int(delay * 1000))

    with serve(root) as url:
        url = append_query(url, query)
        command = [
            browser,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--window-size=550,400",
            f"--virtual-time-budget={virtual_time_ms}",
            f"--screenshot={out_path}",
            url,
        ]
        result = subprocess.run(command, text=True, capture_output=True)
        if result.returncode != 0 and "old headless mode" in result.stderr.lower():
            command[1] = "--headless"
            result = subprocess.run(command, text=True, capture_output=True)
        if result.returncode != 0:
            if result.stdout:
                print(result.stdout, file=sys.stderr, end="")
            if result.stderr:
                print(result.stderr, file=sys.stderr, end="")
            result.check_returncode()

    stats = analyze_png(out_path)
    print(
        f"Shot saved: {out_path} "
        f"({stats['width']}x{stats['height']}, uniqueColors={stats['unique_colors']}, "
        f"nonBackgroundPixels={stats['non_background_pixels']})"
    )


def check_fps(root, duration, target, tolerance, browser_path, query=""):
    browser = resolve_browser(browser_path)

    with serve(root) as url:
        url = append_query(url, query)
        samples = run_browser_and_read_fps(browser, url, duration)

    expected_sample_count = int(duration)
    checked_samples = samples[-expected_sample_count:]
    if len(checked_samples) < expected_sample_count:
        raise SystemExit(f"Only captured {len(checked_samples)} FPS samples, expected {expected_sample_count}: {samples}")

    low = target - tolerance
    high = target + tolerance
    failures = [(index + 1, sample) for index, sample in enumerate(checked_samples) if sample < low or sample > high]
    sample_text = ",".join(str(sample) for sample in checked_samples)
    print(f"FPS samples ({len(checked_samples)}s): {sample_text}")
    print(f"FPS range: min={min(checked_samples)} max={max(checked_samples)} target={target} tolerance=+/-{tolerance}")
    if failures:
        failure_text = ", ".join(f"{second}s={sample}" for second, sample in failures)
        raise SystemExit(f"FPS validation failed: {failure_text}")
    print("FPS validation passed.")


def check_debug_state(root, delay, browser_path, query, expected):
    browser = resolve_browser(browser_path)

    with serve(root) as url:
        url = append_query(url, query)
        state_text = run_browser_and_read_debug_state(browser, url, delay)

    state = parse_debug_state(state_text)
    print("Debug state:", state_text)

    failures = []
    for expectation in expected:
        key, expected_value = parse_expectation(expectation)
        actual_value = state.get(key)
        if actual_value != expected_value:
            failures.append((key, expected_value, actual_value))

    if failures:
        for key, expected_value, actual_value in failures:
            print(f"Expected {key}={expected_value}, got {actual_value}", file=sys.stderr)
        raise SystemExit("Debug-state validation failed.")

    if expected:
        print(f"Debug-state validation passed ({len(expected)} expectations).")


def run_browser_and_read_debug_state(browser, url, delay):
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-openfl-chrome-")
    command = [
        browser,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--window-size=550,400",
        f"--remote-debugging-port={debug_port}",
        f"--user-data-dir={user_data_dir}",
        url,
    ]
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        page_ws_url = wait_for_page_websocket(debug_port)
        time.sleep(delay)
        state_text = cdp_evaluate(page_ws_url, 'document.body.getAttribute("data-pr2-debug-state") || ""')
        if not state_text:
            raise SystemExit("OpenFL harness did not expose data-pr2-debug-state.")
        return state_text
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        shutil.rmtree(user_data_dir, ignore_errors=True)


@contextlib.contextmanager
def browser_devtools_session(browser, url):
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-openfl-chrome-")
    command = [
        browser,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--window-size=550,400",
        f"--remote-debugging-port={debug_port}",
        f"--user-data-dir={user_data_dir}",
        url,
    ]
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    ws = None
    try:
        page_ws_url = wait_for_page_websocket(debug_port)
        ws = DevToolsSession(page_ws_url)
        ws.request("Page.bringToFront")
        ws.request("Emulation.setDeviceMetricsOverride", {
            "width": 550,
            "height": 400,
            "deviceScaleFactor": 1,
            "mobile": False,
        })
        yield ws
    finally:
        if ws is not None:
            ws.close()
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        shutil.rmtree(user_data_dir, ignore_errors=True)


def parse_debug_state(state_text):
    state = {}
    for part in state_text.split(";"):
        if not part:
            continue
        key, separator, value = part.partition("=")
        if not separator:
            raise SystemExit(f"Malformed debug-state field: {part}")
        state[key] = value
    return state


def parse_expectation(expectation):
    key, separator, value = expectation.partition("=")
    if not separator or not key:
        raise SystemExit(f"Expected --expect key=value, got: {expectation}")
    return key, value


def run_browser_and_read_fps(browser, url, duration):
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-openfl-chrome-")
    command = [
        browser,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--window-size=550,400",
        f"--remote-debugging-port={debug_port}",
        f"--user-data-dir={user_data_dir}",
        url,
    ]
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        page_ws_url = wait_for_page_websocket(debug_port)
        time.sleep(duration + 2.0)
        raw_samples = cdp_evaluate(page_ws_url, 'document.body.getAttribute("data-pr2-fps-samples") || ""')
        return [int(value) for value in raw_samples.split(",") if value]
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        shutil.rmtree(user_data_dir, ignore_errors=True)


def reserve_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def wait_for_page_websocket(debug_port):
    deadline = time.time() + 10
    last_error = None
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{debug_port}/json", timeout=0.5) as response:
                targets = json.loads(response.read().decode("utf-8"))
            for target in targets:
                if target.get("type") == "page" and target.get("webSocketDebuggerUrl"):
                    return target["webSocketDebuggerUrl"]
        except Exception as error:
            last_error = error
        time.sleep(0.1)
    raise SystemExit(f"Timed out waiting for Chrome DevTools page target: {last_error}")


def cdp_evaluate(ws_url, expression):
    ws = DevToolsSession(ws_url)
    try:
        response = ws.request("Runtime.evaluate", {
            "expression": expression,
            "returnByValue": True,
        })
    finally:
        ws.close()

    if "error" in response:
        raise SystemExit(f"Chrome DevTools evaluation failed: {response['error']}")
    return response.get("result", {}).get("result", {}).get("value", "")


class DevToolsSession:
    def __init__(self, url):
        self.ws = WebSocket(url)
        self.next_id = 1

    def request(self, method, params=None):
        request_id = self.next_id
        self.next_id += 1
        payload = {"id": request_id, "method": method}
        if params is not None:
            payload["params"] = params
        response = self.ws.request(payload)
        if "error" in response:
            raise SystemExit(f"Chrome DevTools {method} failed: {response['error']}")
        return response

    def evaluate(self, expression):
        response = self.request("Runtime.evaluate", {
            "expression": expression,
            "returnByValue": True,
        })
        return response.get("result", {}).get("result", {}).get("value", "")

    def close(self):
        self.ws.close()


class WebSocket:
    def __init__(self, url):
        match = re.match(r"ws://([^/:]+):(\d+)(/.*)", url)
        if not match:
            raise SystemExit(f"Unsupported WebSocket URL: {url}")
        host, port, path = match.group(1), int(match.group(2)), match.group(3)
        self.socket = socket.create_connection((host, port), timeout=5)
        key = base64.b64encode(os.urandom(16)).decode("ascii")
        request = (
            f"GET {path} HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            "Sec-WebSocket-Version: 13\r\n\r\n"
        )
        self.socket.sendall(request.encode("ascii"))
        response = self.socket.recv(4096)
        if b" 101 " not in response.split(b"\r\n", 1)[0]:
            raise SystemExit(f"WebSocket handshake failed: {response.decode('utf-8', 'replace')}")

    def request(self, payload):
        self.send_text(json.dumps(payload))
        while True:
            message = json.loads(self.recv_text())
            if message.get("id") == payload["id"]:
                return message

    def send_text(self, text):
        data = text.encode("utf-8")
        mask = os.urandom(4)
        header = bytearray([0x81])
        length = len(data)
        if length < 126:
            header.append(0x80 | length)
        elif length < 65536:
            header.append(0x80 | 126)
            header.extend(struct.pack(">H", length))
        else:
            header.append(0x80 | 127)
            header.extend(struct.pack(">Q", length))
        header.extend(mask)
        masked = bytes(byte ^ mask[index % 4] for index, byte in enumerate(data))
        self.socket.sendall(bytes(header) + masked)

    def recv_text(self):
        while True:
            first = self.read_exact(2)
            opcode = first[0] & 0x0F
            length = first[1] & 0x7F
            if length == 126:
                length = struct.unpack(">H", self.read_exact(2))[0]
            elif length == 127:
                length = struct.unpack(">Q", self.read_exact(8))[0]
            masked = (first[1] & 0x80) != 0
            mask = self.read_exact(4) if masked else None
            payload = self.read_exact(length)
            if masked:
                payload = bytes(byte ^ mask[index % 4] for index, byte in enumerate(payload))
            if opcode == 0x8:
                raise SystemExit("WebSocket closed before receiving DevTools response")
            if opcode == 0x1:
                return payload.decode("utf-8")

    def read_exact(self, length):
        chunks = bytearray()
        while len(chunks) < length:
            chunk = self.socket.recv(length - len(chunks))
            if not chunk:
                raise SystemExit("WebSocket connection closed unexpectedly")
            chunks.extend(chunk)
        return bytes(chunks)

    def close(self):
        with contextlib.suppress(Exception):
            self.socket.close()


def run_sequence(script_path, root, browser_path):
    browser = resolve_browser(browser_path)
    query, steps = load_pr2_sequence(script_path, normalize_hold=True)

    with serve(root) as url:
        url = append_query(url, query)
        with browser_devtools_session(browser, url) as devtools:
            run_sequence_steps(devtools, steps)


def run_sequence_steps(devtools, steps):
    start = time.monotonic()
    for step in steps:
        wait = start + step["time"] - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        run_sequence_step(devtools, step)


def run_sequence_step(devtools, step):
    action = step["action"]
    if action == "keyDown":
        dispatch_key(devtools, "keyDown", require_key(step))
    elif action == "keyUp":
        dispatch_key(devtools, "keyUp", require_key(step))
    elif action == "tap":
        key = require_key(step)
        dispatch_key(devtools, "keyDown", key)
        dispatch_key(devtools, "keyUp", key)
    elif action == "click":
        dispatch_click(devtools, require_coordinate(step, "x"), require_coordinate(step, "y"))
    elif action == "shot":
        capture_devtools_shot(devtools, require_field(step, "out"))
    elif action == "debug-state":
        validate_sequence_debug_state(devtools, step.get("expect", {}))
    elif action == "body-attribute":
        validate_sequence_body_attribute(devtools, require_field(step, "name"), require_field(step, "value"))
    else:
        raise SystemExit(f"Unsupported OpenFL sequence action: {action}")


def dispatch_key(devtools, event_type, key_name):
    definition = KEY_DEFINITIONS.get(key_name.lower())
    if definition is None:
        raise SystemExit(f"Unknown key '{key_name}'. Valid: {', '.join(sorted(KEY_DEFINITIONS))}")
    params = dict(definition)
    cdp_event_type = "rawKeyDown" if event_type == "keyDown" and "text" not in params else event_type
    params["type"] = cdp_event_type
    params["nativeVirtualKeyCode"] = params["windowsVirtualKeyCode"]
    if event_type == "keyUp":
        params.pop("text", None)
    devtools.request("Input.dispatchKeyEvent", params)
    if not dispatch_harness_key(devtools, event_type, definition):
        dispatch_dom_key(devtools, event_type, definition)
    print(f"{event_type}: {key_name}")


def dispatch_harness_key(devtools, event_type, definition):
    pressed = event_type == "keyDown"
    expression = """
(() => {
  if (typeof window.__pr2HarnessSetKeyCode !== "function") {
    return false;
  }
  window.__pr2HarnessSetKeyCode(%d, %s);
  return true;
})()
""" % (
        definition["windowsVirtualKeyCode"],
        json.dumps(pressed),
    )
    return devtools.evaluate(expression) is True


def dispatch_dom_key(devtools, event_type, definition):
    dom_event_type = "keydown" if event_type == "keyDown" else "keyup"
    key_code = definition["windowsVirtualKeyCode"]
    expression = """
(() => {
  const event = new KeyboardEvent(%s, {
    key: %s,
    code: %s,
    bubbles: true,
    cancelable: true
  });
  Object.defineProperty(event, "keyCode", {get: () => %d});
  Object.defineProperty(event, "which", {get: () => %d});
  const targets = [window, document, document.body, document.activeElement];
  for (const canvas of document.querySelectorAll("canvas")) {
    targets.push(canvas);
  }
  for (const target of targets) {
    if (target) {
      target.dispatchEvent(event);
    }
  }
})()
""" % (
        json.dumps(dom_event_type),
        json.dumps(definition["key"]),
        json.dumps(definition["code"]),
        key_code,
        key_code,
    )
    devtools.evaluate(expression)


def dispatch_click(devtools, x, y):
    base_params = {
        "x": x,
        "y": y,
        "button": "left",
        "clickCount": 1,
    }
    devtools.request("Input.dispatchMouseEvent", dict(base_params, type="mouseMoved", button="none", buttons=0))
    devtools.request("Input.dispatchMouseEvent", dict(base_params, type="mousePressed", buttons=1))
    devtools.request("Input.dispatchMouseEvent", dict(base_params, type="mouseReleased", buttons=0))
    print(f"click: {x},{y}")


def capture_devtools_shot(devtools, out_path):
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    response = devtools.request("Page.captureScreenshot", {
        "format": "png",
        "captureBeyondViewport": False,
    })
    image_data = response.get("result", {}).get("data")
    if not image_data:
        raise SystemExit("Chrome DevTools did not return screenshot data.")
    with open(out_path, "wb") as file:
        file.write(base64.b64decode(image_data))
    stats = analyze_png(out_path)
    print(
        f"Shot saved: {out_path} "
        f"({stats['width']}x{stats['height']}, uniqueColors={stats['unique_colors']}, "
        f"nonBackgroundPixels={stats['non_background_pixels']})"
    )


def validate_sequence_debug_state(devtools, expected):
    if not isinstance(expected, dict):
        raise SystemExit("debug-state expect must be an object of key/value pairs.")
    state_text = wait_for_sequence_debug_state(devtools)
    if not state_text:
        raise SystemExit("OpenFL harness did not expose data-pr2-debug-state.")
    state = parse_debug_state(state_text)
    print("Debug state:", state_text)

    failures = []
    for key, expected_value in expected.items():
        actual_value = state.get(key)
        expected_value = str(expected_value)
        if actual_value != expected_value:
            failures.append((key, expected_value, actual_value))

    if failures:
        for key, expected_value, actual_value in failures:
            print(f"Expected {key}={expected_value}, got {actual_value}", file=sys.stderr)
        raise SystemExit("Debug-state validation failed.")
    if expected:
        print(f"Debug-state validation passed ({len(expected)} expectations).")


def validate_sequence_body_attribute(devtools, name, expected_value):
    actual_value = wait_for_body_attribute(devtools, name, expected_value)
    print(f"Body attribute {name}: {actual_value}")
    if actual_value != expected_value:
        raise SystemExit(f"Expected body attribute {name}={expected_value}, got {actual_value}")
    print(f"Body attribute validation passed ({name}).")


def wait_for_sequence_debug_state(devtools):
    deadline = time.monotonic() + 5.0
    while time.monotonic() < deadline:
        state_text = devtools.evaluate('document.body.getAttribute("data-pr2-debug-state") || ""')
        if state_text:
            return state_text
        time.sleep(0.1)
    return ""


def wait_for_body_attribute(devtools, name, expected_value):
    deadline = time.monotonic() + 5.0
    expression = f'document.body.getAttribute({json.dumps(name)}) || ""'
    last_value = ""
    while time.monotonic() < deadline:
        last_value = devtools.evaluate(expression)
        if last_value == expected_value:
            return last_value
        time.sleep(0.1)
    return last_value


def require_key(step):
    return require_field(step, "key")


def require_coordinate(step, field):
    value = require_field(step, field)
    try:
        return float(value)
    except (TypeError, ValueError):
        raise SystemExit(f"Sequence {step.get('action')} step requires numeric {field}: {step}")


def append_query(url, query):
    if not query:
        return url
    return f"{url}?{query[1:] if query.startswith('?') else query}"


def analyze_png(path):
    with open(path, "rb") as file:
        data = file.read()

    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"Not a PNG file: {path}")

    pos = 8
    width = height = bit_depth = color_type = None
    compressed = bytearray()
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        chunk_type = data[pos + 4 : pos + 8]
        chunk_data = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk_data[:10])
        elif chunk_type == b"IDAT":
            compressed.extend(chunk_data)
        elif chunk_type == b"IEND":
            break

    if bit_depth != 8 or color_type not in (2, 6):
        raise SystemExit(f"Unsupported PNG format in {path}: bitDepth={bit_depth} colorType={color_type}")

    channels = 3 if color_type == 2 else 4
    stride = width * channels
    raw = zlib.decompress(bytes(compressed))
    previous = [0] * stride
    pixels = []
    offset = 0

    for _ in range(height):
        filter_type = raw[offset]
        offset += 1
        scanline = list(raw[offset : offset + stride])
        offset += stride
        recon = unfilter_scanline(filter_type, scanline, previous, channels)
        pixels.extend(tuple(recon[i : i + channels]) for i in range(0, stride, channels))
        previous = recon

    background = pixels[0]
    unique_colors = len(set(pixels))
    non_background_pixels = sum(1 for pixel in pixels if pixel != background)
    return {
        "width": width,
        "height": height,
        "unique_colors": unique_colors,
        "non_background_pixels": non_background_pixels,
    }


def unfilter_scanline(filter_type, scanline, previous, channels):
    result = [0] * len(scanline)
    for i, value in enumerate(scanline):
        left = result[i - channels] if i >= channels else 0
        up = previous[i]
        up_left = previous[i - channels] if i >= channels else 0
        if filter_type == 0:
            predictor = 0
        elif filter_type == 1:
            predictor = left
        elif filter_type == 2:
            predictor = up
        elif filter_type == 3:
            predictor = (left + up) // 2
        elif filter_type == 4:
            predictor = paeth(left, up, up_left)
        else:
            raise SystemExit(f"Unsupported PNG filter type: {filter_type}")
        result[i] = (value + predictor) & 0xFF
    return result


def paeth(left, up, up_left):
    estimate = left + up - up_left
    distance_left = abs(estimate - left)
    distance_up = abs(estimate - up)
    distance_up_left = abs(estimate - up_left)
    if distance_left <= distance_up and distance_left <= distance_up_left:
        return left
    if distance_up <= distance_up_left:
        return up
    return up_left


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=DEFAULT_ROOT)
    parser.add_argument("--delay", type=float, default=1.5)
    parser.add_argument("--query", default="")
    parser.add_argument("--browser")
    parser.add_argument("--fps-duration", type=float, default=30.0)
    parser.add_argument("--fps-target", type=int, default=27)
    parser.add_argument("--fps-tolerance", type=int, default=5)
    parser.add_argument("--expect", action="append", default=[])
    subparsers = parser.add_subparsers(dest="command", required=True)

    shot = subparsers.add_parser("shot")
    shot.add_argument("out")

    sequence = subparsers.add_parser("sequence")
    sequence.add_argument("script")

    subparsers.add_parser("fps")
    subparsers.add_parser("debug-state")

    args = parser.parse_args()
    if args.command == "shot":
        capture_shot(args.out, args.root, args.delay, args.browser, args.query)
    elif args.command == "sequence":
        run_sequence(args.script, args.root, args.browser)
    elif args.command == "fps":
        check_fps(args.root, args.fps_duration, args.fps_target, args.fps_tolerance, args.browser, args.query)
    elif args.command == "debug-state":
        check_debug_state(args.root, args.delay, args.browser, args.query, args.expect)


if __name__ == "__main__":
    main()
