#!/usr/bin/env python3
"""
Generate a JSFL batch script to export non-character PR2 vector assets as SVGs.

Categories exported:
  backgrounds  - bg1-bg7 (single frame each)
  stamps       - decorative level objects (single frame each)
  effects      - in-game visual effect symbols (one SVG per reusable symbol)
  items        - ItemDisplay icon frames (one per label)
  intro        - baked leaf/composite art used by intro timelines

The generated JSFL should be run inside Adobe Animate the same way as the
character export JSFL. Outputs land directly in vector-art/svg/<category>/.

Run with Adobe Animate on macOS:
  "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-other-assets-svg.jsfl
"""

import argparse
import json
import os
import sys
from pathlib import Path


DEFAULT_FLA = os.path.join("flash", "platform-racing-2.fla")
DEFAULT_ADOBE_SVG_EXPORTER = (
    "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/Common/"
    "Configuration/Extensions/ExportSVG/jsfl/Export SVG.jsfl"
)
DEFAULT_SVG_DIR = os.path.join("vector-art", "svg")
DEFAULT_OUT = os.path.join("vector-art", "export-other-assets-svg.jsfl")


BACKGROUNDS = [
    {"slug": "bg1", "symbol": "UI/Pages/Levels/Backgrounds/bg1"},
    {"slug": "bg2", "symbol": "UI/Pages/Levels/Backgrounds/bg2"},
    {"slug": "bg3", "symbol": "UI/Pages/Levels/Backgrounds/bg3"},
    {"slug": "bg4", "symbol": "UI/Pages/Levels/Backgrounds/bg4"},
    {"slug": "bg5", "symbol": "UI/Pages/Levels/Backgrounds/bg5"},
    {"slug": "bg6", "symbol": "UI/Pages/Levels/Backgrounds/bg6"},
    {"slug": "bg7", "symbol": "UI/Pages/Levels/Backgrounds/bg7"},
]

STAMPS = [
    {"slug": "petrified_tree", "symbol": "UI/Pages/Levels/Stamps/PetrifiedTree"},
    {"slug": "rock1",          "symbol": "UI/Pages/Levels/Stamps/rock1"},
    {"slug": "rock2",          "symbol": "UI/Pages/Levels/Stamps/rock2"},
    {"slug": "spire1",         "symbol": "UI/Pages/Levels/Stamps/spire1"},
    {"slug": "spire2",         "symbol": "UI/Pages/Levels/Stamps/spire2"},
    {"slug": "tree1",          "symbol": "UI/Pages/Levels/Stamps/tree1"},
    {"slug": "tree2",          "symbol": "UI/Pages/Levels/Stamps/tree2"},
    {"slug": "tree3",          "symbol": "UI/Pages/Levels/Stamps/tree3"},
]

# Effect timelines are exported as reusable symbol artwork, not as baked frame
# sequences. Haxe/OpenFL owns timeline playback, labels, scripts, and nested
# composition; these SVGs are fallback/static leaf assets for the runtime.
EFFECTS = [
    {
        "slug":   "laser_shot",
        "symbol": "UI/Pages/Levels/In-Game/Effects/LaserShot",
    },
    {
        "slug":   "lightning_bolt",
        "symbol": "UI/Pages/Levels/In-Game/Effects/LightningBolt",
    },
    {
        "slug":   "slash",
        "symbol": "UI/Pages/Levels/In-Game/Effects/Slash",
    },
    {
        "slug":   "sting",
        "symbol": "UI/Pages/Levels/In-Game/Effects/Sting",
    },
    {
        "slug":   "teleport",
        "symbol": "UI/Pages/Levels/In-Game/Effects/Teleport",
    },
    {
        "slug":   "speed_burst",
        "symbol": "UI/Pages/Levels/In-Game/Effects/SpeedBurst/SpeedBurst",
    },
    {
        "slug":   "speed_burst_star",
        "symbol": "UI/Pages/Levels/In-Game/Effects/SpeedBurst/SpeedBurstStar",
    },
    {
        "slug":   "mine_piece",
        "symbol": "UI/Pages/Levels/In-Game/Effects/Mine/Symbol 472",
    },
    {
        "slug":   "mine_explosion",
        "symbol": "UI/Pages/Levels/In-Game/Effects/Mine/Symbol 976",
    },
    {
        "slug":   "mine_appear",
        "symbol": "UI/Pages/Levels/In-Game/Effects/Mine/Symbol 1020",
    },
]

