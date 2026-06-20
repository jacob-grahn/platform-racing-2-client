#!/usr/bin/env python3
"""crop_zoom.py <in.png> <out.png> x0 y0 x1 y1 scale — crop a region and nearest-neighbor upscale."""
import sys
from PIL import Image

inp, outp, x0, y0, x1, y1, scale = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]), int(sys.argv[7])
img = Image.open(inp).convert("RGBA")
# Source may be retina (2x). Detect by comparing width to 550.
sw = img.width / 550.0
box = (int(x0 * sw), int(y0 * sw), int(x1 * sw), int(y1 * sw))
crop = img.crop(box)
crop = crop.resize((crop.width * scale, crop.height * scale), Image.NEAREST)
crop.save(outp)
print(f"saved {outp} size={crop.size} srcscale={sw}")
