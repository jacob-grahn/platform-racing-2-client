#!/usr/bin/env python3
"""Verify the audited set of linkage symbols intentionally deferred from export."""

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

from generate_other_assets_jsfl import build_jobs


IN_SCOPE_CATEGORIES = (
    "backgrounds",
    "blocks",
    "components",
    "items_effects",
    "ui",
    "uncategorized",
)
EXPECTED_COUNTS = {
    "backgrounds": 3,
    "blocks": 5,
    "components": 41,
    "items_effects": 10,
    "ui": 140,
    "uncategorized": 48,
}


def deferred_counts(inventory_path, svg_dir):
    with open(inventory_path, encoding="utf-8") as handle:
        inventory = json.load(handle)

    exported_symbols = {job["symbolName"] for job in build_jobs(svg_dir)}
    deferred = [
        symbol
        for symbol in inventory["symbols"]
        if symbol.get("linkageClassName")
        and symbol.get("category") in IN_SCOPE_CATEGORIES
        and symbol.get("name") not in exported_symbols
    ]
    return dict(sorted(Counter(symbol["category"] for symbol in deferred).items()))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--inventory",
        default="docs/vector-art-inventory.json",
        help="generated vector inventory",
    )
    parser.add_argument("--svg-dir", default="art/svg", help="SVG export root")
    args = parser.parse_args(argv)

    actual = deferred_counts(Path(args.inventory), Path(args.svg_dir))
    if actual != EXPECTED_COUNTS:
        print(f"Deferred linkage audit changed: expected {EXPECTED_COUNTS}, got {actual}", file=sys.stderr)
        return 1

    print(f"Deferred linkage audit passed: {sum(actual.values())} symbols {actual}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
