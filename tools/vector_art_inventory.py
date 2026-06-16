#!/usr/bin/env python3
"""
Build a deterministic inventory of PR2 vector art and proposed export groups.

The manifest is intended to bridge the Adobe Animate source and the later
SVG/PNG export pipeline. It records every parsed DOMShape location, all library
symbol summaries, and game-facing character part channels based on Parts.as.
"""

import argparse
import json
import os
import re
import sys
from collections import Counter

from xfl_metadata import DEFAULT_XFL_DIR, build_metadata, compact_record


DEFAULT_PARTS_PATH = os.path.join("flash", "Parts.as")
DEFAULT_OUT_PATH = os.path.join("docs", "vector-art-inventory.json")

PART_CONTAINER_NAMES = {
    "hat": "Parts/Hats/hatsMC",
    "head": "Parts/Heads/headsMC",
    "body": "Parts/Bodies/bodyMC",
    "feet": "Parts/Feet/footMC",
}

PART_TYPE_MAP = {
    "HAT": "hat",
    "HEAD": "head",
    "BODY": "body",
    "FEET": "feet",
}

CHANNELS = ("static", "primary", "secondary", "composite")
PART_CONST_RE = re.compile(r"public\s+static\s+const\s+(HAT|HEAD|BODY|FEET)_([A-Z0-9_]+)\s*:\s*int\s*=\s*(\d+)")


def slug(value):
    text = value.lower().replace("&", "and")
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return text.strip("_") or "unnamed"


def parse_parts(parts_path):
    try:
        source = open(parts_path, encoding="utf-8").read()
    except OSError as exc:
        raise ValueError(f"Could not read parts file: {parts_path}: {exc}") from exc

    parts = {kind: [] for kind in PART_CONTAINER_NAMES}
    for match in PART_CONST_RE.finditer(source):
        raw_kind, raw_name, raw_id = match.groups()
        kind = PART_TYPE_MAP[raw_kind]
        parts[kind].append(
            {
                "id": int(raw_id),
                "name": raw_name.lower(),
                "constant": f"{raw_kind}_{raw_name}",
            }
        )

    for kind in parts:
        parts[kind].sort(key=lambda item: (item["id"], item["constant"]))
    return parts


def walk_elements(elements, path=None):
    path = path or []
    for index, element in enumerate(elements or []):
        element_path = path + [index]
        yield element_path, element
        yield from walk_elements(element.get("children"), element_path)


def style_type(style):
    value = style.get("value") or {}
    return value.get("type", "unknown")


def symbol_stats(symbol):
    element_types = Counter()
    fill_styles = Counter()
    stroke_styles = Counter()
    dependencies = Counter()
    direct_shapes = 0
    nested_shapes = 0
    shape_edges = 0
    labels = []
    frame_count = 0

    for timeline in symbol.get("timelines", []):
        frame_count = max(frame_count, timeline.get("frameCount", 0))
        labels.extend(label.get("name") for label in timeline.get("labels", []) if label.get("name"))
        for layer in timeline.get("layers", []):
            for frame in layer.get("frames", []):
                for path, element in walk_elements(frame.get("elements")):
                    element_type = element.get("type", "unknown")
                    element_types[element_type] += 1
                    if element.get("libraryItemName"):
                        dependencies[element["libraryItemName"]] += 1
                    if element_type == "DOMShape":
                        nested_shapes += 1
                        if len(path) == 1:
                            direct_shapes += 1
                        shape_edges += element.get("edgeCount", 0)
                    for fill in element.get("fills") or []:
                        fill_styles[style_type(fill)] += 1
                    for stroke in element.get("strokes") or []:
                        stroke_styles[style_type(stroke)] += 1

    return {
        "frameCount": frame_count,
        "labels": labels,
        "elementTypes": dict(sorted(element_types.items())),
        "directShapeCount": direct_shapes,
        "nestedShapeCount": nested_shapes,
        "shapeEdgeCount": shape_edges,
        "fillStyles": dict(sorted(fill_styles.items())),
        "strokeStyles": dict(sorted(stroke_styles.items())),
        "dependencies": dict(sorted(dependencies.items())),
    }


def active_elements_for_frame(layer, frame_index):
    best = None
    for frame in layer.get("frames", []):
        index = frame.get("index", 0)
        duration = frame.get("duration", 1)
        if index <= frame_index < index + duration:
            best = frame
    return [] if best is None else best.get("elements", [])


