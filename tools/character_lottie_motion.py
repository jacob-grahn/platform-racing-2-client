#!/usr/bin/env python3
"""Standard-Lottie transform interchange for native character motion.

Character artwork remains runtime-owned.  Each Lottie document contains only
named null layers whose standard transform channels describe the rig root and
the character attachment slots.
"""

from __future__ import annotations

import json
import math
from pathlib import Path
from typing import Any


ROOT_LAYER = "characterRoot"
REQUIRED_SLOTS = {"heldItem", "head", "body", "frontFoot", "backFoot"}
OPTIONAL_SLOTS = {"frozenOverlay"}
SUPPORTED_SLOTS = REQUIRED_SLOTS | OPTIONAL_SLOTS
METADATA_FORMAT = "pr2-character-motion"
METADATA_VERSION = 1
END_BEHAVIORS = {"loop", "hold", "hold-complete"}


def _clean(value: float) -> float:
    return 0.0 if abs(value) < 1e-14 else value


def decompose_matrix(matrix: dict[str, float]) -> dict[str, float | list[float]]:
    """Decompose an OpenFL affine matrix into standard 2D Lottie channels.

    We use a zero skew axis.  That still represents every nonsingular 2D
    affine transform through position, scale, rotation, and X skew.
    """
    a = matrix["a"]
    b = matrix["b"]
    c = matrix["c"]
    d = matrix["d"]
    scale_x = math.hypot(a, b)
    if scale_x == 0:
        raise ValueError("character Lottie cannot encode a zero X scale")
    rotation = math.atan2(b, a)
    cosine = math.cos(rotation)
    sine = math.sin(rotation)
    scale_y = (a * d - b * c) / scale_x
    if scale_y == 0:
        raise ValueError("character Lottie cannot encode a zero Y scale")
    shear = (cosine * c + sine * d) / scale_y
    return {
        "p": [_clean(matrix["tx"]), _clean(matrix["ty"])],
        "s": [_clean(scale_x * 100.0), _clean(scale_y * 100.0)],
        "r": _clean(math.degrees(rotation)),
        # Lottie-web applies skewFromAxis(-sk, sa).
        "sk": _clean(-math.degrees(math.atan(shear))),
        "sa": 0.0,
        "o": _clean(matrix["alpha"] * 100.0),
    }


def compose_channels(channels: dict[str, float | list[float]]) -> dict[str, float]:
    """Recompose the supported standard Lottie transform subset."""
    skew_axis = float(channels["sa"])
    if abs(skew_axis) > 1e-12:
        raise ValueError("character Lottie currently requires a zero skew axis")
    position = channels["p"]
    scale = channels["s"]
    if not isinstance(position, list) or not isinstance(scale, list):
        raise ValueError("character Lottie position and scale must be vectors")
    scale_x = float(scale[0]) / 100.0
    scale_y = float(scale[1]) / 100.0
    rotation = math.radians(float(channels["r"]))
    shear = math.tan(math.radians(-float(channels["sk"])))
    cosine = math.cos(rotation)
    sine = math.sin(rotation)
    return {
        "a": _clean(cosine * scale_x),
        "b": _clean(sine * scale_x),
        "c": _clean(scale_y * (cosine * shear - sine)),
        "d": _clean(scale_y * (sine * shear + cosine)),
        "tx": float(position[0]),
        "ty": float(position[1]),
        "alpha": float(channels["o"]) / 100.0,
    }


def _animated(values: list[Any]) -> dict[str, Any]:
    return {
        "a": 1,
        "k": [{"t": index, "s": value if isinstance(value, list) else [value], "h": 1} for index, value in enumerate(values)],
    }


def _static(value: Any) -> dict[str, Any]:
    return {"a": 0, "k": value}


def _property(values: list[Any]) -> dict[str, Any]:
    return _static(values[0]) if all(value == values[0] for value in values[1:]) else _animated(values)


def _transform(frames: list[dict[str, float]]) -> dict[str, Any]:
    channels = [decompose_matrix(frame) for frame in frames]
    return {
        "a": _static([0.0, 0.0]),
        "p": _property([channel["p"] for channel in channels]),
        "s": _property([channel["s"] for channel in channels]),
        "r": _property([channel["r"] for channel in channels]),
        "o": _property([channel["o"] for channel in channels]),
        "sk": _property([channel["sk"] for channel in channels]),
        "sa": _static(0.0),
    }


