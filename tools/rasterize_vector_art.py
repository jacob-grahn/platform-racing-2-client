#!/usr/bin/env python3
"""
Rasterize committed PR2 SVG vector art to trimmed 4x PNGs and sprite sheets.

The SVGs exported from Animate keep the original 550x400 stage. This tool
renders each SVG at 4x, trims transparent pixels, records the trim rectangle,
and optionally packs related character assets into PNG atlases.
"""

import argparse
import json
import math
import os
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
CHANNELS = ("static", "primary", "secondary", "composite")
# Categories that produce individual PNGs with no atlas. Large timeline-driven
# effect symbols can exceed the default atlas page and are animated by metadata
# rather than by atlas frame sequencing.
NO_ATLAS_CATEGORIES = frozenset({"backgrounds", "effects"})


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
        return {
            "category": "character",
            "rel": rel,
            "kind": kind,
            "part": part,
            "channel": channel,
            "id": int(part.split("_", 1)[0]) if part[:3].isdigit() else None,
            # atlas group key: one atlas per (kind, channel)
            "atlas_group": f"character/{kind}/{channel}",
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


def run_inkscape(inkscape, svg_path, out_path, width):
    cmd = [
        inkscape,
        "--export-area-drawing",
        f"--export-filename={out_path}",
        f"--export-width={width}",
        str(svg_path),
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def trim_image(source_path, out_path, bounds, scale):
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
    trimmed.save(out_path)
    return trim


def png_path_for(png_root, job, scale):
    cat = job["category"]
    if cat == "character":
        return png_root / "character" / job["kind"] / job["part"] / f"{job['channel']}@{scale}x.png"
    if cat == "backgrounds":
        return png_root / "backgrounds" / f"{job['slug']}@{scale}x.png"
    if cat == "stamps":
        return png_root / "stamps" / f"{job['slug']}@{scale}x.png"
    if cat == "effects":
        if job.get("frame") is None:
            return png_root / "effects" / f"{job['slug']}@{scale}x.png"
        return png_root / "effects" / job["slug"] / f"{job['frame']}@{scale}x.png"
    if cat == "items":
        return png_root / "items" / job["group"] / f"{job['slug']}@{scale}x.png"
    raise ValueError(f"Unknown category: {cat}")


def rasterize_jobs(jobs, args):
    records = []
    with tempfile.TemporaryDirectory(prefix="pr2-raster-") as temp_dir:
        temp_path = Path(temp_dir)
        for index, job in enumerate(jobs, start=1):
            out_path = png_path_for(args.png_root, job, args.scale)
            raw_path = temp_path / f"{index}.png"
            print(f"[{index}/{len(jobs)}] {job['svg']} -> {out_path}", file=sys.stderr)
            bounds = query_drawing_bounds(args.inkscape, job["svg"])
            if bounds is None or bounds["width"] <= 0 or bounds["height"] <= 0:
                out_path.parent.mkdir(parents=True, exist_ok=True)
                Image.new("RGBA", (1, 1), (0, 0, 0, 0)).save(out_path)
                trim = {"x": 0, "y": 0, "width": 0, "height": 0, "empty": True}
            else:
                width = max(1, math.ceil(bounds["width"] * args.scale))
                run_inkscape(args.inkscape, job["svg"], raw_path, width)
                trim = trim_image(raw_path, out_path, bounds, args.scale)
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
            elif cat in ("backgrounds", "stamps"):
                record["slug"] = job["slug"]
            elif cat == "effects":
                record["slug"] = job["slug"]
                if job.get("frame") is not None:
                    record["frame"] = job["frame"]
            elif cat == "items":
                record["group"] = job["group"]
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
        return (record.get("id") or 0, record.get("part", ""), record.get("channel", ""))
    return (0, record.get("frame") or record.get("slug", ""), "")


def entry_name(record):
    """Human-readable name for an atlas frame entry."""
    cat = record.get("category")
    if cat == "character":
        return record["part"]
    if cat in ("backgrounds", "stamps"):
        return record["slug"]
    if cat == "effects":
        return record.get("frame") or record["slug"]
    if cat == "items":
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
        # The atlas_group is a slash-separated path like "character/body/composite"
        # or "effects/laser_shot".  We put the file in the parent directory and use
        # the last component as the filename stem, which preserves the legacy
        # character atlas naming (e.g. atlases/character/body/composite@4x.png).
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
                frames[placement["name"]] = frame_entry

            page_suffix = "" if len(pages) == 1 else f"-p{page_index:02d}"
            image_path = out_dir / f"{file_stem}@{scale}x{page_suffix}.png"
            json_path = out_dir / f"{file_stem}@{scale}x{page_suffix}.json"
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
                atlas_meta["kind"] = sample["kind"]
                atlas_meta["channel"] = sample["channel"]

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
        choices=("character", "backgrounds", "stamps", "effects", "items"),
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
    print(f"wrote {len(records)} PNGs and {len(atlas_records)} atlases", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
