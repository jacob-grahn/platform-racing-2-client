#!/usr/bin/env python3
"""
Extract top-level metadata from the PR2 XFL source.

The output is deterministic JSON intended for asset-pipeline checks and later
code generation inputs. It uses only Python's standard library.
"""

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET


DEFAULT_XFL_DIR = os.path.join("flash", "platform-racing-2-xfl")
EDGE_NUMBER_RE = re.compile(r"(?<![#A-Za-z])-?\d+(?:\.\d+)?")


def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def parse_xml(path):
    try:
        return ET.parse(path).getroot()
    except ET.ParseError as exc:
        raise ValueError(f"Could not parse XML: {path}: {exc}") from exc
    except OSError as exc:
        raise ValueError(f"Could not read XML: {path}: {exc}") from exc


def child_elements(root, name):
    for element in root.iter():
        if local_name(element.tag) == name:
            yield element


def direct_children(parent, name):
    for child in list(parent):
        if local_name(child.tag) == name:
            yield child


def first_direct_child(parent, name):
    for child in direct_children(parent, name):
        return child
    return None


def text_for(parent, name):
    for child in list(parent):
        if local_name(child.tag) == name and child.text is not None:
            return child.text.strip()
    return None


def maybe_int(value):
    if value is None or value == "":
        return None
    try:
        return int(value)
    except ValueError:
        return None


def maybe_float(value):
    if value is None or value == "":
        return None
    try:
        return float(value)
    except ValueError:
        return None


def item_record(element):
    attrs = element.attrib
    return {
        "type": local_name(element.tag),
        "name": attrs.get("name"),
        "href": attrs.get("href"),
        "itemID": attrs.get("itemID"),
        "linkageClassName": attrs.get("linkageClassName"),
        "linkageIdentifier": attrs.get("linkageIdentifier"),
    }


def compact_record(record):
    return {key: value for key, value in record.items() if value not in (None, "")}


def parse_bool(value):
    if value == "true":
        return True
    if value == "false":
        return False
    return None


def parse_float_attrs(element, names):
    record = {}
    if element is None:
        return record
    for name in names:
        value = maybe_float(element.attrib.get(name))
        if value is not None:
            record[name] = value
    return record


def parse_direct_float_child(parent, wrapper_name, value_name, attrs):
    wrapper = first_direct_child(parent, wrapper_name)
    if wrapper is None:
        return None

    value = first_direct_child(wrapper, value_name)
    if value is None:
        return None

    return compact_record(parse_float_attrs(value, attrs))


def parse_matrix(element):
    matrix = parse_direct_float_child(
        element,
        "matrix",
        "Matrix",
        ("a", "b", "c", "d", "tx", "ty"),
    )
    return matrix


def parse_point(element):
    point = parse_direct_float_child(
        element,
        "transformationPoint",
        "Point",
        ("x", "y"),
    )
    return point


# Filter element types we carry through to the runtime. Other Animate filters
# (Bevel, gradient glow/bevel, adjust color, convolution) are not used by the
# PR2 library and have no OpenFL mapping here, so they are skipped.
SUPPORTED_FILTERS = ("BlurFilter", "GlowFilter", "DropShadowFilter")
FILTER_FLOAT_ATTRS = ("blurX", "blurY", "strength", "alpha", "angle", "distance")
FILTER_INT_ATTRS = ("quality",)
FILTER_BOOL_ATTRS = ("inner", "knockout", "hideObject")


def parse_color_hex(value):
    if not value:
        return None
    try:
        return int(value.lstrip("#"), 16)
    except ValueError:
        return None


def parse_filter(element):
    record = {"type": local_name(element.tag)}
    attrs = element.attrib
    for name in FILTER_FLOAT_ATTRS:
        value = maybe_float(attrs.get(name))
        if value is not None:
            record[name] = value
    for name in FILTER_INT_ATTRS:
        value = maybe_int(attrs.get(name))
        if value is not None:
            record[name] = value
    for name in FILTER_BOOL_ATTRS:
        value = parse_bool(attrs.get(name))
        if value is not None:
            record[name] = value
    color = parse_color_hex(attrs.get("color"))
    if color is not None:
        record["color"] = color
    return record


def filter_is_noop(record):
    """A filter that produces no visible output, so it can be dropped instead of
    paying for a per-frame raster + GPU texture upload.

    - Glow/DropShadow with strength 0 draw nothing.
    - Glow/Blur with no blur radius spread nothing (a drop shadow can still show
      an offset hard edge, so it is not covered here).
    """
    filter_type = record.get("type")
    if filter_type in ("GlowFilter", "DropShadowFilter") and record.get("strength") == 0:
        return True
    if filter_type in ("GlowFilter", "BlurFilter"):
        if record.get("blurX") == 0 and record.get("blurY") == 0:
            return True
    return False


