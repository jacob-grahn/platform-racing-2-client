#!/usr/bin/env python3
"""
leak_probe.py - drive the PR2 lobby chat tab over a long session and sample
memory/CPU growth via Chrome DevTools, to localize a suspected leak.

It serves export/html5/bin, opens the lobby, selects the Chat tab, then injects
chat frames in batches through the temporary window.__pr2InjectFrame hook while
periodically reading Performance.getMetrics (JS heap, DOM nodes, listeners,
layout/recalc counts). Growth that tracks the number of injected messages is the
leak signal.

Usage:
  python3 tools/leak_probe.py --messages 4000 --batch 40 --samples 25
  python3 tools/leak_probe.py --no-headless
"""

import argparse
import json
import shutil
import subprocess
import tempfile
import time

from openfl_driver import (
    DEFAULT_ROOT,
    DevToolsSession,
    dispatch_click,
    reserve_port,
    resolve_browser,
    serve,
    wait_for_app_ready,
    wait_for_page_websocket,
)

METRIC_KEYS = [
    "JSHeapUsedSize", "JSHeapTotalSize", "Nodes", "JSEventListeners",
    "LayoutCount", "RecalcStyleCount", "Documents", "Frames", "MediaKeySessions",
    "LayoutObjects",
]


def read_metrics(session):
    resp = session.request("Performance.getMetrics")
    out = {}
    for m in resp.get("result", {}).get("metrics", []):
        out[m["name"]] = m["value"]
    return out


def select_chat_tab(session):
    # The Chat tab is the leftmost tab of the left pane (pane at x=3). Try a few
    # plausible hit points until the body attribute reports the chat tab active.
    for (x, y) in [(22, 9), (22, 12), (18, 8), (28, 10), (15, 11), (30, 13)]:
        dispatch_click(session, x, y)
        time.sleep(0.3)
        tab = session.evaluate(
            "document.body.getAttribute('data-pr2-lobby-left')"
        )
        if tab == "chat":
            return True
    return False


def inject_batch(session, count, start_index):
    # Build a JS loop that injects `count` chat frames: chat`name`group`text.
    # Vary name/group/text so nothing is trivially de-duplicated.
    expr = (
        "(function(){"
        "  if(!window.__pr2InjectFrame) return 'no-hook';"
        "  for(var i=0;i<%d;i++){"
        "    var n=%d+i;"
        "    window.__pr2InjectFrame('chat`User'+(n%%50)+'`'+(n%%4)+'`message number '+n+' hello world');"
        "  }"
        "  return 'ok';"
        "})()" % (count, start_index)
    )
    return session.evaluate(expr)