def find_part_channel_sources(container):
    sources = {}
    for timeline in container.get("timelines", []):
        for layer in timeline.get("layers", []):
            for frame in layer.get("frames", []):
                for _, element in walk_elements(frame.get("elements")):
                    name = element.get("name")
                    if name in ("colorMC", "colorMC2") and element.get("libraryItemName"):
                        channel = "primary" if name == "colorMC" else "secondary"
                        sources[channel] = {
                            "symbolName": element["libraryItemName"],
                            "instanceName": name,
                            "containerLayer": layer.get("name"),
                            "containerFrame": frame.get("index", 0),
                        }
    return sources


def frame_shape_counts(symbol, frame_index):
    counts = Counter()
    for timeline in symbol.get("timelines", []):
        for layer in timeline.get("layers", []):
            for _, element in walk_elements(active_elements_for_frame(layer, frame_index)):
                counts[element.get("type", "unknown")] += 1
    return dict(sorted(counts.items()))


def build_character_exports(parts, symbols_by_name):
    exports = []
    warnings = []

    for kind, part_records in parts.items():
        container_name = PART_CONTAINER_NAMES[kind]
        container = symbols_by_name.get(container_name)
        if container is None:
            warnings.append(f"Missing character container: {container_name}")
            continue

        channel_sources = find_part_channel_sources(container)
        container_frame_count = max(
            (timeline.get("frameCount", 0) for timeline in container.get("timelines", [])),
            default=0,
        )

        for part in part_records:
            frame = part["id"] - 1
            part_slug = f"{part['id']:03}_{slug(part['name'])}"
            export_base = f"character/{kind}/{part_slug}"
            frame_elements = frame_shape_counts(container, frame)
            if frame >= container_frame_count:
                warnings.append(
                    f"{kind} {part['id']} {part['name']} exceeds {container_name} frame count {container_frame_count}"
                )

            for channel in CHANNELS:
                source = {
                    "containerSymbol": container_name,
                    "containerFrame": frame,
                    "jsflRecipe": None,
                }
                if channel == "primary":
                    source.update(channel_sources.get("primary", {}))
                    source["jsflRecipe"] = "part.gotoAndStop(id); part.colorMC.gotoAndStop(id); export part.colorMC"
                elif channel == "secondary":
                    source.update(channel_sources.get("secondary", {}))
                    source["jsflRecipe"] = "part.gotoAndStop(id); part.colorMC2.gotoAndStop(id); export part.colorMC2"
                elif channel == "static":
                    source["jsflRecipe"] = "part.gotoAndStop(id); hide colorMC/colorMC2; export remaining visible part art"
                else:
                    source["jsflRecipe"] = "part.gotoAndStop(id); color primary/secondary channels; export composed part"

                exports.append(
                    compact_record(
                        {
                            "group": "character",
                            "kind": kind,
                            "id": part["id"],
                            "name": part["name"],
                            "constant": part["constant"],
                            "channel": channel,
                            "frame": frame,
                            "exportPath": f"{export_base}/{channel}.svg",
                            "rasterPath": f"{export_base}/{channel}@4x.png",
                            "source": compact_record(source),
                            "containerFrameElementTypes": frame_elements,
                        }
                    )
                )

    return exports, warnings


def classify_symbol(symbol):
    text = " ".join(
        value for value in (symbol.get("name"), symbol.get("href"), symbol.get("linkageClassName")) if value
    ).lower()

    if symbol.get("name") in PART_CONTAINER_NAMES.values():
        return "character_container"
    if "parts/" in text:
        return "character_internal"
    if "block" in text:
        return "blocks"
    if any(token in text for token in ("item", "laser", "sword", "lightning", "mine", "teleport", "jet")):
        return "items_effects"
    if any(token in text for token in ("button", "ui/", "popup", "menu", "tab", "scroll", "slider", "lobby")):
        return "ui"
    if any(token in text for token in ("background", "bg", "grid")):
        return "backgrounds"
    if symbol.get("href", "").startswith("Graphics/"):
        return "graphics_internal"
    if symbol.get("href", "").startswith("Components/"):
        return "components"
    return "uncategorized"


