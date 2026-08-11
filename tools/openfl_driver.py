#!/usr/bin/env python3
"""
openfl_driver.py - drive the PR2 OpenFL HTML5 build for visual checks.

Commands:
  shot <out.png>                serve export/html5/bin and capture a screenshot
  fps                           run the build and validate logged FPS samples
  smooth60-flag                 validate opt-in and navigation query behavior
  smooth60-stability            prove the opt-in survives sustained browser load
  smooth60-replays              capture paired 30/60 gameplay replay scenes
  smooth60-benchmark            benchmark smooth presentation scene/device matrix
  debug-state                   read and optionally validate harness debug state
  sequence <script.json>        replay timed screenshot/navigation actions

Shot options:
  --root <dir>                  HTML root, default export/html5/bin
  --delay <seconds>             wait before capture, default 5.0
  --query <query>               query string to append to index.html
  --browser <path>              Chrome/Chromium binary path
  --base-url <url>              use an existing server (for example dev_proxy.py)
  --fps-duration <seconds>      FPS validation duration, default 30.0
  --fps-target <fps>            presented-frame target, default 30
  --fps-tolerance <fps>         presented-frame tolerance, default 5
  --simulation-fps-target <fps> simulation-tick target, default 30
  --simulation-fps-tolerance    simulation-tick tolerance, default 1
  --expect <key=value>          expected debug-state field, repeatable
  --metrics-out <path>          write JSON metrics collected by sequence metrics steps

Sequence script format:
  {
    "query": "hat=16",
    "steps": [
      {"time": 0.0, "action": "keyDown", "key": "right"},
      {"time": 1.0, "action": "keyUp", "key": "right"},
      {"time": 1.1, "action": "debug-state", "expect": {"grounded": "true"}},
      {"time": 1.2, "action": "shot", "out": "test/output/run.png"}
    ]
  }

  A bare list of steps is also accepted. Sequence actions: keyDown, keyUp,
  tap, hold, mouseMove, click, click-display-object, dragPath, typeText,
  rebuild-lobby, open-level-editor, level-editor-e2e, assert-level-editor-state,
  smooth60-replay, navigate, metrics, shot, debug-state, body-attribute.

  Sequences wait for the app to boot past the OpenFL preloader before the
  clock starts: step `time` offsets are measured from the moment `Main` sets
  the `data-pr2-app-ready` body attribute, not from browser launch. This means
  input is never dispatched into the preloader (where it would be silently
  dropped), so `time` values only need to account for in-app settling, not a
  guessed preload duration.
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
    "enter": {"key": "Enter", "code": "Enter", "windowsVirtualKeyCode": 13, "text": "\r"},
    "a": {"key": "a", "code": "KeyA", "windowsVirtualKeyCode": 65, "text": "a"},
    "d": {"key": "d", "code": "KeyD", "windowsVirtualKeyCode": 68, "text": "d"},
    "w": {"key": "w", "code": "KeyW", "windowsVirtualKeyCode": 87, "text": "w"},
    "s": {"key": "s", "code": "KeyS", "windowsVirtualKeyCode": 83, "text": "s"},
    "c": {"key": "c", "code": "KeyC", "windowsVirtualKeyCode": 67, "text": "c"},
}

SEQUENCE_METRIC_KEYS = [
    "Timestamp",
    "JSHeapUsedSize",
    "JSHeapTotalSize",
    "Nodes",
    "JSEventListeners",
    "Documents",
    "Frames",
    "LayoutObjects",
    "LayoutCount",
    "RecalcStyleCount",
    "TaskDuration",
    "ScriptDuration",
    "LayoutDuration",
    "RecalcStyleDuration",
]


def gpu_flags(use_gpu):
    # Default: software compositing (SwiftShader) for reproducible, machine-independent
    # rendering, which the committed screenshot baselines depend on. --gpu opts into the
    # real GPU path, useful for the e2e physics run where a higher/steadier framerate
    # matters more than pixel-identical output. Explicitly request the high-performance
    # adapter so dual-GPU Macs do not leave headless rendering on the integrated GPU.
    return ["--force-high-performance-gpu"] if use_gpu else ["--disable-gpu"]


def browser_harness_flags():
    return ["--disable-features=BackForwardCache"]


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


def capture_shot(out_path, root, delay, browser_path, query="", use_gpu=False):
    browser = resolve_browser(browser_path)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    virtual_time_ms = max(0, int(delay * 1000))

    with tempfile.TemporaryDirectory(prefix="pr2-openfl-shot-") as profile, serve(root) as url:
        url = append_query(url, query)
        command = [
            browser,
            "--headless=new",
            *browser_harness_flags(),
            f"--user-data-dir={profile}",
            "--js-flags=--expose-gc",
            *gpu_flags(use_gpu),
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


def check_fps(
    root,
    duration,
    target,
    tolerance,
    simulation_target,
    simulation_tolerance,
    browser_path,
    query="",
    use_gpu=False,
    uncapped_browser_refresh=False,
):
    browser = resolve_browser(browser_path)

    with serve(root) as url:
        url = append_query(url, query)
        result = run_browser_and_read_fps(
            browser,
            url,
            duration,
            use_gpu,
            uncapped_browser_refresh,
        )

    expected_sample_count = int(duration)
    presentation_samples = result["presentation"][-expected_sample_count:]
    simulation_samples = result["simulation"][-expected_sample_count:]
    if len(presentation_samples) < expected_sample_count or len(simulation_samples) < expected_sample_count:
        raise SystemExit(
            "Only captured "
            f"{len(presentation_samples)} presentation and {len(simulation_samples)} simulation samples, "
            f"expected {expected_sample_count}: {result}"
        )

    low = target - tolerance
    high = target + tolerance
    presentation_failures = [
        (index + 1, sample)
        for index, sample in enumerate(presentation_samples)
        if sample < low or sample > high
    ]
    simulation_low = simulation_target - simulation_tolerance
    simulation_high = simulation_target + simulation_tolerance
    simulation_failures = [
        (index + 1, sample)
        for index, sample in enumerate(simulation_samples)
        if sample < simulation_low or sample > simulation_high
    ]
    query_parts = query.lstrip("?").split("&")
    requested_strategy = next(
        (
            part.split("=", 1)[1]
            for part in reversed(query_parts)
            if part.startswith("frame_strategy=")
        ),
        None,
    )
    smooth60 = (
        requested_strategy == "60smooth"
        or (
            requested_strategy not in {"30smooth", "30fixed", "60smooth", "60fixed"}
            and any(part == "smooth60=1" for part in query_parts)
        )
    )
    fixed = requested_strategy in {"30fixed", "60fixed"}
    cadence_failures = []
    for index, (presented, simulated) in enumerate(zip(presentation_samples, simulation_samples)):
        cadence_matches = (
            True
            if fixed
            else simulated <= presented
            if smooth60
            else presented == simulated
        )
        if not cadence_matches:
            cadence_failures.append((index + 1, presented, simulated))

    print(f"Presented-frame samples ({len(presentation_samples)}s): {','.join(map(str, presentation_samples))}")
    print(f"Simulation-tick samples ({len(simulation_samples)}s): {','.join(map(str, simulation_samples))}")
    print(
        f"Presented range: min={min(presentation_samples)} max={max(presentation_samples)} "
        f"target={target} tolerance=+/-{tolerance}"
    )
    print(
        f"Simulation range: min={min(simulation_samples)} max={max(simulation_samples)} "
        f"target={simulation_target} tolerance=+/-{simulation_tolerance}"
    )
    failures = []
    if presentation_failures:
        failures.append(
            "presented " + ", ".join(f"{second}s={sample}" for second, sample in presentation_failures)
        )
    if simulation_failures:
        failures.append(
            "simulation " + ", ".join(f"{second}s={sample}" for second, sample in simulation_failures)
        )
    if cadence_failures:
        failures.append(
            "cadence "
            + ", ".join(
                f"{second}s={presented}/{simulated}" for second, presented, simulated in cadence_failures
            )
        )
    if failures:
        raise SystemExit("Independent FPS validation failed: " + "; ".join(failures))
    print("Independent presentation/simulation FPS validation passed.")


def check_smooth60_flag(root, browser_path, use_gpu=False):
    browser = resolve_browser(browser_path)
    with serve(root) as url:
        with browser_devtools_session(browser, url, use_gpu) as devtools:
            cases = [
                ("default", "", "30smooth", "0", "30"),
                ("non-exact legacy value", "smooth60=true", "30smooth", "0", "30"),
                ("invalid strategy", "frame_strategy=invalid", "30smooth", "0", "30"),
                ("legacy exact opt-in", "smooth60=1", "60smooth", "1", "60"),
                ("explicit 30smooth", "frame_strategy=30smooth", "30smooth", "0", "30"),
                ("explicit 30fixed", "frame_strategy=30fixed", "30fixed", "0", "60"),
                ("explicit 60smooth", "frame_strategy=60smooth", "60smooth", "1", "60"),
                ("explicit 60fixed", "frame_strategy=60fixed", "60fixed", "0", "60"),
                ("explicit strategy wins", "smooth60=1&frame_strategy=30fixed", "30fixed", "0", "60"),
                ("navigation without flag", "screen=intro", "30smooth", "0", "30"),
            ]
            for label, query, expected_strategy, expected_enabled, expected_target in cases:
                destination = append_query(url, query)
                devtools.request("Page.navigate", {"url": destination})
                wait_for_app_ready(devtools)
                actual_strategy = devtools.evaluate(
                    'document.body.getAttribute("data-pr2-frame-strategy") || ""'
                )
                actual_enabled = devtools.evaluate(
                    'document.body.getAttribute("data-pr2-smooth60") || ""'
                )
                actual_target = devtools.evaluate(
                    'document.body.getAttribute("data-pr2-presentation-fps-target") || ""'
                )
                actual_search = devtools.evaluate("location.search")
                if (
                    actual_strategy != expected_strategy
                    or actual_enabled != expected_enabled
                    or actual_target != expected_target
                ):
                    raise SystemExit(
                        f"Frame strategy {label} failed: strategy={actual_strategy}, "
                        f"smooth60={actual_enabled}, target={actual_target}, query={actual_search}"
                    )
                if label == "navigation without flag" and "smooth60" in actual_search:
                    raise SystemExit(
                        f"Smooth60 flag survived navigation without its parameter: {actual_search}"
                    )
                print(
                    f"Frame strategy {label}: strategy={actual_strategy}, smooth60={actual_enabled}, "
                    f"presentationTarget={actual_target}, query={actual_search or '<none>'}"
                )
    print("Frame-strategy browser validation passed.")


def check_smooth60_stability(root, browser_path, use_gpu=False):
    browser = resolve_browser(browser_path)
    with serve(root) as url:
        with browser_devtools_session(browser, url, use_gpu) as devtools:
            destination = append_query(
                url,
                "screen=campaign&debug=1&localLevel=art-heavy&smooth60=1",
            )
            devtools.request("Page.navigate", {"url": destination})
            wait_for_app_ready(devtools)
            race_phase = wait_for_body_attribute(
                devtools,
                "data-pr2-race-phase",
                "racing",
                30.0,
            )
            if race_phase != "racing":
                raise SystemExit("Smooth60 stability fixture did not reach racing phase.")
            initial_requested = devtools.evaluate(
                'document.body.getAttribute("data-pr2-smooth60") || ""'
            )
            initial_target = devtools.evaluate(
                'document.body.getAttribute("data-pr2-presentation-fps-target") || ""'
            )
            if (initial_requested, initial_target) != ("1", "60"):
                raise SystemExit(
                    "Smooth60 stability fixture did not begin in requested 60 FPS mode: "
                    f"requested={initial_requested}, target={initial_target}"
                )
            presentation_count = len(read_all_int_attribute(
                devtools,
                "data-pr2-presentation-frame-samples",
            ))
            simulation_count = len(read_all_int_attribute(
                devtools,
                "data-pr2-simulation-tick-samples",
            ))
            try:
                devtools.request("Emulation.setCPUThrottlingRate", {"rate": 20})
                time.sleep(6.2)
                loaded_presentation = read_all_int_attribute(
                    devtools,
                    "data-pr2-presentation-frame-samples",
                )[presentation_count + 1:]
                loaded_simulation = read_all_int_attribute(
                    devtools,
                    "data-pr2-simulation-tick-samples",
                )[simulation_count + 1:]
            finally:
                devtools.request("Emulation.setCPUThrottlingRate", {"rate": 1})
            requested = devtools.evaluate(
                'document.body.getAttribute("data-pr2-smooth60") || ""'
            )
            target = devtools.evaluate(
                'document.body.getAttribute("data-pr2-presentation-fps-target") || ""'
            )
            search = devtools.evaluate("location.search")
            if requested != "1" or target != "60":
                raise SystemExit(
                    "Smooth60 changed mode under sustained load: "
                    f"requested={requested}, target={target}, query={search}"
                )
            if "smooth60=1" not in search:
                raise SystemExit(
                    f"Smooth60 stability test lost the requested URL parameter: {search}"
                )
            paired_samples = list(zip(loaded_presentation, loaded_simulation))
            if len(paired_samples) < 3 or any(
                simulated > 35
                or abs(simulated * 2 - presented) > 2
                for presented, simulated in paired_samples
            ):
                raise SystemExit(
                    "Smooth60 sustained-load cadence did not preserve strict alternation: "
                    f"{paired_samples}"
                )
            print(
                "Smooth60 sustained-load stability: "
                f"requested={requested}, presentationTarget={target}, "
                f"samples={paired_samples}, query={search}"
            )
    print("Smooth60 browser stability validation passed.")


def capture_smooth60_replays(root, browser_path, out_dir, use_gpu=False):
    browser = resolve_browser(browser_path)
    cases = [
        ("running", "flat"),
        ("jumping", "flat"),
        ("falling", "flat"),
        ("landing", "flat"),
        ("wall-contact", "rotate"),
        ("teleporting", "flat"),
        ("rotating", "rotate"),
        ("spectating", "flat"),
        ("multiplayer-correction", "flat"),
        ("particle-heavy", "flat"),
    ]
    os.makedirs(out_dir, exist_ok=True)
    with serve(root) as url:
        with browser_devtools_session(browser, url, use_gpu) as devtools:
            for name, level in cases:
                pair = []
                for smooth in (False, True):
                    rate = "60" if smooth else "30"
                    query = f"screen=campaign&debug=1&localLevel={level}"
                    if smooth:
                        query += "&smooth60=1"
                    devtools.request("Page.navigate", {"url": append_query(url, query)})
                    wait_for_app_ready(devtools)
                    race_phase = wait_for_body_attribute(devtools, "data-pr2-race-phase", "racing", 20.0)
                    if race_phase != "racing":
                        current_url = devtools.evaluate("location.href")
                        screen_state = devtools.evaluate(
                            'document.body.getAttribute("data-pr2-screen") || ""'
                        )
                        debug_state = devtools.evaluate(
                            'document.body.getAttribute("data-pr2-debug-state") || ""'
                        )
                        error_state = devtools.evaluate(
                            'document.body.getAttribute("data-pr2-error") || ""'
                        )
                        raise SystemExit(
                            f"Replay {name} did not reach racing phase at {rate} FPS: "
                            f"url={current_url!r}, screen={screen_state!r}, phase={race_phase!r}, "
                            f"debug={debug_state!r}, error={error_state!r}"
                        )
                    time.sleep(0.35)
                    perform_smooth60_replay_case(devtools, name)
                    out_path = os.path.join(out_dir, f"{name}-{rate}.png")
                    capture_devtools_shot(devtools, out_path)
                    pair.append(out_path)
                combined = os.path.join(out_dir, f"{name}-side-by-side.png")
                combine_replay_pair(pair[0], pair[1], combined)
    manifest = {
        "presentationRates": [30, 60],
        "authoritativeSimulationRate": 30,
        "cases": [
            {
                "name": name,
                "baseline": f"{name}-30.png",
                "smooth": f"{name}-60.png",
                "sideBySide": f"{name}-side-by-side.png",
            }
            for name, _ in cases
        ],
    }
    manifest_path = os.path.join(out_dir, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as file:
        json.dump(manifest, file, indent=2)
        file.write("\n")
    print(f"Smooth60 replay capture passed: {len(cases)} paired scenes, manifest={manifest_path}")


def perform_smooth60_replay_case(devtools, name):
    if name == "running":
        dispatch_key(devtools, "keyDown", "right")
        time.sleep(0.45)
        dispatch_key(devtools, "keyUp", "right")
    elif name == "jumping":
        dispatch_key(devtools, "keyDown", "up")
        time.sleep(0.20)
        dispatch_key(devtools, "keyUp", "up")
        time.sleep(0.08)
    elif name == "falling":
        dispatch_key(devtools, "keyDown", "up")
        time.sleep(0.20)
        dispatch_key(devtools, "keyUp", "up")
        time.sleep(0.50)
    elif name == "landing":
        dispatch_key(devtools, "keyDown", "up")
        time.sleep(0.20)
        dispatch_key(devtools, "keyUp", "up")
        time.sleep(1.00)
    elif name == "wall-contact":
        dispatch_key(devtools, "keyDown", "right")
        time.sleep(1.25)
        dispatch_key(devtools, "keyUp", "right")
    elif name == "teleporting":
        run_smooth60_replay_action(devtools, "teleport")
        time.sleep(0.12)
    elif name == "rotating":
        dispatch_key(devtools, "keyDown", "up")
        time.sleep(0.35)
        dispatch_key(devtools, "keyUp", "up")
        time.sleep(0.25)
    elif name == "spectating":
        run_smooth60_replay_action(devtools, "spectate")
        time.sleep(0.30)
    elif name == "multiplayer-correction":
        run_smooth60_replay_action(devtools, "correction")
        time.sleep(0.18)
    elif name == "particle-heavy":
        run_smooth60_replay_action(devtools, "particles")
        time.sleep(0.30)
    else:
        raise SystemExit(f"Unsupported smooth60 replay case: {name}")


def combine_replay_pair(baseline_path, smooth_path, out_path):
    try:
        from PIL import Image, ImageDraw
    except ImportError as error:
        raise SystemExit(f"Pillow is required to compose smooth60 replay pairs: {error}")
    baseline = Image.open(baseline_path).convert("RGB")
    smooth = Image.open(smooth_path).convert("RGB")
    width = baseline.width + smooth.width
    height = max(baseline.height, smooth.height) + 30
    combined = Image.new("RGB", (width, height), (20, 20, 20))
    combined.paste(baseline, (0, 30))
    combined.paste(smooth, (baseline.width, 30))
    labels = ImageDraw.Draw(combined)
    labels.text((10, 8), "30 FPS presentation / 30 Hz simulation", fill=(255, 255, 255))
    labels.text((baseline.width + 10, 8), "60 FPS presentation / 30 Hz simulation", fill=(255, 255, 255))
    combined.save(out_path)
    print(f"Side-by-side replay saved: {out_path}")


def benchmark_smooth60(root, browser_path, out_path, duration, use_gpu=False):
    browser = resolve_browser(browser_path)
    scenes = [
        ("small", "flat", None),
        ("large", "large", None),
        ("art-heavy", "art-heavy", None),
        ("multiplayer", "flat", "multiplayer"),
    ]
    devices = [
        ("desktop", 1),
        ("lower-powered-emulation", 4),
    ]
    results = []
    with serve(root) as url:
        with browser_devtools_session(browser, url, use_gpu) as devtools:
            devtools.request("Performance.enable")
            for device, cpu_rate in devices:
                devtools.request("Emulation.setCPUThrottlingRate", {"rate": cpu_rate})
                for scene, level, setup in scenes:
                    query = f"screen=campaign&debug=1&localLevel={level}&smooth60=1"
                    devtools.request("Page.navigate", {"url": append_query(url, query)})
                    wait_for_app_ready(devtools)
                    race_phase = wait_for_body_attribute(devtools, "data-pr2-race-phase", "racing", 30.0)
                    if race_phase != "racing":
                        raise SystemExit(f"Benchmark {device}/{scene} did not reach racing phase.")
                    time.sleep(0.35)
                    if setup == "multiplayer":
                        run_smooth60_replay_action(devtools, "spectate")
                        run_smooth60_replay_action(devtools, "correction")
                    devtools.evaluate("window.gc && window.gc()")
                    time.sleep(0.05)
                    heap_before = read_heap_usage(devtools)
                    metrics_before = read_performance_metrics(devtools)
                    initial_presentation_count = len(read_all_int_attribute(
                        devtools, "data-pr2-presentation-frame-samples"
                    ))
                    initial_simulation_count = len(read_all_int_attribute(
                        devtools, "data-pr2-simulation-tick-samples"
                    ))
                    install_stage_interval_probe(devtools)
                    heap_samples = [heap_before["usedSize"]]
                    sample_count = max(1, int(duration))
                    measured_seconds = duration + 1.2
                    sample_seconds = measured_seconds / sample_count
                    for _ in range(sample_count):
                        time.sleep(sample_seconds)
                        heap_samples.append(read_heap_usage(devtools)["usedSize"])
                    intervals = stop_stage_interval_probe(devtools)
                    all_presentation = read_all_int_attribute(devtools, "data-pr2-presentation-frame-samples")
                    all_simulation = read_all_int_attribute(devtools, "data-pr2-simulation-tick-samples")
                    presentation_samples = all_presentation[
                        initial_presentation_count + 1:initial_presentation_count + 1 + sample_count
                    ]
                    simulation_samples = all_simulation[
                        initial_simulation_count + 1:initial_simulation_count + 1 + sample_count
                    ]
                    if len(presentation_samples) < sample_count or len(simulation_samples) < sample_count:
                        raise SystemExit(
                            f"Benchmark {device}/{scene} captured incomplete FPS windows: "
                            f"presentation={presentation_samples}, simulation={simulation_samples}"
                        )
                    invalid_cadence = [
                        (presented, simulated)
                        for presented, simulated in zip(presentation_samples, simulation_samples)
                        if simulated > 35
                        or abs(presented - simulated * 2) > 1
                    ]
                    if invalid_cadence:
                        raise SystemExit(
                            f"Benchmark {device}/{scene} observed unsafe presentation/simulation "
                            f"cadence: {invalid_cadence}"
                        )
                    effective_target = int(devtools.evaluate(
                        'document.body.getAttribute("data-pr2-presentation-fps-target") || "0"'
                    ))
                    if effective_target != 60:
                        raise SystemExit(
                            f"Benchmark {device}/{scene} changed requested smooth60 mode: "
                            f"target={effective_target}"
                        )
                    metrics_after = read_performance_metrics(devtools)
                    heap_peak = max(heap_samples)
                    devtools.evaluate("window.gc && window.gc()")
                    time.sleep(0.05)
                    heap_after_gc = read_heap_usage(devtools)
                    result = {
                        "device": device,
                        "cpuThrottleRate": cpu_rate,
                        "scene": scene,
                        "durationSeconds": duration,
                        "presentationFps": average(presentation_samples),
                        "simulationFps": average(simulation_samples),
                        "effectivePresentationTargetFps": effective_target,
                        "presentationSamples": presentation_samples,
                        "simulationSamples": simulation_samples,
                        "frameTimeMs": {
                            "p50": percentile(intervals, 50),
                            "p95": percentile(intervals, 95),
                            "p99": percentile(intervals, 99),
                            "max": max(intervals) if intervals else 0,
                            "sampleCount": len(intervals),
                        },
                        "memory": {
                            "heapBeforeBytes": heap_before["usedSize"],
                            "heapPeakBytes": heap_peak,
                            "heapAfterGcBytes": heap_after_gc["usedSize"],
                            "gcReclaimedBytes": max(0, heap_peak - heap_after_gc["usedSize"]),
                            "heapLimitBytes": heap_after_gc["embedderHeapUsedSize"] + heap_after_gc["backingStorageSize"]
                                if "embedderHeapUsedSize" in heap_after_gc else heap_after_gc.get("totalSize", 0),
                        },
                        "performanceDelta": performance_delta(metrics_before, metrics_after),
                    }
                    results.append(result)
                    print(
                        f"Smooth60 benchmark {device}/{scene}: "
                        f"presentation={result['presentationFps']:.1f}, simulation={result['simulationFps']:.1f}, "
                        f"target={effective_target}, frame p95={result['frameTimeMs']['p95']:.2f}ms, "
                        f"heap peak={heap_peak}"
                    )
            devtools.request("Emulation.setCPUThrottlingRate", {"rate": 1})
    report = {
        "feature": "smooth60",
        "simulationRateHz": 30,
        "presentationTargetFps": 60,
        "lowerPoweredProxy": "Chrome 4x CPU throttling",
        "results": results,
    }
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as file:
        json.dump(report, file, indent=2)
        file.write("\n")
    print(f"Smooth60 benchmark matrix passed: {len(results)} runs, report={out_path}")


def install_stage_interval_probe(devtools):
    installed = devtools.evaluate(
        """
