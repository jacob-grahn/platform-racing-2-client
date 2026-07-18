#!/usr/bin/env python3
"""Pack every production SVG into deterministic OpenFL text assets."""

import argparse
import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SVG_ROOT = ROOT / "art/svg"
OUTPUT_ROOT = ROOT / "art/svg-packs"
ASSET_PREFIX = "assets/svg/"


def pack_group(relative: Path) -> str:
    parts = relative.parts
    if parts[0] == "character":
        return f"character_{parts[1]}"
    return parts[0]


def render_packs() -> dict[Path, str]:
    packs: dict[str, dict[str, str]] = defaultdict(dict)
    for source in sorted(SVG_ROOT.rglob("*.svg")):
        relative = source.relative_to(SVG_ROOT)
        if relative.parts[0] == "timeline":
            continue
        asset_path = ASSET_PREFIX + relative.as_posix()
        packs[pack_group(relative)][asset_path] = source.read_text(encoding="utf-8")

    rendered = {}
    for group, entries in sorted(packs.items()):
        payload = {
            "schema": "pr2-svg-pack-v1",
            "group": group,
            "entries": dict(sorted(entries.items())),
        }
        rendered[OUTPUT_ROOT / f"{group}.json"] = json.dumps(
            payload, ensure_ascii=False, separators=(",", ":")
        ) + "\n"
    return rendered


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = render_packs()
    existing = set(OUTPUT_ROOT.rglob("*.json")) if OUTPUT_ROOT.exists() else set()
    stale = existing - set(rendered)
    changed = [path for path, content in rendered.items() if not path.is_file() or path.read_text(encoding="utf-8") != content]

    if args.check:
        if stale or changed:
            details = [path.relative_to(ROOT).as_posix() for path in sorted(stale | set(changed))]
            raise SystemExit("SVG packs are stale; run tools/generate_svg_packs.py: " + ", ".join(details))
        return 0

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    for path, content in rendered.items():
        path.write_text(content, encoding="utf-8")
    for path in stale:
        path.unlink()
    for directory in sorted((path for path in OUTPUT_ROOT.rglob("*") if path.is_dir()), reverse=True):
        if not any(directory.iterdir()):
            directory.rmdir()

    entry_count = sum(len(json.loads(content)["entries"]) for content in rendered.values())
    total_bytes = sum(len(content.encode("utf-8")) for content in rendered.values())
    print(f"Generated {len(rendered)} SVG packs with {entry_count} entries ({total_bytes} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
