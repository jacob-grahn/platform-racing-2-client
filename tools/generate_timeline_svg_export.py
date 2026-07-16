#!/usr/bin/env python3
"""Generate the complete PR2 timeline-leaf SVG export and manifest.

Each job copies one contiguous run of vector-safe top-level elements from an
authored keyframe layer and exports that selection through Animate's official
SVG extension. The generated Haxe catalog uses the same manifest to replace
those elements with a lightweight DOMSvgInstance while preserving their layer
and display-list position.
"""

import argparse
import copy
import hashlib
import html
import json
import os
import re
import sys
from pathlib import Path

from xfl_metadata import DEFAULT_XFL_DIR, build_metadata


DEFAULT_FLA = os.path.join("flash", "platform-racing-2.fla")
DEFAULT_OUT = os.path.join("art", "export-timeline-svg.jsfl")
DEFAULT_MANIFEST = os.path.join("art", "timeline-svg-manifest.json")
DEFAULT_SVG_DIR = os.path.join("art", "svg", "timeline")
DEFAULT_ADOBE_SVG_EXPORTER = (
    "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/Common/"
    "Configuration/Extensions/ExportSVG/jsfl/Export SVG.jsfl"
)
VECTOR_TYPES = frozenset(("DOMShape", "DOMRectangleObject", "DOMOvalObject"))


def file_uri(path):
    return Path(path).resolve().as_uri()


def walk_elements(elements):
    for element in elements or []:
        yield element
        yield from walk_elements(element.get("children"))


def contains_vector(element):
    return any(item.get("type") in VECTOR_TYPES for item in walk_elements([element]))


def style_type(style):
    return (style.get("value") or {}).get("type")


def contains_bitmap_fill(element):
    for item in walk_elements([element]):
        if item.get("type") not in VECTOR_TYPES:
            continue
        if any(style_type(style) == "BitmapFill" for style in item.get("fills") or []):
            return True
        fill = item.get("fill") or {}
        if fill.get("type") == "BitmapFill":
            return True
    return False


def build_bakeable_symbol_set(metadata):
    symbols = {symbol.get("name"): symbol for symbol in metadata["symbols"] if symbol.get("name")}
    bakeable = set()

    def safe_element(element):
        if element.get("name") or element.get("filters"):
            return False
        element_type = element.get("type")
        if element_type in VECTOR_TYPES:
            return True
        if element_type == "DOMGroup":
            return all(safe_element(child) for child in element.get("children") or [])
        if element_type == "DOMSymbolInstance":
            return element.get("libraryItemName") in bakeable
        return False

    changed = True
    while changed:
        changed = False
        for name, symbol in symbols.items():
            if name in bakeable:
                continue
            timelines = symbol.get("timelines") or []
            if len(timelines) != 1 or timelines[0].get("frameCount", 0) > 1:
                continue
            layers = timelines[0].get("layers") or []
            if any(layer.get("layerType") == "mask" or layer.get("parentLayerIndex") is not None for layer in layers):
                continue
            if all(
                safe_element(element)
                for layer in layers
                for frame in layer.get("frames") or []
                for element in frame.get("elements") or []
            ):
                bakeable.add(name)
                changed = True
    return bakeable


def make_safe_element_predicate(bakeable):
    def safe_element(element):
        if element.get("name") or element.get("filters"):
            return False
        element_type = element.get("type")
        if element_type in VECTOR_TYPES:
            return True
        if element_type == "DOMGroup":
            return all(safe_element(child) for child in element.get("children") or [])
        if element_type == "DOMSymbolInstance":
            return element.get("libraryItemName") in bakeable
        return False

    return safe_element


def symbol_slug(name):
    cleaned = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    digest = hashlib.sha1(name.encode("utf-8")).hexdigest()[:10]
    return f"{cleaned[:64] or 'symbol'}_{digest}"


def contiguous_runs(indices):
    runs = []
    for index in indices:
        if not runs or index != runs[-1][-1] + 1:
            runs.append([index])
        else:
            runs[-1].append(index)
    return runs


