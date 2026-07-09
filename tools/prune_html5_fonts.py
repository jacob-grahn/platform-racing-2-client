#!/usr/bin/env python3
"""Remove legacy webfont formats from the generated HTML5 build."""

from pathlib import Path


ROOTS = (
    Path("export/html5/bin/assets/fonts"),
    Path("export/html5/obj/webfont"),
)
LEGACY_SUFFIXES = {".eot", ".svg", ".woff"}


def main() -> None:
    removed = 0
    for root in ROOTS:
        if not root.exists():
            continue
        for path in root.iterdir():
            if path.is_file() and path.suffix.lower() in LEGACY_SUFFIXES:
                path.unlink()
                removed += 1
    print(f"Pruned {removed} legacy HTML5 webfont files.")


if __name__ == "__main__":
    main()
