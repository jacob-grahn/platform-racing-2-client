#!/usr/bin/env python3
"""Fail when production source or the HTML5 bundle reaches the XFL runtime."""

from __future__ import annotations

import argparse
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "haxe" / "src"
SOURCE_TOKENS = (
    "import pr2.runtime.PR2MovieClip",
    "import pr2.runtime.AssetLibrary",
    "import pr2.runtime.Fl",
    "import pr2.generated.assets",
    "PR2MovieClip.fromLinkage",
    "PR2MovieClip.fromSymbolName",
)
OUTPUT_TOKENS = (
    "pr2_runtime_PR2MovieClip",
    "pr2_runtime_AssetLibrary",
    "pr2_runtime_Fl",
    "pr2_generated_assets_",
    "AssetCatalogSymbols",
    "linkageClassName",
    "soundFrameHandler",
    "assets/svg-packs/timeline",
    "assets/timeline-bitmap",
)


def source_failures() -> list[str]:
    failures: list[str] = []
    for path in sorted(SOURCE_ROOT.rglob("*.hx")):
        relative = path.relative_to(SOURCE_ROOT)
        content = production_content(path.read_text(encoding="utf-8"))
        for token in SOURCE_TOKENS:
            if token in content:
                failures.append(f"{relative}: {token}")
    return failures


def production_content(content: str) -> str:
    output: list[str] = []
    legacy_depth = 0
    for line in content.splitlines():
        stripped = line.strip()
        if stripped == "#if pr2_legacy_preview":
            legacy_depth = 1
            continue
        if legacy_depth > 0:
            if stripped.startswith("#if "):
                legacy_depth += 1
            elif stripped == "#end":
                legacy_depth -= 1
            continue
        output.append(line)
    return "\n".join(output)


def output_failures(bundle: Path) -> list[str]:
    if not bundle.exists():
        return [f"missing HTML5 bundle: {bundle.relative_to(ROOT)}"]
    content = bundle.read_text(encoding="utf-8")
    return [f"{bundle.relative_to(ROOT)}: {token}" for token in OUTPUT_TOKENS if token in content]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-only", action="store_true")
    parser.add_argument("--bundle", type=Path, default=ROOT / "export/html5/bin/PlatformRacing2.js")
    args = parser.parse_args()
    failures = source_failures()
    if not args.source_only:
        failures.extend(output_failures(args.bundle if args.bundle.is_absolute() else ROOT / args.bundle))
    if failures:
        print("Compatibility runtime gate failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    scope = "production source" if args.source_only else "production source and HTML5 output"
    print(f"Compatibility runtime gate passed: {scope} are native-only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
