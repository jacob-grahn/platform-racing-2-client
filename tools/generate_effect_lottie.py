#!/usr/bin/env python3
"""Convert frame-based PR2 gameplay effects to semantic Lottie timelines."""

import argparse
import hashlib
import json
from pathlib import Path

from compose_static_xfl_symbol_svg import (
    Composer,
    direct_children,
    first_child,
    frame_at,
    load_leaf_jobs,
    load_symbols,
    svg_bytes,
)
from generate_intro_lottie import color_values, document, layer, matrix_values
from generate_native_effect_frames import EXCLUDED_INSTANCES, SELECTED_INSTANCES


XFL_ROOT = "flash/platform-racing-2-xfl/LIBRARY"
MANIFEST = "art/timeline-svg-manifest.json"
LEAF_ROOT = "art/svg/timeline"
SVG_OUTPUT = Path("art/svg/effects/lottie")
LOTTIE_OUTPUT = Path("art/effects")
SEQUENCES = {
    "countdown": ("MovieClips/Symbol 430", 62),
    "cowboy": ("MovieClips/Symbol 437", 82),
    "egg_base": ("MovieClips/Symbol 901", 46),
    "egg_dots": ("MovieClips/Symbol 901", 46),
    "egg_feet": ("MovieClips/Symbol 901", 46),
    "egg_fixed": ("MovieClips/Symbol 901", 46),
    "happy_hour": ("UI/Pages/Levels/In-Game/HappyHour", 100),
    "item_display": ("UI/Pages/Levels/In-Game/ItemDisplay", 51),
    "laser": ("UI/Pages/Levels/In-Game/Effects/LaserShot", 18),
    "mine": ("UI/Pages/Levels/In-Game/Effects/Mine/Symbol 976", 14),
    "slash": ("UI/Pages/Levels/In-Game/Effects/Slash", 6),
    "teleport": ("UI/Pages/Levels/In-Game/Effects/Teleport", 15),
}
EGG_CHANNELS = {
    "egg_fixed": None,
    "egg_feet": "colorMC",
    "egg_base": "base",
    "egg_dots": "dots",
}


def child_frame(composer, element, source_frame, frame_index):
    child_name = element.get("libraryItemName")
    count = composer.frame_count(child_name)
    first = int(element.get("firstFrame", "0"))
    elapsed = frame_index - int(source_frame.get("index", "0"))
    if element.get("symbolType") != "graphic":
        return elapsed % count
    mode = element.get("loop", "loop")
    if mode == "single frame":
        return first
    if mode == "play once":
        return min(first + elapsed, count - 1)
    return (first + elapsed) % count


def multiply_matrix(parent, child):
    pa, pb, pc, pd, ptx, pty = parent
    ca, cb, cc, cd, ctx, cty = child
    return [
        pa * ca + pc * cb,
        pb * ca + pd * cb,
        pa * cc + pc * cd,
        pb * cc + pd * cd,
        pa * ctx + pc * cty + ptx,
        pb * ctx + pd * cty + pty,
    ]


def compose_color(parent, child):
    return [
        parent[index] * child[index] for index in range(4)
    ] + [
        parent[index] * child[index + 4] + parent[index + 4] for index in range(4)
    ]


def flatten_symbol(composer, symbol, frame_index, matrix, color, selected_active, key, output):
    _, item = composer.symbols[symbol]
    timeline = direct_children(first_child(item, "timeline"), "DOMTimeline")[0]
    layers = direct_children(first_child(timeline, "layers"), "DOMLayer")
    for layer_index in range(len(layers) - 1, -1, -1):
        source_layer = layers[layer_index]
        if source_layer.get("name") in composer.excluded_layers_by_symbol.get(symbol, set()):
            continue
        source_frame = frame_at(source_layer, frame_index)
        if source_frame is None:
            continue
        holder = first_child(source_frame, "elements")
        elements = list(holder) if holder is not None else []
        job_key = (symbol, 0, layer_index, int(source_frame.get("index", "0")))
        jobs = composer.jobs.get(job_key, [])
        jobs_by_start = {job["elementIndices"][0]: job for job in jobs}
        covered = {index for job in jobs for index in job["elementIndices"]}
        for element_index, element in enumerate(elements):
            record_key = key + ((layer_index, element_index),)
            job = jobs_by_start.get(element_index)
            if job is not None and selected_active:
                path = Path(LEAF_ROOT) / job["exportPath"]
                output.append({
                    "key": record_key + (("leaf", job["exportPath"]),),
                    "content": path.read_bytes(),
                    "matrix": matrix,
                    "color": color,
                    "name": job["exportPath"],
                })
            if element_index in covered:
                continue
            instance_name = element.get("name")
            if instance_name in composer.excluded_instance_names:
                continue
            tag = element.tag.rsplit("}", 1)[-1]
            if tag == "DOMSymbolInstance":
                nested_symbol = element.get("libraryItemName")
                nested_frame = child_frame(composer, element, source_frame, frame_index)
                nested_selected = selected_active or (
                    composer.selected_instance_names is not None
                    and instance_name in composer.selected_instance_names
                )
                flatten_symbol(
                    composer,
                    nested_symbol,
                    nested_frame,
                    multiply_matrix(matrix, matrix_values(element)),
                    compose_color(color, color_values(element)),
                    nested_selected,
                    record_key + (("symbol", nested_symbol),),
                    output,
                )
                continue
            if not selected_active:
                continue
            if tag == "DOMStaticText":
                content = svg_bytes(composer.compose_static_text(element), f"{symbol} text")
            elif tag == "DOMBitmapInstance":
                content = svg_bytes(composer.compose_bitmap(element), f"{symbol} bitmap")
            else:
                raise ValueError(f"Unsupported {tag} in {symbol} layer {layer_index}")
            output.append({
                "key": record_key + ((tag,),),
                "content": content,
                "matrix": matrix,
                "color": color,
                "name": f"{symbol}:{tag}",
            })


