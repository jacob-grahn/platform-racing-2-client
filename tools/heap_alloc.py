#!/usr/bin/env python3
"""Allocation-sampling profiler for the idle PR2 lobby chat tab. Reports the JS
call sites responsible for the most allocated bytes while idling, to locate the
render-loop allocation leak. Run after warmup so steady-state idle dominates."""
import argparse, collections, shutil, subprocess, tempfile, time
from openfl_driver import (DEFAULT_ROOT, DevToolsSession, reserve_port,
    resolve_browser, serve, wait_for_app_ready, wait_for_page_websocket)


def collect(node, totals):
    cf = node.get("callFrame", {})
    key = (cf.get("functionName") or "(anon)",
           (cf.get("url") or "").rsplit("/", 1)[-1],
           cf.get("lineNumber", -1) + 1)
    totals[key] += node.get("selfSize", 0)
    for child in node.get("children", []):
        collect(child, totals)


def run(root, idle, browser_path, top):
    browser = resolve_browser(browser_path)
    port = reserve_port()
    udd = tempfile.mkdtemp(prefix="pr2-alloc-")
    cmd = [browser, "--headless=new", "--disable-gpu", "--js-flags=--expose-gc",
           "--hide-scrollbars", "--window-size=550,400",
           f"--remote-debugging-port={port}", f"--user-data-dir={udd}"]
    with serve(root) as url:
        url = f"{url}?screen=lobby&user=Tester&lobbyLeftTab=chat"
        cmd.append(url)
        proc = subprocess.Popen(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        s = None
        try:
            s = DevToolsSession(wait_for_page_websocket(port))
            wait_for_app_ready(s)
            s.request("HeapProfiler.enable")
            time.sleep(1.0)
            for i in range(15):
                s.evaluate("window.__pr2InjectFrame && window.__pr2InjectFrame('chat`U%d`%d`m%d')" % (i % 50, i % 4, i))
            time.sleep(0.5)
            s.request("HeapProfiler.startSampling", {"samplingInterval": 2048})
            print(f"Sampling allocations while idle for {idle}s ...")
            time.sleep(idle)
            resp = s.request("HeapProfiler.stopSampling")
            profile = resp.get("result", {}).get("profile", {})
            totals = collections.Counter()
            collect(profile.get("head", {}), totals)
            grand = sum(totals.values()) or 1
            print(f"\nTotal sampled allocation: {grand/1e6:.1f} MB over {idle}s "
                  f"({grand/1e6/idle*60:.1f} MB/min)")
            print(f"\nTop {top} allocation SELF sites:")
            print(f"  {'MB':>7} {'%':>6}  function  [file:line]")
            for key, sz in totals.most_common(top):
                fn, file, line = key
                print(f"  {sz/1e6:7.2f} {100*sz/grand:5.1f}%  {fn}  [{file}:{line}]")
        finally:
            if s:
                s.close()
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill(); proc.wait()
            shutil.rmtree(udd, ignore_errors=True)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--root", default=DEFAULT_ROOT)
    p.add_argument("--idle", type=float, default=20.0)
    p.add_argument("--top", type=int, default=30)
    p.add_argument("--browser")
    a = p.parse_args()
    run(a.root, a.idle, a.browser, a.top)
