#!/usr/bin/env python3
"""
check_race_complete.py — assert the Flash "Race Complete!" popup is open.

Crops the static "-- Race Complete! --" title region out of a full PR2 stage
screenshot (550x400, captured by pr2driver.py shot) and compares it against
test/baselines/flash/race-complete-title.png. Exits 0 on match, 1 on mismatch.

Usage:
  python3 tools/check_race_complete.py <stage-screenshot.jpg> [--threshold N]

The title text is static (unlike the timer / EXP figures elsewhere in the popup),
so a tight mean-absolute-difference threshold is reliable.
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
DEFAULT_THRESHOLD = 12.0  # mean abs diff per channel (0-255)


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

    crop = shot.crop(TITLE_BOX)
    baseline = Image.open(BASELINE).convert("RGB")
    if crop.size != baseline.size:
        print(f"FAIL: crop size {crop.size} != baseline {baseline.size}")
        sys.exit(1)

    diff = ImageChops.difference(crop, baseline)
    mean = sum(ImageStat.Stat(diff).mean) / 3.0

    if mean <= threshold:
        print(f"PASS: Race Complete! popup detected (mean diff {mean:.2f} <= {threshold})")
        sys.exit(0)
    print(f"FAIL: Race Complete! popup NOT detected (mean diff {mean:.2f} > {threshold})")
    sys.exit(1)


if __name__ == "__main__":
    main()
