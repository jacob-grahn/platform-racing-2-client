#!/usr/bin/env python3
"""Report the first meaningful frame-state difference in PR2 physics traces."""

from __future__ import annotations

import argparse
import math
from pathlib import Path


STATE_FIELDS = (
    "x",
    "y",
    "velX",
    "velY",
    "targetVelX",
    "targetVelY",
    "grounded",
    "crouching",
    "mode",
    "state",
    "gravity",
    "defaultGravity",
    "jumpVel",
    "superJump",
    "accel",
    "maxVelX",
    "accelFactor",
    "waterTicks",
    "hurtTime",
    "lastSafe",
    "rotation",
    "mapRotation",
    "scaleX",
    "item",
)


def parse_fields(text: str, separator: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for part in text.split(separator):
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        result[key.removeprefix("owner.")] = value
    return result


def load_trace(path: Path) -> tuple[dict[int, dict[str, str]], dict[int, list[str]]]:
    states: dict[int, dict[str, str]] = {}
    lines_by_frame: dict[int, list[str]] = {}
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not raw.startswith("PR2TRACE|"):
            continue
        fields = parse_fields(raw, "|")
        try:
            frame = int(fields["frame"])
        except (KeyError, ValueError):
            continue
        lines_by_frame.setdefault(frame, []).append(raw)
        if fields.get("event") == "frame" and fields.get("phase") == "after":
            states[frame] = parse_fields(fields.get("state", ""), ";")
    return states, lines_by_frame


def values_equal(field: str, left: str | None, right: str | None) -> bool:
    if left == right:
        return True
    if left is None or right is None:
        return False
    try:
        # Flash display coordinates are stored in twentieths of a pixel and
        # occasionally choose the adjacent twip at a floating-point midpoint.
        tolerance = 0.051 if field in ("x", "y") else 1e-5
        return math.isclose(float(left), float(right), rel_tol=0, abs_tol=tolerance)
    except ValueError:
        return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("flash", type=Path)
    parser.add_argument("haxe", type=Path)
    args = parser.parse_args()

    flash_states, flash_lines = load_trace(args.flash)
    haxe_states, haxe_lines = load_trace(args.haxe)
    shared_frames = sorted(set(flash_states) & set(haxe_states))
    if not shared_frames:
        print("FAIL: traces contain no shared completed frames")
        return 2

    for frame in shared_frames:
        differences = []
        for field in STATE_FIELDS:
            flash_value = flash_states[frame].get(field)
            haxe_value = haxe_states[frame].get(field)
            if not values_equal(field, flash_value, haxe_value):
                differences.append(f"{field}: flash={flash_value} haxe={haxe_value}")
        if differences:
            print(f"DIVERGENCE: first differing completed frame is {frame}")
            for difference in differences:
                print(f"  {difference}")
            print("  Flash frame events:")
            for line in flash_lines.get(frame, []):
                print(f"    {line}")
            print("  Haxe frame events:")
            for line in haxe_lines.get(frame, []):
                print(f"    {line}")
            return 1

    flash_last = max(flash_states)
    haxe_last = max(haxe_states)
    if flash_last != haxe_last:
        print(f"PREFIX MATCH: frames {shared_frames[0]}-{shared_frames[-1]} match; trace lengths differ "
              f"(flash last={flash_last}, haxe last={haxe_last})")
        return 1

    print(f"PASS: detailed physics frame states match through frame {flash_last}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