def parse_filters(element):
    wrapper = first_direct_child(element, "filters")
    if wrapper is None:
        return []
    filters = []
    for child in list(wrapper):
        if local_name(child.tag) not in SUPPORTED_FILTERS:
            continue
        record = parse_filter(child)
        if filter_is_noop(record):
            continue
        filters.append(record)
    return filters


def parse_color_transform(element):
    color = parse_direct_float_child(
        element,
        "color",
        "Color",
        (
            "alphaMultiplier",
            "redMultiplier",
            "greenMultiplier",
            "blueMultiplier",
            "alphaOffset",
            "redOffset",
            "greenOffset",
            "blueOffset",
        ),
    )
    return color


def parse_indexed_style(style):
    record = compact_record({"index": maybe_int(style.attrib.get("index"))})
    value = first_style_value(style)
    if value is not None:
        record["value"] = parse_style_value(value)
    return compact_record(record)


def first_style_value(style):
    for child in list(style):
        name = local_name(child.tag)
        if name not in ("matrix",):
            return child
    return None


def parse_gradient_entries(element):
    entries = []
    for entry in direct_children(element, "GradientEntry"):
        entries.append(
            compact_record(
                {
                    "ratio": maybe_float(entry.attrib.get("ratio")),
                    "color": entry.attrib.get("color"),
                    "alpha": maybe_float(entry.attrib.get("alpha")),
                }
            )
        )
    return entries


def parse_style_value(element):
    name = local_name(element.tag)
    record = {"type": name}

    for key, value in sorted(element.attrib.items()):
        parsed = maybe_float(value)
        if key in ("bitmapIsClipped", "pixelHinting"):
            parsed_bool = parse_bool(value)
            record[key] = parsed_bool if parsed_bool is not None else value
        elif parsed is not None and key not in ("color", "bitmapPath", "scaleMode", "caps", "joints", "solidStyle"):
            record[key] = parsed
        else:
            record[key] = value

    matrix = parse_matrix(element)
    if matrix:
        record["matrix"] = matrix

    entries = parse_gradient_entries(element)
    if entries:
        record["entries"] = entries

    fill = first_direct_child(element, "fill")
    if fill is not None:
        fill_value = first_style_value(fill)
        if fill_value is not None:
            record["fill"] = parse_style_value(fill_value)

    return compact_record(record)


def parse_shape_styles(element, wrapper_name, style_name):
    wrapper = first_direct_child(element, wrapper_name)
    if wrapper is None:
        return []
    return [parse_indexed_style(style) for style in direct_children(wrapper, style_name)]


def parse_edge(element):
    # The XFL `cubics` attribute is a redundant cubic-Bezier copy of geometry the
    # styled `edges` quadratics already fully describe. Cubics edges carry no
    # fill/stroke style, and Flash itself renders only the quadratic `edges` (SWF
    # is quadratic-only), so we drop `cubics` here. A style-less cubics-only Edge
    # then compacts to an empty record, which parse_shape_edges filters out.
    record = {
        "fillStyle0": maybe_int(element.attrib.get("fillStyle0")),
        "fillStyle1": maybe_int(element.attrib.get("fillStyle1")),
        "strokeStyle": maybe_int(element.attrib.get("strokeStyle")),
        "edges": element.attrib.get("edges"),
    }
    return compact_record(record)


def parse_shape_edges(element):
    wrapper = first_direct_child(element, "edges")
    if wrapper is None:
        return []
    return [edge for edge in (parse_edge(edge) for edge in direct_children(wrapper, "Edge")) if edge]


def edge_numbers(edge_record):
    text = edge_record.get("edges") or ""
    return [maybe_float(match.group(0)) for match in EDGE_NUMBER_RE.finditer(text)]


def parse_shape_bounds(edges):
    min_x = None
    min_y = None
    max_x = None
    max_y = None

    for edge in edges:
        numbers = [number for number in edge_numbers(edge) if number is not None]
        for index in range(0, len(numbers) - 1, 2):
            x = numbers[index]
            y = numbers[index + 1]
            min_x = x if min_x is None else min(min_x, x)
            min_y = y if min_y is None else min(min_y, y)
            max_x = x if max_x is None else max(max_x, x)
            max_y = y if max_y is None else max(max_y, y)

    if min_x is None:
        return None

    return {
        "left": min_x,
        "top": min_y,
        "right": max_x,
        "bottom": max_y,
    }


