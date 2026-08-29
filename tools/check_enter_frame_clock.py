#!/usr/bin/env python3
"""Require production ENTER_FRAME callbacks to declare their clock policy."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "haxe" / "src"

REGISTRATION_PATTERN = re.compile(
    r"\baddEventListener\s*\(\s*Event\.ENTER_FRAME\s*,"
)
BINDING_PATTERN = re.compile(
    r"\baddEventListener\s*\(\s*Event\.ENTER_FRAME\s*,\s*([A-Za-z_]\w*)"
)
SIMULATION_GUARD_PATTERN = re.compile(
    r"(?:pr2\.runtime\.)?FrameClock\.shouldRunSimulationFrame\s*\(\s*\)"
)

# These callbacks intentionally observe every rendered frame. Keep this list
# exact: adding another exception requires a code-review-visible rationale.
PRESENTATION_ONLY_CALLBACKS = {
    ("haxe/src/pr2/levelEditor/EditorGraphicCursor.hx", "updateObjectLayerScale"):
        "keeps the pointer graphic aligned with the latest display transform",
    ("haxe/src/pr2/lobby/account/CursorEyedropper.hx", "maybeUpdate"):
        "samples the latest pointer and display state",
    ("haxe/src/pr2/page/CampaignTestScreen.hx", "onHarnessFrame"):
        "publishes browser harness diagnostics only",
    ("haxe/src/pr2/page/CharacterPartCachePreview.hx", "animateCharacters"):
        "is a rendered-frame performance benchmark",
    ("haxe/src/pr2/page/GamePage.hx", "advanceGameplayWarmup"):
        "presents one cold asset group to the renderer per display frame",
    ("haxe/src/pr2/runtime/FrameClock.hx", "onStageFrame"):
        "classifies the presentation frame before simulation owners run",
    ("haxe/src/pr2/runtime/SvgAsset.hx", "enteredFrame"):
        "keeps Flash hairlines at one device pixel when the stage display scale changes",
}


def mask_non_code(source: str) -> str:
    """Blank comments and string contents while preserving offsets/newlines."""
    chars = list(source)
    state = "code"
    index = 0
    while index < len(chars):
        char = chars[index]
        following = chars[index + 1] if index + 1 < len(chars) else ""
        if state == "code":
            if char == "/" and following == "/":
                chars[index] = chars[index + 1] = " "
                state = "line-comment"
                index += 2
                continue
            if char == "/" and following == "*":
                chars[index] = chars[index + 1] = " "
                state = "block-comment"
                index += 2
                continue
            if char == '"':
                chars[index] = " "
                state = "double-string"
            elif char == "'":
                chars[index] = " "
                state = "single-string"
        elif state == "line-comment":
            if char == "\n":
                state = "code"
            else:
                chars[index] = " "
        elif state == "block-comment":
            if char == "*" and following == "/":
                chars[index] = chars[index + 1] = " "
                state = "code"
                index += 2
                continue
            if char != "\n":
                chars[index] = " "
        elif state in ("double-string", "single-string"):
            quote = '"' if state == "double-string" else "'"
            if char == "\\":
                chars[index] = " "
                if index + 1 < len(chars) and chars[index + 1] != "\n":
                    chars[index + 1] = " "
                index += 2
                continue
            if char == quote:
                state = "code"
            chars[index] = " "
        index += 1
    return "".join(chars)


def extract_function_body(source: str, callback: str) -> str | None:
    declaration = re.search(rf"\bfunction\s+{re.escape(callback)}\s*\(", source)
    if declaration is None:
        return None

    brace = source.find("{", declaration.end())
    semicolon = source.find(";", declaration.end())
    if brace < 0 or (semicolon >= 0 and semicolon < brace):
        return None

    depth = 0
    state = "code"
    index = brace
    while index < len(source):
        char = source[index]
        following = source[index + 1] if index + 1 < len(source) else ""

        if state == "code":
            if char == "/" and following == "/":
                state = "line-comment"
                index += 2
                continue
            if char == "/" and following == "*":
                state = "block-comment"
                index += 2
                continue
            if char == '"':
                state = "double-string"
            elif char == "'":
                state = "single-string"
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    return source[brace + 1:index]
        elif state == "line-comment":
            if char == "\n":
                state = "code"
        elif state == "block-comment":
            if char == "*" and following == "/":
                state = "code"
                index += 2
                continue
        elif state == "double-string":
            if char == "\\":
                index += 2
                continue
            if char == '"':
                state = "code"
        elif state == "single-string":
            if char == "\\":
                index += 2
                continue
            if char == "'":
                state = "code"
        index += 1
    return None


def main() -> int:
    bindings: set[tuple[str, str]] = set()
    errors: list[str] = []

    for path in sorted(SOURCE_ROOT.rglob("*.hx")):
        source = path.read_text(encoding="utf-8")
        code = mask_non_code(source)
        relative = path.relative_to(ROOT).as_posix()
        for registration in REGISTRATION_PATTERN.finditer(code):
            match = BINDING_PATTERN.match(code, registration.start())
            if match is None:
                line = code.count("\n", 0, registration.start()) + 1
                errors.append(
                    f"{relative}:{line}: ENTER_FRAME registration must use a "
                    "named callback so its clock policy can be inspected"
                )
                continue
            callback = match.group(1)
            binding = (relative, callback)
            bindings.add(binding)
            if binding in PRESENTATION_ONLY_CALLBACKS:
                continue

            body = extract_function_body(source, callback)
            if body is None:
                errors.append(
                    f"{relative}: cannot inspect ENTER_FRAME callback `{callback}`"
                )
                continue
            if SIMULATION_GUARD_PATTERN.search(mask_non_code(body)[:600]) is None:
                errors.append(
                    f"{relative}: ENTER_FRAME callback `{callback}` must call "
                    "FrameClock.shouldRunSimulationFrame() near its start or be "
                    "explicitly added to PRESENTATION_ONLY_CALLBACKS"
                )

    for relative, callback in sorted(PRESENTATION_ONLY_CALLBACKS):
        if (relative, callback) not in bindings:
            errors.append(
                f"{relative}: stale presentation-only allowlist entry `{callback}`"
            )

    if errors:
        print("ENTER_FRAME clock policy check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    simulation_count = len(bindings) - len(PRESENTATION_ONLY_CALLBACKS)
    print(
        "ENTER_FRAME clock policy passed: "
        f"{simulation_count} simulation-timed callbacks, "
        f"{len(PRESENTATION_ONLY_CALLBACKS)} presentation-only callbacks"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
