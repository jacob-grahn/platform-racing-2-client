#!/usr/bin/env python3
"""
heap_diff.py - take two V8 heap snapshots of the idle PR2 lobby chat tab and
report which object constructors grew, to localize the render-loop leak.

Boots the lobby chat tab, adds a few chat lines, then takes snapshot A, idles
for --idle seconds while the render loop runs, forces GC, takes snapshot B, and
prints the constructors with the largest retained-count / retained-size growth.

Usage:
  python3 tools/heap_diff.py --idle 30
"""

import argparse
import collections
import json
import shutil
import subprocess
import tempfile
import time

from openfl_driver import (
    DEFAULT_ROOT,
    DevToolsSession,
    reserve_port,
    resolve_browser,
    serve,
    wait_for_app_ready,
    wait_for_page_websocket,
)


def take_snapshot(session):
    """Drive HeapProfiler.takeHeapSnapshot and collect the streamed chunks."""
    ws = session.ws
    req_id = session.next_id
    session.next_id += 1
    ws.send_text(json.dumps({
        "id": req_id,
        "method": "HeapProfiler.takeHeapSnapshot",
        "params": {"reportProgress": False, "captureNumericValue": False},
    }))
    chunks = []
    while True:
        msg = json.loads(ws.recv_text())
        if msg.get("method") == "HeapProfiler.addHeapSnapshotChunk":
            chunks.append(msg["params"]["chunk"])
        elif msg.get("id") == req_id:
            break
    return json.loads("".join(chunks))


def aggregate(snapshot):
    """Sum count and self_size per node name (constructor/class)."""
    meta = snapshot["snapshot"]["meta"]
    node_fields = meta["node_fields"]
    name_idx = node_fields.index("name")
    size_idx = node_fields.index("self_size")
    type_idx = node_fields.index("type")
    stride = len(node_fields)
    node_types = meta["node_types"][type_idx]
    strings = snapshot["strings"]
    nodes = snapshot["nodes"]

    count = collections.Counter()
    size = collections.Counter()
    for base in range(0, len(nodes), stride):
        name = strings[nodes[base + name_idx]]
        type_name = node_types[nodes[base + type_idx]]
        # Group by "type:name" so e.g. object constructors and strings separate.
        key = f"{type_name}:{name}" if type_name in ("object",) else type_name
        count[key] += 1
        size[key] += nodes[base + size_idx]
    return count, size


def run(root, idle, warmup, headless, browser_path, top):
    browser = resolve_browser(browser_path)
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-heapdiff-")
    command = [browser]
    if headless:
        command += ["--headless=new", "--disable-gpu"]
    else:
        command += ["--new-window", "--no-first-run", "--no-default-browser-check",
                    "--disable-backgrounding-occluded-windows",
                    "--disable-renderer-backgrounding",
                    "--disable-background-timer-throttling"]
    command += ["--js-flags=--expose-gc", "--hide-scrollbars", "--window-size=550,400",
                f"--remote-debugging-port={debug_port}", f"--user-data-dir={user_data_dir}"]

    with serve(root) as url:
        url = f"{url}?screen=lobby&user=Tester&lobbyLeftTab=chat"
        command.append(url)
        process = subprocess.Popen(command, text=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        session = None
        try:
            session = DevToolsSession(wait_for_page_websocket(debug_port))
            wait_for_app_ready(session)
            session.request("HeapProfiler.enable")
            time.sleep(1.0)
            tab = session.evaluate("document.body.getAttribute('data-pr2-lobby-left')")
            print(f"lobby-left tab = {tab!r}")
            for i in range(warmup):
                session.evaluate(
                    "window.__pr2InjectFrame && window.__pr2InjectFrame("
                    "'chat`User%d`%d`idle leak hunt message %d')" % (i % 50, i % 4, i))
            time.sleep(0.5)

            def gc():
                session.evaluate("window.gc && window.gc()")
                time.sleep(0.3)

            gc()
            print("Snapshot A ...")
            snap_a = take_snapshot(session)
            count_a, size_a = aggregate(snap_a)

            print(f"Idling {idle}s with render loop running ...")
            time.sleep(idle)

            gc()
            print("Snapshot B ...")
            snap_b = take_snapshot(session)
            count_b, size_b = aggregate(snap_b)

            report(count_a, size_a, count_b, size_b, idle, top)
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


def report(count_a, size_a, count_b, size_b, idle, top):
    keys = set(count_a) | set(count_b)
    growth = []
    for k in keys:
        dc = count_b[k] - count_a[k]
        ds = size_b[k] - size_a[k]
        growth.append((ds, dc, k))

    print(f"\n=== Retained-SIZE growth over {idle}s idle (top {top}) ===")
    print(f"  {'+bytes':>12} {'+KB/min':>9} {'+count':>9}  constructor")
    for ds, dc, k in sorted(growth, reverse=True)[:top]:
        kb_min = ds / 1024 / idle * 60
        print(f"  {ds:12d} {kb_min:9.1f} {dc:9d}  {k}")

    print(f"\n=== Retained-COUNT growth over {idle}s idle (top {top}) ===")
    print(f"  {'+count':>9} {'+/min':>9} {'+bytes':>12}  constructor")
    for ds, dc, k in sorted(growth, key=lambda g: g[1], reverse=True)[:top]:
        per_min = dc / idle * 60
        print(f"  {dc:9d} {per_min:9.0f} {ds:12d}  {k}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--root", default=DEFAULT_ROOT)
    p.add_argument("--idle", type=float, default=30.0)
    p.add_argument("--warmup", type=int, default=15)
    p.add_argument("--top", type=int, default=25)
    p.add_argument("--browser")
    p.add_argument("--no-headless", dest="headless", action="store_false")
    p.set_defaults(headless=True)
    a = p.parse_args()
    run(a.root, a.idle, a.warmup, a.headless, a.browser, a.top)


if __name__ == "__main__":
    main()