def parse_common_display_attrs(element):
    attrs = element.attrib
    record = {
        "type": local_name(element.tag),
        "name": attrs.get("name"),
        "libraryItemName": attrs.get("libraryItemName"),
        "symbolType": attrs.get("symbolType"),
        "loop": attrs.get("loop"),
        "firstFrame": maybe_int(attrs.get("firstFrame")),
        "visible": parse_bool(attrs.get("visible")),
        "blendMode": attrs.get("blendMode"),
        "centerPoint3DX": maybe_float(attrs.get("centerPoint3DX")),
        "centerPoint3DY": maybe_float(attrs.get("centerPoint3DY")),
        "left": maybe_float(attrs.get("left")),
        "width": maybe_float(attrs.get("width")),
        "height": maybe_float(attrs.get("height")),
    }

    matrix = parse_matrix(element)
    if matrix:
        record["matrix"] = matrix

    point = parse_point(element)
    if point:
        record["transformationPoint"] = point

    color = parse_color_transform(element)
    if color:
        record["color"] = color

    filters = parse_filters(element)
    if filters:
        record["filters"] = filters

    return compact_record(record)


def parse_text_attrs(text_run):
    text_attrs = first_direct_child(text_run, "textAttrs")
    if text_attrs is None:
        return {}
    dom_text_attrs = first_direct_child(text_attrs, "DOMTextAttrs")
    if dom_text_attrs is None:
        return {}

    record = {}
    for key, value in sorted(dom_text_attrs.attrib.items()):
        parsed_bool = parse_bool(value)
        parsed_float = maybe_float(value)
        if parsed_bool is not None:
            record[key] = parsed_bool
        elif parsed_float is not None and key not in ("face", "alignment"):
            record[key] = parsed_float
        else:
            record[key] = value
    return compact_record(record)


def parse_text(element):
    record = parse_common_display_attrs(element)
    text_runs = first_direct_child(element, "textRuns")
    if text_runs is None:
        return compact_record(record)

    parts = []
    first_attrs = {}
    for text_run in direct_children(text_runs, "DOMTextRun"):
        chars = text_for(text_run, "characters")
        if chars is not None:
            parts.append(chars)
        if not first_attrs:
            first_attrs = parse_text_attrs(text_run)

    if parts:
        record["text"] = "".join(parts)
    if first_attrs:
        record["textAttrs"] = first_attrs
    return compact_record(record)


def parse_component_params(element):
    params = first_direct_child(element, "parametersAsXML")
    if params is None or params.text is None:
        return {}

    try:
        root = ET.fromstring("<root>" + params.text + "</root>")
    except ET.ParseError:
        return {}

    record = {}
    for prop in root.findall("property"):
        prop_id = prop.attrib.get("id")
        inspectable = prop.find("Inspectable")
        if prop_id is None or inspectable is None:
            continue
        value = inspectable.attrib.get("defaultValue")
        value_type = inspectable.attrib.get("type")
        if value_type == "Boolean":
            parsed_bool = parse_bool(value)
            value = parsed_bool if parsed_bool is not None else value
        elif value_type == "Number":
            parsed_float = maybe_float(value)
            value = parsed_float if parsed_float is not None else value
        record[prop_id] = compact_record(
            {
                "value": value,
                "type": value_type,
            }
        )
    return record


def parse_component_instance(element):
    record = parse_common_display_attrs(element)
    params = parse_component_params(element)
    if params:
        record["componentParams"] = params
    return compact_record(record)


def parse_shape_summary(element):
    record = parse_common_display_attrs(element)
    fills = parse_shape_styles(element, "fills", "FillStyle")
    strokes = parse_shape_styles(element, "strokes", "StrokeStyle")
    edges = parse_shape_edges(element)
    bounds = parse_shape_bounds(edges)

    record.update(
        compact_record(
            {
                "fillStyleCount": len(fills),
                "strokeStyleCount": len(strokes),
                "edgeCount": len(edges),
            }
        )
    )
    if fills:
        record["fills"] = fills
    if strokes:
        record["strokes"] = strokes
    if edges:
        record["edges"] = edges
    if bounds:
        record["bounds"] = bounds
    return compact_record(record)


