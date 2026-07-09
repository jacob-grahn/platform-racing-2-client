#!/usr/bin/env python3
"""
check_race_complete.py — assert the Flash "Race Complete!" popup is open.

Crops the static "-- Race Complete! --" title region out of a full PR2 stage
screenshot (550x400, captured by pr2driver.py shot) and compares it against
test/baselines/flash/race-complete-title.png. Exits 0 on match, 1 on mismatch.

Usage:
  python3 tools/check_race_complete.py <stage-screenshot.jpg> [--threshold N]

The title text is static (unlike the timer / EXP figures elsewhere in the popup),
so this deliberately ignores the rest of the popup.
"""

import sys
import os
from PIL import Image, ImageChops, ImageStat

# Title region in stage coords, matching how the baseline was cut.
TITLE_BOX = (160, 78, 392, 102)
BASELINE = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "test", "baselines", "flash", "race-complete-title.png",
)
DEFAULT_THRESHOLD = 30.0  # mean abs diff per channel (0-255)
SEARCH_RADIUS_X = 3
SEARCH_RADIUS_Y = 3


def main():
    args = sys.argv[1:]
    threshold = DEFAULT_THRESHOLD
    if "--threshold" in args:
        i = args.index("--threshold")
        threshold = float(args[i + 1])
        del args[i:i + 2]
    if len(args) != 1:
        print(__doc__)
        sys.exit(2)

    shot_path = args[0]
    shot = Image.open(shot_path).convert("RGB")
    if shot.size != (550, 400):
        # Screenshots are captured at logical 550x400; bail loudly if not.
        print(f"FAIL: unexpected screenshot size {shot.size} (expected 550x400)")
        sys.exit(1)

    baseline = Image.open(BASELINE).convert("RGB")
    crop = shot.crop(TITLE_BOX)
    if crop.size != baseline.size:
        print(f"FAIL: crop size {crop.size} != baseline {baseline.size}")
        sys.exit(1)

    best_mean = None
    best_offset = (0, 0)
    width, height = baseline.size
    for dy in range(-SEARCH_RADIUS_Y, SEARCH_RADIUS_Y + 1):
        for dx in range(-SEARCH_RADIUS_X, SEARCH_RADIUS_X + 1):
            shifted_box = (
                TITLE_BOX[0] + dx,
                TITLE_BOX[1] + dy,
                TITLE_BOX[0] + dx + width,
                TITLE_BOX[1] + dy + height,
            )
            shifted_crop = shot.crop(shifted_box)
            diff = ImageChops.difference(shifted_crop, baseline)
            mean = sum(ImageStat.Stat(diff).mean) / 3.0
            if best_mean is None or mean < best_mean:
                best_mean = mean
                best_offset = (dx, dy)

    if best_mean <= threshold:
        print(f"PASS: Race Complete! popup detected (mean diff {best_mean:.2f} <= {threshold}, offset {best_offset})")
        sys.exit(0)
    print(f"FAIL: Race Complete! popup NOT detected (mean diff {best_mean:.2f} > {threshold}, offset {best_offset})")
    sys.exit(1)


if __name__ == "__main__":
    main()