def collect_symbols(metadata):
    records = []
    for symbol in metadata["symbols"]:
        stats = symbol_stats(symbol)
        records.append(
            compact_record(
                {
                    "name": symbol.get("name"),
                    "href": symbol.get("href"),
                    "type": symbol.get("type"),
                    "linkageClassName": symbol.get("linkageClassName"),
                    "category": classify_symbol(symbol),
                    **stats,
                }
            )
        )
    return sorted(records, key=lambda item: (item.get("category", ""), item.get("name", ""), item.get("href", "")))


def collect_vector_elements(metadata):
    elements = []
    for symbol in metadata["symbols"]:
        for timeline_index, timeline in enumerate(symbol.get("timelines", [])):
            for layer in timeline.get("layers", []):
                for frame in layer.get("frames", []):
                    for element_path, element in walk_elements(frame.get("elements")):
                        if element.get("type") != "DOMShape":
                            continue
                        fills = [style_type(fill) for fill in element.get("fills") or []]
                        strokes = [style_type(stroke) for stroke in element.get("strokes") or []]
                        elements.append(
                            compact_record(
                                {
                                    "symbolName": symbol.get("name"),
                                    "symbolHref": symbol.get("href"),
                                    "timeline": timeline.get("name"),
                                    "timelineIndex": timeline_index,
                                    "layer": layer.get("name"),
                                    "layerIndex": layer.get("index"),
                                    "frame": frame.get("index", 0),
                                    "elementPath": element_path,
                                    "fillStyles": fills,
                                    "strokeStyles": strokes,
                                    "edgeCount": element.get("edgeCount"),
                                    "bounds": element.get("bounds"),
                                }
                            )
                        )
    return elements


def category_summary(symbols):
    categories = {}
    for symbol in symbols:
        category = symbol["category"]
        if category not in categories:
            categories[category] = {
                "symbolCount": 0,
                "directShapeCount": 0,
                "nestedShapeCount": 0,
                "symbolRefCount": 0,
            }
        summary = categories[category]
        summary["symbolCount"] += 1
        summary["directShapeCount"] += symbol.get("directShapeCount", 0)
        summary["nestedShapeCount"] += symbol.get("nestedShapeCount", 0)
        summary["symbolRefCount"] += sum(symbol.get("dependencies", {}).values())
    return dict(sorted(categories.items()))


def build_inventory(xfl_dir, parts_path):
    metadata = build_metadata(xfl_dir)
    parts = parse_parts(parts_path)
    symbols_by_name = {
        symbol["name"]: symbol
        for symbol in metadata["symbols"]
        if symbol.get("name")
    }
    symbols = collect_symbols(metadata)
    vector_elements = collect_vector_elements(metadata)
    character_exports, warnings = build_character_exports(parts, symbols_by_name)

    return {
        "schema": "pr2-vector-art-inventory-v1",
        "source": {
            "xflDir": xfl_dir,
            "partsPath": parts_path,
            "stage": metadata["stage"],
            "frameRate": metadata["document"].get("frameRate"),
        },
        "summary": {
            **metadata["counts"],
            "vectorElementCount": len(vector_elements),
            "characterExportCount": len(character_exports),
            "categorySummary": category_summary(symbols),
        },
        "exportPolicy": {
            "sourceFormat": "svg",
            "rasterScale": 4,
            "rasterSuffix": "@4x",
            "characterChannels": list(CHANNELS),
            "note": "Character part IDs come from Parts.as; extra Animate frames remain internal unless a later audit proves they are addressed.",
        },
        "characterParts": parts,
        "characterExports": character_exports,
        "symbols": symbols,
        "vectorElements": vector_elements,
        "warnings": warnings,
    }


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xfl-dir", default=DEFAULT_XFL_DIR, help=f"default: {DEFAULT_XFL_DIR}")
    parser.add_argument("--parts", default=DEFAULT_PARTS_PATH, help=f"default: {DEFAULT_PARTS_PATH}")
    parser.add_argument("--out", default=DEFAULT_OUT_PATH, help=f"default: {DEFAULT_OUT_PATH}; use - for stdout")
    parser.add_argument("--compact", action="store_true", help="emit compact JSON")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])
    try:
        inventory = build_inventory(args.xfl_dir, args.parts)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    indent = None if args.compact else 2
    content = json.dumps(inventory, indent=indent, sort_keys=True) + "\n"
    if args.out == "-":
        print(content, end="")
    else:
        os.makedirs(os.path.dirname(args.out), exist_ok=True)
        with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(content)
    return 0


if __name__ == "__main__":
    sys.exit(main())
