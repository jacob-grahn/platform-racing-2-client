#!/usr/bin/env python3
"""Add the generated HTML5 bundle's content hash to its script URL."""

import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUNDLE = ROOT / "export/html5/bin/PlatformRacing2.js"
INDEX = ROOT / "export/html5/bin/index.html"
BUNDLE_URL = "./PlatformRacing2.js"


def main() -> None:
    if not BUNDLE.exists():
        raise SystemExit(f"Missing HTML5 bundle: {BUNDLE}")
    if not INDEX.exists():
        raise SystemExit(f"Missing HTML5 index: {INDEX}")

    digest = hashlib.sha256(BUNDLE.read_bytes()).hexdigest()[:12]
    html = INDEX.read_text(encoding="utf-8")
    pattern = re.escape(BUNDLE_URL) + r"(?:\?v=[A-Za-z0-9._-]+)?"
    updated, count = re.subn(pattern, f"{BUNDLE_URL}?v={digest}", html)
    if count != 1:
        raise SystemExit(f"Expected one {BUNDLE_URL} reference in {INDEX}, found {count}")

    INDEX.write_text(updated, encoding="utf-8")
    print(f"Cache-busted HTML5 JS: {BUNDLE_URL}?v={digest}")


if __name__ == "__main__":
    main()
