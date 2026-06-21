#!/usr/bin/env python3
"""
openfl_profile.py - capture a Chrome CPU profile of the PR2 OpenFL HTML5 build.

Serves export/html5/bin, launches headless Chrome with remote debugging,
loads a chosen screen (default: the lobby), records a V8 CPU sampling profile
for a fixed duration, then writes the raw .cpuprofile and prints the functions
with the most self time so render/update hot spots are obvious.

Usage:
  python3 tools/openfl_profile.py
  python3 tools/openfl_profile.py --query 'screen=lobby&user=Tester' --duration 12
  python3 tools/openfl_profile.py --out test/output/lobby.cpuprofile --top 40

Load the written .cpuprofile in Chrome DevTools (Performance > Load profile)
for a flame chart.
"""

import argparse
import collections
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

from openfl_driver import (
    DEFAULT_ROOT,
    DevToolsSession,
    reserve_port,
    resolve_browser,
    serve,
    wait_for_page_websocket,
)


def capture_profile(root, query, duration, out_path, browser_path, top, interval_us, headless):
    browser = resolve_browser(browser_path)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)

    with serve(root) as url:
        if query:
            url = f"{url}?{query[1:] if query.startswith('?') else query}"
        profile, fps_samples = run_profiler(browser, url, duration, interval_us, headless)

    with open(out_path, "w") as file:
        json.dump(profile, file)

    print(f"Profile saved: {out_path}")
    print(f"Loaded URL: {url}")
    if fps_samples:
        print(f"FPS samples during capture: {fps_samples}")
    report_hot_functions(profile, top)


def run_profiler(browser, url, duration, interval_us, headless):
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-openfl-profile-")
    command = [browser]
    if headless:
        # Software canvas path; renders fine even when a real browser stalls.
        command += ["--headless=new", "--disable-gpu"]
    else:
        # Real GPU-accelerated canvas, where per-frame filter readbacks stall.
        # Disable background/occluded throttling so an unfocused window still
        # renders at full rate (otherwise Chrome caps rAF and the measurement
        # reflects throttling, not the actual render cost).
        command += [
            "--new-window", "--no-first-run", "--no-default-browser-check",
            "--disable-backgrounding-occluded-windows",
            "--disable-renderer-backgrounding",
            "--disable-background-timer-throttling",
        ]
    command += [
        "--hide-scrollbars",
        "--window-size=550,400",
        f"--remote-debugging-port={debug_port}",
        f"--user-data-dir={user_data_dir}",
        url,
    ]
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    session = None
    try:
        page_ws_url = wait_for_page_websocket(debug_port)
        session = DevToolsSession(page_ws_url)
        # Let the app boot and reach steady state before sampling.
        time.sleep(3.0)
        # Install a real requestAnimationFrame counter to measure actual FPS.
        session.evaluate(
            "window.__pr2Frames = 0;"
            "(function tick(){ window.__pr2Frames++; requestAnimationFrame(tick); })();"
        )
        session.request("Profiler.enable")
        session.request("Profiler.setSamplingInterval", {"interval": interval_us})
        session.request("Profiler.start")
        print(f"Profiling for {duration}s ...")
        time.sleep(duration)
        response = session.request("Profiler.stop")
        profile = response.get("result", {}).get("profile", {})
        frames = session.evaluate("window.__pr2Frames || 0")
        try:
            measured_fps = float(frames) / duration
        except (TypeError, ValueError):
            measured_fps = 0.0
        fps_samples = f"measured rAF fps ~{measured_fps:.1f} ({frames} frames / {duration:.0f}s)"
        return profile, fps_samples
    finally:
        if session is not None:
            session.close()
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        shutil.rmtree(user_data_dir, ignore_errors=True)


def report_hot_functions(profile, top):
    nodes = profile.get("nodes", [])
    samples = profile.get("samples", [])
    deltas = profile.get("timeDeltas", [])
    if not nodes or not samples:
        print("No samples captured.", file=sys.stderr)
        return

    node_by_id = {node["id"]: node for node in nodes}
    # Map each node to its parent so we can attribute self-time up the tree.
    parent_of = {}
    for node in nodes:
        for child in node.get("children", []):
            parent_of[child] = node["id"]

    self_time = collections.defaultdict(float)
    total_time = collections.defaultdict(float)
    self_count = collections.defaultdict(int)

    for index, node_id in enumerate(samples):
        delta = deltas[index] if index < len(deltas) else 0
        delta_ms = max(delta, 0) / 1000.0
        self_time[node_id] += delta_ms
        self_count[node_id] += 1
        # Walk up the ancestry to accumulate total (inclusive) time.
        seen = set()
        current = node_id
        while current is not None and current not in seen:
            seen.add(current)
            total_time[current] += delta_ms
            current = parent_of.get(current)

    grand_total = sum(self_time.values()) or 1.0

    def label(node_id):
        frame = node_by_id.get(node_id, {}).get("callFrame", {})
        name = frame.get("functionName") or "(anonymous)"
        url = frame.get("url") or ""
        line = frame.get("lineNumber", -1)
        short_url = url.rsplit("/", 1)[-1] if url else ""
        location = f"{short_url}:{line + 1}" if short_url else "(native)"
        return f"{name}  [{location}]"

    print()
    print(f"Total sampled CPU time: {grand_total:.0f} ms across {len(samples)} samples")
    print()
    print(f"Top {top} functions by SELF time:")
    print(f"  {'self ms':>9} {'self %':>7} {'samples':>8}  function")
    ranked = sorted(self_time.items(), key=lambda item: item[1], reverse=True)[:top]
    for node_id, ms in ranked:
        pct = 100.0 * ms / grand_total
        print(f"  {ms:9.0f} {pct:6.1f}% {self_count[node_id]:8d}  {label(node_id)}")

    print()
    print(f"Top {top} functions by TOTAL (inclusive) time:")
    print(f"  {'total ms':>9} {'total %':>7}  function")
    ranked_total = sorted(total_time.items(), key=lambda item: item[1], reverse=True)[:top]
    for node_id, ms in ranked_total:
        pct = 100.0 * ms / grand_total
        print(f"  {ms:9.0f} {pct:6.1f}%  {label(node_id)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=DEFAULT_ROOT)
    parser.add_argument("--query", default="screen=lobby&user=Tester")
    parser.add_argument("--duration", type=float, default=10.0)
    parser.add_argument("--out", default="test/output/lobby.cpuprofile")
    parser.add_argument("--browser")
    parser.add_argument("--top", type=int, default=30)
    parser.add_argument("--interval-us", type=int, default=200,
                        help="V8 sampling interval in microseconds (smaller = finer).")
    parser.add_argument("--no-headless", dest="headless", action="store_false",
                        help="Launch a visible GPU-accelerated Chrome (reproduces real-browser stalls).")
    parser.set_defaults(headless=True)
    args = parser.parse_args()
    capture_profile(args.root, args.query, args.duration, args.out, args.browser,
                    args.top, args.interval_us, args.headless)


if __name__ == "__main__":
    main()
