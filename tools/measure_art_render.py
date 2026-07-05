#!/usr/bin/env python3
"""Measure art-heavy level drawing through the OpenFL campaign harness."""

import argparse
import json
import os
import shutil
import statistics
import subprocess
import sys
import tempfile
import time

from openfl_driver import (
    DevToolsSession,
    browser_harness_flags,
    gpu_flags,
    reserve_port,
    resolve_browser,
    wait_for_page_websocket,
)


def parse_state(text):
    out = {}
    for part in text.split(";"):
        if "=" in part:
            key, value = part.split("=", 1)
            out[key] = value
    return out


def read_metrics(session):
    response = session.request("Performance.getMetrics")
    return {item["name"]: item["value"] for item in response.get("result", {}).get("metrics", [])}


def wait_for_app_ready(session, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        error = session.evaluate('document.body.getAttribute("data-pr2-error") || ""')
        if error:
            raise SystemExit(f"app error: {error}")
        if session.evaluate('document.body.getAttribute("data-pr2-app-ready") || ""'):
            return
        time.sleep(0.1)
    raise SystemExit(f"timed out after {timeout}s waiting for app ready")


def summarize(rows):
    drawing = [row for row in rows if row["phase"] == "drawing"]
    playable = [row for row in rows if row["phase"] in ("playable", "post-playable")]
    result = {
        "samples": len(rows),
        "firstDrawingSec": drawing[0]["t"] if drawing else None,
        "lastDrawingSec": drawing[-1]["t"] if drawing else None,
        "firstPlayableSec": playable[0]["t"] if playable else None,
        "maxArt": max((row["art"] for row in rows), default=0),
        "maxBlocks": max((row["blocks"] for row in rows), default=0),
    }
    if drawing:
        fps = [row["fps"] for row in drawing]
        result.update({
            "drawingDurationSec": (playable[0]["t"] - drawing[0]["t"]) if playable else (drawing[-1]["t"] - drawing[0]["t"]),
            "drawingFpsMin": min(fps),
            "drawingFpsMean": statistics.mean(fps),
            "drawingFpsMedian": statistics.median(fps),
            "drawingFpsMax": max(fps),
            "artPerSec": (drawing[-1]["art"] - drawing[0]["art"]) / max(drawing[-1]["t"] - drawing[0]["t"], 0.001),
        })
    if playable:
        fps = [row["fps"] for row in playable]
        result.update({
            "playableFpsMin": min(fps),
            "playableFpsMean": statistics.mean(fps),
            "playableFpsMedian": statistics.median(fps),
            "playableFpsMax": max(fps),
        })
    return result


def run(args):
    browser = resolve_browser(args.browser)
    url = (
        f"{args.base_url.rstrip('/')}/index.html"
        f"?screen=campaign&debug=1&levelId={args.level_id}&version={args.version}&apiHost={args.api_host}"
    )
    debug_port = reserve_port()
    user_data_dir = tempfile.mkdtemp(prefix="pr2-art-render-")
    command = [
        browser,
        "--headless=new",
        *browser_harness_flags(),
        "--js-flags=--expose-gc",
        *gpu_flags(args.gpu),
        "--hide-scrollbars",
        "--window-size=550,400",
        f"--remote-debugging-port={debug_port}",
        f"--user-data-dir={user_data_dir}",
        url,
    ]

    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    session = None
    rows = []
    started = time.monotonic()
    try:
        session = DevToolsSession(wait_for_page_websocket(debug_port))
        session.request("Performance.enable")
        wait_for_app_ready(session, args.boot_timeout)
        session.evaluate(
            "window.__pr2Frames=0;"
            "(function tick(){window.__pr2Frames++;requestAnimationFrame(tick);})();"
        )
        last = time.monotonic()
        post_playable = 0
        last_phase = ""
        last_art = -1
        print(f"measuring {url}")
        while time.monotonic() - started < args.timeout:
            time.sleep(args.interval)
            now = time.monotonic()
            elapsed = max(now - last, 0.001)
            last = now
            state_text = session.evaluate('document.body.getAttribute("data-pr2-debug-state") || ""')
            state = parse_state(state_text)
            frames = session.evaluate("window.__pr2Frames || 0")
            session.evaluate("window.__pr2Frames = 0")
            metrics = read_metrics(session)
            phase = state.get("phase", "")
            art = int(state.get("art") or 0)
            blocks = int(state.get("blocks") or 0)
            fps = float(frames) / elapsed
            row = {
                "t": now - started,
                "phase": phase,
                "state": state_text,
                "art": art,
                "blocks": blocks,
                "fps": fps,
                "heap": metrics.get("JSHeapUsedSize"),
                "nodes": metrics.get("Nodes"),
                "taskDuration": metrics.get("TaskDuration"),
                "scriptDuration": metrics.get("ScriptDuration"),
            }
            rows.append(row)
            if phase != last_phase or art != last_art or len(rows) % args.print_every == 0:
                print(
                    f"t={row['t']:6.2f}s phase={phase:12s} blocks={blocks:5d} "
                    f"art={art:5d} fps={fps:5.1f} heapMB={(row['heap'] or 0) / 1e6:5.1f}"
                )
            last_phase = phase
            last_art = art
            if phase == "playable":
                post_playable += 1
                row["phase"] = "post-playable" if post_playable > 1 else "playable"
                if post_playable >= args.post_playable_samples:
                    break
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

    report = {
        "label": args.label,
        "url": url,
        "levelId": args.level_id,
        "version": args.version,
        "summary": summarize(rows),
        "rows": rows,
    }
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
    print(f"saved {args.out}")
    print(json.dumps(report["summary"], indent=2, sort_keys=True))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--level-id", type=int, default=5821108)
    parser.add_argument("--version", type=int, default=92)
    parser.add_argument("--base-url", default="http://127.0.0.1:8000")
    parser.add_argument("--api-host", default="/api")
    parser.add_argument("--label", default="baseline")
    parser.add_argument("--out", default="test/output/art-render-smog-baseline.json")
    parser.add_argument("--interval", type=float, default=0.25)
    parser.add_argument("--print-every", type=int, default=12)
    parser.add_argument("--post-playable-samples", type=int, default=8)
    parser.add_argument("--boot-timeout", type=float, default=60)
    parser.add_argument("--timeout", type=float, default=150)
    parser.add_argument("--browser")
    parser.add_argument("--gpu", action="store_true")
    run(parser.parse_args())


if __name__ == "__main__":
    main()
