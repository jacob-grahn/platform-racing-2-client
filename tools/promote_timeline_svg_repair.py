#!/usr/bin/env python3
"""Promote a partial SVG repair set into the runtime/source split."""

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/timeline-svg-manifest.json"
RUNTIME_ROOT = ROOT / "art/svg/timeline"
UNSUPPORTED_ROOT = ROOT / "art/svg-unsupported/timeline"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    source_root = args.source.resolve()
    plan = json.loads(MANIFEST.read_text(encoding="utf-8"))
    promoted = 0
    for job in plan["exports"]:
        relative = Path(job["exportPath"])
        source = source_root / relative
        if not source.exists():
            continue
        runtime = RUNTIME_ROOT / relative
        unsupported = UNSUPPORTED_ROOT / relative
        if runtime != source:
            runtime.unlink(missing_ok=True)
        if unsupported != source:
            unsupported.unlink(missing_ok=True)
        runtime.parent.mkdir(parents=True, exist_ok=True)
        source.replace(runtime)
        promoted += 1
    print(f"promoted {promoted} repaired timeline SVGs")


if __name__ == "__main__":
    main()