(() => {
  const stage = window.__pr2Stage;
  if (!stage) return false;
  if (window.__pr2SmoothBenchHandler) {
    stage.removeEventListener("enterFrame", window.__pr2SmoothBenchHandler);
  }
  window.__pr2SmoothBenchIntervals = [];
  window.__pr2SmoothBenchLast = performance.now();
  window.__pr2SmoothBenchHandler = () => {
    const now = performance.now();
    window.__pr2SmoothBenchIntervals.push(now - window.__pr2SmoothBenchLast);
    window.__pr2SmoothBenchLast = now;
  };
  stage.addEventListener("enterFrame", window.__pr2SmoothBenchHandler);
  return true;
})()
"""
    )
    if installed is not True:
        raise SystemExit("OpenFL stage interval probe is unavailable.")


def stop_stage_interval_probe(devtools):
    raw = devtools.evaluate(
        """
(() => {
  const stage = window.__pr2Stage;
  if (stage && window.__pr2SmoothBenchHandler) {
    stage.removeEventListener("enterFrame", window.__pr2SmoothBenchHandler);
  }
  window.__pr2SmoothBenchHandler = null;
  return JSON.stringify(window.__pr2SmoothBenchIntervals || []);
})()
"""
    )
    return [float(value) for value in json.loads(raw) if value >= 0]


def read_heap_usage(devtools):
    return devtools.request("Runtime.getHeapUsage").get("result", {})


def read_all_int_attribute(devtools, name):
    expression = f'document.body.getAttribute({json.dumps(name)}) || ""'
    raw = devtools.evaluate(expression)
    return [int(value) for value in raw.split(",") if value]


def average(values):
    return sum(values) / len(values) if values else 0


def percentile(values, percentage):
    if not values:
        return 0
    ordered = sorted(values)
    index = max(0, min(len(ordered) - 1, int((percentage / 100) * len(ordered) + 0.999999) - 1))
    return ordered[index]


def performance_delta(before, after):
    keys = [
        "TaskDuration",
        "ScriptDuration",
        "LayoutDuration",
        "RecalcStyleDuration",
        "LayoutCount",
        "RecalcStyleCount",
    ]
    return {
        key: after.get(key, 0) - before.get(key, 0)
        for key in keys
    }


def check_debug_state(root, delay, browser_path, query, expected, use_gpu=False):
    browser = resolve_browser(browser_path)

    with serve(root) as url:
        url = append_query(url, query)
        state_text = run_browser_and_read_debug_state(browser, url, delay, use_gpu)

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


def run_browser_and_read_debug_state(browser, url, delay, use_gpu=False):
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-openfl-chrome-")
    command = [
        browser,
        "--headless=new",
        *browser_harness_flags(),
        "--js-flags=--expose-gc",
        *gpu_flags(use_gpu),
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
def browser_devtools_session(browser, url, use_gpu=False):
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-openfl-chrome-")
    command = [
        browser,
        "--headless=new",
        *browser_harness_flags(),
        "--js-flags=--expose-gc",
        *gpu_flags(use_gpu),
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


def run_browser_and_read_fps(
    browser,
    url,
    duration,
    use_gpu=False,
    uncapped_browser_refresh=False,
):
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-openfl-chrome-")
    command = [
        browser,
        "--headless=new",
        *gpu_flags(use_gpu),
        *(
            ["--disable-frame-rate-limit", "--disable-gpu-vsync"]
            if uncapped_browser_refresh
            else []
        ),
        "--hide-scrollbars",
        "--window-size=550,400",
        f"--remote-debugging-port={debug_port}",
        f"--user-data-dir={user_data_dir}",
        url,
    ]
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        page_ws_url = wait_for_page_websocket(debug_port)
        devtools = DevToolsSession(page_ws_url)
        wait_for_app_ready(devtools)
        initial_presentation = devtools.evaluate(
            'document.body.getAttribute("data-pr2-presentation-frame-samples") || ""'
        )
        initial_simulation = devtools.evaluate(
            'document.body.getAttribute("data-pr2-simulation-tick-samples") || ""'
        )
        initial_presentation_count = len([value for value in initial_presentation.split(",") if value])
        initial_simulation_count = len([value for value in initial_simulation.split(",") if value])
        time.sleep(duration + 2.0)
        raw_samples = devtools.evaluate('document.body.getAttribute("data-pr2-fps-samples") || ""')
        raw_presentation = devtools.evaluate(
            'document.body.getAttribute("data-pr2-presentation-frame-samples") || ""'
        )
        raw_simulation = devtools.evaluate(
            'document.body.getAttribute("data-pr2-simulation-tick-samples") || ""'
        )
        devtools.close()
        presentation = [int(value) for value in raw_presentation.split(",") if value]
        simulation = [int(value) for value in raw_simulation.split(",") if value]
        # Drop the first window that closes after readiness because it began
        # during preload and is not a full in-app measurement second.
        presentation_start = min(len(presentation), initial_presentation_count + 1)
        simulation_start = min(len(simulation), initial_simulation_count + 1)
        return {
            "legacy": [int(value) for value in raw_samples.split(",") if value],
            "presentation": presentation[presentation_start:],
            "simulation": simulation[simulation_start:],
        }
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
    # Connect/handshake should be quick, but individual CDP responses can take a
    # while: Page.captureScreenshot waits for a frame commit, and during the
    # racing phase the page renders at low FPS, so a screenshot can take many
    # seconds to come back. create_connection's timeout stays on the socket for
    # all later recv() calls, so a short value would make read_exact time out
    # mid-gameplay. Connect briefly, then widen the timeout for operations.
    CONNECT_TIMEOUT = 5
    OPERATION_TIMEOUT = 120

    def __init__(self, url):
        match = re.match(r"ws://([^/:]+):(\d+)(/.*)", url)
        if not match:
            raise SystemExit(f"Unsupported WebSocket URL: {url}")
        host, port, path = match.group(1), int(match.group(2)), match.group(3)
        self.socket = socket.create_connection((host, port), timeout=self.CONNECT_TIMEOUT)
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
        # Handshake done; allow long-running CDP calls (e.g. a mid-gameplay
        # Page.captureScreenshot) to complete without tripping the recv timeout.
        self.socket.settimeout(self.OPERATION_TIMEOUT)

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


def run_sequence(script_path, root, browser_path, base_url=None, use_gpu=False, metrics_out=None):
    browser = resolve_browser(browser_path)
    query, steps = load_pr2_sequence(script_path, normalize_hold=True)
    if sequence_uses_console_trace(steps):
        query = append_query(query, "physicsTrace=1")

    server = contextlib.nullcontext(base_url) if base_url else serve(root)
    with server as url:
        base_page_url = url
        initial_url = append_query(base_page_url, query)
        with browser_devtools_session(browser, initial_url, use_gpu) as devtools:
            context = SequenceContext(devtools, base_page_url, metrics_out)
            run_sequence_steps(devtools, steps, context)
            context.write_metrics()


def sequence_uses_console_trace(steps):
    return any(step.get("action") in ("saveConsoleTrace", "saveConsoleTraceWindow") for step in steps)


# The OpenFL preloader runs for a variable amount of time before `Main` boots.
# Input dispatched during preload hits the preloader, not the game, and is
# silently dropped, which makes sequences flaky. Gate the sequence clock on the
# screen-independent ready signal `Main` sets once it is running (see Main.hx),
# so step `time` offsets are relative to app boot rather than browser launch.
APP_READY_TIMEOUT = float(os.environ.get("PR2_APP_READY_TIMEOUT", "60"))


def wait_for_app_ready(devtools, timeout=APP_READY_TIMEOUT):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if devtools.evaluate('document.body.getAttribute("data-pr2-app-ready") || ""'):
            return
        error = devtools.evaluate('document.body.getAttribute("data-pr2-error") || ""')
        if error:
            raise SystemExit(f"App failed to boot before sequence: {error}")
        boot_error = devtools.evaluate('window.__pr2BootError || ""')
        if boot_error:
            raise SystemExit(f"JavaScript failed before the app booted: {boot_error}")
        time.sleep(0.1)
    state = devtools.evaluate(
        "JSON.stringify({readyState:document.readyState,"
        "lime:typeof window.lime,canvasCount:document.querySelectorAll('canvas').length,"
        "resources:performance.getEntriesByType('resource').length,"
        "bootError:window.__pr2BootError||'',"
        "bodyText:(document.body.innerText||'').slice(0,240)})"
    )
    raise SystemExit(
        f"Timed out after {timeout:.0f}s waiting for data-pr2-app-ready; "
        f"the OpenFL build may have failed to boot past the preloader. Browser state: {state}"
    )


class SequenceContext:
    def __init__(self, devtools, base_page_url, metrics_out=None):
        self.devtools = devtools
        self.base_page_url = base_page_url
        self.metrics_out = metrics_out
        self.run_id = str(int(time.time()))
        self.samples = []
        self.last_metric_time = None
        self.performance_enabled = False

    def after_app_ready(self):
        self.install_console_trace()
        if self.metrics_out is None:
            return
        if not self.performance_enabled:
            self.devtools.request("Performance.enable")
            self.performance_enabled = True
        self.install_frame_counter()
        self.last_metric_time = time.monotonic()

    def install_frame_counter(self):
        self.devtools.evaluate(
            """