def write_or_check(path, encoded, check, label):
    if check:
        if not path.is_file() or path.read_bytes() != encoded:
            raise SystemExit(f"{label} is stale: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encoded)


def asset_for(content, assets, asset_ids, check):
    digest = hashlib.sha256(content).hexdigest()[:20]
    filename = f"{digest}.svg"
    if filename not in asset_ids:
        asset_ids[filename] = f"effect_{len(asset_ids)}"
        assets.append({
            "id": asset_ids[filename],
            "w": 550,
            "h": 400,
            "u": "assets/svg/effects/lottie/",
            "p": filename,
            "e": 0,
        })
        write_or_check(SVG_OUTPUT / filename, content, check, "Effect Lottie SVG")
    return asset_ids[filename]


def effect_lottie(kind, symbol, frame_count, symbols, jobs, check):
    selected = SELECTED_INSTANCES.get(kind)
    excluded = EXCLUDED_INSTANCES.get(kind, set())
    if kind in EGG_CHANNELS:
        channel_names = {name for name in EGG_CHANNELS.values() if name is not None} | {"colorMC2"}
        selected_name = EGG_CHANNELS[kind]
        selected = None if selected_name is None else {selected_name}
        excluded = channel_names if selected_name is None else channel_names - {selected_name}
    composer = Composer(symbols, jobs, LEAF_ROOT, selected_instance_names=selected, excluded_instance_names=excluded)
    frames = []
    key_order = []
    for frame_index in range(frame_count):
        records = []
        flatten_symbol(
            composer,
            symbol,
            frame_index,
            [1, 0, 0, 1, 0, 0],
            [1, 1, 1, 1, 0, 0, 0, 0],
            selected is None,
            (("root", symbol),),
            records,
        )
        mapping = {record["key"]: record for record in records}
        frames.append(mapping)
        for record in records:
            if record["key"] not in key_order:
                key_order.append(record["key"])
    assets = []
    asset_ids = {}
    layers = []
    for record_key in reversed(key_order):
        cursor = 0
        while cursor < frame_count:
            record = frames[cursor].get(record_key)
            if record is None:
                cursor += 1
                continue
            end = cursor + 1
            while end < frame_count:
                candidate = frames[end].get(record_key)
                if candidate is None or candidate["content"] != record["content"]:
                    break
                end += 1
            ref_id = asset_for(record["content"], assets, asset_ids, check)
            active = [frames[index][record_key] for index in range(cursor, end)]
            layers.append(layer(
                record["name"],
                ref_id,
                cursor,
                [entry["matrix"] for entry in active],
                [entry["color"] for entry in active],
                len(layers) + 1,
            ))
            cursor = end
    metadata = {"sourceSymbol": symbol, "sourceFrameCount": frame_count}
    return document(kind, frame_count, assets, layers, custom_props=metadata)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    symbols = load_symbols(XFL_ROOT)
    jobs = load_leaf_jobs(MANIFEST)
    expected_svgs = set()
    for kind, (symbol, frame_count) in SEQUENCES.items():
        value = effect_lottie(kind, symbol, frame_count, symbols, jobs, args.check)
        encoded = (json.dumps(value, separators=(",", ":")) + "\n").encode()
        write_or_check(LOTTIE_OUTPUT / f"{kind}.lottie.json", encoded, args.check, "Effect Lottie timeline")
        for asset in value["assets"]:
            expected_svgs.add(SVG_OUTPUT / asset["p"])
    if not args.check and SVG_OUTPUT.exists():
        for path in SVG_OUTPUT.glob("*.svg"):
            if path not in expected_svgs:
                path.unlink()
    print(("Verified" if args.check else "Generated") + f" {len(SEQUENCES)} semantic effect Lottie timelines")


if __name__ == "__main__":
    main()
