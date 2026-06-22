#!/usr/bin/env python3
"""Trace what retains the render-loop leak. Takes two heap snapshots of the idle
chat tab (V8 node ids are stable across snapshots), finds nodes created between
A and B of a target constructor, and walks retaining edges to a GC root for a
sample, printing the retainer chain. Pinpoints the structure holding the leak."""
import argparse, collections, json, shutil, subprocess, tempfile, time
from openfl_driver import (DEFAULT_ROOT, DevToolsSession, reserve_port,
    resolve_browser, serve, wait_for_app_ready, wait_for_page_websocket)
from heap_diff import take_snapshot


def parse(snapshot):
    meta = snapshot["snapshot"]["meta"]
    nf = meta["node_fields"]; ef = meta["edge_fields"]
    nstride = len(nf); estride = len(ef)
    ni = {k: nf.index(k) for k in ("type", "name", "id", "self_size", "edge_count")}
    ei = {k: ef.index(k) for k in ("type", "name_or_index", "to_node")}
    node_types = meta["node_types"][nf.index("type")]
    edge_types = meta["edge_types"][ef.index("type")]
    nodes = snapshot["nodes"]; edges = snapshot["edges"]; strings = snapshot["strings"]
    n = len(nodes) // nstride
    # edge start offset per node
    edge_start = [0] * (n + 1)
    for i in range(n):
        edge_start[i + 1] = edge_start[i] + nodes[i * nstride + ni["edge_count"]]
    return dict(nodes=nodes, edges=edges, strings=strings, nstride=nstride,
                estride=estride, ni=ni, ei=ei, node_types=node_types,
                edge_types=edge_types, n=n, edge_start=edge_start)


def node_name(P, i):
    return P["strings"][P["nodes"][i * P["nstride"] + P["ni"]["name"]]]


def node_type(P, i):
    return P["node_types"][P["nodes"][i * P["nstride"] + P["ni"]["type"]]]


def node_id(P, i):
    return P["nodes"][i * P["nstride"] + P["ni"]["id"]]


def build_reverse(P):
    rev = collections.defaultdict(list)  # to_node_index -> [(from_index, edge_name)]
    nodes, edges = P["nodes"], P["edges"]
    estride, nstride = P["estride"], P["nstride"]
    ei = P["ei"]
    for src in range(P["n"]):
        s = P["edge_start"][src]
        e = P["edge_start"][src + 1]
        for k in range(s, e):
            base = k * estride
            to_node_off = edges[base + ei["to_node"]]
            to_idx = to_node_off // nstride
            etype = P["edge_types"][edges[base + ei["type"]]]
            nm = edges[base + ei["name_or_index"]]
            label = P["strings"][nm] if etype in ("property", "internal", "shortcut") and nm < len(P["strings"]) else f"[{etype}]"
            rev[to_idx].append((src, label))
    return rev


def run(root, idle, target, samples, browser_path):
    browser = resolve_browser(browser_path); port = reserve_port(); udd = tempfile.mkdtemp(prefix="pr2-ret-")
    cmd = [browser, "--headless=new", "--disable-gpu", "--js-flags=--expose-gc",
           "--hide-scrollbars", "--window-size=550,400",
           f"--remote-debugging-port={port}", f"--user-data-dir={udd}"]
    with serve(root) as url:
        cmd.append(f"{url}?screen=lobby&user=Tester&lobbyLeftTab=chat")
        proc = subprocess.Popen(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        s = None
        try:
            s = DevToolsSession(wait_for_page_websocket(port)); wait_for_app_ready(s)
            s.request("HeapProfiler.enable"); time.sleep(1.0)
            for i in range(15):
                s.evaluate("window.__pr2InjectFrame && window.__pr2InjectFrame('chat`U%d`%d`m%d')" % (i % 50, i % 4, i))
            time.sleep(0.5)
            s.evaluate("window.gc && window.gc()"); time.sleep(0.3)
            A = parse(take_snapshot(s))
            ids_a = set()
            for i in range(A["n"]):
                ids_a.add(node_id(A, i))
            print(f"Idling {idle}s ...")
            time.sleep(idle)
            s.evaluate("window.gc && window.gc()"); time.sleep(0.3)
            B = parse(take_snapshot(s))
            print("Building reverse edge graph ...")
            rev = build_reverse(B)

            new_targets = [i for i in range(B["n"])
                           if node_name(B, i) == target and node_id(B, i) not in ids_a]
            print(f"\n{len(new_targets)} NEW '{target}' nodes since A. Tracing {min(samples,len(new_targets))} to a root:\n")
            for idx in new_targets[:samples]:
                trace_to_root(B, rev, idx)
                print()
        finally:
            if s:
                s.close()
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill(); proc.wait()
            shutil.rmtree(udd, ignore_errors=True)


def trace_to_root(P, rev, start, max_depth=40):
    # BFS from the leaf toward GC roots, following reverse (retaining) edges.
    # came_from[node] = (discovered_from_toward_leaf, edge_label). Stop at a
    # synthetic root (GC root) or when we run out / hit depth.
    from collections import deque
    came_from = {start: (None, "")}
    q = deque([(start, 0)])
    goal = None
    while q:
        cur, d = q.popleft()
        if node_type(P, cur) == "synthetic":
            goal = cur
            break
        if d >= max_depth:
            continue
        for (src, label) in rev.get(cur, []):
            if src not in came_from:
                came_from[src] = (cur, label)
                q.append((src, d + 1))
    if goal is None:
        # No synthetic root within depth; use the deepest node reached.
        goal = max(came_from, key=lambda x: 0)  # fallback: any; refined below
        # pick the node whose came_from chain is longest
        def depth_of(n):
            dd = 0
            while came_from[n][0] is not None:
                n = came_from[n][0]; dd += 1
            return dd
        goal = max(came_from, key=depth_of)
    # reconstruct root(goal) -> ... -> start
    chain = []
    n = goal
    while n is not None:
        prev, label = came_from[n]
        chain.append((n, label))
        n = prev
    parts = []
    for nd, label in chain:  # already ordered root -> leaf
        nm = node_name(P, nd) or "?"
        ty = node_type(P, nd)
        seg = f"{ty}:{nm}"
        if label:
            seg += f" --{label}-->"
        parts.append(seg)
    print("  " + " ".join(parts))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--root", default=DEFAULT_ROOT)
    p.add_argument("--idle", type=float, default=20.0)
    p.add_argument("--target", default="openfl_geom_Matrix")
    p.add_argument("--samples", type=int, default=6)
    p.add_argument("--browser")
    a = p.parse_args()
    run(a.root, a.idle, a.target, a.samples, a.browser)