# Animate primitive drawing objects (DOMRectangleObject / DOMOvalObject) carry
# their geometry as attributes instead of `edges`, plus direct `<fill>`/`<stroke>`
# children (not the `fills`/`strokes` wrappers used by DOMShape).
PRIMITIVE_GEOMETRY_ATTRS = (
    "x",
    "y",
    "objectWidth",
    "objectHeight",
    "topLeftRadius",
    "topRightRadius",
    "bottomLeftRadius",
    "bottomRightRadius",
    "startAngle",
    "endAngle",
    "innerRadius",
)


def parse_direct_style(element, wrapper_name):
    wrapper = first_direct_child(element, wrapper_name)
    if wrapper is None:
        return None
    value = first_style_value(wrapper)
    if value is None:
        return None
    return parse_style_value(value)


def parse_primitive_object(element):
    record = parse_common_display_attrs(element)
    record.update(parse_float_attrs(element, PRIMITIVE_GEOMETRY_ATTRS))

    close_path = parse_bool(element.attrib.get("closePath"))
    if close_path is not None:
        record["closePath"] = close_path

    fill = parse_direct_style(element, "fill")
    if fill is not None:
        record["fill"] = fill

    stroke = parse_direct_style(element, "stroke")
    if stroke is not None:
        record["stroke"] = stroke

    return compact_record(record)


def parse_display_element(element):
    name = local_name(element.tag)
    if name in ("DOMSymbolInstance", "DOMBitmapInstance"):
        return parse_common_display_attrs(element)

    if name in ("DOMStaticText", "DOMDynamicText", "DOMInputText"):
        return parse_text(element)

    if name == "DOMComponentInstance":
        return parse_component_instance(element)

    if name == "DOMShape":
        return parse_shape_summary(element)

    if name in ("DOMRectangleObject", "DOMOvalObject"):
        return parse_primitive_object(element)

    if name == "DOMGroup":
        record = parse_common_display_attrs(element)
        members = first_direct_child(element, "members")
        if members is not None:
            children = parse_display_elements(members)
            if children:
                record["children"] = children
        return compact_record(record)

    return compact_record({"type": name})


def parse_display_elements(parent):
    elements = []
    for element in list(parent):
        name = local_name(element.tag)
        if name in (
            "DOMSymbolInstance",
            "DOMBitmapInstance",
            "DOMComponentInstance",
            "DOMStaticText",
            "DOMDynamicText",
            "DOMInputText",
            "DOMShape",
            "DOMGroup",
            "DOMRectangleObject",
            "DOMOvalObject",
        ):
            elements.append(parse_display_element(element))
    return elements


def parse_frame(frame):
    attrs = frame.attrib
    label = attrs.get("name")
    element_types = []
    display_elements = []

    elements = first_direct_child(frame, "elements")
    if elements is not None:
        element_types = sorted({local_name(element.tag) for element in list(elements)})
        display_elements = parse_display_elements(elements)

    record = compact_record(
        {
            "index": maybe_int(attrs.get("index")),
            "duration": maybe_int(attrs.get("duration")),
            "label": label,
            "labelType": attrs.get("labelType"),
            "keyMode": maybe_int(attrs.get("keyMode")),
            "motionTweenScale": parse_bool(attrs.get("motionTweenScale")),
            "elementCount": len(list(elements)) if elements is not None else 0,
            "elementTypes": element_types,
        }
    )
    if display_elements:
        record["elements"] = display_elements
    return record


def parse_layer(layer, layer_index):
    attrs = layer.attrib
    frames_parent = first_direct_child(layer, "frames")
    frames = []
    if frames_parent is not None:
        frames = [parse_frame(frame) for frame in direct_children(frames_parent, "DOMFrame")]

    return compact_record(
        {
            "index": layer_index,
            "name": attrs.get("name"),
            "color": attrs.get("color"),
            "visible": parse_bool(attrs.get("visible")),
            "locked": parse_bool(attrs.get("locked")),
            "layerType": attrs.get("layerType"),
            "parentLayerIndex": maybe_int(attrs.get("parentLayerIndex")),
            "frameCount": len(frames),
            "frames": frames,
        }
    )


