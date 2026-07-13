#!/usr/bin/env python3
"""Verify the committed Kongregate intro exports and packed runtime atlas."""

import json
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/raster-manifest-intro.json"
ATLAS_JSON = ROOT / "assets/intro/atlases/kongregate@4x.json"
BITMAP_379 = ROOT / "flash/platform-racing-2-xfl/LIBRARY/Images/bitmap379.jpg"


def fail(message: str) -> None:
    raise SystemExit(f"Kongregate intro verification failed: {message}")


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    records = [item for item in manifest["pngs"] if item.get("group") == "kongregate"]
    atlas_meta = json.loads(ATLAS_JSON.read_text(encoding="utf-8"))
    frames = atlas_meta["frames"]

    if len(records) != 15 or len(frames) != 15:
        fail(f"expected 15 exported symbols, found {len(records)} PNGs and {len(frames)} atlas frames")

    atlas_path = ROOT / atlas_meta["image"]
    with Image.open(atlas_path) as atlas_source:
        atlas = atlas_source.convert("RGBA")
        for record in records:
            slug = record["slug"]
            frame = frames.get(slug)
            if frame is None:
                fail(f"missing atlas frame {slug}")

            source_path = ROOT / record["source"]
            png_path = ROOT / record["png"]
            if not source_path.is_file():
                fail(f"missing Adobe SVG export {source_path.relative_to(ROOT)}")

            with Image.open(png_path) as source_image:
                source = source_image.convert("RGBA")
            rect = frame["frame"]
            packed = atlas.crop((rect["x"], rect["y"], rect["x"] + rect["width"], rect["y"] + rect["height"]))
            if packed.size != source.size or ImageChops.difference(packed, source).getbbox() is not None:
                fail(f"atlas frame {slug} differs from {png_path.relative_to(ROOT)}")

    with Image.open(BITMAP_379) as bitmap:
        bitmap.verify()

    print(f"verified {len(records)} Kongregate symbols, runtime atlas, and bitmap379.jpg")


if __name__ == "__main__":
    main()