def animation_to_lottie(animation: dict[str, Any]) -> dict[str, Any]:
    total = int(animation["frameCount"])
    root = {
        "ddd": 0,
        "ind": 1,
        "ty": 3,
        "nm": ROOT_LAYER,
        "sr": 1,
        "ks": _transform([animation["root"]] * total),
        "ao": 0,
        "ip": 0,
        "op": total,
        "st": 0,
        "bm": 0,
    }
    layers = [root]
    for index, slot in enumerate(animation["slots"], 2):
        layers.append({
            "ddd": 0,
            "ind": index,
            "ty": 3,
            "nm": slot["name"],
            "parent": 1,
            "sr": 1,
            "ks": _transform(slot["frames"]),
            "ao": 0,
            "ip": 0,
            "op": total,
            "st": 0,
            "bm": 0,
        })
    slot_metadata = [
        {
            "name": slot["name"],
            "parent": slot["parent"],
            "partKind": slot["partKind"],
            "asset": slot["asset"],
            "drawOrder": slot["drawOrder"],
        }
        for slot in animation["slots"]
    ]
    return {
        "v": "5.12.2",
        "fr": int(animation["frameRate"]),
        "ip": 0,
        "op": total,
        "w": 550,
        "h": 400,
        "nm": f"PR2 character: {animation['name']}",
        "ddd": 0,
        "assets": [],
        "layers": layers,
        "metadata": {
            "customProps": {
                "pr2": {
                    "format": METADATA_FORMAT,
                    "version": METADATA_VERSION,
                    "state": animation["name"],
                    "endBehavior": animation["endBehavior"],
                    "endSignal": animation["endSignal"],
                    "slots": slot_metadata,
                }
            }
        },
    }


def _value_at(prop: dict[str, Any], frame: int) -> Any:
    if int(prop.get("a", 0)) == 0:
        return prop["k"]
    value = None
    for key in prop["k"]:
        if int(key["t"]) > frame:
            break
        value = key["s"]
    if value is None:
        raise ValueError(f"animated Lottie property has no value at frame {frame}")
    return value


def _scalar_at(prop: dict[str, Any], frame: int) -> float:
    value = _value_at(prop, frame)
    return float(value[0] if isinstance(value, list) else value)


def _matrix_at(transform: dict[str, Any], frame: int) -> dict[str, float]:
    anchor = _value_at(transform["a"], frame)
    if [float(value) for value in anchor[:2]] != [0.0, 0.0]:
        raise ValueError("character Lottie currently requires a zero anchor point")
    return compose_channels({
        "p": [float(value) for value in _value_at(transform["p"], frame)[:2]],
        "s": [float(value) for value in _value_at(transform["s"], frame)[:2]],
        "r": _scalar_at(transform["r"], frame),
        "o": _scalar_at(transform["o"], frame),
        "sk": _scalar_at(transform.get("sk", _static(0.0)), frame),
        "sa": _scalar_at(transform.get("sa", _static(0.0)), frame),
    })


def load_lottie_motion(path: Path) -> dict[str, Any]:
    document = json.loads(path.read_text(encoding="utf-8"))
    total = int(document["op"]) - int(document.get("ip", 0))
    if total <= 0 or int(document["fr"]) <= 0:
        raise ValueError(f"invalid character Lottie timing in {path}")
    layers = document.get("layers", [])
    root_layers = [layer for layer in layers if layer.get("nm") == ROOT_LAYER]
    if len(root_layers) != 1 or int(root_layers[0].get("ty", -1)) != 3:
        raise ValueError(f"{path} must contain one {ROOT_LAYER} null layer")
    root_layer = root_layers[0]
    root_index = int(root_layer["ind"])
    slot_layers = [layer for layer in layers if layer.get("nm") in SUPPORTED_SLOTS]
    names = {str(layer["nm"]) for layer in slot_layers}
    if not REQUIRED_SLOTS.issubset(names) or len(names) != len(slot_layers):
        raise ValueError(f"{path} has invalid character slots: {sorted(names)}")
    for layer in slot_layers:
        if int(layer.get("ty", -1)) != 3 or int(layer.get("parent", -1)) != root_index:
            raise ValueError(f"character slot {layer['nm']} must be a null parented to {ROOT_LAYER}")
    metadata = document.get("metadata", {}).get("customProps", {}).get("pr2", {})
    if metadata.get("format") != METADATA_FORMAT or int(metadata.get("version", -1)) != METADATA_VERSION:
        raise ValueError(f"{path} has invalid PR2 character metadata")
    if metadata.get("endBehavior") not in END_BEHAVIORS:
        raise ValueError(f"{path} has invalid end behavior {metadata.get('endBehavior')}")
    slot_definitions = metadata.get("slots")
    if not isinstance(slot_definitions, list):
        raise ValueError(f"{path} has no PR2 slot metadata")
    metadata_names = [str(slot.get("name")) for slot in slot_definitions]
    layer_names = [str(layer["nm"]) for layer in slot_layers]
    if metadata_names != layer_names:
        raise ValueError(f"{path} PR2 slot metadata order differs from its Lottie layers")
    for slot in slot_definitions:
        if slot.get("parent") != "root" or not isinstance(slot.get("drawOrder"), int):
            raise ValueError(f"{path} has invalid metadata for slot {slot.get('name')}")
    return {
        "name": str(metadata.get("state")),
        "frameRate": int(document["fr"]),
        "frameCount": total,
        "endBehavior": str(metadata["endBehavior"]),
        "endSignal": metadata.get("endSignal"),
        "root": _matrix_at(root_layer["ks"], 0),
        "slotDefinitions": slot_definitions,
        "slots": {
            str(layer["nm"]): [_matrix_at(layer["ks"], frame) for frame in range(total)]
            for layer in slot_layers
        },
    }


def write_lottie(path: Path, animation: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(animation_to_lottie(animation), indent=2) + "\n", encoding="utf-8")
