#!/usr/bin/env python3
"""
Rasterize committed PR2 SVG vector art to trimmed 4x PNGs and sprite sheets.

The SVGs exported from Animate keep the original 550x400 stage. This tool
renders each SVG at 4x, trims transparent pixels, records the trim rectangle,
and optionally packs related assets into atlases. Character atlases and level
backgrounds are written as lossless WebP so they can be loaded on demand
without carrying the full PNG payload up front.
"""

import argparse
import json
import math
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image


DEFAULT_INKSCAPE = "/Applications/Inkscape.app/Contents/MacOS/inkscape"
DEFAULT_SVG_ROOT = Path("vector-art/svg")
DEFAULT_PNG_ROOT = Path("vector-art/png")
DEFAULT_ATLAS_ROOT = Path("vector-art/atlases")
DEFAULT_SCALE = 4
DEFAULT_STAGE_WIDTH = 550
DEFAULT_STAGE_HEIGHT = 400
DEFAULT_MAX_ATLAS_SIZE = 4096
CHANNELS = ("static", "primary", "secondary")
# Animate exports Flash hairline strokes as 0.05 SVG units. Flash renders a
# hairline at one screen pixel regardless of that nominal width, but a literal
# SVG renderer makes it sub-pixel. A non-scaling stroke as wide as the raster
# scale preserves one pixel when the resulting bitmap is displayed at 1x.
FLASH_HAIRLINE_RE = re.compile(r'stroke-width="0\.05"')
# Empirical vertical-registration correction for character parts, in unscaled
# stage units (the same units as the runtime slot-local coordinate space, since
# parts are exported at scale 1). Against test/baselines/flash/08_standing.jpg,
# normalized to the feet line, the head and body atlas frames render ~7px too
# high while the feet line up. The root cause (some registration-point vs slot
# mismatch in the Animate export staging) is not yet understood, so this nudges
# sourceTrim.y downward to match Flash. Calibrated by sweeping the runtime
# slot-local Y offset until head/body matched the baseline, then carried here
# (sourceTrim.y += nudge * scale). Feet/hat = 0.
CHARACTER_Y_NUDGE = {"head": 55, "body": 55}
# Categories that produce individual PNGs with no atlas. Large timeline-driven
# effect symbols can exceed the default atlas page and are animated by metadata
# rather than by atlas frame sequencing.
NO_ATLAS_CATEGORIES = frozenset({"backgrounds", "blocks", "effects", "login", "menus"})


