#!/usr/bin/env python3
"""Inventory legacy presentation coupling and enforce its shrinking boundary."""

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path


DEFAULT_REPORT = Path("docs/deflash-coupling-inventory.md")
DEFAULT_ALLOWLIST = Path("tools/deflash-boundary-allowlist.json")
SOURCE_ROOTS = (Path("haxe/src/pr2"), Path("haxe/src/com/jiggmin/data"))
EXCLUDED_PREFIXES = (
    "haxe/src/pr2/generated/",
    "haxe/src/pr2/harness/",
    "haxe/src/pr2/runtime/",
)
EXCLUDED_FILES = {
    "haxe/src/pr2/page/SymbolPreview.hx",
    "haxe/src/pr2/page/PopupPreview.hx",
    "haxe/src/pr2/page/CharacterPartCachePreview.hx",
    "haxe/src/pr2/effects/FollowFadeEffect.hx",
    "haxe/src/pr2/lobby/tabs/ScaffoldTab.hx",
}

FORBIDDEN_IMPORT_RE = re.compile(
    r"^\s*import\s+(pr2\.runtime\.(?:PR2MovieClip|Fl[A-Za-z0-9_]*)|"
    r"pr2\.generated\.assets\.(?:AssetTypes(?:\.[A-Za-z0-9_]+)?|AssetCatalog[A-Za-z0-9_]*))\s*;"
)
FORBIDDEN_REFERENCE_RE = re.compile(
    r"\b(pr2\.runtime\.(?:PR2MovieClip|Fl[A-Za-z0-9_]*)|"
    r"pr2\.generated\.assets\.(?:AssetTypes(?:\.[A-Za-z0-9_]+)?|AssetCatalog[A-Za-z0-9_]*))\b"
)
FRAME_NAV_RE = re.compile(r"\.gotoAnd(Play|Stop)\s*\((.*)")
FL_CONTROL_RE = re.compile(
    r"\bFl(?:Button|CheckBox|ComboBox|Components|DataProvider|List|Slider|SliderEvent|TextArea|TextInput|UIScrollBar)\b"
)


def path_name(path):
    return path.as_posix()


def excluded(path):
    name = path_name(path)
    return name in EXCLUDED_FILES or any(name.startswith(prefix) for prefix in EXCLUDED_PREFIXES)


def owner_for(path):
    name = path_name(path)
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
        ("/audio/", "Audio"),
        ("/com/jiggmin/data/Objects.hx", "Level objects"),
    )
    for marker, owner in mappings:
        if marker in name:
            return owner
    return "Other production code"


def source_files():
    for root in SOURCE_ROOTS:
        for path in sorted(root.rglob("*.hx")):
            if not excluded(path):
                yield path


def meaningful_line(line):
    stripped = line.strip()
    return stripped and not stripped.startswith(("//", "/*", "*"))


def add_occurrence(into, path, line_number, kind, api, line):
    into.append(
        {
            "owner": owner_for(path),
            "path": path_name(path),
            "line": line_number,
            "kind": kind,
            "api": api,
            "code": line.strip(),
        }
    )


def scan_couplings():
    occurrences = []
    for path in source_files():
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not meaningful_line(line):
                continue

            import_match = FORBIDDEN_IMPORT_RE.match(line)
            if import_match:
                dependency = import_match.group(1)
                if dependency == "pr2.runtime.PR2MovieClip":
                    add_occurrence(occurrences, path, line_number, "PR2MovieClip dependency", dependency, line)
                elif dependency.startswith("pr2.runtime.Fl"):
                    add_occurrence(occurrences, path, line_number, "Fl control dependency", dependency, line)
                else:
                    add_occurrence(occurrences, path, line_number, "generated timeline dependency", dependency, line)

            frame_match = FRAME_NAV_RE.search(line)
            if frame_match:
                argument = frame_match.group(2).lstrip()
                kind = "frame-label navigation" if argument.startswith(('"', "'")) else "numeric/dynamic frame navigation"
                add_occurrence(occurrences, path, line_number, kind, f"gotoAnd{frame_match.group(1)}", line)

            if "getChildByTimelineName" in line:
                add_occurrence(occurrences, path, line_number, "timeline child lookup", "getChildByTimelineName", line)
            if "DisplayUtil.findByName" in line or "pr2.util.DisplayUtil.findByName" in line:
                add_occurrence(occurrences, path, line_number, "recursive name lookup", "DisplayUtil.findByName", line)
            if "LobbyArt.text(" in line:
                add_occurrence(occurrences, path, line_number, "recursive name lookup", "LobbyArt.text", line)
            if "Reflect.getProperty" in line or "Reflect.setProperty" in line:
                api = "Reflect.getProperty" if "Reflect.getProperty" in line else "Reflect.setProperty"
                add_occurrence(occurrences, path, line_number, "reflective display property", api, line)

            # Imports were recorded above as dependencies. Record non-import Fl
            # usage separately so migration progress measures actual adapters,
            # not only their import declarations.
            if not import_match:
                controls = sorted(set(FL_CONTROL_RE.findall(line)))
                for control in controls:
                    add_occurrence(occurrences, path, line_number, "Fl control usage", control, line)

    return sorted(occurrences, key=lambda item: (item["owner"], item["path"], item["line"], item["kind"], item["api"]))


