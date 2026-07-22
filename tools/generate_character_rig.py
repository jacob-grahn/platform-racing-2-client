#!/usr/bin/env python3
"""Generate the character rig from the archival XFL.

The generated rig contains every CharacterGraphic state.
Runtime code sees only slots, assets, affine transforms, and explicit end
behavior; no linkage class names or frame scripts cross this boundary.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from character_lottie_motion import load_lottie_motion


ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / "flash/platform-racing-2-xfl/LIBRARY"
CHARACTER_SOURCE = LIBRARY / "MovieClips/Character.xml"
HEADS_SOURCE = LIBRARY / "Parts/Heads/headsMC.xml"
BODIES_SOURCE = LIBRARY / "Parts/Bodies/bodyMC.xml"
DEFAULT_OUTPUT = ROOT / "art/rigs/character-rig.json"
LOTTIE_ROOT = ROOT / "art/intermediate/character-lottie"
CHARACTER_ART = ROOT / "art/svg/character"
XFL_NS = "{http://ns.adobe.com/xfl/2008/}"

STATE_SOURCES = (
    ("stand", "standAnim", "Parts/playerStandingMC.xml", "loop", None),
    ("run", "runAnim", "MovieClips/Symbol 890.xml", "loop", None),
    ("jump", "jumpAnim", "MovieClips/Symbol 888.xml", "hold", None),
    ("superJump", "superJumpAnim", "MovieClips/Symbol 887.xml", "hold", None),
    ("bumped", "bumpedAnim", "MovieClips/Symbol 886.xml", "loop", "bumpedComplete"),
    ("crouch", "crouchAnim", "MovieClips/Symbol 885.xml", "loop", None),
    ("crouchWalk", "crouchWalkAnim", "MovieClips/Symbol 884.xml", "loop", None),
    ("swim", "swimAnim", "MovieClips/Symbol 883.xml", "loop", None),
    ("frozen", "frozenSolidAnim", "MovieClips/Symbol 896.xml", "hold-complete", "complete"),
)

LOTTIE_STATES = {state[0] for state in STATE_SOURCES}

SLOT_NAMES = {
    "weapon": ("heldItem", None),
    "head": ("head", "head"),
    "body": ("body", "body"),
    "foot1": ("frontFoot", "feet"),
    "foot2": ("backFoot", "feet"),
}

FROZEN_OVERLAY_ASSET = "assets/svg/character/frozen/overlay.svg"

# Animate's standalone channel exports retain each library item's staging
# registration. Convert that origin back to the nested character-part origin.
PART_REGISTRATION = {
    "head": {"x": 62.75, "y": 76.85},
    "body": {"x": 33.5, "y": 72.6},
    "feet": {"x": 28.4, "y": 10.7},
    "hat": {"x": -19.1, "y": -39.65},
}

EXCLUDED_PART_IDS = {
    "body": {29},  # Fred owns a different attachment and visibility hierarchy.
}

ANIMATED_HAT_OVERLAYS = {
    4: {"frames": 4},
    13: {"frames": 9},
}


def number(value: str | None, default: float) -> float:
    return default if value is None else float(value)


def instance_matrix(instance: ET.Element) -> dict[str, float]:
    matrix = instance.find(f"{XFL_NS}matrix/{XFL_NS}Matrix")
    if matrix is None:
        values = {"a": 1.0, "b": 0.0, "c": 0.0, "d": 1.0, "tx": 0.0, "ty": 0.0}
    else:
        values = {
            "a": number(matrix.get("a"), 1.0),
            "b": number(matrix.get("b"), 0.0),
            "c": number(matrix.get("c"), 0.0),
            "d": number(matrix.get("d"), 1.0),
            "tx": number(matrix.get("tx"), 0.0),
            "ty": number(matrix.get("ty"), 0.0),
        }
    color = instance.find(f"{XFL_NS}color/{XFL_NS}Color")
    values["alpha"] = number(color.get("alphaMultiplier"), 1.0) if color is not None else 1.0
    if color is not None:
        values["colorTransform"] = {
            "redMultiplier": number(color.get("redMultiplier"), 1.0),
            "greenMultiplier": number(color.get("greenMultiplier"), 1.0),
            "blueMultiplier": number(color.get("blueMultiplier"), 1.0),
            "alphaMultiplier": number(color.get("alphaMultiplier"), 1.0),
            "redOffset": number(color.get("redOffset"), 0.0),
            "greenOffset": number(color.get("greenOffset"), 0.0),
            "blueOffset": number(color.get("blueOffset"), 0.0),
            "alphaOffset": number(color.get("alphaOffset"), 0.0),
        }
    blur = instance.find(f"{XFL_NS}filters/{XFL_NS}BlurFilter")
    if blur is not None and (number(blur.get("blurX"), 0.0) != 0.0 or number(blur.get("blurY"), 0.0) != 0.0):
        values["blur"] = {
            "x": number(blur.get("blurX"), 0.0),
            "y": number(blur.get("blurY"), 0.0),
            "quality": int(blur.get("quality", "1")),
        }
    return values


def frame_count(layers: list[ET.Element]) -> int:
    return max(
        int(frame.get("index", "0")) + int(frame.get("duration", "1"))
        for layer in layers
        for frame in layer.findall(f"{XFL_NS}frames/{XFL_NS}DOMFrame")
    )


def expanded_layer_frames(layer: ET.Element, total: int) -> list[dict[str, float]]:
    result: list[dict[str, float] | None] = [None] * total
    previous = None
    for frame in layer.findall(f"{XFL_NS}frames/{XFL_NS}DOMFrame"):
        index = int(frame.get("index", "0"))
        duration = int(frame.get("duration", "1"))
        instance = frame.find(f"{XFL_NS}elements/{XFL_NS}DOMSymbolInstance")
        if instance is not None:
            previous = instance_matrix(instance)
        if previous is None:
            raise ValueError(f"layer {layer.get('name')} starts without a symbol instance")
        for target in range(index, min(total, index + duration)):
            result[target] = dict(previous)
    for index in range(total):
        if result[index] is None:
            if index == 0:
                raise ValueError(f"layer {layer.get('name')} has no frame-zero pose")
            result[index] = dict(result[index - 1])
    return result  # type: ignore[return-value]


def root_matrices() -> dict[str, dict[str, float]]:
    root = ET.parse(CHARACTER_SOURCE).getroot()
    result = {}
    for instance in root.findall(f".//{XFL_NS}DOMSymbolInstance"):
        name = instance.get("name")
        if name:
            result[name] = instance_matrix(instance)
    return result


def part_variants(kind: str, include_excluded: bool = False) -> list[dict[str, object]]:
    variants = []
    for directory in sorted((CHARACTER_ART / kind).iterdir()):
        fixed = directory / "static.svg"
        if not directory.is_dir() or not fixed.exists():
            continue
        prefix, separator, name = directory.name.partition("_")
        if not separator or not prefix.isdigit():
            continue
        part_id = int(prefix)
        if not include_excluded and part_id in EXCLUDED_PART_IDS.get(kind, set()):
            continue
        record = {
            "id": part_id,
            "name": name,
            "fixed": f"assets/svg/character/{kind}/{directory.name}/static.svg",
            "primary": f"assets/svg/character/{kind}/{directory.name}/primary.svg",
            "secondary": f"assets/svg/character/{kind}/{directory.name}/secondary.svg",
        }
        # Propeller and Jigg keep their nested MovieClip animation above a static
        # base. Their generated frames share the hat container's local origin.
        if kind == "hat" and part_id in ANIMATED_HAT_OVERLAYS:
            overlay = ANIMATED_HAT_OVERLAYS[part_id]
            record["fixed"] = f"assets/svg/character/hat/{directory.name}/static_base.svg"
            record["overlayAnimation"] = {
                "frameRate": 27,
                "endBehavior": "loop",
                "frames": [
                    f"assets/svg/character/hat/{directory.name}/overlay_frames/frame_{frame:03d}.svg"
                    for frame in range(1, overlay["frames"] + 1)
                ],
            }
        if kind == "body" and part_id == 21:
            record["channelAnimations"] = [
                {
                    "channel": channel,
                    "frameRate": 27,
                    "endBehavior": "loop",
                    "frames": [
                        f"assets/svg/character/body/021_bubble/{channel}_frames/frame_{frame:03d}.svg"
                        for frame in range(1, 22)
                    ],
                }
                for channel in ("primary", "static")
            ]
        variants.append(record)
    return variants


def hat_attachments() -> list[dict[str, object]]:
    root = ET.parse(HEADS_SOURCE).getroot()
    layers = root.findall(f".//{XFL_NS}DOMTimeline/{XFL_NS}layers/{XFL_NS}DOMLayer")
    slot_frames = {}
    for layer in layers:
        instance = layer.find(f"{XFL_NS}frames/{XFL_NS}DOMFrame/{XFL_NS}elements/{XFL_NS}DOMSymbolInstance")
        name = instance.get("name") if instance is not None else None
        if name in {"hat1", "hat2", "hat3", "hat4"}:
            slot_frames[name] = expanded_layer_frames(layer, 50)
    if len(slot_frames) != 4:
        raise ValueError("headsMC does not expose all four standard hat slots")
    return [
        {
            "headId": head_id,
            "slots": [
                {"name": name, "matrix": slot_frames[name][head_id - 1]}
                for name in ("hat1", "hat2", "hat3", "hat4")
            ],
        }
        for head_id in range(1, 51)
    ]


def fred_record() -> dict[str, object]:
    root = ET.parse(BODIES_SOURCE).getroot()
    slots = {}
    for layer in root.findall(f".//{XFL_NS}DOMTimeline/{XFL_NS}layers/{XFL_NS}DOMLayer"):
        for frame in layer.findall(f"{XFL_NS}frames/{XFL_NS}DOMFrame"):
            if int(frame.get("index", "0")) != 28:
                continue
            instance = frame.find(f"{XFL_NS}elements/{XFL_NS}DOMSymbolInstance")
            name = instance.get("name") if instance is not None else None
            if name in {"hat1", "hat2", "hat3", "hat4"}:
                slots[name] = instance_matrix(instance)
    if len(slots) != 4:
        raise ValueError("bodyMC frame 29 does not expose all four Fred hat slots")
    return {
        "bodyId": 29,
        "hiddenSlots": ["head", "frontFoot", "backFoot"],
        "hatAttachments": [
            {"name": name, "matrix": slots[name]}
            for name in ("hat1", "hat2", "hat3", "hat4")
        ],
    }


def item_records() -> list[dict[str, object]]:
    records = (
        ("Laser", "laser", 16, {}),
        ("Mine", "mine", 1, {"a": 3.52897644042969, "d": 3.52897644042969, "tx": -53.6, "ty": -53.3}),
        ("Lightning", "lightning", 1, {}),
        ("Teleport", "teleport", 1, {}),
        ("Super Jump", "super_jump", 1, {}),
        ("Jet Pack", "jet_pack", 2, {"tx": -125.2, "ty": 5.95}),
        ("Speed Burst", "speed_burst", 1, {}),
        ("Sword", "sword", 14, {"a": 0.965927124023438, "b": 0.258819580078125, "c": -0.258819580078125, "d": 0.965927124023438, "tx": -45.9, "ty": -14.9}),
        ("Ice Wave", "ice_wave", 1, {"tx": 3.8, "ty": -3.95}),
    )
    result = []
    for name, slug, count, overrides in records:
        matrix = {"a": 1.0, "b": 0.0, "c": 0.0, "d": 1.0, "tx": 0.0, "ty": 0.0, "alpha": 1.0}
        matrix.update(overrides)
        result.append({
            "name": name,
            "matrix": matrix,
            "frames": [f"assets/svg/character/item/{slug}/frame_{frame:03d}.svg" for frame in range(1, count + 1)],
            "actionStartFrame": 2 if name in {"Laser", "Sword"} else 1,
            "actionEndBehavior": "loop" if name in {"Laser", "Sword"} else "hold",
        })
    return result


def animation_record(
    name: str,
    root_name: str,
    source_path: str,
    end_behavior: str,
    end_signal: str | None,
    roots: dict[str, dict[str, float]],
    use_lottie: bool = True,
) -> dict[str, object]:
    source = LIBRARY / source_path
    root = ET.parse(source).getroot()
    layers = root.findall(f".//{XFL_NS}DOMTimeline/{XFL_NS}layers/{XFL_NS}DOMLayer")
    total = frame_count(layers)
    slots = []
    for layer_index, layer in enumerate(layers):
        first_instance = layer.find(f"{XFL_NS}frames/{XFL_NS}DOMFrame/{XFL_NS}elements/{XFL_NS}DOMSymbolInstance")
        if first_instance is None:
            continue
        instance_name = first_instance.get("name")
        asset = None
        if instance_name in SLOT_NAMES:
            slot_name, part_kind = SLOT_NAMES[instance_name]
        elif name == "frozen" and layer_index == 0:
            slot_name, part_kind = "frozenOverlay", None
            asset = FROZEN_OVERLAY_ASSET
        else:
            continue
        slots.append(
            {
                "name": slot_name,
                "parent": "root",
                "partKind": part_kind,
                "asset": asset,
                "drawOrder": len(layers) - 1 - layer_index,
                "frames": expanded_layer_frames(layer, total),
            }
        )
    expected = {"heldItem", "head", "body", "frontFoot", "backFoot"}
    actual = {slot["name"] for slot in slots}
    if not expected.issubset(actual):
        raise ValueError(f"{name} is missing slots {sorted(expected - actual)}")
    if root_name not in roots:
        raise ValueError(f"Character root has no state instance {root_name}")
    animation_root = roots[root_name]
    if use_lottie and name in LOTTIE_STATES:
        xfl_frames = {slot["name"]: slot["frames"] for slot in slots}
        motion = load_lottie_motion(LOTTIE_ROOT / f"{name}.lottie.json")
        if motion["frameCount"] != total:
            raise ValueError(f"{name} Lottie has {motion['frameCount']} frames; expected {total}")
        if motion["name"] != name:
            raise ValueError(f"{name} Lottie metadata names state {motion['name']}")
        total = motion["frameCount"]
        animation_root = motion["root"]
        slots = [
            {
                **definition,
                "frames": [
                    {
                        **frame,
                        **{
                            key: value
                            for key, value in xfl_frames[definition["name"]][index].items()
                            if key in {"colorTransform", "blur"}
                        },
                    }
                    for index, frame in enumerate(motion["slots"][definition["name"]])
                ],
            }
            for definition in motion["slotDefinitions"]
        ]
    return {
        "name": name,
        "frameRate": motion["frameRate"] if use_lottie and name in LOTTIE_STATES else 27,
        "frameCount": total,
        "endBehavior": motion["endBehavior"] if use_lottie and name in LOTTIE_STATES else end_behavior,
        "endSignal": motion["endSignal"] if use_lottie and name in LOTTIE_STATES else end_signal,
        "root": animation_root,
        "slots": slots,
    }


def generate() -> dict[str, object]:
    roots = root_matrices()
    parts = {}
    for kind in ("head", "body", "feet", "hat"):
        parts[kind] = {
            "registration": PART_REGISTRATION.get(kind, {"x": 0.0, "y": 0.0}),
            "variants": part_variants(kind, include_excluded=kind == "body"),
        }
    return {
        "format": "pr2-character-rig",
        "version": 9,
        "source": "MovieClips/Character",
        "parts": parts,
        "emptyPartIds": {
            kind: sorted(set(range(1, 51)) - {variant["id"] for variant in parts[kind]["variants"]})
            for kind in ("head", "body", "feet")
        },
        "hatAttachments": hat_attachments(),
        "hatStackStep": {"x": -10.0, "y": -16.0},
        "fred": fred_record(),
        "items": item_records(),
        "animations": [animation_record(*state, roots) for state in STATE_SOURCES],
    }


def summary(payload: dict[str, object]) -> str:
    animations = payload["animations"]
    frames = sum(animation["frameCount"] for animation in animations)  # type: ignore[index]
    parts = payload["parts"]
    variants = sum(len(parts[kind]["variants"]) for kind in ("head", "body", "feet")) - 1  # type: ignore[index]
    hats = len(parts["hat"]["variants"])  # type: ignore[index]
    items = payload["items"]
    item_frames = sum(len(item["frames"]) for item in items)  # type: ignore[index]
    return f"{len(animations)} states, {frames} generated frames, {variants} standard parts, Fred, {hats} hats, {len(items)} items/{item_frames} item frames"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    payload = generate()
    serialized = json.dumps(payload, indent=2) + "\n"
    if args.check:
        if not args.output.exists() or args.output.read_text(encoding="utf-8") != serialized:
            raise SystemExit(f"classic character rig is stale: regenerate {args.output.relative_to(ROOT)}")
        print(f"Classic character rig passed: {summary(payload)}")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(serialized, encoding="utf-8")
    print(f"Generated {args.output.relative_to(ROOT)}: {summary(payload)}")


if __name__ == "__main__":
    main()