def build_plan(metadata):
    bakeable = build_bakeable_symbol_set(metadata)
    safe_element = make_safe_element_predicate(bakeable)
    jobs = []
    covered_vectors = 0
    total_vectors = 0

    for symbol in metadata["symbols"]:
        symbol_name = symbol.get("name")
        if not symbol_name:
            continue
        for timeline_index, timeline in enumerate(symbol.get("timelines") or []):
            for layer in timeline.get("layers") or []:
                for frame in layer.get("frames") or []:
                    elements = frame.get("elements") or []
                    total_vectors += sum(
                        1 for element in elements for item in walk_elements([element]) if item.get("type") in VECTOR_TYPES
                    )
                    selected = [
                        index
                        for index, element in enumerate(elements)
                        if contains_vector(element) and safe_element(element)
                    ]
                    for run_index, indices in enumerate(contiguous_runs(selected)):
                        run_elements = [elements[index] for index in indices]
                        vector_count = sum(
                            1
                            for element in run_elements
                            for item in walk_elements([element])
                            if item.get("type") in VECTOR_TYPES
                        )
                        covered_vectors += vector_count
                        rel_path = (
                            f"{symbol_slug(symbol_name)}/"
                            f"t{timeline_index:02d}_l{layer.get('index', 0):03d}_f{frame.get('index', 0):04d}_r{run_index:02d}.svg"
                        )
                        jobs.append(
                            {
                                "symbolName": symbol_name,
                                "timelineIndex": timeline_index,
                                "layerIndex": layer.get("index", 0),
                                "layerName": layer.get("name") or "",
                                "frame": frame.get("index", 0),
                                "runIndex": run_index,
                                "elementIndices": indices,
                                "sourceElementCount": len(elements),
                                "selectWholeFrame": indices == list(range(len(elements))),
                                "vectorCount": vector_count,
                                "bitmapFill": any(contains_bitmap_fill(element) for element in run_elements),
                                "exportPath": rel_path,
                            }
                        )

    if covered_vectors != total_vectors:
        raise ValueError(f"SVG plan covers {covered_vectors} of {total_vectors} vector leaves")
    return {
        "schema": "pr2-timeline-svg-export-v1",
        "symbolCount": len({job["symbolName"] for job in jobs}),
        "exportCount": len(jobs),
        "vectorLeafCount": total_vectors,
        "bakeableSymbolCount": len(bakeable),
        "bitmapFillExportCount": sum(job["bitmapFill"] for job in jobs),
        "exports": jobs,
    }


def plan_key(symbol_name, timeline_index, layer_index, frame_index):
    return symbol_name, timeline_index, layer_index, frame_index


def apply_plan(metadata, plan, bitmap_fallbacks=None):
    transformed = copy.deepcopy(metadata)
    jobs_by_frame = {}
    for job in plan["exports"]:
        key = plan_key(job["symbolName"], job["timelineIndex"], job["layerIndex"], job["frame"])
        jobs_by_frame.setdefault(key, []).append(job)

    for symbol in transformed["symbols"]:
        symbol_name = symbol.get("name")
        for timeline_index, timeline in enumerate(symbol.get("timelines") or []):
            for layer in timeline.get("layers") or []:
                for frame in layer.get("frames") or []:
                    key = plan_key(symbol_name, timeline_index, layer.get("index", 0), frame.get("index", 0))
                    jobs = jobs_by_frame.get(key)
                    if not jobs:
                        continue
                    starts = {job["elementIndices"][0]: job for job in jobs}
                    skipped = {index for job in jobs for index in job["elementIndices"]}
                    output = []
                    for index, element in enumerate(frame.get("elements") or []):
                        job = starts.get(index)
                        if job is not None:
                            replacement = {
                                "type": "DOMSvgInstance",
                                "svgAssetPath": "assets/svg/timeline/" + job["exportPath"],
                            }
                            fallback = bitmap_fallbacks.get(job["exportPath"]) if bitmap_fallbacks is not None else None
                            if fallback is not None:
                                replacement["bitmapAssetPath"] = fallback["assetPath"]
                                replacement["bitmapScale"] = fallback["scale"]
                            elif bitmap_fallbacks is None and job["bitmapFill"]:
                                replacement["bitmapAssetPath"] = (
                                    "assets/timeline-bitmap/" + job["exportPath"][:-4] + ".png"
                                )
                                replacement["bitmapScale"] = 0.5
                            output.append(replacement)
                        if index not in skipped:
                            output.append(element)
                    frame["elements"] = output

    remaining = [
        (symbol.get("name"), item.get("type"))
        for symbol in transformed["symbols"]
        for timeline in symbol.get("timelines") or []
        for layer in timeline.get("layers") or []
        for frame in layer.get("frames") or []
        for item in walk_elements(frame.get("elements") or [])
        if item.get("type") in VECTOR_TYPES
    ]
    if remaining:
        raise ValueError(f"SVG plan left {len(remaining)} vector elements in generated timelines")
    return transformed


