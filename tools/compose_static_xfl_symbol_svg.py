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
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image

from extract_xfl_bitmaps import decode_raw_bitmap_pixels


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


def frame_at(layer, index):
    frames = first_child(layer, "frames")
    if frames is None:
        return None
    for frame in direct_children(frames, "DOMFrame"):
        start = int(frame.get("index", "0"))
        duration = int(frame.get("duration", "1"))
        if start <= index < start + duration:
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


def color_transform_for(element):
    color_holder = first_child(element, "color")
    color = first_child(color_holder, "Color") if color_holder is not None else None
    if color is None:
        return None
    return {
        "redMultiplier": float(color.get("redMultiplier", "1")),
        "greenMultiplier": float(color.get("greenMultiplier", "1")),
        "blueMultiplier": float(color.get("blueMultiplier", "1")),
        "alphaMultiplier": float(color.get("alphaMultiplier", "1")),
        "redOffset": float(color.get("redOffset", "0")) / 255.0,
        "greenOffset": float(color.get("greenOffset", "0")) / 255.0,
        "blueOffset": float(color.get("blueOffset", "0")) / 255.0,
        "alphaOffset": float(color.get("alphaOffset", "0")) / 255.0,
    }


def format_number(value):
    if value == int(value):
        return str(int(value))
    return ("%.10f" % value).rstrip("0").rstrip(".")


