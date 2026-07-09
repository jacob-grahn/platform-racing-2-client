#!/usr/bin/env python3
"""Remove stale duplicate body atlas files from HTML5 output."""

from pathlib import Path


DUPLICATE_ATLASES = (
    Path("export/html5/bin/assets/character/atlases/body/static/atlas@4x.png"),
    Path("export/html5/bin/assets/character/atlases/body/static/atlas@4x.json"),
    Path("export/html5/bin/assets/character/atlases/body/composite/atlas@4x.png"),
    Path("export/html5/bin/assets/character/atlases/body/composite/atlas@4x.json"),
)


def main() -> None:
    removed = 0
    for path in DUPLICATE_ATLASES:
        if path.exists():
            path.unlink()
            removed += 1
    print(f"Pruned {removed} duplicate HTML5 atlas files.")


if __name__ == "__main__":
    main()