def output_jobs(plan, svg_dir):
    root = Path(svg_dir).resolve()
    jobs = []
    for source in plan["exports"]:
        job = dict(source)
        # Illustrator-imported library items preserve numeric entities in the
        # XFL attribute, while Animate exposes the decoded name through JSFL.
        job["editSymbolName"] = html.unescape(source["symbolName"])
        job["outputUri"] = (root / source["exportPath"]).as_uri()
        jobs.append(job)
    return jobs


def jsfl_source(jobs, fla_uri, svg_exporter_uri):
    return f'''// Generated by tools/generate_timeline_svg_export.py. Do not edit by hand.
var SOURCE_FLA_URI = {json.dumps(fla_uri)};
var ADOBE_SVG_EXPORTER_URI = {json.dumps(svg_exporter_uri)};
var JOBS = {json.dumps(jobs, indent=2, sort_keys=True)};

function log(message) {{ fl.trace("[PR2 Timeline SVG] " + message); }}
function dirname(uri) {{ return uri.replace(/\\/[^\\/]*$/, ""); }}
function mkdirs(uri) {{
    var parts = uri.split("/");
    if (parts.length < 4) return;
    var current = parts[0] + "//" + parts[2];
    for (var i = 3; i < parts.length; i++) {{
        current += "/" + parts[i];
        if (!FLfile.exists(current)) FLfile.createFolder(current);
    }}
}}
function selectFrame(timeline, frame) {{
    timeline.currentFrame = frame;
    try {{ timeline.setSelectedFrames(frame, frame + 1, true); }} catch (e) {{}}
}}
function findLayer(timeline, name) {{
    for (var i = 0; i < timeline.layers.length; i++) if (timeline.layers[i].name == name) return i;
    return -1;
}}
function copyElements(editDoc, timeline, job) {{
    var layerIndex = findLayer(timeline, job.layerName);
    if (layerIndex < 0) throw new Error("Missing layer " + job.layerName + " in " + job.symbolName);
    var layer = timeline.layers[layerIndex];
    var frame = layer.frames[job.frame];
    if (!frame) throw new Error("Missing frame " + job.frame + " in " + job.symbolName + " / " + job.layerName);
    if (!job.selectWholeFrame && frame.elements.length != job.sourceElementCount) {{
        throw new Error(
            "Element count changed in " + job.symbolName + " / " + job.layerName + " / " + job.frame +
            ": expected " + job.sourceElementCount + ", got " + frame.elements.length
        );
    }}
    var state = {{ layers: [], elements: [] }};
    for (var l = 0; l < timeline.layers.length; l++) {{
        state.layers.push({{ layer: timeline.layers[l], locked: timeline.layers[l].locked, visible: timeline.layers[l].visible }});
        timeline.layers[l].locked = true;
        timeline.layers[l].visible = false;
    }}
    layer.locked = false;
    layer.visible = true;
    var selectedLookup = {{}};
    for (var i = 0; i < job.elementIndices.length; i++) selectedLookup[job.elementIndices[i]] = true;
    for (var e = 0; e < frame.elements.length; e++) {{
        state.elements.push({{ element: frame.elements[e], visible: frame.elements[e].visible }});
        frame.elements[e].visible = job.selectWholeFrame || selectedLookup[e] === true;
    }}
    timeline.currentLayer = layerIndex;
    try {{ timeline.setSelectedLayers(layerIndex, true); }} catch (e) {{}}
    try {{ timeline.setSelectedFrames(job.frame, job.frame + 1, true); }} catch (e) {{}}
    try {{ editDoc.selectNone(); }} catch (e) {{}}
    editDoc.selectAll();
    for (var d = 0; d < frame.elements.length; d++) {{
        if (!job.selectWholeFrame && selectedLookup[d] !== true) frame.elements[d].selected = false;
    }}
    var selectionValid = job.selectWholeFrame
        ? editDoc.selection && editDoc.selection.length > 0
        : editDoc.selection && editDoc.selection.length == job.elementIndices.length;
    if (!selectionValid) {{
        throw new Error(
            "Could not select export run in " + job.symbolName + " / " + job.layerName +
            ": requested " + job.elementIndices.length + ", selected " +
            (editDoc.selection ? editDoc.selection.length : 0)
        );
    }}
    editDoc.clipCopy();
    return state;
}}
function restoreLayerState(doc, job, state) {{
    if (!doc.library.editItem(job.editSymbolName)) throw new Error("Could not restore " + job.editSymbolName);
    for (var l = 0; l < state.layers.length; l++) {{
        state.layers[l].layer.locked = state.layers[l].locked;
        state.layers[l].layer.visible = state.layers[l].visible;
    }}
    for (var e = 0; e < state.elements.length; e++) {{
        state.elements[e].element.visible = state.elements[e].visible;
    }}
    fl.getDocumentDOM().exitEditMode();
}}
function normalizeHairlineStrokes(outputUri) {{
    var svg = FLfile.read(outputUri);
    if (!svg) throw new Error("Could not read exported SVG: " + outputUri);
    // Animate serializes Flash hairlines (weight 0.05, solidStyle hairline)
    // as ordinary 0.05-unit SVG strokes. OpenFL uses width 0 for a true
    // one-device-pixel hairline, matching Flash at every display scale.
    svg = svg.split('stroke-width=\"0.05\"').join('stroke-width=\"0\"');
    FLfile.write(outputUri, svg);
}}
function exportJob(doc, job, index) {{
    fl.setActiveWindow(doc);
    if (!doc.library.editItem(job.editSymbolName)) throw new Error("Could not edit " + job.editSymbolName);
    var editDoc = fl.getDocumentDOM();
    var timeline = editDoc.getTimeline();
    selectFrame(timeline, job.frame);
    var layerState = copyElements(editDoc, timeline, job);
    editDoc.exitEditMode();
    var exportDoc = null;
    try {{
        // Animate's SVG exporter retains hidden document state after deleting
        // pasted artwork. A fresh document per run prevents earlier symbols
        // from leaking into later SVGs.
        exportDoc = fl.createDocument("timeline");
        if (!exportDoc) throw new Error("Could not create temporary export document");
        fl.setActiveWindow(exportDoc);
        exportDoc.clipPaste(true);
        mkdirs(dirname(job.outputUri));
        log((index + 1) + "/" + JOBS.length + " " + job.exportPath);
        fl.runScript(ADOBE_SVG_EXPORTER_URI, "exportSVG", "", job.outputUri, true, "", false, false, 0, 0);
        normalizeHairlineStrokes(job.outputUri);
    }} finally {{
        try {{ if (exportDoc) exportDoc.close(false); }} catch (e) {{}}
        fl.setActiveWindow(doc);
        restoreLayerState(doc, job, layerState);
    }}
}}
function run() {{
    var doc = fl.openDocument(SOURCE_FLA_URI);
    if (!doc) throw new Error("Could not open " + SOURCE_FLA_URI);
    fl.setActiveWindow(doc);
    try {{
        for (var i = 0; i < JOBS.length; i++) exportJob(doc, JOBS[i], i);
        FLfile.write("file:///tmp/pr2-timeline-svg-complete.log", "complete: " + JOBS.length);
        log("complete: " + JOBS.length);
    }} finally {{
        try {{ fl.setActiveWindow(doc); }} catch (e) {{}}
        try {{ doc.close(false); }} catch (e) {{}}
    }}
}}
try {{ run(); }} catch (error) {{
    var message = error && error.message ? error.message : String(error);
    fl.trace("[PR2 Timeline SVG] ERROR: " + message);
    try {{ FLfile.write("file:///tmp/pr2-timeline-svg-error.log", message); }} catch (e) {{}}
    throw error;
}}
'''


