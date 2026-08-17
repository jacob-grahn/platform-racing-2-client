#!/usr/bin/env python3
"""Reject ambiguous renderer rotation access in gameplay code."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOTS = (ROOT / "haxe" / "src", ROOT / "haxe" / "test")
FORBIDDEN = "levelRenderer.rotation"


def main() -> int:
    violations: list[str] = []
    checked = 0
    for source_root in SOURCE_ROOTS:
        for path in source_root.rglob("*.hx"):
            checked += 1
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if FORBIDDEN in line:
                    violations.append(f"{path.relative_to(ROOT)}:{line_number}: {line.strip()}")
    if violations:
        print("Rotation coordinate boundary check failed:", file=sys.stderr)
        for violation in violations:
            print(f"- {violation}", file=sys.stderr)
        print("Use LevelRenderer.courseRotationDegrees for Flash blockBackground rotation.", file=sys.stderr)
        return 1
    print(f"Rotation coordinate boundary passed: {checked} Haxe files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
