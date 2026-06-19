#!/usr/bin/env python3
"""Recover bitmap library files from Animate XFL bin payloads."""

import argparse
import struct
import zlib
from pathlib import Path
import xml.etree.ElementTree as ET


DEFAULT_XFL = Path("flash/platform-racing-2-xfl")
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
RECOVERY_TARGETS = {
    "Images/bitmap97.jpg",
    "Images/bitmap371.png",
    "Images/bitmap379.jpg",
    "Images/bitmap386.png",
    "Images/bitmap1249.png",
}
# Animate's imported source JPEG can differ from its recompressed bin payload.
PRESERVE_IMPORTED = {"Images/bitmap379.jpg"}


def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def encode_argb_png(width, height, stride, pixels):
    if len(pixels) != stride * height or stride < width * 4:
        raise ValueError("invalid XFL bitmap dimensions")
    rows = bytearray()
    for y in range(height):
        rows.append(0)  # PNG's None row filter.
        row = pixels[y * stride : y * stride + width * 4]
        for offset in range(0, len(row), 4):
            alpha, red, green, blue = row[offset : offset + 4]
            rows.extend((red, green, blue, alpha))
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return (
        PNG_SIGNATURE
        + png_chunk(b"IHDR", header)
        + png_chunk(b"IDAT", zlib.compress(bytes(rows), 9))
        + png_chunk(b"IEND", b"")
    )


def decode_raw_bitmap(payload):
    if payload[:2] != b"\x03\x05":
        raise ValueError("unsupported XFL bitmap type (expected 32-bit bitmap)")
    stride, width = struct.unpack_from("<HH", payload, 2)
    height = struct.unpack_from("<I", payload, 6)[0]
    has_alpha, compressed = payload[24:26]
    if not has_alpha or not compressed:
        raise ValueError("unsupported XFL bitmap flags")

    position = 26
    compressed_data = bytearray()
    while True:
        if position + 2 > len(payload):
            raise ValueError("truncated XFL bitmap chunk header")
        size = struct.unpack_from("<H", payload, position)[0]
        position += 2
        if size == 0:
            break
        if position + size > len(payload):
            raise ValueError("truncated XFL bitmap chunk")
        compressed_data.extend(payload[position : position + size])
        position += size

    pixels = zlib.decompress(compressed_data)
    return encode_argb_png(width, height, stride, pixels)


def bitmap_items(xfl_dir):
    document = ET.parse(xfl_dir / "DOMDocument.xml").getroot()
    for item in document.iter():
        if item.tag.rsplit("}", 1)[-1] != "DOMBitmapItem":
            continue
        href = item.get("href")
        data_href = item.get("bitmapDataHRef")
        if href and data_href:
            yield href, data_href


def recovered_bytes(xfl_dir, data_href):
    payload = (xfl_dir / "bin" / data_href).read_bytes()
    if payload.startswith(b"\xff\xd8"):
        return payload
    return decode_raw_bitmap(payload)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xfl", type=Path, default=DEFAULT_XFL)
    parser.add_argument("--check", action="store_true", help="fail if recovered files are missing")
    args = parser.parse_args()

    changed = []
    found = set()
    for href, data_href in bitmap_items(args.xfl):
        if href not in RECOVERY_TARGETS:
            continue
        found.add(href)
        target = args.xfl / "LIBRARY" / href
        if href in PRESERVE_IMPORTED and target.exists():
            continue
        recovered = recovered_bytes(args.xfl, data_href)
        if target.exists() and target.read_bytes() == recovered:
            continue
        if args.check:
            changed.append(str(target))
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(recovered)
        changed.append(str(target))

    missing_items = sorted(RECOVERY_TARGETS - found)
    if missing_items:
        raise SystemExit("Bitmap items absent from DOMDocument.xml:\n" + "\n".join(missing_items))
    if args.check and changed:
        raise SystemExit("Missing or stale recovered XFL bitmaps:\n" + "\n".join(changed))
    if changed:
        print("Recovered " + ", ".join(changed))
    else:
        print("All XFL bitmap media files are present.")


if __name__ == "__main__":
    main()