def write_text(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xfl-dir", default=DEFAULT_XFL_DIR)
    parser.add_argument("--fla", default=DEFAULT_FLA)
    parser.add_argument("--svg-dir", default=DEFAULT_SVG_DIR)
    parser.add_argument("--out", default=DEFAULT_OUT)
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--svg-exporter", default=DEFAULT_ADOBE_SVG_EXPORTER)
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--skip-existing", action="store_true")
    parser.add_argument("--ranges", help="comma-separated half-open job ranges, e.g. 30:188,531:706")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])
    metadata = build_metadata(args.xfl_dir)
    try:
        plan = build_plan(metadata)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1
    jobs = output_jobs(plan, args.svg_dir)
    if args.ranges:
        ranges = [tuple(int(value) for value in item.split(":")) for item in args.ranges.split(",")]
        jobs = [job for index, job in enumerate(jobs) if any(start <= index < end for start, end in ranges)]
    jobs = jobs[args.offset :]
    if args.limit is not None:
        jobs = jobs[: args.limit]
    if args.skip_existing:
        jobs = [job for job in jobs if not (Path(args.svg_dir) / job["exportPath"]).exists()]
    write_text(args.manifest, json.dumps(plan, indent=2, sort_keys=True) + "\n")
    write_text(args.out, jsfl_source(jobs, file_uri(args.fla), file_uri(args.svg_exporter)))
    print(
        f"wrote {len(jobs)} SVG jobs from offset {args.offset} of {plan['exportCount']} covering "
        f"{plan['vectorLeafCount']} vector leaves ({plan['bitmapFillExportCount']} bitmap-fill jobs)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
