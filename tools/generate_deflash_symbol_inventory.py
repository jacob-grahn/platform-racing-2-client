#!/usr/bin/env python3
"""Generate the production PR2MovieClip root-symbol migration inventory.

The report covers symbols explicitly requested by handwritten production code.
Nested XFL symbols and component skins are transitive dependencies of those
roots and intentionally remain owned by the root that caused their creation.
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path


DEFAULT_OUTPUT = Path("docs/deflash-symbol-inventory.md")
DEFAULT_VECTOR_INVENTORY = Path("docs/vector-art-inventory.json")
SOURCE_ROOTS = (Path("haxe/src/pr2"), Path("haxe/src/com/jiggmin/data"))
LITERAL_CALL_RE = re.compile(r'PR2MovieClip\.fromLinkage\(\s*"([^"]+)"')
DYNAMIC_CALL_RE = re.compile(r"PR2MovieClip\.fromLinkage\(\s*([A-Za-z_][A-Za-z0-9_]*)")

# Developer-only routes do not represent production migration roots. Runtime
# internals instantiate nested symbols and component skins on behalf of an
# already inventoried root, so they are transitive rather than new roots.
EXCLUDED_PREFIXES = ("haxe/src/pr2/runtime/", "haxe/src/pr2/harness/", "haxe/src/pr2/generated/")
EXCLUDED_FILES = {
    "haxe/src/pr2/page/SymbolPreview.hx": "developer symbol preview route",
    "haxe/src/pr2/effects/FollowFadeEffect.hx": "no production caller",
    "haxe/src/pr2/lobby/tabs/ScaffoldTab.hx": "unused migration scaffold",
}

# Dynamic factories are deliberately resolved here. Generation fails when a
# new dynamic call site appears without an audited resolution or exclusion.
DYNAMIC_ROOTS = {
    "haxe/src/pr2/levelEditor/EditorBlockOptionsPopup.hx": [
        "StatBlockOptionsGraphic",
        "CustomStatsBlockOptionsGraphic",
        "TeleportBlockOptionsGraphic",
        "ItemBlockOptionsGraphic",
    ],
    "haxe/src/pr2/levelEditor/EditorSideBarIconFactory.hx": [
        "ObjectDeleterButtonGraphic",
        "MusicNoteGraphic",
        "ItemButtonGraphic",
        "HatsButtonGraphic",
        "ValueButtonGraphic",
        "BrushGraphic",
        "TextToolButtonGraphic",
        "LandscapeGraphic",
        "BrushButtonGraphic",
        "EraserButtonGraphic",
    ],
    "haxe/src/pr2/lobby/dialogs/FormPopup.hx": [
        "ChangePasswordPopupGraphic",
        "SetEmailPopupGraphic",
        "TransferGuildPopupGraphic",
    ],
    "haxe/src/pr2/page/LoginFlashPopup.hx": [
        "LoginPopupGraphic",
        "ServerSelectPopupGraphic",
    ],
}

STATIC_ART = {
    "ArrowBlockGraphic",
    "BG1",
    "BG2",
    "BG3",
    "BG4",
    "BG5",
    "BG6",
    "BG7",
    "BrickPieceGraphic",
    "Circle",
    "CrumblePieceGraphic",
    "DjinnIceGraphic",
    "HalfSquareBG",
    "HeartGraphic",
    "MinePieceGraphic",
    "MiniMapDot",
    "MiniMapFinishGraphic",
    "MoveArrow",
    "ShadowBG",
    "Square",
    "SquareBG",
    "Tree",
    "Tree2",
    "Tree3",
    "PetrifiedTree",
    "Cactus",
    "Rock",
    "Rock2",
    "Spire",
    "Spire2",
    "Building1",
}

SIMPLE_ANIMATIONS = {
    "Arrow2Graphic",
    "IceWaveGraphic",
    "CountdownGraphic",
    "EggGraphic",
    "LaserShotGraphic",
    "MineAppearAnimation",
    "MineExplodeAnimation",
    "PointyStar",
    "SlashAnimation",
    "TeleportAnimation",
}

TWEENED_ANIMATIONS = {
    "JiggminIntroGraphic",
    "KongregateIntroGraphic",
    "ArmorIntroGraphic",
    "BubbleBoxIntroGraphic",
}

STATE_ART_TOKENS = (
    "Button",
    "Check",
    "Cursor",
    "HighlightStar",
    "LobbyTab",
    "PageNumber",
    "ScrollBar",
    "Slider",
)


def relative(path):
    return path.as_posix()


def is_excluded(path):
    name = relative(path)
    return name in EXCLUDED_FILES or any(name.startswith(prefix) for prefix in EXCLUDED_PREFIXES)


def owner_for(path):
    name = relative(path)
    mappings = (
        ("/character/", "Character"),
        ("/effects/", "Gameplay effects"),
        ("/gameplay/", "Gameplay UI and visuals"),
        ("/levelEditor/", "Level editor"),
        ("/lobby/account/", "Lobby account and customization"),
        ("/lobby/dialogs/", "Lobby dialogs"),
        ("/lobby/level/", "Lobby level browser"),
        ("/lobby/messages/", "Lobby messages"),
        ("/lobby/players/", "Lobby players"),
        ("/lobby/store/", "Lobby store"),
        ("/lobby/tabs/", "Lobby tabs"),
        ("/lobby/", "Lobby shell"),
        ("/level/", "Level rendering"),
        ("/page/Intro", "Intro page"),
        ("/page/Login", "Login page"),
        ("/page/Lobby", "Lobby shell"),
        ("/page/", "Application pages"),
        ("/ui/", "Shared UI"),
        ("/com/jiggmin/data/Objects.hx", "Level objects"),
    )
    for marker, owner in mappings:
        if marker in name:
            return owner
    raise ValueError(f"No feature owner mapping for {name}")


def category_for(symbol, owners):
    if symbol == "CharacterGraphic":
        return "character rig"
    if symbol in SIMPLE_ANIMATIONS or symbol.endswith("Animation"):
        return "simple frame animation"
    if symbol in TWEENED_ANIMATIONS:
        return "tweened animation"
    if symbol in STATIC_ART or symbol.startswith("BG"):
        return "static art"
    if any(token in symbol for token in STATE_ART_TOKENS):
        return "state art"
    if owners == {"Gameplay effects"}:
        return "simple frame animation"
    return "UI composition"


def vector_symbols(path):
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    return {symbol.get("linkageClassName"): symbol for symbol in data["symbols"] if symbol.get("linkageClassName")}


def scan_sources():
    usages = defaultdict(list)
    unresolved_dynamic = []
    excluded_dynamic = []
    scanned_files = 0
    for root in SOURCE_ROOTS:
        for path in sorted(root.rglob("*.hx")):
            name = relative(path)
            source = path.read_text(encoding="utf-8")
            if is_excluded(path):
                for match in DYNAMIC_CALL_RE.finditer(source):
                    if not source[match.start() :].startswith(f'PR2MovieClip.fromLinkage("'):
                        excluded_dynamic.append((name, match.group(1)))
                continue
            scanned_files += 1
            for match in LITERAL_CALL_RE.finditer(source):
                line = source.count("\n", 0, match.start()) + 1
                usages[match.group(1)].append((name, line, "literal"))
            dynamic_matches = []
            for match in DYNAMIC_CALL_RE.finditer(source):
                call = source[match.start() : match.end()]
                if 'fromLinkage("' not in call:
                    dynamic_matches.append(match)
            if dynamic_matches:
                resolved = DYNAMIC_ROOTS.get(name)
                if resolved is None:
                    unresolved_dynamic.extend((name, match.group(1)) for match in dynamic_matches)
                else:
                    first_line = source.count("\n", 0, dynamic_matches[0].start()) + 1
                    for symbol in resolved:
                        usages[symbol].append((name, first_line, "audited dynamic factory"))
    if unresolved_dynamic:
        details = ", ".join(f"{path} ({argument})" for path, argument in unresolved_dynamic)
        raise ValueError(f"Unresolved dynamic PR2MovieClip linkage sites: {details}")
    return usages, scanned_files, excluded_dynamic


def render(usages, metadata, scanned_files):
    missing = sorted(symbol for symbol in usages if symbol not in metadata)
    if missing:
        raise ValueError("Production linkages absent from vector-art inventory: " + ", ".join(missing))

    records = []
    by_owner = defaultdict(list)
    for symbol, symbol_usages in usages.items():
        owners = {owner_for(Path(path)) for path, _, _ in symbol_usages}
        category = category_for(symbol, owners)
        record = {
            "symbol": symbol,
            "category": category,
            "owners": sorted(owners),
            "sources": sorted(symbol_usages),
            "xfl_name": metadata[symbol].get("name", ""),
        }
        records.append(record)
        for owner in owners:
            by_owner[owner].append(record)

    records.sort(key=lambda record: record["symbol"].lower())
    lines = [
        "# Production PR2MovieClip Root-Symbol Inventory",
        "",
        "Generated by `tools/generate_deflash_symbol_inventory.py`; do not edit by hand.",
        "",
        "## Scope",
        "",
        "This inventory is the migration boundary for handwritten production code. It",
        "lists each linkage used as a root `PR2MovieClip`, groups it by the feature that",
        "owns the user-facing flow, and assigns the intended native replacement shape.",
        "Nested XFL symbols and component skins instantiated while rendering a root are",
        "transitive dependencies of that root, not independently owned production roots.",
        "Developer preview routes, runtime internals, and source files with no production",
        "caller are excluded. Dynamic factories are expanded from audited call sites; a",
        "new unresolved dynamic factory makes generation fail.",
        "",
        "The categories describe migration shape, not observable changes. Every replacement",
        "must remain visually and functionally identical under the existing deterministic",
        "and screenshot/parity tests.",
        "",
        "## Summary",
        "",
        f"- {len(records)} unique production root linkages",
        f"- {sum(len(record['sources']) for record in records)} audited root usages",
        f"- {scanned_files} handwritten source files scanned",
        "- Excluded developer routes: `SymbolPreview` and files under `pr2.harness`",
        "- Excluded transitive construction: files under `pr2.runtime`",
        "- Explicitly excluded as uncalled: `FollowFadeEffect` and `ScaffoldTab`",
        "",
        "| Replacement shape | Unique roots |",
        "| --- | ---: |",
    ]
    counts = defaultdict(int)
    for record in records:
        counts[record["category"]] += 1
    for category in sorted(counts):
        lines.append(f"| {category} | {counts[category]} |")

    lines.extend(["", "## Roots By Feature Owner", ""])
    for owner in sorted(by_owner):
        lines.extend([f"### {owner}", "", "| Linkage | Replacement shape | Source |", "| --- | --- | --- |"])
        for record in sorted(by_owner[owner], key=lambda item: item["symbol"].lower()):
            owned_sources = []
            for path, line, resolution in record["sources"]:
                if owner_for(Path(path)) == owner:
                    suffix = "; dynamic" if resolution != "literal" else ""
                    owned_sources.append(f"`{path}:{line}`{suffix}")
            lines.append(f"| `{record['symbol']}` | {record['category']} | {', '.join(owned_sources)} |")
        lines.append("")

    lines.extend(
        [
            "## Dynamic Factory Resolutions",
            "",
            "These call sites accept a linkage variable. Their currently reachable production",
            "values are maintained explicitly so code review can detect a changed boundary.",
            "",
            "| Factory source | Audited production linkages |",
            "| --- | --- |",
        ]
    )
    for path in sorted(DYNAMIC_ROOTS):
        values = ", ".join(f"`{value}`" for value in DYNAMIC_ROOTS[path])
        lines.append(f"| `{path}` | {values} |")
    lines.append("")
    return "\n".join(lines), records


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--vector-inventory", type=Path, default=DEFAULT_VECTOR_INVENTORY)
    parser.add_argument("--check", action="store_true", help="fail if the committed report is stale")
    args = parser.parse_args(argv)

    try:
        usages, scanned_files, _ = scan_sources()
        report, records = render(usages, vector_symbols(args.vector_inventory), scanned_files)
    except (OSError, KeyError, ValueError, json.JSONDecodeError) as exc:
        print(f"deflash symbol inventory: {exc}", file=sys.stderr)
        return 1

    report += "\n"
    if args.check:
        try:
            current = args.output.read_text(encoding="utf-8")
        except OSError as exc:
            print(f"deflash symbol inventory: {exc}", file=sys.stderr)
            return 1
        if current != report:
            print(f"deflash symbol inventory is stale: regenerate {args.output}", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(report, encoding="utf-8")

    print(f"Deflash inventory passed: {len(records)} production root linkages -> {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
