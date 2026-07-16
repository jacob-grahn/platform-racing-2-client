#!/usr/bin/env python3
"""Rasterize timeline SVG features unsupported by OpenFL's SVG parser.

The SVG remains the canonical editable source. A single persistent headless
Chrome session renders only exports containing pattern images or SVG filters.
Fallbacks retain Animate's complete 550x400 authoring canvas, so they use the
same origin as native SVG exports and require no placement offsets.
"""

import base64
import argparse
import contextlib
import http.server
import json
import socketserver
import threading
import time
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image
from openfl_driver import browser_devtools_session, resolve_browser


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/timeline-svg-manifest.json"
SVG_ROOT = ROOT / "art/svg/timeline"
UNSUPPORTED_ROOT = ROOT / "art/svg-unsupported/timeline"
PNG_ROOT = ROOT / "art/png/timeline"
REPORT = ROOT / "art/timeline-bitmap-report.json"
UNSUPPORTED_TAGS = frozenset(("filter", "image", "pattern"))


def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def requires_fallback(path):
    tags = {local_name(node.tag) for node in ET.parse(path).getroot().iter()}
    return bool(tags & UNSUPPORTED_TAGS)


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        pass


@contextlib.contextmanager
def serve_art_root():
    handler = lambda *args, **kwargs: QuietHandler(*args, directory=ROOT / "art", **kwargs)
    with socketserver.TCPServer(("127.0.0.1", 0), handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            yield f"http://127.0.0.1:{server.server_address[1]}"
        finally:
            server.shutdown()


def wait_for_load(session):
    deadline = time.time() + 10
    while time.time() < deadline:
        if session.evaluate("document.readyState") == "complete":
            return
        time.sleep(0.01)
    raise RuntimeError("SVG page did not finish loading")


def save_screenshot(temporary, output):
    image = Image.open(temporary).convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)
    return {
        "width": image.width,
        "height": image.height,
        "empty": bbox is None,
    }


def source_path(relative):
    exported = SVG_ROOT / relative
    return exported if exported.exists() else UNSUPPORTED_ROOT / relative


def source_url(relative):
    source = source_path(relative)
    return source.relative_to(ROOT / "art").as_posix()


def organize_sources(fallbacks):
    for relative in fallbacks:
        source = SVG_ROOT / relative
        target = UNSUPPORTED_ROOT / relative
        if source.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            source.replace(target)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--organize-only", action="store_true")
    return parser.parse_args()


def main():
    args = parse_args()
    if args.organize_only:
        report = json.loads(REPORT.read_text(encoding="utf-8"))
        organize_sources(report["fallbacks"])
        print(f"organized {len(report['fallbacks'])} unsupported SVG sources")
        return
    plan = json.loads(MANIFEST.read_text(encoding="utf-8"))
    jobs = [job for job in plan["exports"] if source_path(job["exportPath"]).exists() and requires_fallback(source_path(job["exportPath"]))]
    browser = resolve_browser(None)
    fallbacks = {}
    with serve_art_root() as base_url:
        first_url = f"{base_url}/{source_url(jobs[0]['exportPath'])}"
        with browser_devtools_session(browser, first_url) as session:
            session.request("Emulation.setDeviceMetricsOverride", {
                "width": 550,
                "height": 400,
                "deviceScaleFactor": 2,
                "mobile": False,
            })
            session.request("Emulation.setDefaultBackgroundColorOverride", {
                "color": {"r": 0, "g": 0, "b": 0, "a": 0}
            })
            for index, job in enumerate(jobs):
                relative = Path(job["exportPath"])
                session.request("Page.navigate", {"url": f"{base_url}/{source_url(job['exportPath'])}"})
                wait_for_load(session)
                response = session.request("Page.captureScreenshot", {
                    "format": "png",
                    "fromSurface": True,
                    "captureBeyondViewport": False,
                })
                temporary = PNG_ROOT / ".capture.png"
                temporary.parent.mkdir(parents=True, exist_ok=True)
                temporary.write_bytes(base64.b64decode(response["result"]["data"]))
                output = (PNG_ROOT / relative).with_suffix(".png")
                result = save_screenshot(temporary, output)
                temporary.unlink()
                result["assetPath"] = "assets/timeline-bitmap/" + relative.with_suffix(".png").as_posix()
                result["sourceSvg"] = job["exportPath"]
                result["scale"] = 0.5
                fallbacks[job["exportPath"]] = result
                print(f"{index + 1}/{len(jobs)} {job['exportPath']}")
    report = {
        "schema": "pr2-timeline-bitmap-report-v1",
        "fallbackCount": len(fallbacks),
        "fallbacks": fallbacks,
    }
    REPORT.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    organize_sources(fallbacks)
    print(f"rasterized {len(fallbacks)} unsupported timeline SVGs")


if __name__ == "__main__":
    main()