(() => {
  window.__pr2SequenceFrames = 0;
  if (!window.__pr2SequenceFrameCounterInstalled) {
    window.__pr2SequenceFrameCounterInstalled = true;
    const tick = () => {
      window.__pr2SequenceFrames = (window.__pr2SequenceFrames || 0) + 1;
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }
	})()
	"""
        )

    def install_console_trace(self):
        self.devtools.evaluate(
            """
(() => {
  window.__pr2ConsoleTrace = window.__pr2ConsoleTrace || [];
  if (window.__pr2ConsoleTraceInstalled) return;
  window.__pr2ConsoleTraceInstalled = true;
  for (const name of ["log", "info", "debug", "warn"]) {
    const original = console[name] ? console[name].bind(console) : console.log.bind(console);
    console[name] = (...args) => {
      const line = args.map((arg) => {
        try {
          return typeof arg === "string" ? arg : JSON.stringify(arg);
        } catch (_) {
          return String(arg);
        }
      }).join(" ");
      if (line.includes("PR2TRACE")) {
        window.__pr2ConsoleTrace.push(line);
      }
      original(...args);
    };
  }
})()
"""
        )

    def write_console_trace(self, out_path):
        out_path = out_path.replace("{target}", "openfl")
        raw = self.devtools.evaluate("JSON.stringify(window.__pr2ConsoleTrace || [])")
        lines = json.loads(raw)
        os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as file:
            for line in lines:
                file.write(line)
                file.write("\n")
        print(f"Console trace saved: {out_path} ({len(lines)} lines)")

    def navigate(self, query):
        url = append_query(self.base_page_url, query)
        self.devtools.request("Page.navigate", {"url": url})
        wait_for_app_ready(self.devtools)
        self.after_app_ready()
        print(f"navigate: {query}")

    def sample_metrics(self, label, seconds=0.5):
        if self.metrics_out is None:
            print(f"metrics: {label} (no --metrics-out path; skipped)")
            return
        try:
            seconds = float(seconds)
        except (TypeError, ValueError):
            raise SystemExit(f"Invalid metrics seconds value: {seconds}")
        if seconds <= 0:
            raise SystemExit(f"metrics seconds must be positive: {seconds}")
        self.install_frame_counter()
        self.devtools.evaluate("window.__pr2SequenceFrames = 0")
        time.sleep(seconds)
        frames = self.devtools.evaluate("window.__pr2SequenceFrames || 0")
        try:
            fps = float(frames) / seconds
        except (TypeError, ValueError):
            fps = 0.0
        self.devtools.evaluate("window.gc && window.gc()")
        time.sleep(0.05)
        metrics = read_performance_metrics(self.devtools)
        attrs = read_sequence_attributes(self.devtools)
        url = self.devtools.evaluate("location.href")
        selected = {key: metrics.get(key) for key in SEQUENCE_METRIC_KEYS if key in metrics}
        sample = {
            "label": label,
            "url": url,
            "sampleWindowSec": seconds,
            "fps": fps,
            "attributes": attrs,
            "metrics": selected,
        }
        self.samples.append(sample)
        heap_mb = selected.get("JSHeapUsedSize", 0) / 1e6
        nodes = int(selected.get("Nodes", 0))
        layouts = int(selected.get("LayoutCount", 0))
        recalcs = int(selected.get("RecalcStyleCount", 0))
        print(f"metrics: {label} fps={fps:.1f} heapMB={heap_mb:.1f} nodes={nodes} layouts={layouts} recalcs={recalcs}")
        self.last_metric_time = time.monotonic()

    def write_metrics(self):
        if self.metrics_out is None:
            return
        os.makedirs(os.path.dirname(os.path.abspath(self.metrics_out)), exist_ok=True)
        with open(self.metrics_out, "w", encoding="utf-8") as file:
            json.dump(self.samples, file, indent=2, sort_keys=True)
        print(f"Metrics saved: {self.metrics_out} ({len(self.samples)} samples)")


def read_performance_metrics(devtools):
    response = devtools.request("Performance.getMetrics")
    metrics = {}
    for metric in response.get("result", {}).get("metrics", []):
        metrics[metric["name"]] = metric["value"]
    return metrics


def read_sequence_attributes(devtools):
    text = devtools.evaluate(
        """
JSON.stringify({
  screen: document.body.getAttribute("data-pr2-screen") || "",
  page: document.body.getAttribute("data-pr2-page") || "",
  introState: document.body.getAttribute("data-pr2-intro-state") || "",
  lobbyLeft: document.body.getAttribute("data-pr2-lobby-left") || "",
  lobbyRight: document.body.getAttribute("data-pr2-lobby-right") || "",
  debugState: document.body.getAttribute("data-pr2-debug-state") || "",
  error: document.body.getAttribute("data-pr2-error") || ""
})
"""
    )
    return json.loads(text)


def run_sequence_steps(devtools, steps, context=None):
    wait_for_app_ready(devtools)
    if context is not None:
        context.after_app_ready()
    start = time.monotonic()
    for step in steps:
        wait = start + step["time"] - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        run_sequence_step(devtools, step, context)


def run_sequence_step(devtools, step, context=None):
    action = step["action"]
    if action == "keyDown":
        dispatch_key(devtools, "keyDown", require_key(step))
    elif action == "keyUp":
        dispatch_key(devtools, "keyUp", require_key(step))
    elif action == "tap":
        key = require_key(step)
        dispatch_key(devtools, "keyDown", key)
        dispatch_key(devtools, "keyUp", key)
    elif action == "repeatTap":
        repeat_tap(
            devtools,
            require_key(step),
            float(step.get("duration", 0)),
            float(step.get("interval", 0.2)),
            step.get("refreshKeys", []),
        )
    elif action == "click":
        dispatch_click(devtools, require_coordinate(step, "x"), require_coordinate(step, "y"))
    elif action == "click-display-object":
        click_display_object(
            devtools,
            require_field(step, "name"),
            int(step.get("index", 0)),
            float(step.get("timeout", 5.0)),
            int(step.get("clickCount", 1)),
            bool(step.get("optional", False)),
        )
    elif action == "dragPath":
        dispatch_drag_path(devtools, require_points(step))
    elif action == "mouseMove":
        dispatch_mouse_move(devtools, require_coordinate(step, "x"), require_coordinate(step, "y"))
    elif action == "typeText":
        value = require_field(step, "text")
        if not isinstance(value, str):
            raise SystemExit("Sequence typeText step requires a string text field.")
        value = render_sequence_text(value, context)
        devtools.request("Input.insertText", {"text": value})
        print(f"typeText: {value}")
    elif action == "rebuild-lobby":
        rebuilt = devtools.evaluate(
            'typeof window.__pr2RebuildLobby === "function" && '
            '(window.__pr2RebuildLobby(), true)'
        )
        if rebuilt is not True:
            raise SystemExit("Lobby rebuild hook is unavailable.")
        print("rebuild-lobby")
    elif action == "open-level-editor":
        open_level_editor(devtools)
    elif action == "level-editor-e2e":
        run_level_editor_e2e(devtools)
    elif action == "assert-level-editor-state":
        assert_level_editor_state(devtools, step, context)
    elif action == "smooth60-replay":
        run_smooth60_replay_action(devtools, require_field(step, "name"))
    elif action == "navigate":
        if context is None:
            raise SystemExit("Sequence navigate step requires a sequence context.")
        context.navigate(require_field(step, "query"))
    elif action == "metrics":
        if context is None:
            raise SystemExit("Sequence metrics step requires a sequence context.")
        context.sample_metrics(str(step.get("label", "metrics")), step.get("seconds", 0.5))
    elif action in ("launch", "quit"):
        # Lifecycle steps for the Flash projector; the browser session manages
        # its own launch/teardown, so these are no-ops for parity sequences.
        print(action)
    elif action == "shot":
        capture_devtools_shot(devtools, require_field(step, "out"))
    elif action == "shotSeries":
        capture_devtools_shot_series(
            devtools,
            require_field(step, "out"),
            step.get("duration", 0),
            step.get("interval", 1.0),
            step.get("startSecond", int(step["time"])),
        )
    elif action == "debug-state":
        validate_sequence_debug_state(devtools, step.get("expect", {}))
    elif action == "debugStateSeries":
        capture_debug_state_series(
            devtools,
            float(step.get("duration", 0)),
            float(step.get("interval", 1.0)),
            step.get("label", "debug"),
        )
    elif action == "saveConsoleTrace":
        if context is None:
            raise SystemExit("Sequence saveConsoleTrace step requires a sequence context.")
        context.write_console_trace(require_field(step, "out"))
    elif action == "saveConsoleTraceWindow":
        if context is None:
            raise SystemExit("Sequence saveConsoleTraceWindow step requires a sequence context.")
        wait_for_body_attribute(devtools, "race-phase", "racing")
        time.sleep(float(step.get("duration", 5.0)))
        context.write_console_trace(require_field(step, "out"))
    elif action == "body-attribute":
        validate_sequence_body_attribute(devtools, require_field(step, "name"), require_field(step, "value"))
    else:
        raise SystemExit(f"Unsupported OpenFL sequence action: {action}")


def run_smooth60_replay_action(devtools, name):
    result = devtools.evaluate(
        'typeof window.__pr2RunSmooth60ReplayAction === "function" '
        f'? window.__pr2RunSmooth60ReplayAction({json.dumps(name)}) : "hook-unavailable"'
    )
    print(f"smooth60-replay: {name} -> {result}")
    if result == "hook-unavailable" or str(result).startswith("unsupported:"):
        raise SystemExit(f"Smooth60 replay action failed: {result}")


def render_sequence_text(value, context=None):
    run_id = context.run_id if context is not None else str(int(time.time()))
    return value.replace("{run_id}", run_id)


def click_display_object(devtools, name, index=0, timeout=5.0, click_count=1, optional=False):
    deadline = time.monotonic() + timeout
    target = None
    while time.monotonic() < deadline:
        raw = devtools.evaluate(
            """
((name, index) => {
  if (typeof window.__pr2DisplayBoundsForTests === "function") {
    const rawBounds = window.__pr2DisplayBoundsForTests(name, index);
    const parsed = JSON.parse(rawBounds);
    if (parsed.ok) {
      parsed.x = parsed.x + parsed.width / 2;
      parsed.y = parsed.y + parsed.height / 2;
      return JSON.stringify(parsed);
    }
  }
  const stage = window.__pr2Stage;
  if (!stage) return JSON.stringify({ok: false, error: "stage unavailable"});
  const matches = [];
  const visit = (node) => {
    if (!node || node.visible === false) return;
    if (node.name === name) matches.push(node);
    const count = Number(node.numChildren || 0);
    for (let i = 0; i < count; i++) {
      try { visit(node.getChildAt(i)); } catch (_) {}
    }
  };
  visit(stage);
  const target = matches[index];
  if (!target) return JSON.stringify({ok: false, count: matches.length});
  try {
    const bounds = target.getBounds(stage);
    return JSON.stringify({
      ok: true,
      count: matches.length,
      x: bounds.x + bounds.width / 2,
      y: bounds.y + bounds.height / 2,
      width: bounds.width,
      height: bounds.height
    });
  } catch (error) {
    return JSON.stringify({ok: false, count: matches.length, error: String(error)});
  }
})(%s, %d)
"""
            % (json.dumps(name), index)
        )
        target = json.loads(raw)
        if target.get("ok"):
            break
        time.sleep(0.1)
    if not target or not target.get("ok"):
        if optional:
            print(f"click-display-object: {name}[{index}] unavailable (optional)")
            return
        raise SystemExit(f"Display object {name}[{index}] unavailable: {target}")
    canvas_metrics = json.loads(devtools.evaluate(
        """
(() => {
  const canvas = document.querySelector("#openfl-content canvas") || document.querySelector("canvas");
  const stage = window.__pr2Stage;
  if (!canvas || !stage) return JSON.stringify({ok: false});
  const rect = canvas.getBoundingClientRect();
  return JSON.stringify({
    ok: true,
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    stageWidth: Number(stage.stageWidth || 550),
    stageHeight: Number(stage.stageHeight || 400)
  });
})()
"""
    ))
    click_x = float(target["x"])
    click_y = float(target["y"])
    if canvas_metrics.get("ok"):
        click_x = canvas_metrics["left"] + click_x * canvas_metrics["width"] / canvas_metrics["stageWidth"]
        click_y = canvas_metrics["top"] + click_y * canvas_metrics["height"] / canvas_metrics["stageHeight"]
    hit_element = devtools.evaluate(
        f"(() => {{ const e = document.elementFromPoint({click_x}, {click_y}); return e ? `${{e.tagName}}#${{e.id || ''}}` : 'none'; }})()"
    )
    dispatch_click(devtools, click_x, click_y, click_count)
    print(
        f"click-display-object: {name}[{index}] "
        f"at stage={target['x']:.1f},{target['y']:.1f} css={click_x:.1f},{click_y:.1f} "
        f"size={target.get('width', 0):.1f}x{target.get('height', 0):.1f} element={hit_element}"
    )


def open_level_editor(devtools):
    opened = devtools.evaluate(
        """
(() => {
  if (typeof window.__pr2OpenLevelEditorForTests !== "function") {
    return false;
  }
  window.__pr2OpenLevelEditorForTests();
  return true;
})()
"""
    )
    if opened is not True:
        raise SystemExit("Lobby level-editor hook is unavailable.")
    print("open-level-editor")


def run_level_editor_e2e(devtools):
    raw = devtools.evaluate(
        """
(() => {
  if (typeof window.__pr2RunLevelEditorE2E !== "function") {
    return JSON.stringify({ok: false, error: "level editor e2e hook is unavailable"});
  }
  return window.__pr2RunLevelEditorE2E();
})()
"""
    )
    try:
        result = json.loads(raw)
    except Exception as error:
        raise SystemExit(f"Level editor e2e hook returned invalid JSON: {raw!r} ({error})")
    print(
        "level-editor-e2e: "
        f"ok={result.get('ok')} floorBlocks={result.get('floorBlocks')} "
        f"artActions={result.get('artActions')} stamps={result.get('stamps')} "
        f"savedLength={result.get('savedLength')}"
    )
    if result.get("ok") is not True:
        raise SystemExit(f"Level editor e2e failed: {json.dumps(result, sort_keys=True)}")


def assert_level_editor_state(devtools, step, context=None):
    raw = devtools.evaluate(
        """
(() => {
  if (typeof window.__pr2GetLevelEditorStateForTests !== "function") {
    return JSON.stringify({ok: false, error: "level editor state hook is unavailable"});
  }
  return window.__pr2GetLevelEditorStateForTests();
})()
"""
    )
    try:
        state = json.loads(raw)
    except Exception as error:
        raise SystemExit(f"Level editor state hook returned invalid JSON: {raw!r} ({error})")
    if state.get("ok") is not True:
        raise SystemExit(f"Level editor state unavailable: {json.dumps(state, sort_keys=True)}")

    failures = []
    expected_title = step.get("title")
    if expected_title is not None:
        expected_title = render_sequence_text(str(expected_title), context)
        if state.get("title") != expected_title:
            failures.append(f"title expected {expected_title!r}, got {state.get('title')!r}")
    for field, key in (
        ("minBasicBlocks", "basicBlocks"),
        ("minArtActions", "artActions"),
        ("minStamps", "stamps"),
    ):
        if field in step:
            expected = int(step[field])
            actual = int(state.get(key, 0))
            if actual < expected:
                failures.append(f"{key} expected >= {expected}, got {actual}")
    print(
        "assert-level-editor-state: "
        f"title={state.get('title')!r} selected={state.get('selectedToolSidebar')!r}:{state.get('selectedToolId')!r} "
        f"mouseDowns={state.get('mouseDownEvents')} lastMouse={state.get('lastMouseDownTarget')!r}@"
        f"{state.get('lastMouseDownX')},{state.get('lastMouseDownY')} "
        f"basicBlocks={state.get('basicBlocks')} "
        f"artActions={state.get('artActions')} stamps={state.get('stamps')}"
    )
    if failures:
        raise SystemExit("Level editor state assertion failed: " + "; ".join(failures))


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


def repeat_tap(devtools, key_name, duration, interval, refresh_keys=None):
    if duration < 0 or interval <= 0:
        raise SystemExit("repeatTap duration must be non-negative and interval must be positive.")
    definition = KEY_DEFINITIONS.get(key_name.lower())
    if definition is None:
        raise SystemExit(f"Unknown key '{key_name}'. Valid: {', '.join(sorted(KEY_DEFINITIONS))}")
    key_code = definition["windowsVirtualKeyCode"]
    key_value = json.dumps(definition["key"])
    code_value = json.dumps(definition["code"])
    refresh_definitions = []
    for refresh_key in refresh_keys or []:
        refresh_definition = KEY_DEFINITIONS.get(str(refresh_key).lower())
        if refresh_definition is None:
            raise SystemExit(f"Unknown refresh key '{refresh_key}'. Valid: {', '.join(sorted(KEY_DEFINITIONS))}")
        refresh_definitions.append(refresh_definition)
    refresh_json = json.dumps(refresh_definitions)
    interval_ms = interval * 1000.0
    hold_ms = min(40.0, interval_ms / 2.0)
    installed = devtools.evaluate(
        """
(() => {
  if (window.__pr2RepeatTapTimer) clearInterval(window.__pr2RepeatTapTimer);
  const refreshKeys = %s;
  const setPressed = (keyCode, key, code, pressed) => {
    if (typeof window.__pr2HarnessSetKeyCode === "function") {
      window.__pr2HarnessSetKeyCode(keyCode, pressed);
      return;
    }
    const type = pressed ? "keydown" : "keyup";
    const event = new KeyboardEvent(type, {
      key,
      code,
      bubbles: true,
      cancelable: true
    });
    Object.defineProperty(event, "keyCode", {get: () => keyCode});
    Object.defineProperty(event, "which", {get: () => keyCode});
    const targets = [window, document, document.body, document.activeElement];
    for (const canvas of document.querySelectorAll("canvas")) targets.push(canvas);
    for (const target of targets) if (target) target.dispatchEvent(event);
  };
  const fire = () => {
    for (const definition of refreshKeys) {
      setPressed(definition.windowsVirtualKeyCode, definition.key, definition.code, true);
    }
    setPressed(%d, %s, %s, true);
    setTimeout(() => setPressed(%d, %s, %s, false), %f);
  };
  fire();
  window.__pr2RepeatTapTimer = setInterval(fire, %f);
  return true;
})()
""" % (refresh_json, key_code, key_value, code_value, key_code, key_value, code_value, hold_ms, interval_ms)
    )
    if installed is not True:
        raise SystemExit("repeatTap could not install its OpenFL input timer.")
    time.sleep(duration)
    devtools.evaluate(
        """
(() => {
  if (window.__pr2RepeatTapTimer) clearInterval(window.__pr2RepeatTapTimer);
  window.__pr2RepeatTapTimer = null;
  if (typeof window.__pr2HarnessSetKeyCode === "function") {
    window.__pr2HarnessSetKeyCode(%d, false);
  } else {
    const event = new KeyboardEvent("keyup", {
      key: %s,
      code: %s,
      bubbles: true,
      cancelable: true
    });
    Object.defineProperty(event, "keyCode", {get: () => %d});
    Object.defineProperty(event, "which", {get: () => %d});
    window.dispatchEvent(event);
  }
})()
""" % (key_code, key_value, code_value, key_code, key_code)
    )
    count = int(duration / interval) + 1
    print(f"Repeated {key_name} {count} times over {duration:.3f}s")


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


def dispatch_click(devtools, x, y, click_count=1):
    base_params = {
        "x": x,
        "y": y,
        "button": "left",
        "clickCount": click_count,
    }
    devtools.request("Input.dispatchMouseEvent", dict(base_params, type="mouseMoved", button="none", buttons=0))
    devtools.request("Input.dispatchMouseEvent", dict(base_params, type="mousePressed", buttons=1))
    devtools.request("Input.dispatchMouseEvent", dict(base_params, type="mouseReleased", buttons=0))
    print(f"click: {x},{y}")


def dispatch_drag_path(devtools, points):
    if len(points) < 2:
        raise SystemExit("dragPath requires at least two points.")
    first = points[0]
    last = points[-1]
    devtools.request("Input.dispatchMouseEvent", {"type": "mouseMoved", "x": first["x"], "y": first["y"], "button": "none", "buttons": 0})
    devtools.request("Input.dispatchMouseEvent", {"type": "mousePressed", "x": first["x"], "y": first["y"], "button": "left", "buttons": 1, "clickCount": 1})
    for point in points[1:]:
        devtools.request("Input.dispatchMouseEvent", {"type": "mouseMoved", "x": point["x"], "y": point["y"], "button": "left", "buttons": 1})
        time.sleep(0.03)
    devtools.request("Input.dispatchMouseEvent", {"type": "mouseReleased", "x": last["x"], "y": last["y"], "button": "left", "buttons": 0, "clickCount": 1})
    print("dragPath: " + " -> ".join(f"{point['x']},{point['y']}" for point in points))


def dispatch_mouse_move(devtools, x, y):
    devtools.request("Input.dispatchMouseEvent", {
        "type": "mouseMoved",
        "x": x,
        "y": y,
        "button": "none",
        "buttons": 0,
    })
    print(f"mouseMove: {x},{y}")


def capture_devtools_shot(devtools, out_path):
    out_path = out_path.replace("{target}", "openfl")
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


def series_out_path(pattern, label_second, index):
    return (
        pattern
        .replace("{elapsed}", str(label_second))
        .replace("{elapsed03}", f"{label_second:03d}")
        .replace("{index}", str(index))
        .replace("{index03}", f"{index:03d}")
    )


def capture_devtools_shot_series(devtools, pattern, duration, interval=1.0, start_second=0):
    try:
        duration = float(duration)
        interval = float(interval)
        start_second = int(start_second)
    except (TypeError, ValueError):
        raise SystemExit("shotSeries requires numeric duration, interval, and startSecond fields.")
    if duration < 0:
        raise SystemExit("shotSeries duration must be non-negative.")
    if interval <= 0:
        raise SystemExit("shotSeries interval must be positive.")
    started = time.monotonic()
    count = int(duration / interval) + 1
    for index in range(count):
        wait = started + index * interval - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        label_second = int(round(start_second + index * interval))
        capture_devtools_shot(devtools, series_out_path(pattern, label_second, index))


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


def capture_debug_state_series(devtools, duration, interval, label):
    if duration < 0:
        raise SystemExit("debugStateSeries duration must be non-negative.")
    if interval <= 0:
        raise SystemExit("debugStateSeries interval must be positive.")
    started = time.monotonic()
    count = int(duration / interval) + 1
    last_state = None
    for index in range(count):
        wait = started + index * interval - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        state_text = wait_for_sequence_debug_state(devtools)
        if not state_text:
            print(f"Debug series {label} +{index * interval:.2f}s: <none>")
            continue
        if state_text != last_state:
            print(f"Debug series {label} +{index * interval:.2f}s: {state_text}")
            last_state = state_text


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


def wait_for_body_attribute(devtools, name, expected_value, timeout=5.0):
    deadline = time.monotonic() + timeout
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


def require_points(step):
    raw = require_field(step, "points")
    if not isinstance(raw, list):
        raise SystemExit(f"Sequence {step.get('action')} step requires points array: {step}")
    points = []
    for point in raw:
        if not isinstance(point, dict) or "x" not in point or "y" not in point:
            raise SystemExit(f"Invalid drag point: {point}")
        try:
            points.append({"x": float(point["x"]), "y": float(point["y"])})
        except (TypeError, ValueError):
            raise SystemExit(f"Invalid drag point coordinates: {point}")
    return points


def append_query(url, query):
    if not query:
        return url
    normalized = query[1:] if query.startswith("?") else query
    separator = "&" if "?" in url else "?"
    return f"{url}{separator}{normalized}"


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
    parser.add_argument("--delay", type=float, default=5.0)
    parser.add_argument("--query", default="")
    parser.add_argument("--browser")
    parser.add_argument("--base-url", help="existing static/proxy server URL")
    parser.add_argument("--fps-duration", type=float, default=30.0)
    parser.add_argument("--fps-target", type=int, default=30)
    parser.add_argument("--fps-tolerance", type=int, default=5)
    parser.add_argument("--simulation-fps-target", type=int, default=30)
    parser.add_argument("--simulation-fps-tolerance", type=int, default=1)
    parser.add_argument("--expect", action="append", default=[])
    parser.add_argument("--metrics-out")
    parser.add_argument("--replay-out", default=os.path.join("test", "output", "smooth60-replays"))
    parser.add_argument("--benchmark-duration", type=float, default=5.0)
    parser.add_argument(
        "--benchmark-out",
        default=os.path.join("test", "output", "smooth60-benchmark.json"),
    )
    parser.add_argument(
        "--gpu",
        action="store_true",
        help="use the real GPU instead of software rendering (drops --disable-gpu); "
             "higher/steadier framerate but machine-dependent rendering, so avoid for "
             "screenshot-baseline comparisons",
    )
    parser.add_argument(
        "--uncapped-browser-refresh",
        action="store_true",
        help="let the FPS harness receive requestAnimationFrame callbacks faster than 60 Hz",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    shot = subparsers.add_parser("shot")
    shot.add_argument("out")

    sequence = subparsers.add_parser("sequence")
    sequence.add_argument("script")

    subparsers.add_parser("fps")
    subparsers.add_parser("smooth60-flag")
    subparsers.add_parser("smooth60-stability")
    subparsers.add_parser("smooth60-replays")
    subparsers.add_parser("smooth60-benchmark")
    subparsers.add_parser("debug-state")

    args = parser.parse_args()
    if args.command == "shot":
        capture_shot(args.out, args.root, args.delay, args.browser, args.query, args.gpu)
    elif args.command == "sequence":
        run_sequence(args.script, args.root, args.browser, args.base_url, args.gpu, args.metrics_out)
    elif args.command == "fps":
        check_fps(
            args.root,
            args.fps_duration,
            args.fps_target,
            args.fps_tolerance,
            args.simulation_fps_target,
            args.simulation_fps_tolerance,
            args.browser,
            args.query,
            args.gpu,
            args.uncapped_browser_refresh,
        )
    elif args.command == "smooth60-flag":
        check_smooth60_flag(args.root, args.browser, args.gpu)
    elif args.command == "smooth60-stability":
        check_smooth60_stability(args.root, args.browser, args.gpu)
    elif args.command == "smooth60-replays":
        capture_smooth60_replays(args.root, args.browser, args.replay_out, args.gpu)
    elif args.command == "smooth60-benchmark":
        benchmark_smooth60(
            args.root,
            args.browser,
            args.benchmark_out,
            args.benchmark_duration,
            args.gpu,
        )
    elif args.command == "debug-state":
        check_debug_state(args.root, args.delay, args.browser, args.query, args.expect, args.gpu)


if __name__ == "__main__":
    main()