def scan_forbidden_dependencies():
    dependencies = defaultdict(set)
    for path in source_files():
        for line in path.read_text(encoding="utf-8").splitlines():
            if not meaningful_line(line):
                continue
            for match in FORBIDDEN_REFERENCE_RE.finditer(line):
                dependencies[path_name(path)].add(match.group(1))
    return {path: sorted(values) for path, values in sorted(dependencies.items())}


def render_report(occurrences, dependencies):
    kind_counts = Counter(item["kind"] for item in occurrences)
    owner_counts = Counter(item["owner"] for item in occurrences)
    lines = [
        "# De-Flash Handwritten Coupling Inventory",
        "",
        "Generated by `tools/audit_deflash_boundaries.py`; do not edit by hand.",
        "",
        "## Scope",
        "",
        "This report inventories handwritten production code that still exposes Flash",
        "presentation structure: timeline navigation, frame labels/numbers, recursive",
        "instance-name lookup, emulated `Fl*` controls, reflective display-property access,",
        "and direct dependencies on `PR2MovieClip` or generated timeline definitions.",
        "Runtime internals, generated code, harnesses, preview routes, and uncalled migration",
        "scaffolds are excluded. Generic `Reflect.field` access used to decode network/data",
        "payloads is also excluded because it is not a dependency on Flash presentation art.",
        "",
        "Every occurrence has a feature owner. Counts are a deletion ledger: native view",
        "migration should make them decrease without changing observable behavior or visuals.",
        "",
        "## Summary",
        "",
        f"- {len(occurrences)} coupling occurrences",
        f"- {len({item['path'] for item in occurrences})} files with coupling",
        f"- {len(dependencies)} migration-adapter files in the dependency allowlist",
        "",
        "| Coupling kind | Occurrences |",
        "| --- | ---: |",
    ]
    for kind in sorted(kind_counts):
        lines.append(f"| {kind} | {kind_counts[kind]} |")
    lines.extend(["", "| Feature owner | Occurrences |", "| --- | ---: |"])
    for owner in sorted(owner_counts):
        lines.append(f"| {owner} | {owner_counts[owner]} |")

    lines.extend(["", "## Occurrences By Feature Owner", ""])
    grouped = defaultdict(list)
    for item in occurrences:
        grouped[item["owner"]].append(item)
    for owner in sorted(grouped):
        lines.extend(
            [
                f"### {owner}",
                "",
                "| Kind | API | Source |",
                "| --- | --- | --- |",
            ]
        )
        for item in grouped[owner]:
            lines.append(f"| {item['kind']} | `{item['api']}` | `{item['path']}:{item['line']}` |")
        lines.append("")

    lines.extend(
        [
            "## Dependency Boundary",
            "",
            "`tools/deflash-boundary-allowlist.json` records the current adapter files and",
            "their exact legacy dependencies. The audit permits removal but rejects a new",
            "file or an additional forbidden dependency. Regenerate this report after a",
            "removal so the committed ledger continues to match the source tree.",
            "",
        ]
    )
    return "\n".join(lines) + "\n"


def allowlist_document(dependencies):
    return {
        "schema": "pr2-deflash-boundary-v1",
        "description": "Maximum legacy presentation dependencies allowed per migration-adapter source file. Entries may shrink but not grow.",
        "files": dependencies,
    }


def load_allowlist(path):
    with path.open(encoding="utf-8") as handle:
        document = json.load(handle)
    if document.get("schema") != "pr2-deflash-boundary-v1" or not isinstance(document.get("files"), dict):
        raise ValueError(f"unsupported boundary allowlist schema in {path}")
    return document["files"]


def check_boundary(actual, allowed):
    violations = []
    for path, dependencies in actual.items():
        maximum = set(allowed.get(path, []))
        added = sorted(set(dependencies) - maximum)
        if added:
            violations.append(f"{path}: {', '.join(added)}")
    return violations


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--allowlist", type=Path, default=DEFAULT_ALLOWLIST)
    parser.add_argument("--check", action="store_true", help="check the dependency boundary without validating the Markdown report")
    parser.add_argument("--update-allowlist", action="store_true", help="replace the maximum dependency allowlist with current imports")
    args = parser.parse_args(argv)
    if args.check and args.update_allowlist:
        parser.error("--check and --update-allowlist are mutually exclusive")

    try:
        occurrences = scan_couplings()
        dependencies = scan_forbidden_dependencies()
        if args.check:
            violations = check_boundary(dependencies, load_allowlist(args.allowlist))
            if violations:
                raise ValueError("new forbidden presentation dependencies:\n  " + "\n  ".join(violations))
        else:
            report = render_report(occurrences, dependencies)
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(report, encoding="utf-8")
            if args.update_allowlist:
                args.allowlist.write_text(json.dumps(allowlist_document(dependencies), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"deflash boundary audit: {exc}", file=sys.stderr)
        return 1

    print(
        f"Deflash boundary audit passed: {len(occurrences)} occurrences, "
        f"{len(dependencies)} adapter files"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
