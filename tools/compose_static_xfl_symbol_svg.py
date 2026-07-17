#!/usr/bin/env python3
"""Compose a static XFL symbol into one standalone SVG without Adobe Animate.

The repository's timeline export already contains Animate-authored SVGs for
every vector leaf. This tool reads the XFL hierarchy and frame-zero layer order,
then inlines those exact leaves with the authored instance matrices. It is
deliberately strict: unsupported animation, masks, filters, groups, or missing
leaf exports fail instead of producing approximate art.
"""

import argparse
import copy
import json
import os
import xml.etree.ElementTree as ET
from pathlib import Path


XFL_NS = "http://ns.adobe.com/xfl/2008/"
SVG_NS = "http://www.w3.org/2000/svg"
XLINK_NS = "http://www.w3.org/1999/xlink"
DEFAULT_XFL_ROOT = os.path.join("flash", "platform-racing-2-xfl", "LIBRARY")
DEFAULT_MANIFEST = os.path.join("art", "timeline-svg-manifest.json")
DEFAULT_LEAF_ROOT = os.path.join("art", "svg", "timeline")


def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def direct_children(parent, name):
    return [child for child in list(parent) if local_name(child.tag) == name]


def first_child(parent, name):
    for child in list(parent):
        if local_name(child.tag) == name:
            return child
    return None


def load_symbols(root):
    symbols = {}
    for path in Path(root).rglob("*.xml"):
        try:
            item = ET.parse(path).getroot()
        except ET.ParseError:
            continue
        if local_name(item.tag) != "DOMSymbolItem":
            continue
        name = item.get("name")
        if name:
            symbols[name] = (path, item)
    return symbols


def load_leaf_jobs(path):
    with open(path, encoding="utf-8") as handle:
        manifest = json.load(handle)
    jobs = {}
    for job in manifest.get("exports", []):
        key = (job["symbolName"], job["timelineIndex"], job["layerIndex"], job["frame"])
        jobs.setdefault(key, []).append(job)
    for values in jobs.values():
        values.sort(key=lambda job: job["elementIndices"][0])
    return jobs


def frame_at_zero(layer):
    frames = first_child(layer, "frames")
    if frames is None:
        return None
    for frame in direct_children(frames, "DOMFrame"):
        start = int(frame.get("index", "0"))
        duration = int(frame.get("duration", "1"))
        if start <= 0 < start + duration:
            return frame
    return None


def matrix_for(element):
    matrix_holder = first_child(element, "matrix")
    matrix = first_child(matrix_holder, "Matrix") if matrix_holder is not None else None
    if matrix is None:
        return None
    values = [
        float(matrix.get("a", "1")),
        float(matrix.get("b", "0")),
        float(matrix.get("c", "0")),
        float(matrix.get("d", "1")),
        float(matrix.get("tx", "0")),
        float(matrix.get("ty", "0")),
    ]
    if values == [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]:
        return None
    return "matrix(" + " ".join(format_number(value) for value in values) + ")"


def format_number(value):
    if value == int(value):
        return str(int(value))
    return ("%.10f" % value).rstrip("0").rstrip(".")


