#!/usr/bin/env python3
"""Validate the complete timeline SVG export against its generated plan."""

import json
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/timeline-svg-manifest.json"
SVG_ROOT = ROOT / "art/svg/timeline"
UNSUPPORTED_ROOT = ROOT / "art/svg-unsupported/timeline"
REPORT = ROOT / "test/output/timeline-svg-report.json"


def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def main():
    plan = json.loads(MANIFEST.read_text(encoding="utf-8"))
    expected = {job["exportPath"] for job in plan["exports"]}
    runtime = {path.relative_to(SVG_ROOT).as_posix() for path in SVG_ROOT.rglob("*.svg")}
    unsupported = {path.relative_to(UNSUPPORTED_ROOT).as_posix() for path in UNSUPPORTED_ROOT.rglob("*.svg")}
    actual = runtime | unsupported
    errors = []
    if expected != actual:
        errors.append(f"missing={len(expected - actual)} extra={len(actual - expected)}")

    tags = Counter()
    total_bytes = 0
    empty = []
    invalid = []
    for relative in sorted(actual):
        path = SVG_ROOT / relative
        if not path.exists():
            path = UNSUPPORTED_ROOT / relative
        total_bytes += path.stat().st_size
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as error:
            invalid.append(f"{relative}: {error}")
            continue
        file_tags = Counter(local_name(node.tag) for node in root.iter())
        tags.update(file_tags)
        if not any(file_tags[name] for name in ("path", "polygon", "polyline", "rect", "circle", "ellipse", "image", "use")):
            empty.append(relative)

    if invalid:
        errors.append(f"invalid XML={len(invalid)}")
    if empty:
        errors.append(f"empty exports={len(empty)}")
    report = {
        "schema": "pr2-timeline-svg-report-v1",
        "expectedExports": len(expected),
        "actualExports": len(actual),
        "runtimeSvgExports": len(runtime),
        "unsupportedSvgSources": len(unsupported),
        "totalBytes": total_bytes,
        "bitmapFillExports": plan["bitmapFillExportCount"],
        "tags": dict(sorted(tags.items())),
        "missing": sorted(expected - actual),
        "extra": sorted(actual - expected),
        "invalid": invalid,
        "empty": empty,
    }
    REPORT.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    if errors:
        print("; ".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
