#!/usr/bin/env python3
"""
Extract top-level metadata from the PR2 XFL source.

The output is deterministic JSON intended for asset-pipeline checks and later
code generation inputs. It uses only Python's standard library.
"""

import argparse
import json
import os
import sys
import xml.etree.ElementTree as ET


DEFAULT_XFL_DIR = os.path.join("flash", "platform-racing-2-xfl")


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


def parse_frame(frame):
    attrs = frame.attrib
    label = attrs.get("name")
    element_types = []

    elements = first_direct_child(frame, "elements")
    if elements is not None:
        element_types = sorted({local_name(element.tag) for element in list(elements)})

    return compact_record(
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