class Composer:
    def __init__(self, symbols, jobs, leaf_root, xfl_root=DEFAULT_XFL_ROOT, selected_instance_names=None, excluded_instance_names=None,
                 excluded_layers_by_symbol=None):
        self.symbols = symbols
        self.jobs = jobs
        self.leaf_root = Path(leaf_root)
        self.inline_index = 0
        self.stack = []
        self.frame_counts = {}
        self.xfl_dir = Path(xfl_root).parent
        self.bitmap_items = None
        self.selected_instance_names = None if selected_instance_names is None else set(selected_instance_names)
        self.excluded_instance_names = set(excluded_instance_names or [])
        self.excluded_layers_by_symbol = {
            symbol: set(layer_names) for symbol, layer_names in (excluded_layers_by_symbol or {}).items()
        }
    def apply_color_transform(self, child, transform):
        if transform is None:
            return child
        for node in child.iter():
            for attribute, channel in (("fill", None), ("stroke", None), ("stop-color", None), ("flood-color", None)):
                value = node.get(attribute)
                match = re.fullmatch(r"#([0-9A-Fa-f]{6})", value or "")
                if match is None:
                    continue
                rgb = int(match.group(1), 16)
                channels = [(rgb >> 16) & 255, (rgb >> 8) & 255, rgb & 255]
                adjusted = []
                for name, component in zip(("red", "green", "blue"), channels):
                    value = component * transform[f"{name}Multiplier"] + transform[f"{name}Offset"] * 255.0
                    adjusted.append(max(0, min(255, round(value))))
                node.set(attribute, "#" + "".join(f"{component:02X}" for component in adjusted))
        alpha = max(0.0, min(1.0, transform["alphaMultiplier"] + transform["alphaOffset"]))
        if alpha == 1.0:
            return child
        wrapper = ET.Element(f"{{{SVG_NS}}}g", {"opacity": format_number(alpha)})
        wrapper.append(child)
        return wrapper

    def frame_count(self, symbol_name):
        cached = self.frame_counts.get(symbol_name)
        if cached is not None:
            return cached
        record = self.symbols.get(symbol_name)
        if record is None:
            raise ValueError(f"Missing XFL symbol {symbol_name}")
        _, item = record
        timeline_holder = first_child(item, "timeline")
        timelines = direct_children(timeline_holder, "DOMTimeline") if timeline_holder is not None else []
        count = 1
        if timelines:
            layers_holder = first_child(timelines[0], "layers")
            for layer in direct_children(layers_holder, "DOMLayer") if layers_holder is not None else []:
                frames_holder = first_child(layer, "frames")
                for frame in direct_children(frames_holder, "DOMFrame") if frames_holder is not None else []:
                    count = max(count, int(frame.get("index", "0")) + int(frame.get("duration", "1")))
        self.frame_counts[symbol_name] = count
        return count

    def compose_symbol(self, symbol_name, frame_index=0, selected_active=None):
        if symbol_name in self.stack:
            raise ValueError("Recursive symbol dependency: " + " -> ".join(self.stack + [symbol_name]))
        record = self.symbols.get(symbol_name)
        if record is None:
            raise ValueError(f"Missing XFL symbol {symbol_name}")
        self.stack.append(symbol_name)
        if selected_active is None:
            selected_active = self.selected_instance_names is None
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
            if layer.get("name") in self.excluded_layers_by_symbol.get(symbol_name, set()):
                continue
            if layer.get("layerType") in ("mask", "guide", "folder") or layer.get("parentLayerIndex") is not None:
                raise ValueError(f"Unsupported layer relationship in {symbol_name}: {layer.get('name', layer_index)}")
            frame = frame_at(layer, frame_index)
            if frame is None:
                continue
            self.compose_frame(output, symbol_name, layer_index, frame, frame_index, selected_active)
        self.stack.pop()
        return output

    def compose_frame(self, output, symbol_name, layer_index, frame, frame_index, selected_active):
        elements_holder = first_child(frame, "elements")
        elements = list(elements_holder) if elements_holder is not None else []
        key = (symbol_name, 0, layer_index, int(frame.get("index", "0")))
        jobs = self.jobs.get(key, [])
        jobs_by_start = {job["elementIndices"][0]: job for job in jobs}
        covered = {index for job in jobs for index in job["elementIndices"]}
        for index, element in enumerate(elements):
            job = jobs_by_start.get(index)
            if job is not None and selected_active:
                output.append(self.inline_leaf(job["exportPath"]))
            if index in covered:
                continue
            element_type = local_name(element.tag)
            instance_name = element.get("name")
            if instance_name in self.excluded_instance_names:
                continue
            if element_type == "DOMSymbolInstance":
                child_name = element.get("libraryItemName")
                child_count = self.frame_count(child_name)
                first_frame = int(element.get("firstFrame", "0"))
                elapsed = frame_index - int(frame.get("index", "0"))
                if element.get("symbolType") == "graphic":
                    loop = element.get("loop", "loop")
                    if loop == "single frame":
                        child_frame = first_frame
                    elif loop == "play once":
                        child_frame = min(first_frame + elapsed, child_count - 1)
                    else:
                        child_frame = (first_frame + elapsed) % child_count
                else:
                    child_frame = elapsed % child_count
                child_selected = selected_active or (self.selected_instance_names is not None and instance_name in self.selected_instance_names)
                child = self.compose_symbol(child_name, child_frame, child_selected)
                child = self.apply_color_transform(child, color_transform_for(element))
                transform = matrix_for(element)
                attributes = {}
                if transform is not None:
                    attributes["transform"] = transform
                if instance_name:
                    attributes["data-xfl-instance"] = instance_name
                if attributes:
                    wrapper = ET.Element(f"{{{SVG_NS}}}g", attributes)
                    wrapper.append(child)
                    child = wrapper
                output.append(child)
                continue
            if element_type == "DOMStaticText":
                if selected_active:
                    output.append(self.compose_static_text(element))
                continue
            if element_type == "DOMBitmapInstance":
                if selected_active:
                    output.append(self.compose_bitmap(element))
                continue
            if not selected_active:
                continue
            raise ValueError(f"Unsupported {element_type} in {symbol_name} layer {layer_index}")

    def compose_bitmap(self, element):
        library_name = element.get("libraryItemName")
        if not library_name:
            raise ValueError("XFL bitmap instance has no library item name")
        item = self.load_bitmap_items().get(library_name)
        if item is None:
            raise ValueError(f"Missing XFL bitmap item {library_name}")
        if item.get("isJPEG") == "true" and item.get("href"):
            source = self.xfl_dir / "LIBRARY" / item.get("href")
            image = Image.open(source).convert("RGBA")
            width, height = image.size
            stride = width * 4
            rgba = image.tobytes()
            pixels = bytearray(len(rgba))
            for offset in range(0, len(rgba), 4):
                red, green, blue, alpha = rgba[offset:offset + 4]
                pixels[offset:offset + 4] = bytes((alpha, red, green, blue))
        else:
            data_href = item.get("bitmapDataHRef")
            if not data_href:
                raise ValueError(f"XFL bitmap item has no lossless payload: {library_name}")
            payload = (self.xfl_dir / "bin" / data_href).read_bytes()
            width, height, stride, pixels = decode_raw_bitmap_pixels(payload)
        paths = {}
        for y in range(height):
            row = pixels[y * stride:y * stride + width * 4]
            x = 0
            while x < width:
                color = tuple(row[x * 4:x * 4 + 4])
                end = x + 1
                while end < width and tuple(row[end * 4:end * 4 + 4]) == color:
                    end += 1
                alpha, red, green, blue = color
                if alpha:
                    paths.setdefault((red, green, blue, alpha), []).append(f"M{x} {y}h{end - x}v1h-{end - x}z")
                x = end
        bitmap = ET.Element(f"{{{SVG_NS}}}g", {"data-xfl-bitmap": library_name})
        for (red, green, blue, alpha), commands in sorted(paths.items()):
            attributes = {"d": "".join(commands), "fill": f"#{red:02X}{green:02X}{blue:02X}"}
            if alpha != 255:
                attributes["fill-opacity"] = format_number(alpha / 255.0)
            bitmap.append(ET.Element(f"{{{SVG_NS}}}path", attributes))
        bitmap = self.apply_color_transform(bitmap, color_transform_for(element))
        transform = matrix_for(element)
        if transform is None:
            return bitmap
        wrapper = ET.Element(f"{{{SVG_NS}}}g", {"transform": transform})
        wrapper.append(bitmap)
        return wrapper

    def load_bitmap_items(self):
        if self.bitmap_items is not None:
            return self.bitmap_items
        self.bitmap_items = {}
        document = ET.parse(self.xfl_dir / "DOMDocument.xml").getroot()
        for item in document.iter():
            if local_name(item.tag) == "DOMBitmapItem" and item.get("name"):
                self.bitmap_items[item.get("name")] = item
        return self.bitmap_items

    def compose_static_text(self, element):
        text_runs = first_child(element, "textRuns")
        run = first_child(text_runs, "DOMTextRun") if text_runs is not None else None
        characters = first_child(run, "characters") if run is not None else None
        attrs_holder = first_child(run, "textAttrs") if run is not None else None
        attrs = first_child(attrs_holder, "DOMTextAttrs") if attrs_holder is not None else None
        if characters is None or attrs is None:
            raise ValueError("Unsupported empty XFL static text")
        line_height = float(attrs.get("lineHeight", "14.55"))
        text = ET.Element(
            f"{{{SVG_NS}}}text",
            {
                # XFL stores the text field's local left edge separately from
                # its instance matrix. Ignoring it shifts authored labels left
                # (and can clip them entirely in registration-local exports).
                "x": format_number(float(element.get("left", "0"))),
                "y": format_number(line_height * 0.82),
                "fill": attrs.get("fillColor", "#000000"),
                "font-family": attrs.get("face", "sans-serif"),
                "font-size": format_number(line_height * 0.82),
                "letter-spacing": attrs.get("letterSpacing", "0"),
            },
        )
        text.text = characters.text or ""
        transform = matrix_for(element)
        if transform is None:
            return text
        wrapper = ET.Element(f"{{{SVG_NS}}}g", {"transform": transform})
        wrapper.append(text)
        return wrapper

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
                for attribute, value in list(node.attrib.items()):
                    for old_id, new_id in id_map.items():
                        value = value.replace(f"url(#{old_id})", f"url(#{new_id})")
                    node.set(attribute, value)
            wrapper.append(child)
        return wrapper