def parse_svg_path(svg_root, path):
    rel = path.relative_to(svg_root)
    parts = rel.parts

    if not parts:
        return None

    category = parts[0]

    if category == "character":
        if len(parts) < 4:
            return None
        kind = parts[1]
        part = parts[2]
        channel = path.stem
        if channel not in CHANNELS:
            return None
        part_id = int(part.split("_", 1)[0]) if part[:3].isdigit() else None
        if kind == "hat":
            atlas_group = "character/hats/atlas"
        elif part_id is not None:
            atlas_group = f"character/part-sets/{part_id:03d}/atlas"
        else:
            atlas_group = None
        return {
            "category": "character",
            "rel": rel,
            "kind": kind,
            "part": part,
            "channel": channel,
            "id": part_id,
            # Character art is packed into on-demand sheets: one atlas per
            # non-hat part id, and one shared hat atlas.
            "atlas_group": atlas_group,
        }

    if category == "backgrounds":
        # backgrounds/bg1.svg
        if len(parts) != 2:
            return None
        return {
            "category": "backgrounds",
            "rel": rel,
            "slug": path.stem,
            "atlas_group": None,  # no atlas for backgrounds
        }

    if category == "blocks":
        # blocks/<slug>.svg overlays the separately exported block bitmap tile.
        if len(parts) != 2:
            return None
        return {
            "category": "blocks",
            "rel": rel,
            "slug": path.stem,
            "atlas_group": None,
        }

    if category == "stamps":
        # stamps/tree1.svg
        if len(parts) != 2:
            return None
        return {
            "category": "stamps",
            "rel": rel,
            "slug": path.stem,
            "atlas_group": "stamps/stamps",
        }

    if category == "effects":
        # effects/<slug>.svg is the current timeline-driven export shape:
        # one reusable image per effect symbol. The older
        # effects/<slug>/frame_NN.svg form is still accepted so existing local
        # experiments can be rasterized intentionally.
        if len(parts) == 2:
            return {
                "category": "effects",
                "rel": rel,
                "slug": path.stem,
                "frame": None,
                "atlas_group": None,
            }
        if len(parts) != 3:
            return None
        slug = parts[1]
        return {
            "category": "effects",
            "rel": rel,
            "slug": slug,
            "frame": path.stem,  # e.g. "frame_00"
            "atlas_group": f"effects/{slug}",
        }

    if category == "items":
        # items/display/<slug>.svg
        if len(parts) != 3:
            return None
        group = parts[1]
        return {
            "category": "items",
            "rel": rel,
            "group": group,
            "slug": path.stem,
            "atlas_group": f"items/{group}",
        }

    if category == "intro":
        # intro/kongregate/<slug>.svg
        if len(parts) != 3:
            return None
        group = parts[1]
        return {
            "category": "intro",
            "rel": rel,
            "group": group,
            "slug": path.stem,
            "atlas_group": f"intro/{group}",
        }

    if category == "login":
        # login/<slug>.svg
        if len(parts) != 2:
            return None
        return {
            "category": "login",
            "rel": rel,
            "slug": path.stem,
            "atlas_group": None,
        }

    if category == "menus":
        # menus/<slug>.svg
        if len(parts) != 2:
            return None
        return {
            "category": "menus",
            "rel": rel,
            "slug": path.stem,
            "atlas_group": None,
        }

    return None


def discover_jobs(svg_root, kinds, channels, categories, limit):
    jobs = []
    for path in sorted(svg_root.rglob("*.svg")):
        info = parse_svg_path(svg_root, path)
        if info is None:
            continue
        cat = info["category"]
        if categories and cat not in categories:
            continue
        # character-specific filters
        if cat == "character":
            if kinds and info["kind"] not in kinds:
                continue
            if channels and info["channel"] not in channels:
                continue
        info["svg"] = path
        jobs.append(info)
    if limit is not None:
        jobs = jobs[:limit]
    return jobs


