#!/usr/bin/env python3
"""Pack runtime timeline SVGs into deterministic group JSON assets."""

import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/timeline-svg-manifest.json"
SVG_ROOT = ROOT / "art/svg/timeline"
OUTPUT_ROOT = ROOT / "art/svg-packs/timeline"
REPORT = ROOT / "test/output/timeline-svg-pack-report.json"
KNOWN_GROUPS = frozenset(("buttons", "components", "graphics", "images", "movieclips", "parts", "ui"))


def pack_group(symbol_name):
    if "/" not in symbol_name:
        return "misc"
    group = symbol_name.split("/", 1)[0].lower()
    return group if group in KNOWN_GROUPS else "misc"


def main():
    plan = json.loads(MANIFEST.read_text(encoding="utf-8"))
    packs = defaultdict(dict)
    missing = []
    for job in plan["exports"]:
        relative = job["exportPath"]
        source = SVG_ROOT / relative
        if not source.exists():
            # Unsupported SVG features have a PNG runtime fallback and remain
            # canonical under art/svg-unsupported; they do not belong in packs.
            continue
        asset_path = "assets/svg/timeline/" + relative
        packs[pack_group(job["symbolName"])][asset_path] = source.read_text(encoding="utf-8")

    expected = sum(1 for job in plan["exports"] if (SVG_ROOT / job["exportPath"]).exists())
    actual = sum(len(entries) for entries in packs.values())
    if actual != expected:
        missing.append(f"expected {expected} runtime SVGs, packed {actual}")

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    expected_files = set()
    pack_report = {}
    for group in sorted(packs):
        output = OUTPUT_ROOT / f"{group}.json"
        expected_files.add(output)
        payload = {
            "schema": "pr2-timeline-svg-pack-v1",
            "group": group,
            "entries": dict(sorted(packs[group].items())),
        }
        output.write_text(
            json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )
        pack_report[group] = {
            "assetPath": f"assets/svg-packs/timeline/{group}.json",
            "bytes": output.stat().st_size,
            "entries": len(packs[group]),
        }

    for stale in OUTPUT_ROOT.glob("*.json"):
        if stale not in expected_files:
            stale.unlink()

    report = {
        "schema": "pr2-timeline-svg-pack-report-v1",
        "packCount": len(pack_report),
        "entryCount": actual,
        "totalBytes": sum(item["bytes"] for item in pack_report.values()),
        "packs": pack_report,
        "errors": missing,
    }
    REPORT.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    if missing:
        raise SystemExit("; ".join(missing))


if __name__ == "__main__":
    main()