def parse_timeline(timeline):
    layers_parent = first_direct_child(timeline, "layers")
    layers = []
    if layers_parent is not None:
        layers = [
            parse_layer(layer, index)
            for index, layer in enumerate(direct_children(layers_parent, "DOMLayer"))
        ]

    total_frames = 0
    labels = []
    for layer in layers:
        for frame in layer.get("frames", []):
            index = frame.get("index", 0)
            duration = frame.get("duration", 1)
            total_frames = max(total_frames, index + duration)
            if frame.get("label"):
                labels.append(
                    compact_record(
                        {
                            "name": frame.get("label"),
                            "type": frame.get("labelType"),
                            "frame": index,
                            "layer": layer.get("index"),
                        }
                    )
                )

    return compact_record(
        {
            "name": timeline.attrib.get("name"),
            "layerCount": len(layers),
            "frameCount": total_frames,
            "labels": labels,
            "layers": layers,
        }
    )


def parse_timelines(root):
    timelines = []
    timeline_parent = first_direct_child(root, "timeline")
    if timeline_parent is None:
        return timelines

    for timeline in direct_children(timeline_parent, "DOMTimeline"):
        timelines.append(parse_timeline(timeline))

    return timelines


def timeline_counts(timelines):
    layers = 0
    frames = 0
    labels = 0
    max_total_frames = 0

    for timeline in timelines:
        layers += timeline.get("layerCount", 0)
        labels += len(timeline.get("labels", []))
        max_total_frames = max(max_total_frames, timeline.get("frameCount", 0))
        for layer in timeline.get("layers", []):
            frames += layer.get("frameCount", 0)

    return {
        "timelines": len(timelines),
        "layers": layers,
        "frames": frames,
        "labels": labels,
        "maxTotalFrames": max_total_frames,
    }


def parse_publish_settings(path):
    root = parse_xml(path)
    profiles = []

    for profile in child_elements(root, "PublishProfile"):
        width = maybe_int(text_for(profile, "Width"))
        height = maybe_int(text_for(profile, "Height"))
        if width is None and height is None:
            continue
        profiles.append(
            compact_record(
                {
                    "name": profile.attrib.get("name"),
                    "width": width,
                    "height": height,
                }
            )
        )

    # Some Animate versions store width/height under multiple publish sections
    # without PublishProfile wrappers. Preserve unique sizes in document order.
    seen = {(entry.get("width"), entry.get("height")) for entry in profiles}
    for parent in root.iter():
        width = maybe_int(text_for(parent, "Width"))
        height = maybe_int(text_for(parent, "Height"))
        key = (width, height)
        if width is not None and height is not None and key not in seen:
            profiles.append({"width": width, "height": height})
            seen.add(key)

    stage = None
    if profiles:
        stage = {"width": profiles[0]["width"], "height": profiles[0]["height"]}

    return {"stage": stage, "profiles": profiles}


def parse_dom_document(path):
    root = parse_xml(path)

    folders = [compact_record(item_record(element)) for element in child_elements(root, "DOMFolderItem")]
    fonts = [compact_record(item_record(element)) for element in child_elements(root, "DOMFontItem")]
    media = []
    for element in root.iter():
        name = local_name(element.tag)
        if name in ("DOMBitmapItem", "DOMSoundItem", "DOMCompiledClipItem"):
            record = item_record(element)
            record.update(
                {
                    "bitmapDataHRef": element.attrib.get("bitmapDataHRef"),
                    "soundDataHRef": element.attrib.get("soundDataHRef"),
                    "frameRight": maybe_int(element.attrib.get("frameRight")),
                    "frameBottom": maybe_int(element.attrib.get("frameBottom")),
                    "format": element.attrib.get("format"),
                    "sampleCount": maybe_int(element.attrib.get("sampleCount")),
                }
            )
            media.append(compact_record(record))

    symbol_includes = []
    for include in child_elements(root, "Include"):
        symbol_includes.append(
            compact_record(
                {
                    "href": include.attrib.get("href"),
                    "itemID": include.attrib.get("itemID"),
                    "lastModified": maybe_int(include.attrib.get("lastModified")),
                    "loadImmediate": include.attrib.get("loadImmediate"),
                }
            )
        )

    timelines = parse_timelines(root)

    linkage_classes = sorted(
        {
            item["linkageClassName"]
            for item in media
            if item.get("linkageClassName")
        }
    )

    return {
        "document": compact_record(
            {
                "frameRate": maybe_int(root.attrib.get("frameRate")),
                "xflVersion": root.attrib.get("xflVersion"),
                "creatorInfo": root.attrib.get("creatorInfo"),
                "platform": root.attrib.get("platform"),
                "versionInfo": root.attrib.get("versionInfo"),
                "majorVersion": maybe_int(root.attrib.get("majorVersion")),
                "buildNumber": maybe_int(root.attrib.get("buildNumber")),
                "fileGUID": root.attrib.get("fileGUID"),
            }
        ),
        "folders": folders,
        "fonts": fonts,
        "media": media,
        "symbolIncludes": symbol_includes,
        "timelines": timelines,
        "linkageClasses": linkage_classes,
    }