def query_drawing_bounds(inkscape, svg_path):
    result = subprocess.run(
        [inkscape, "--query-all", str(svg_path)],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    for line in result.stdout.splitlines():
        parts = line.split(",")
        if len(parts) != 5:
            continue
        try:
            x = float(parts[1])
            y = float(parts[2])
            width = float(parts[3])
            height = float(parts[4])
        except ValueError:
            continue
        return {"x": x, "y": y, "width": width, "height": height}
    return None


def prepare_svg(svg_path, temp_dir, index, scale):
    """Expand Animate's Flash hairline marker before bounds and rendering."""
    source = svg_path.read_text(encoding="utf-8")
    normalized = FLASH_HAIRLINE_RE.sub(f'stroke-width="{scale}" vector-effect="non-scaling-stroke"', source)
    if normalized == source:
        return svg_path
    prepared_path = temp_dir / f"{index}.svg"
    prepared_path.write_text(normalized, encoding="utf-8")
    return prepared_path


def run_inkscape(inkscape, svg_path, out_path, width, export_area=None):
    area_arg = "--export-area-drawing" if export_area is None else f"--export-area={export_area}"
    cmd = [
        inkscape,
        area_arg,
        f"--export-filename={out_path}",
        f"--export-width={width}",
        str(svg_path),
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def save_raster(image, out_path, category):
    if category in ("backgrounds", "character") and out_path.suffix == ".webp":
        image.save(out_path, lossless=True, method=6)
    else:
        image.save(out_path)


def save_untrimmed_image(source_path, out_path, bounds, scale, category):
    image = Image.open(source_path).convert("RGBA")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    save_raster(image, out_path, category)
    return {
        "x": math.floor(bounds["x"] * scale),
        "y": math.floor(bounds["y"] * scale),
        "width": image.width,
        "height": image.height,
        "empty": image.getchannel("A").getbbox() is None,
    }


def trim_image(source_path, out_path, bounds, scale, category):
    image = Image.open(source_path).convert("RGBA")
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        trimmed = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
        trim = {"x": 0, "y": 0, "width": 0, "height": 0, "empty": True}
    else:
        trimmed = image.crop(bbox)
        trim = {
            "x": math.floor(bounds["x"] * scale) + bbox[0],
            "y": math.floor(bounds["y"] * scale) + bbox[1],
            "width": bbox[2] - bbox[0],
            "height": bbox[3] - bbox[1],
            "empty": False,
        }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    save_raster(trimmed, out_path, category)
    return trim


def rasterize_with_batik(svg_path, out_path, temp_path, stage_width, stage_height, scale, centered, category, trim=True):
    """Fallback for systems where the configured Inkscape cannot run."""
    lime_path = subprocess.run(
        ["haxelib", "libpath", "lime"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout.strip()
    rasterizer = Path(lime_path) / "templates/bin/batik/batik-rasterizer.jar"
    if not rasterizer.exists():
        raise FileNotFoundError(f"Batik SVG rasterizer not found: {rasterizer}")

    x = -stage_width / 2 if centered else 0
    y = -stage_height / 2 if centered else 0
    source = svg_path.read_text(encoding="utf-8")
    source = re.sub(r'width="[^"]+"', f'width="{stage_width}px"', source, count=1)
    source = re.sub(r'height="[^"]+"', f'height="{stage_height}px"', source, count=1)
    source = re.sub(
        r'viewBox="[^"]+"',
        f'viewBox="{x:g} {y:g} {stage_width} {stage_height}"',
        source,
        count=1,
    )
    fallback_svg = temp_path.with_suffix(".svg")
    fallback_svg.write_text(source, encoding="utf-8")
    subprocess.run(
        [
            "java",
            "-Djava.security.manager=allow",
            "-Djava.awt.headless=true",
            "-jar",
            str(rasterizer),
            "-d",
            str(temp_path),
            "-w",
            str(stage_width * scale),
            "-h",
            str(stage_height * scale),
            str(fallback_svg),
        ],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    image = Image.open(temp_path).convert("RGBA")
    if not trim:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        save_raster(image, out_path, category)
        return {
            "x": x,
            "y": y,
            "width": stage_width,
            "height": stage_height,
        }, {
            "x": math.floor(x * scale),
            "y": math.floor(y * scale),
            "width": image.width,
            "height": image.height,
            "empty": image.getchannel("A").getbbox() is None,
        }
    bbox = image.getchannel("A").getbbox()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if bbox is None:
        save_raster(Image.new("RGBA", (1, 1), (0, 0, 0, 0)), out_path, category)
        return None, {"x": 0, "y": 0, "width": 0, "height": 0, "empty": True}

    save_raster(image.crop(bbox), out_path, category)
    bounds = {
        "x": x + bbox[0] / scale,
        "y": y + bbox[1] / scale,
        "width": (bbox[2] - bbox[0]) / scale,
        "height": (bbox[3] - bbox[1]) / scale,
    }
    trim = {
        "x": math.floor(x * scale) + bbox[0],
        "y": math.floor(y * scale) + bbox[1],
        "width": bbox[2] - bbox[0],
        "height": bbox[3] - bbox[1],
        "empty": False,
    }
    return bounds, trim


def png_path_for(png_root, job, scale):
    cat = job["category"]
    if cat == "character":
        return png_root / "character" / job["kind"] / job["part"] / f"{job['channel']}@{scale}x.png"
    if cat == "backgrounds":
        return png_root / "backgrounds" / f"{job['slug']}@{scale}x.webp"
    if cat == "blocks":
        return png_root / "blocks" / f"{job['slug']}@{scale}x.png"
    if cat == "stamps":
        return png_root / "stamps" / f"{job['slug']}@{scale}x.png"
    if cat == "effects":
        if job.get("frame") is None:
            return png_root / "effects" / f"{job['slug']}@{scale}x.png"
        return png_root / "effects" / job["slug"] / f"{job['frame']}@{scale}x.png"
    if cat == "items":
        return png_root / "items" / job["group"] / f"{job['slug']}@{scale}x.png"
    if cat == "intro":
        return png_root / "intro" / job["group"] / f"{job['slug']}@{scale}x.png"
    if cat == "login":
        return png_root / "login" / f"{job['slug']}@{scale}x.png"
    if cat == "menus":
        return png_root / "menus" / f"{job['slug']}@{scale}x.png"
    raise ValueError(f"Unknown category: {cat}")


def rasterize_jobs(jobs, args):
    records = []
    with tempfile.TemporaryDirectory(prefix="pr2-raster-") as temp_dir:
        temp_path = Path(temp_dir)
        for index, job in enumerate(jobs, start=1):
            out_path = png_path_for(args.png_root, job, args.scale)
            raw_path = temp_path / f"{index}.png"
            render_svg = prepare_svg(job["svg"], temp_path, index, args.scale)
            print(f"[{index}/{len(jobs)}] {job['svg']} -> {out_path}", file=sys.stderr)
            if job["category"] == "backgrounds":
                bounds = {"x": 0, "y": 0, "width": args.stage_width, "height": args.stage_height}
                try:
                    run_inkscape(
                        args.inkscape,
                        render_svg,
                        raw_path,
                        args.stage_width * args.scale,
                        f"0:0:{args.stage_width}:{args.stage_height}",
                    )
                except (FileNotFoundError, subprocess.CalledProcessError):
                    bounds, trim = rasterize_with_batik(
                        render_svg,
                        out_path,
                        raw_path,
                        args.stage_width,
                        args.stage_height,
                        args.scale,
                        False,
                        job["category"],
                        False,
                    )
                else:
                    trim = save_untrimmed_image(raw_path, out_path, bounds, args.scale, job["category"])
                used_fallback = True
            else:
                try:
                    bounds = query_drawing_bounds(args.inkscape, render_svg)
                except (FileNotFoundError, subprocess.CalledProcessError):
                    bounds, trim = rasterize_with_batik(
                        render_svg,
                        out_path,
                        raw_path,
                        args.stage_width,
                        args.stage_height,
                        args.scale,
                        job["category"] not in ("backgrounds", "login"),
                        job["category"],
                    )
                    used_fallback = True
                else:
                    used_fallback = False
            if used_fallback:
                pass
            elif bounds is None or bounds["width"] <= 0 or bounds["height"] <= 0:
                out_path.parent.mkdir(parents=True, exist_ok=True)
                save_raster(Image.new("RGBA", (1, 1), (0, 0, 0, 0)), out_path, job["category"])
                trim = {"x": 0, "y": 0, "width": 0, "height": 0, "empty": True}
            else:
                width = max(1, math.ceil(bounds["width"] * args.scale))
                run_inkscape(args.inkscape, render_svg, raw_path, width)
                trim = trim_image(raw_path, out_path, bounds, args.scale, job["category"])
            if job["category"] == "character" and not trim.get("empty"):
                nudge = CHARACTER_Y_NUDGE.get(job["kind"])
                if nudge:
                    trim["y"] += int(round(nudge * args.scale))
            record = {
                "source": str(job["svg"]),
                "png": str(out_path),
                "category": job["category"],
                "atlas_group": job.get("atlas_group"),
                "scale": args.scale,
                "stage": {"width": args.stage_width, "height": args.stage_height},
                "drawingBounds": bounds,
                "trim": trim,
            }
            # category-specific fields
            cat = job["category"]
            if cat == "character":
                record["kind"] = job["kind"]
                record["part"] = job["part"]
                record["id"] = job["id"]
                record["channel"] = job["channel"]
            elif cat in ("backgrounds", "blocks", "stamps"):
                record["slug"] = job["slug"]
            elif cat == "effects":
                record["slug"] = job["slug"]
                if job.get("frame") is not None:
                    record["frame"] = job["frame"]
            elif cat == "items":
                record["group"] = job["group"]
                record["slug"] = job["slug"]
            elif cat == "intro":
                record["group"] = job["group"]
                record["slug"] = job["slug"]
            elif cat == "login":
                record["slug"] = job["slug"]
            records.append(record)
    return records


def shelf_pack(entries, padding, max_size):
    x = padding
    y = padding
    row_height = 0
    width = padding
    placements = []

    for entry in sorted(entries, key=lambda item: (-item["height"], item["name"])):
        w = entry["width"]
        h = entry["height"]
        if x + w + padding > max_size and x > padding:
            x = padding
            y += row_height + padding
            row_height = 0
        if x + w + padding > max_size or y + h + padding > max_size:
            raise ValueError(f"Atlas is too small for {entry['name']} ({w}x{h})")
        placements.append({**entry, "x": x, "y": y})
        x += w + padding
        row_height = max(row_height, h)
        width = max(width, x)

    height = y + row_height + padding
    return placements, max(1, width), max(1, height)


def pack_pages(entries, padding, max_size):
    sorted_entries = sorted(entries, key=lambda item: (-item["height"], item["name"]))
    pages = []
    page = []

    for entry in sorted_entries:
        try:
            shelf_pack([entry], padding, max_size)
        except ValueError as error:
            raise ValueError(f"Atlas page is too small for {entry['name']} ({entry['width']}x{entry['height']})") from error

        candidate = page + [entry]
        try:
            shelf_pack(candidate, padding, max_size)
            page = candidate
        except ValueError:
            pages.append(shelf_pack(page, padding, max_size))
            page = [entry]

    if page:
        pages.append(shelf_pack(page, padding, max_size))
    return pages


def entry_sort_key(record):
    """Stable sort key for atlas packing: character parts by id, others by slug."""
    if record.get("category") == "character":
        return (record.get("id") or 0, record.get("kind", ""), record.get("channel", ""), record.get("part", ""))
    return (0, record.get("frame") or record.get("slug", ""), "")


def entry_name(record):
    """Human-readable name for an atlas frame entry."""
    cat = record.get("category")
    if cat == "character":
        if record["kind"] == "hat":
            return f"{record['part']}/{record['channel']}"
        return f"{record['kind']}/{record['channel']}"
    if cat in ("backgrounds", "blocks", "stamps"):
        return record["slug"]
    if cat == "effects":
        return record.get("frame") or record["slug"]
    if cat == "items":
        return record["slug"]
    if cat == "intro":
        return record["slug"]
    if cat == "login":
        return record["slug"]
    return record.get("slug", "unknown")


def build_atlases(records, atlas_root, padding, max_size):
    # Skip records with no atlas_group (e.g. backgrounds).
    groups = {}
    for record in records:
        key = record.get("atlas_group")
        if key is None:
            continue
        groups.setdefault(key, []).append(record)

    atlas_records = []
    for atlas_group, group in sorted(groups.items()):
        entries = []
        for record in sorted(group, key=entry_sort_key):
            image = Image.open(record["png"]).convert("RGBA")
            entries.append(
                {
                    "name": entry_name(record),
                    "png": record["png"],
                    "width": image.width,
                    "height": image.height,
                    "record": record,
                }
            )
        pages = pack_pages(entries, padding, max_size)
        # The atlas_group is a slash-separated path like
        # "character/part-sets/001/atlas" or "effects/laser_shot". We put the
        # file in the parent directory and use the last component as the stem.
        group_path = Path(atlas_group)
        out_dir = atlas_root / group_path.parent
        file_stem = group_path.name
        out_dir.mkdir(parents=True, exist_ok=True)
        scale = group[0]["scale"]
        for page_index, (placements, width, height) in enumerate(pages, start=1):
            atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
            frames = {}
            for placement in placements:
                image = Image.open(placement["png"]).convert("RGBA")
                atlas.alpha_composite(image, (placement["x"], placement["y"]))
                record = placement["record"]
                frame_entry = {
                    "png": record["png"],
                    "frame": {
                        "x": placement["x"],
                        "y": placement["y"],
                        "width": placement["width"],
                        "height": placement["height"],
                    },
                    "sourceTrim": record["trim"],
                    "scale": record["scale"],
                }
                if record.get("id") is not None:
                    frame_entry["id"] = record["id"]
                if record.get("category") == "character":
                    frame_entry["kind"] = record["kind"]
                    frame_entry["part"] = record["part"]
                    frame_entry["channel"] = record["channel"]
                frames[placement["name"]] = frame_entry

            page_suffix = "" if len(pages) == 1 else f"-p{page_index:02d}"
            is_character_atlas = group[0].get("category") == "character"
            image_ext = "webp" if is_character_atlas else "png"
            image_path = out_dir / f"{file_stem}@{scale}x{page_suffix}.{image_ext}"
            json_path = out_dir / f"{file_stem}@{scale}x{page_suffix}.json"
            if is_character_atlas:
                atlas.save(image_path, lossless=True, method=6)
            else:
                atlas.save(image_path)

            # Build atlas metadata, preserving character-specific fields where present.
            sample = group[0]
            atlas_meta = {
                "atlasGroup": atlas_group,
                "category": sample.get("category"),
                "image": str(image_path),
                "page": page_index,
                "pages": len(pages),
                "size": {"width": width, "height": height},
                "frames": frames,
            }
            if sample.get("category") == "character":
                atlas_meta["characterAtlas"] = "hats" if sample.get("kind") == "hat" else "part-set"
                if sample.get("kind") != "hat":
                    atlas_meta["partSetId"] = sample.get("id")

            with open(json_path, "w", encoding="utf-8", newline="\n") as handle:
                json.dump(atlas_meta, handle, indent=2, sort_keys=True)
                handle.write("\n")
            atlas_records.append(
                {
                    "image": str(image_path),
                    "json": str(json_path),
                    "frames": len(frames),
                    "atlasGroup": atlas_group,
                    "category": sample.get("category"),
                    "page": page_index,
                    "pages": len(pages),
                }
            )
    return atlas_records


def write_manifest(path, records, atlas_records):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(
            {
                "schema": "pr2-rasterized-vector-art-v1",
                "pngs": records,
                "atlases": atlas_records,
            },
            handle,
            indent=2,
            sort_keys=True,
        )
        handle.write("\n")


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--svg-root", type=Path, default=DEFAULT_SVG_ROOT)
    parser.add_argument("--png-root", type=Path, default=DEFAULT_PNG_ROOT)
    parser.add_argument("--atlas-root", type=Path, default=DEFAULT_ATLAS_ROOT)
    parser.add_argument("--inkscape", default=DEFAULT_INKSCAPE)
    parser.add_argument("--scale", type=int, default=DEFAULT_SCALE)
    parser.add_argument("--stage-width", type=int, default=DEFAULT_STAGE_WIDTH)
    parser.add_argument("--stage-height", type=int, default=DEFAULT_STAGE_HEIGHT)
    parser.add_argument("--kind", action="append", choices=("hat", "head", "body", "feet"))
    parser.add_argument("--channel", action="append", choices=CHANNELS)
    parser.add_argument(
        "--category",
        action="append",
        choices=("character", "backgrounds", "blocks", "stamps", "effects", "items", "intro", "login", "menus"),
        help="repeatable category filter; default: all categories",
    )
    parser.add_argument("--limit", type=int)
    parser.add_argument("--sheets", action="store_true", help="pack converted PNGs into per-kind/per-channel atlases")
    parser.add_argument("--padding", type=int, default=2)
    parser.add_argument("--max-atlas-size", type=int, default=DEFAULT_MAX_ATLAS_SIZE)
    parser.add_argument("--manifest", type=Path, default=Path("vector-art/raster-manifest.json"))
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])
    jobs = discover_jobs(args.svg_root, args.kind, args.channel, args.category, args.limit)
    if not jobs:
        print("No SVG jobs matched.", file=sys.stderr)
        return 1
    records = rasterize_jobs(jobs, args)
    atlas_records = build_atlases(records, args.atlas_root, args.padding, args.max_atlas_size) if args.sheets else []
    write_manifest(args.manifest, records, atlas_records)
    print(f"wrote {len(records)} rasters and {len(atlas_records)} atlases", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
