#!/usr/bin/env python3
"""
compare_symbol_render.py - score the vector renderer against Adobe @4x rasters.

For each case, render one library symbol through the OpenFL vector path
(`?screen=symbol&symbol=<name>&scale=<n>&bg=<hex>`, served from the HTML5
build), then compare the rendered symbol against its Adobe-exported `@4x.png`.

Alignment is deterministic: `SymbolPreview` draws the symbol's drawing bounds at
a fixed stage inset, so the rendered symbol is trimmed to its content box and
resized to the reference raster's dimensions before scoring. This cancels the
sub-pixel offset / anti-aliased edge differences between Inkscape and OpenFL
rasterization that would otherwise dominate a raw pixel diff. Because trimming
then resizing makes the score scale-independent, each symbol is rendered at the
largest scale that still fits inside the 550x400 stage (derived from the
reference @4x dimensions) so large symbols are not clipped.

Cases come from a small committed manifest (default
`tools/symbol_render_cases.json`); see that file for the schema. Examples:

  python3 tools/compare_symbol_render.py
  python3 tools/compare_symbol_render.py --cases tools/symbol_render_cases.json \
      --diff-dir test/output/symbol-diffs --metrics test/output/symbol-metrics.json
  python3 tools/compare_symbol_render.py --symbol UI/Global/MuteButton \
      --reference assets/login/mute_button@4x.png
"""

import argparse
import json
import os
import sys
import tempfile
import time

from PIL import Image, ImageChops, ImageStat

# Reuse the tested OpenFL serve/devtools machinery rather than re-implementing it.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from openfl_driver import (  # noqa: E402
    append_query,
    browser_devtools_session,
    capture_devtools_shot,
    resolve_browser,
    serve,
)

DEFAULT_ROOT = os.path.join("export", "html5", "bin")
DEFAULT_CASES = os.path.join("tools", "symbol_render_cases.json")
DEFAULT_SCALE = 4
DEFAULT_BG = "FFFFFF"
# Adobe reference rasters are exported at this scale.
REFERENCE_SCALE = 4
# Stage size and the SymbolPreview inset; a symbol drawn at INSET must still fit.
STAGE_WIDTH = 550
STAGE_HEIGHT = 400
PREVIEW_INSET = 10
# The symbol screen loads its catalog asynchronously; the preloader shows for
# several seconds before the first real frame, so default to a generous settle.
DEFAULT_DELAY = 8.0
# rmsDelta is the primary gate: gradient/anti-alias differences between Inkscape
# and OpenFL nudge nearly every pixel by a level or two, so differingPercent runs
# high (often ~100%) even for visually faithful renders and is report-only by
# default. Per-case thresholds in the manifest lock in current fidelity.
DEFAULT_THRESHOLD_PERCENT = 100.0
DEFAULT_THRESHOLD_RMS = 24.0


def fit_scale(reference_size, requested_scale):
    """Largest render scale (<= requested) that keeps the symbol inside the stage."""
    budget_w = STAGE_WIDTH - PREVIEW_INSET
    budget_h = STAGE_HEIGHT - PREVIEW_INSET
    # reference_size is at REFERENCE_SCALE; content at scale s spans size*s/REF.
    width_limit = REFERENCE_SCALE * budget_w / max(1, reference_size[0])
    height_limit = REFERENCE_SCALE * budget_h / max(1, reference_size[1])
    return min(requested_scale, width_limit, height_limit)


def slugify(name):
    return "".join(char if char.isalnum() or char in "-_" else "-" for char in name)