def svg_bytes(content, symbol_name):
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
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def write_svg(path, content, symbol_name):
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(svg_bytes(content, symbol_name))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--symbol", required=True, help="XFL library symbol name")
    parser.add_argument("--out", required=True, help="standalone SVG output path")
    parser.add_argument("--frame", type=int, default=0, help="zero-based root timeline frame")
    parser.add_argument("--xfl-root", default=DEFAULT_XFL_ROOT)
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--leaf-root", default=DEFAULT_LEAF_ROOT)
    parser.add_argument("--check", action="store_true", help="fail if the committed SVG differs")
    args = parser.parse_args()

    symbols = load_symbols(args.xfl_root)
    jobs = load_leaf_jobs(args.manifest)
    composer = Composer(symbols, jobs, args.leaf_root, args.xfl_root)
    content = composer.compose_symbol(args.symbol, args.frame)
    if args.check:
        destination = Path(args.out)
        expected = svg_bytes(content, args.symbol)
        if not destination.is_file() or destination.read_bytes() != expected:
            raise SystemExit(f"Static XFL SVG is stale: {args.out}")
    else:
        write_svg(args.out, content, args.symbol)
    print(f"Composed {args.symbol} -> {args.out} ({composer.inline_index} exact SVG leaves)")


if __name__ == "__main__":
    main()