class Composer:
    def __init__(self, symbols, jobs, leaf_root):
        self.symbols = symbols
        self.jobs = jobs
        self.leaf_root = Path(leaf_root)
        self.inline_index = 0
        self.stack = []

    def compose_symbol(self, symbol_name):
        if symbol_name in self.stack:
            raise ValueError("Recursive symbol dependency: " + " -> ".join(self.stack + [symbol_name]))
        record = self.symbols.get(symbol_name)
        if record is None:
            raise ValueError(f"Missing XFL symbol {symbol_name}")
        self.stack.append(symbol_name)
        _, item = record
        timelines = first_child(item, "timeline")
        timeline_list = direct_children(timelines, "DOMTimeline") if timelines is not None else []
        if len(timeline_list) != 1:
            raise ValueError(f"{symbol_name} must contain exactly one timeline")
        timeline = timeline_list[0]
        layers_holder = first_child(timeline, "layers")
        layers = direct_children(layers_holder, "DOMLayer") if layers_holder is not None else []
        output = ET.Element(f"{{{SVG_NS}}}g", {"data-xfl-symbol": symbol_name})
        for layer_index in range(len(layers) - 1, -1, -1):
            layer = layers[layer_index]
            if layer.get("layerType") in ("mask", "guide", "folder") or layer.get("parentLayerIndex") is not None:
                raise ValueError(f"Unsupported layer relationship in {symbol_name}: {layer.get('name', layer_index)}")
            frame = frame_at_zero(layer)
            if frame is None:
                continue
            self.compose_frame(output, symbol_name, layer_index, frame)
        self.stack.pop()
        return output

    def compose_frame(self, output, symbol_name, layer_index, frame):
        elements_holder = first_child(frame, "elements")
        elements = list(elements_holder) if elements_holder is not None else []
        key = (symbol_name, 0, layer_index, int(frame.get("index", "0")))
        jobs = self.jobs.get(key, [])
        jobs_by_start = {job["elementIndices"][0]: job for job in jobs}
        covered = {index for job in jobs for index in job["elementIndices"]}
        for index, element in enumerate(elements):
            job = jobs_by_start.get(index)
            if job is not None:
                output.append(self.inline_leaf(job["exportPath"]))
            if index in covered:
                continue
            element_type = local_name(element.tag)
            if element_type == "DOMSymbolInstance":
                child = self.compose_symbol(element.get("libraryItemName"))
                transform = matrix_for(element)
                if transform is not None:
                    wrapper = ET.Element(f"{{{SVG_NS}}}g", {"transform": transform})
                    wrapper.append(child)
                    child = wrapper
                output.append(child)
                continue
            raise ValueError(f"Unsupported {element_type} in {symbol_name} layer {layer_index}")

    def inline_leaf(self, relative_path):
        path = self.leaf_root / relative_path
        if not path.is_file():
            raise ValueError(f"Missing timeline SVG leaf {path}")
        leaf = ET.parse(path).getroot()
        self.inline_index += 1
        prefix = f"xfl{self.inline_index}_"
        wrapper = ET.Element(f"{{{SVG_NS}}}g", {"data-svg-leaf": relative_path})
        children = [copy.deepcopy(child) for child in list(leaf)]
        id_map = {}
        for child in children:
            for node in child.iter():
                old_id = node.get("id")
                if old_id:
                    id_map[old_id] = prefix + old_id
                    node.set("id", prefix + old_id)
        for child in children:
            for node in child.iter():
                for attribute in ("href", f"{{{XLINK_NS}}}href"):
                    href = node.get(attribute)
                    if href and href.startswith("#") and href[1:] in id_map:
                        node.set(attribute, "#" + id_map[href[1:]])
            wrapper.append(child)
        return wrapper


def write_svg(path, content, symbol_name):
    ET.register_namespace("", SVG_NS)
    ET.register_namespace("xlink", XLINK_NS)
    root = ET.Element(
        f"{{{SVG_NS}}}svg",
        {
            "version": "1.1",
            "width": "550px",
            "height": "400px",
            "viewBox": "0 0 550 400",
            "preserveAspectRatio": "none",
            "data-xfl-root": symbol_name,
        },
    )
    root.append(content)
    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    tree.write(destination, encoding="utf-8", xml_declaration=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--symbol", required=True, help="XFL library symbol name")
    parser.add_argument("--out", required=True, help="standalone SVG output path")
    parser.add_argument("--xfl-root", default=DEFAULT_XFL_ROOT)
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--leaf-root", default=DEFAULT_LEAF_ROOT)
    args = parser.parse_args()

    symbols = load_symbols(args.xfl_root)
    jobs = load_leaf_jobs(args.manifest)
    composer = Composer(symbols, jobs, args.leaf_root)
    content = composer.compose_symbol(args.symbol)
    write_svg(args.out, content, args.symbol)
    print(f"Composed {args.symbol} -> {args.out} ({composer.inline_index} exact SVG leaves)")


if __name__ == "__main__":
    main()
