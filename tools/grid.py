#!/usr/bin/env python3
"""
grid.py — overlay a labeled coordinate grid on a PR2 stage screenshot.

Usage:
  python3 tools/grid.py <input.jpg> [output.jpg] [--spacing 25]

Input should be a screenshot taken with pr2driver.py shot (550x400 logical stage,
may be Retina 2x or already downscaled). Output defaults to input-grid.jpg.
Grid labels are in stage coordinates (origin = top-left of SWF canvas).
"""

import sys, os, struct, zlib

STAGE_W = 550
STAGE_H = 400

def parse_args():
    args = sys.argv[1:]
    spacing = 25
    input_path = None
    output_path = None
    i = 0
    while i < len(args):
        if args[i] == '--spacing' and i + 1 < len(args):
            spacing = int(args[i+1]); i += 2
        elif input_path is None:
            input_path = args[i]; i += 1
        elif output_path is None:
            output_path = args[i]; i += 1
        else:
            i += 1
    if input_path is None:
        print(__doc__); sys.exit(1)
    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = base + '-grid' + (ext or '.jpg')
    return input_path, output_path, spacing

def read_jpeg_size(path):
    with open(path, 'rb') as f:
        data = f.read()
    i = 0
    while i < len(data) - 1:
        if data[i] != 0xFF:
            i += 1; continue
        marker = data[i+1]
        if marker in (0xC0, 0xC1, 0xC2):
            h = struct.unpack('>H', data[i+4:i+6])[0]
            w = struct.unpack('>H', data[i+6:i+8])[0]
            return w, h
        elif marker in (0xD8, 0xD9, 0x01) or (0xD0 <= marker <= 0xD7):
            i += 2
        else:
            length = struct.unpack('>H', data[i+2:i+4])[0]
            i += 2 + length
    return None, None

def read_png_size(path):
    with open(path, 'rb') as f:
        f.read(8)  # PNG signature
        f.read(4)  # chunk length
        f.read(4)  # IHDR
        w = struct.unpack('>I', f.read(4))[0]
        h = struct.unpack('>I', f.read(4))[0]
    return w, h

def get_image_size(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in ('.jpg', '.jpeg'):
        return read_jpeg_size(path)
    elif ext == '.png':
        return read_png_size(path)
    return None, None

def draw_grid(input_path, output_path, spacing):
    try:
        from PIL import Image, ImageDraw, ImageFont
        use_pil = True
    except ImportError:
        use_pil = False

    if use_pil:
        img = Image.open(input_path).convert('RGB')
        iw, ih = img.size
        scale_x = iw / STAGE_W
        scale_y = ih / STAGE_H
        draw = ImageDraw.Draw(img)

        try:
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', max(8, int(9 * scale_x)))
            font_small = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', max(7, int(8 * scale_x)))
        except Exception:
            font = font_small = ImageFont.load_default()

        # vertical lines (x)
        x = 0
        while x <= STAGE_W:
            px = int(x * scale_x)
            color = (255, 0, 0) if x % 100 == 0 else (200, 200, 0)
            draw.line([(px, 0), (px, ih)], fill=color, width=1)
            if x % spacing == 0:
                draw.text((px + 2, 2), str(x), fill=color, font=font_small)
            x += spacing

        # horizontal lines (y)
        y = 0
        while y <= STAGE_H:
            py = int(y * scale_y)
            color = (255, 0, 0) if y % 100 == 0 else (200, 200, 0)
            draw.line([(0, py), (iw, py)], fill=color, width=1)
            if y % spacing == 0:
                draw.text((2, py + 2), str(y), fill=color, font=font_small)
            y += spacing

        img.save(output_path, quality=90)
        print(f"Grid saved: {output_path}  (image {iw}x{ih}, scale {scale_x:.2f}x)")

    else:
        # Fallback: use sips + shell to add a grid via AppleScript/Quartz
        # Just report coordinates without drawing — PIL not available
        iw, ih = get_image_size(input_path)
        if iw is None:
            print("Cannot read image size. Install Pillow: pip3 install pillow")
            sys.exit(1)
        scale_x = iw / STAGE_W
        scale_y = ih / STAGE_H
        print(f"Image: {iw}x{ih}  Stage scale: {scale_x:.2f}x {scale_y:.2f}y")
        print(f"Stage coords → image pixels:  x_img = x_stage * {scale_x:.2f},  y_img = y_stage * {scale_y:.2f}")
        print(f"Image pixels → stage coords:  x_stage = x_img / {scale_x:.2f},  y_stage = y_img / {scale_y:.2f}")
        print()
        print("Install Pillow to generate a visual grid:  pip3 install pillow")

if __name__ == '__main__':
    input_path, output_path, spacing = parse_args()
    draw_grid(input_path, output_path, spacing)