# ItemDisplay: export one SVG per label frame so we have each item icon.
ITEM_DISPLAY_LABELS = [
    {"slug": "none",        "frame": 0},
    {"slug": "jet_pack",    "frame": 5},
    {"slug": "mine",        "frame": 10},
    {"slug": "speed_burst", "frame": 15},
    {"slug": "super_jump",  "frame": 20},
    {"slug": "teleport",    "frame": 25},
    {"slug": "lightning",   "frame": 30},
    {"slug": "laser",       "frame": 35},
    {"slug": "sword",       "frame": 40},
    {"slug": "ice_wave",    "frame": 45},
]
ITEM_DISPLAY_SYMBOL = "UI/Pages/Levels/In-Game/ItemDisplay"

KONGREGATE_INTRO_SYMBOLS = [
    {"slug": "symbol_27", "symbol": "MovieClips/Symbol 27"},
    {"slug": "symbol_30", "symbol": "MovieClips/Symbol 30"},
    {"slug": "symbol_32", "symbol": "MovieClips/Symbol 32"},
    {"slug": "symbol_34", "symbol": "MovieClips/Symbol 34"},
    {"slug": "symbol_36", "symbol": "MovieClips/Symbol 36"},
    {"slug": "symbol_38", "symbol": "MovieClips/Symbol 38"},
    {"slug": "symbol_40", "symbol": "MovieClips/Symbol 40"},
    {"slug": "symbol_41", "symbol": "MovieClips/Symbol 41"},
    {"slug": "symbol_44", "symbol": "MovieClips/Symbol 44"},
    {"slug": "symbol_47", "symbol": "MovieClips/Symbol 47"},
    {"slug": "symbol_49", "symbol": "MovieClips/Symbol 49"},
    {"slug": "symbol_52", "symbol": "MovieClips/Symbol 52"},
    {"slug": "graphic_28", "symbol": "Graphics/Symbol 28"},
    {"slug": "graphic_42", "symbol": "Graphics/Symbol 42"},
    {"slug": "graphic_43", "symbol": "Graphics/Symbol 43"},
]


def file_uri(path):
    return Path(path).resolve().as_uri()


def js_string(value):
    return json.dumps(value)


def build_jobs(svg_dir):
    root = Path(svg_dir).resolve()
    jobs = []

    for entry in BACKGROUNDS:
        export_path = f"backgrounds/{entry['slug']}.svg"
        jobs.append({
            "category":   "backgrounds",
            "slug":       entry["slug"],
            "symbolName": entry["symbol"],
            "frame":      0,
            "exportPath": export_path,
            "outputUri":  (root / export_path).as_uri(),
        })

    for entry in STAMPS:
        export_path = f"stamps/{entry['slug']}.svg"
        jobs.append({
            "category":   "stamps",
            "slug":       entry["slug"],
            "symbolName": entry["symbol"],
            "frame":      0,
            "exportPath": export_path,
            "outputUri":  (root / export_path).as_uri(),
        })

    for effect in EFFECTS:
        export_path = f"effects/{effect['slug']}.svg"
        jobs.append({
            "category":   "effects",
            "slug":       effect["slug"],
            "symbolName": effect["symbol"],
            "frame":      0,
            "exportPath": export_path,
            "outputUri":  (root / export_path).as_uri(),
        })

    for label in ITEM_DISPLAY_LABELS:
        export_path = f"items/display/{label['slug']}.svg"
        jobs.append({
            "category":   "items",
            "slug":       label["slug"],
            "symbolName": ITEM_DISPLAY_SYMBOL,
            "frame":      label["frame"],
            "exportPath": export_path,
            "outputUri":  (root / export_path).as_uri(),
        })

    for entry in KONGREGATE_INTRO_SYMBOLS:
        export_path = f"intro/kongregate/{entry['slug']}.svg"
        jobs.append({
            "category":   "intro",
            "group":      "kongregate",
            "slug":       entry["slug"],
            "symbolName": entry["symbol"],
            "frame":      0,
            "exportPath": export_path,
            "outputUri":  (root / export_path).as_uri(),
        })

    return jobs