def run(root, warmup, interval, samples, headless, browser_path, gc_each):
    browser = resolve_browser(browser_path)
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-leak-")
    command = [browser]
    if headless:
        command += ["--headless=new", "--disable-gpu"]
    else:
        command += [
            "--new-window", "--no-first-run", "--no-default-browser-check",
            "--disable-backgrounding-occluded-windows",
            "--disable-renderer-backgrounding",
            "--disable-background-timer-throttling",
        ]
    command += [
        "--js-flags=--expose-gc",
        "--hide-scrollbars", "--window-size=550,400",
        f"--remote-debugging-port={debug_port}",
        f"--user-data-dir={user_data_dir}",
    ]

    with serve(root) as url:
        url = f"{url}?screen=lobby&user=Tester&lobbyLeftTab=chat"
        command.append(url)
        process = subprocess.Popen(command, text=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        session = None
        try:
            page_ws_url = wait_for_page_websocket(debug_port)
            session = DevToolsSession(page_ws_url)
            wait_for_app_ready(session)
            session.request("Performance.enable")
            time.sleep(1.0)

            tab = session.evaluate("document.body.getAttribute('data-pr2-lobby-left')")
            if tab != "chat" and not select_chat_tab(session):
                print("WARNING: could not confirm chat tab active; continuing anyway")
            else:
                print("Chat tab active.")
            time.sleep(0.5)

            rows = []

            def force_gc():
                session.evaluate("window.gc && window.gc()")
                time.sleep(0.3)

            # Scenario: add a handful of chat lines once, then sit idle and let
            # the render loop run. The reported slowdown happens while idling, so
            # any growth here is the rAF/render loop, not message handling.
            for i in range(warmup):
                inject_batch(session, 1, i)
            time.sleep(0.5)

            # Install a real rAF frame counter so we can measure render FPS per
            # interval and watch it decay.
            session.evaluate(
                "window.__pr2Frames=0;"
                "(function tick(){window.__pr2Frames++;requestAnimationFrame(tick);})();"
            )

            force_gc()
            base = read_metrics(session)
            t_start = time.time()
            rows.append((0.0, base))
            print(f"warmup={warmup} messages, then idling. interval={interval}s x {samples}")
            print(f"{'t(s)':>7} {'heapMB':>8} {'nodes':>8} {'listeners':>10} "
                  f"{'layoutObj':>10} {'layoutCnt':>10} {'recalc':>10} {'fps':>7}")
            print_row(0.0, base)

            for s in range(samples):
                session.evaluate("window.__pr2Frames=0")
                time.sleep(interval)
                frames = session.evaluate("window.__pr2Frames||0")
                try:
                    fps = float(frames) / interval
                except (TypeError, ValueError):
                    fps = 0.0
                if gc_each:
                    force_gc()
                m = read_metrics(session)
                m["_fps"] = fps
                t = time.time() - t_start
                rows.append((t, m))
                print_row(t, m)

            print()
            force_gc()
            final = read_metrics(session)
            print("After forced GC:")
            print_row(time.time() - t_start, final)

            summarize(rows, base, final)
            with open("test/output/leak_metrics.json", "w") as f:
                json.dump([{"t": t, **m} for (t, m) in rows] +
                          [{"t": time.time() - t_start, "afterGC": True, **final}], f, indent=2)
            print("\nRaw metrics: test/output/leak_metrics.json")
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


def print_row(t, m):
    heap_mb = m.get("JSHeapUsedSize", 0) / 1e6
    print(f"{t:7.1f} {heap_mb:8.1f} {int(m.get('Nodes',0)):8d} "
          f"{int(m.get('JSEventListeners',0)):10d} {int(m.get('LayoutObjects',0)):10d} "
          f"{int(m.get('LayoutCount',0)):10d} {int(m.get('RecalcStyleCount',0)):10d} "
          f"{m.get('_fps',0):7.1f}")


def summarize(rows, base, final):
    if len(rows) < 2:
        return
    span = rows[-1][0] or 1.0
    print("\n=== Growth summary (per minute of idle) ===")
    for key in ["JSHeapUsedSize", "Nodes", "JSEventListeners", "LayoutObjects",
                "LayoutCount", "RecalcStyleCount"]:
        d = final.get(key, 0) - base.get(key, 0)
        per_min = d / span * 60.0
        if key == "JSHeapUsedSize":
            print(f"  {key:18s}: +{d/1e6:8.2f} MB total  ({per_min/1e6:+.3f} MB / min)")
        else:
            print(f"  {key:18s}: +{int(d):8d}     total  ({per_min:+.1f} / min)")
    first_fps = rows[1][1].get("_fps", 0) if len(rows) > 1 else 0
    last_fps = rows[-1][1].get("_fps", 0)
    print(f"  {'FPS':18s}: {first_fps:.1f} -> {last_fps:.1f}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--root", default=DEFAULT_ROOT)
    p.add_argument("--warmup", type=int, default=15,
                   help="chat messages to add once before idling")
    p.add_argument("--interval", type=float, default=5.0,
                   help="seconds between samples while idle")
    p.add_argument("--samples", type=int, default=24)
    p.add_argument("--browser")
    p.add_argument("--gc-each", action="store_true",
                   help="force GC before each sample (isolates retained growth from churn)")
    p.add_argument("--no-headless", dest="headless", action="store_false")
    p.set_defaults(headless=True)
    a = p.parse_args()
    run(a.root, a.warmup, a.interval, a.samples, a.headless, a.browser, a.gc_each)


if __name__ == "__main__":
    main()