def parse_color(value):
    text = str(value).lstrip("#")
    try:
        rgb = int(text, 16)
    except ValueError as error:
        raise SystemExit(f"Invalid background color: {value}") from error
    return ((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF)


def flatten_reference(path, background):
    try:
        image = Image.open(path).convert("RGBA")
    except FileNotFoundError:
        raise SystemExit(f"Missing reference raster: {path}")
    canvas = Image.new("RGB", image.size, background)
    canvas.paste(image, mask=image.getchannel("A"))
    return canvas


def trim_to_content(image, background):
    """Crop a rendered stage capture to the drawn symbol's bounding box."""
    backdrop = Image.new("RGB", image.size, background)
    delta = ImageChops.difference(image, backdrop).convert("L")
    bbox = delta.getbbox()
    if bbox is None:
        return None
    return image.crop(bbox)


def score(expected, actual):
    diff = ImageChops.difference(expected, actual)
    stat = ImageStat.Stat(diff)
    histogram = diff.convert("L").histogram()
    total_pixels = expected.size[0] * expected.size[1]
    differing_pixels = total_pixels - histogram[0]
    return {
        "differingPercent": differing_pixels * 100.0 / total_pixels,
        "meanAbsDelta": sum(stat.mean) / len(stat.mean),
        "rmsDelta": sum(stat.rms) / len(stat.rms),
        "maxDelta": max(channel[1] for channel in diff.getextrema()),
    }


def render_symbol(base_url, symbol, scale, bg_hex, browser, delay, out_path):
    query = f"screen=symbol&symbol={symbol}&scale={scale}&bg={bg_hex}"
    url = append_query(base_url, query)
    with browser_devtools_session(browser, url) as devtools:
        time.sleep(delay)
        capture_devtools_shot(devtools, out_path)
    return Image.open(out_path).convert("RGB")


def compare_case(case, defaults, temp_dir):
    name = case.get("name") or case["symbol"]
    slug = slugify(name)
    symbol = case["symbol"]
    reference = case["reference"]
    bg_hex = str(case.get("bg", defaults["bg"]))
    background = parse_color(bg_hex)
    threshold_percent = case.get("thresholdPercent", defaults["threshold_percent"])
    threshold_rms = case.get("thresholdRms", defaults["threshold_rms"])

    expected = flatten_reference(reference, background)
    # Fit the render to the stage from the reference dimensions so large symbols
    # are not clipped; comparison is scale-independent after trim + resize.
    scale = round(fit_scale(expected.size, case.get("scale", defaults["scale"])), 4)
    capture_path = os.path.join(temp_dir, f"{slug}.png")
    rendered = render_symbol(
        defaults["base_url"], symbol, scale, bg_hex, defaults["browser"], defaults["delay"], capture_path
    )

    actual = trim_to_content(rendered, background)
    if actual is None:
        return {
            "name": name,
            "symbol": symbol,
            "reference": reference,
            "scale": scale,
            "failures": ["rendered symbol was blank (no non-background pixels)"],
            "metrics": None,
            "capture": capture_path,
        }

    actual = actual.resize(expected.size, Image.Resampling.LANCZOS)
    metrics = score(expected, actual)

    diff_path = None
    if defaults["diff_dir"]:
        os.makedirs(defaults["diff_dir"], exist_ok=True)
        diff_path = os.path.join(defaults["diff_dir"], f"{slug}-diff.png")
        diff = ImageChops.difference(expected, actual).point(lambda value: min(255, value * 4))
        diff.save(diff_path)

    failures = []
    if metrics["differingPercent"] > threshold_percent:
        failures.append(
            f"differingPercent {metrics['differingPercent']:.3f}% > {threshold_percent:.3f}%"
        )
    if metrics["rmsDelta"] > threshold_rms:
        failures.append(f"rmsDelta {metrics['rmsDelta']:.3f} > {threshold_rms:.3f}")

    return {
        "name": name,
        "symbol": symbol,
        "reference": reference,
        "scale": scale,
        "size": list(expected.size),
        "thresholds": {"maxDifferingPercent": threshold_percent, "maxRmsDelta": threshold_rms},
        "metrics": metrics,
        "failures": failures,
        "capture": capture_path,
        "diff": diff_path,
    }


def load_cases(args):
    if args.symbol:
        if not args.reference:
            raise SystemExit("--symbol requires --reference")
        return {
            "scale": args.scale or DEFAULT_SCALE,
            "bg": args.bg or DEFAULT_BG,
            "cases": [{"symbol": args.symbol, "reference": args.reference}],
        }
    try:
        with open(args.cases, encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError:
        raise SystemExit(f"Missing cases manifest: {args.cases}")
    if "cases" not in data or not data["cases"]:
        raise SystemExit(f"Cases manifest has no cases: {args.cases}")
    return data


def print_summary(report):
    print(
        "{status} {name} ({symbol}): {size}, "
        "differingPercent={differingPercent:.3f}%, rmsDelta={rmsDelta:.3f}, "
        "maxDelta={maxDelta}".format(
            status="PASS" if not report["failures"] else "FAIL",
            name=report["name"],
            symbol=report["symbol"],
            size="x".join(str(value) for value in report.get("size", [])) or "blank",
            **(report["metrics"] or {"differingPercent": 0.0, "rmsDelta": 0.0, "maxDelta": 0}),
        ),
        flush=True,
    )
    for failure in report["failures"]:
        print(f"  - {failure}", file=sys.stderr)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--cases", default=DEFAULT_CASES, help="JSON cases manifest")
    parser.add_argument("--symbol", help="render a single symbol instead of the manifest")
    parser.add_argument("--reference", help="reference @4x PNG for --symbol")
    parser.add_argument("--root", default=DEFAULT_ROOT, help="HTML5 build root")
    parser.add_argument("--scale", type=float, help="render scale override")
    parser.add_argument("--bg", help="background hex override, e.g. FFFFFF")
    parser.add_argument("--delay", type=float, default=DEFAULT_DELAY, help="render settle seconds")
    parser.add_argument("--browser", help="Chrome/Chromium binary path")
    parser.add_argument("--diff-dir", help="write amplified per-case diff PNGs here")
    parser.add_argument("--metrics", help="write JSON metrics for all cases")
    parser.add_argument("--threshold-percent", type=float, default=DEFAULT_THRESHOLD_PERCENT)
    parser.add_argument("--threshold-rms", type=float, default=DEFAULT_THRESHOLD_RMS)
    args = parser.parse_args(argv or sys.argv[1:])

    manifest = load_cases(args)
    browser = resolve_browser(args.browser)

    reports = []
    with serve(args.root) as base_url, tempfile.TemporaryDirectory(prefix="pr2-symbol-render-") as temp_dir:
        defaults = {
            "base_url": base_url,
            "delay": args.delay,
            "browser": browser,
            "diff_dir": args.diff_dir,
            "scale": args.scale or manifest.get("scale", DEFAULT_SCALE),
            "bg": args.bg or manifest.get("bg", DEFAULT_BG),
            "threshold_percent": args.threshold_percent,
            "threshold_rms": args.threshold_rms,
        }
        for case in manifest["cases"]:
            report = compare_case(case, defaults, temp_dir)
            print_summary(report)
            reports.append(report)

    if args.metrics:
        os.makedirs(os.path.dirname(os.path.abspath(args.metrics)), exist_ok=True)
        with open(args.metrics, "w", encoding="utf-8", newline="\n") as handle:
            json.dump({"cases": reports}, handle, indent=2, sort_keys=True)
            handle.write("\n")

    failed = [report for report in reports if report["failures"]]
    print(f"\n{len(reports) - len(failed)}/{len(reports)} symbols passed.", flush=True)
    if failed:
        print("Symbol render comparison failed: " + ", ".join(r["name"] for r in failed), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