def jsfl_source(jobs, fla_uri, svg_exporter_uri):
    return f"""// Generated by tools/generate_other_assets_jsfl.py. Do not edit by hand.
// Open this file with Adobe Animate to export non-character SVG assets.
// Output lands directly in vector-art/svg/.
// macOS direct run:
// "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-other-assets-svg.jsfl

var SOURCE_FLA_URI = {js_string(fla_uri)};
var ADOBE_SVG_EXPORTER_URI = {js_string(svg_exporter_uri)};
var JOBS = {json.dumps(jobs, indent=2, sort_keys=True)};

function log(message) {{
\tfl.trace("[PR2 SVG Export] " + message);
}}

function dirname(uri) {{
\treturn uri.replace(/\\/[^\\/]*$/, "");
}}

function mkdirs(uri) {{
\tvar parts = uri.split("/");
\tif (parts.length < 4) {{
\t\treturn;
\t}}
\tvar current = parts[0] + "//" + parts[2];
\tfor (var i = 3; i < parts.length; i++) {{
\t\tcurrent += "/" + parts[i];
\t\tif (!FLfile.exists(current)) {{
\t\t\tFLfile.createFolder(current);
\t\t}}
\t}}
}}

function selectFrame(timeline, frameIndex) {{
\ttry {{
\t\ttimeline.currentFrame = frameIndex;
\t}} catch (e) {{
\t}}
\ttry {{
\t\ttimeline.setSelectedFrames(frameIndex, frameIndex + 1, true);
\t}} catch (e) {{
\t}}
}}

function stageSymbol(doc, symbolName, frame) {{
\tdoc.library.addItemToDocument({{ x: 0, y: 0 }}, symbolName);
\tvar instance = doc.selection && doc.selection.length > 0 ? doc.selection[0] : null;
\tif (!instance) {{
\t\tthrow new Error("Could not stage library item: " + symbolName);
\t}}
\t// `addItemToDocument({{x:0,y:0}})` places many library items by their visual
\t// center. Resetting the instance matrix preserves the symbol registration
\t// point, which is what timeline matrices in the XFL reference.
\ttry {{
\t\tinstance.matrix = {{ a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0 }};
\t}} catch (e) {{
\t}}
\ttry {{
\t\tinstance.symbolType = "graphic";
\t}} catch (e) {{
\t}}
\ttry {{
\t\tinstance.firstFrame = frame;
\t}} catch (e) {{
\t}}
\ttry {{
\t\tinstance.loop = "single frame";
\t}} catch (e) {{
\t}}
}}

function exportCurrentView(outputUri) {{
\tmkdirs(dirname(outputUri));
\tfl.runScript(ADOBE_SVG_EXPORTER_URI, "exportSVG", "", outputUri, true, "", false, false, 0, 0);
}}

function exportJob(doc, job) {{
\tlog("[" + job.category + "] " + job.exportPath + " from " + job.symbolName + " frame " + job.frame);
\ttry {{
\t\tdoc.selectAll();
\t\tdoc.deleteSelection();
\t}} catch (e) {{
\t}}
\tstageSymbol(doc, job.symbolName, job.frame);
\texportCurrentView(job.outputUri);
\ttry {{
\t\tdoc.selectAll();
\t\tdoc.deleteSelection();
\t}} catch (e) {{
\t}}
}}

function run() {{
\tlog("opening " + SOURCE_FLA_URI);
\tvar doc = fl.openDocument(SOURCE_FLA_URI);
\tif (!doc) {{
\t\tthrow new Error("Could not open source FLA: " + SOURCE_FLA_URI);
\t}}
\tfor (var i = 0; i < JOBS.length; i++) {{
\t\texportJob(doc, JOBS[i]);
\t}}
\tlog("complete: " + JOBS.length + " SVG exports");
}}

run();
"""


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fla", default=DEFAULT_FLA)
    parser.add_argument("--svg-dir", default=DEFAULT_SVG_DIR)
    parser.add_argument("--out", default=DEFAULT_OUT)
    parser.add_argument("--svg-exporter", default=DEFAULT_ADOBE_SVG_EXPORTER)
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])
    jobs = build_jobs(args.svg_dir)
    source = jsfl_source(jobs, file_uri(args.fla), file_uri(args.svg_exporter))

    if args.out == "-":
        print(source, end="")
    else:
        os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
        with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(source)

    print(f"wrote {len(jobs)} export jobs to {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