def parse_symbol_linkages(xfl_dir, symbol_includes):
    library_dir = os.path.join(xfl_dir, "LIBRARY")
    records = []

    for include in symbol_includes:
        href = include.get("href")
        if not href:
            continue

        path = os.path.join(library_dir, href)
        if not os.path.exists(path):
            records.append({"href": href, "missing": True})
            continue

        root = parse_xml(path)
        attrs = root.attrib
        record = {
            "href": href,
            "type": local_name(root.tag),
            "name": attrs.get("name"),
            "itemID": attrs.get("itemID"),
            "linkageClassName": attrs.get("linkageClassName"),
            "linkageIdentifier": attrs.get("linkageIdentifier"),
            "symbolType": attrs.get("symbolType"),
            "timelines": parse_timelines(root),
        }
        records.append(compact_record(record))

    return records


def build_metadata(xfl_dir):
    dom_path = os.path.join(xfl_dir, "DOMDocument.xml")
    publish_path = os.path.join(xfl_dir, "PublishSettings.xml")

    if not os.path.isdir(xfl_dir):
        raise ValueError(f"XFL directory does not exist: {xfl_dir}")
    if not os.path.exists(dom_path):
        raise ValueError(f"DOMDocument.xml does not exist: {dom_path}")
    if not os.path.exists(publish_path):
        raise ValueError(f"PublishSettings.xml does not exist: {publish_path}")

    dom = parse_dom_document(dom_path)
    publish = parse_publish_settings(publish_path)
    symbol_linkages = parse_symbol_linkages(xfl_dir, dom["symbolIncludes"])
    document_timeline_counts = timeline_counts(dom["timelines"])
    symbol_timelines = [
        timeline
        for symbol in symbol_linkages
        for timeline in symbol.get("timelines", [])
    ]
    symbol_timeline_counts = timeline_counts(symbol_timelines)

    all_linkages = {
        item["linkageClassName"]
        for item in dom["media"] + symbol_linkages
        if item.get("linkageClassName")
    }

    return {
        "xflDir": xfl_dir,
        "document": dom["document"],
        "stage": publish["stage"],
        "publishProfiles": publish["profiles"],
        "counts": {
            "folders": len(dom["folders"]),
            "fonts": len(dom["fonts"]),
            "media": len(dom["media"]),
            "bitmapItems": sum(1 for item in dom["media"] if item["type"] == "DOMBitmapItem"),
            "soundItems": sum(1 for item in dom["media"] if item["type"] == "DOMSoundItem"),
            "compiledClipItems": sum(1 for item in dom["media"] if item["type"] == "DOMCompiledClipItem"),
            "symbolIncludes": len(dom["symbolIncludes"]),
            "symbolFiles": len(symbol_linkages),
            "missingSymbolFiles": sum(1 for item in symbol_linkages if item.get("missing")),
            "linkageClasses": len(all_linkages),
            "documentTimelines": document_timeline_counts["timelines"],
            "symbolTimelines": symbol_timeline_counts["timelines"],
            "timelineLayers": document_timeline_counts["layers"] + symbol_timeline_counts["layers"],
            "timelineFrames": document_timeline_counts["frames"] + symbol_timeline_counts["frames"],
            "timelineLabels": document_timeline_counts["labels"] + symbol_timeline_counts["labels"],
            "maxTimelineFrames": max(
                document_timeline_counts["maxTotalFrames"],
                symbol_timeline_counts["maxTotalFrames"],
            ),
        },
        "folders": dom["folders"],
        "fonts": dom["fonts"],
        "media": dom["media"],
        "symbols": symbol_linkages,
        "timelines": dom["timelines"],
        "linkageClasses": sorted(all_linkages),
    }


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xfl-dir", default=DEFAULT_XFL_DIR, help=f"default: {DEFAULT_XFL_DIR}")
    parser.add_argument("--compact", action="store_true", help="emit compact JSON")
    parser.add_argument("--summary", action="store_true", help="emit only document, stage, and counts")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])

    try:
        metadata = build_metadata(args.xfl_dir)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    if args.summary:
        metadata = {
            "xflDir": metadata["xflDir"],
            "document": metadata["document"],
            "stage": metadata["stage"],
            "counts": metadata["counts"],
        }

    indent = None if args.compact else 2
    print(json.dumps(metadata, indent=indent, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
