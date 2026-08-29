#!/usr/bin/env python3
"""Validate committed SVG hairlines and native non-scaling replacements."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
SVG_ROOT = ROOT / "art" / "svg"
HAXE_ROOT = ROOT / "haxe" / "src"


def main() -> int:
    svg_count = 0
    legacy_svg_widths: list[str] = []
    for path in SVG_ROOT.rglob("*.svg"):
        source = path.read_text(encoding="utf-8")
        svg_count += source.count('stroke-width="0"')
        if 'stroke-width="0.05"' in source:
            legacy_svg_widths.append(str(path.relative_to(ROOT)))

    legacy_native_widths: list[str] = []
    scaling_native_hairlines: list[str] = []
    hairline_call = re.compile(r"lineStyle\s*\(\s*0\s*,.*?\);", re.DOTALL)
    for path in HAXE_ROOT.rglob("*.hx"):
        source = path.read_text(encoding="utf-8")
        if re.search(r"lineStyle\s*\(\s*0\.05(?:\D|$)", source):
            legacy_native_widths.append(str(path.relative_to(ROOT)))
        for call in hairline_call.findall(source):
            if "LineScaleMode.NONE" not in call:
                scaling_native_hairlines.append(str(path.relative_to(ROOT)))
                break

    errors: list[str] = []
    if svg_count == 0:
        errors.append("no normalized SVG hairlines found")
    if legacy_svg_widths:
        errors.append("unnormalized SVG hairlines: " + ", ".join(legacy_svg_widths))
    if legacy_native_widths:
        errors.append("native 0.05 hairlines: " + ", ".join(legacy_native_widths))
    if scaling_native_hairlines:
        errors.append("scaling native hairlines: " + ", ".join(scaling_native_hairlines))

    if errors:
        for error in errors:
            print(f"Hairline audit failed: {error}", file=sys.stderr)
        return 1

    print(f"Hairline audit passed: {svg_count} normalized SVG strokes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
