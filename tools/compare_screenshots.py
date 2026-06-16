#!/usr/bin/env python3
"""
compare_screenshots.py - compare two PR2 stage screenshots.

Examples:
  python3 tools/compare_screenshots.py expected.png actual.png --diff diff.png
  python3 tools/compare_screenshots.py flash.jpg openfl.png --ignore 0,0,550,24 --threshold-rms 12
"""

import argparse
import json
import os
import sys
from dataclasses import dataclass
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageStat


@dataclass(frozen=True)
class Rect:
    x: int
    y: int
    width: int
    height: int

    @staticmethod
    def parse(value: str) -> "Rect":
        parts = value.split(",")
        if len(parts) != 4:
            raise argparse.ArgumentTypeError("expected x,y,width,height")
        try:
            x, y, width, height = [int(part) for part in parts]
        except ValueError as error:
            raise argparse.ArgumentTypeError("rectangle values must be integers") from error
        if width < 0 or height < 0:
            raise argparse.ArgumentTypeError("rectangle width and height must be non-negative")
        return Rect(x, y, width, height)

    def bounds(self) -> tuple[int, int, int, int]:
        return (self.x, self.y, self.x + self.width, self.y + self.height)


def load_rgb(path: str) -> Image.Image:
    try:
        return Image.open(path).convert("RGB")
    except FileNotFoundError:
        raise SystemExit(f"Missing screenshot: {path}")
    except Exception as error:
        raise SystemExit(f"Could not read screenshot {path}: {error}")


def normalize_sizes(expected: Image.Image, actual: Image.Image, resize_actual: bool) -> tuple[Image.Image, Image.Image]:
    if expected.size == actual.size:
        return expected, actual
    if not resize_actual:
        raise SystemExit(f"Screenshot sizes differ: expected={expected.size[0]}x{expected.size[1]} actual={actual.size[0]}x{actual.size[1]}")
    return expected, actual.resize(expected.size, Image.Resampling.LANCZOS)


def apply_ignored_regions(expected: Image.Image, actual: Image.Image, ignored: Iterable[Rect]) -> None:
    for rect in ignored:
        expected_region = expected.crop(rect.bounds())
        actual.paste(expected_region, rect.bounds())


def build_diff(diff: Image.Image, amplify: int, ignored: Iterable[Rect]) -> Image.Image:
    visual = diff.point(lambda value: min(255, value * amplify))
    if ignored:
        draw = ImageDraw.Draw(visual)
        for rect in ignored:
            draw.rectangle(rect.bounds(), outline=(0, 128, 255), width=1)
    return visual


def compare(expected_path: str, actual_path: str, args: argparse.Namespace) -> dict:
    expected = load_rgb(expected_path)
    actual = load_rgb(actual_path)
    expected, actual = normalize_sizes(expected, actual, args.resize_actual)

    ignored = args.ignore or []
    apply_ignored_regions(expected, actual, ignored)

    diff = ImageChops.difference(expected, actual)
    stat = ImageStat.Stat(diff)
    histogram = diff.convert("L").histogram()
    total_pixels = expected.size[0] * expected.size[1]
    matching_pixels = histogram[0]
    differing_pixels = total_pixels - matching_pixels
    differing_percent = differing_pixels * 100.0 / total_pixels
    mean_abs_delta = sum(stat.mean) / len(stat.mean)
    rms_delta = sum(stat.rms) / len(stat.rms)
    max_delta = max(channel[1] for channel in diff.getextrema())

    if args.diff:
        os.makedirs(os.path.dirname(os.path.abspath(args.diff)), exist_ok=True)
        build_diff(diff, args.amplify, ignored).save(args.diff)

    metrics = {
        "expected": expected_path,
        "actual": actual_path,
        "width": expected.size[0],
        "height": expected.size[1],
        "ignoredRegions": [rect.__dict__ for rect in ignored],
        "differingPixels": differing_pixels,
        "differingPercent": differing_percent,
        "meanAbsDelta": mean_abs_delta,
        "rmsDelta": rms_delta,
        "maxDelta": max_delta,
        "thresholds": {
            "maxDifferingPercent": args.threshold_percent,
            "maxRmsDelta": args.threshold_rms,
        },
    }

    if args.metrics:
        os.makedirs(os.path.dirname(os.path.abspath(args.metrics)), exist_ok=True)
        with open(args.metrics, "w", encoding="utf-8") as file:
            json.dump(metrics, file, indent=2, sort_keys=True)
            file.write("\n")

    return metrics


def print_summary(metrics: dict) -> None:
    print(
        "Compared {actual} against {expected}: "
        "{width}x{height}, differingPixels={differingPixels} "
        "({differingPercent:.3f}%), meanAbsDelta={meanAbsDelta:.3f}, "
        "rmsDelta={rmsDelta:.3f}, maxDelta={maxDelta}".format(**metrics),
        flush=True,
    )


def validate_thresholds(metrics: dict) -> list[str]:
    failures = []
    thresholds = metrics["thresholds"]
    if metrics["differingPercent"] > thresholds["maxDifferingPercent"]:
        failures.append(
            f"differingPercent {metrics['differingPercent']:.3f}% > {thresholds['maxDifferingPercent']:.3f}%"
        )
    if metrics["rmsDelta"] > thresholds["maxRmsDelta"]:
        failures.append(f"rmsDelta {metrics['rmsDelta']:.3f} > {thresholds['maxRmsDelta']:.3f}")
    return failures


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("expected")
    parser.add_argument("actual")
    parser.add_argument("--diff", help="write an amplified visual diff PNG")
    parser.add_argument("--metrics", help="write JSON comparison metrics")
    parser.add_argument("--ignore", action="append", type=Rect.parse, help="ignore rectangle x,y,width,height; repeatable")
    parser.add_argument("--resize-actual", action="store_true", help="resize actual image to expected dimensions before comparing")
    parser.add_argument("--amplify", type=int, default=4, help="diff image amplification factor")
    parser.add_argument("--threshold-percent", type=float, default=0.0, help="maximum allowed differing pixel percentage")
    parser.add_argument("--threshold-rms", type=float, default=0.0, help="maximum allowed RGB RMS delta")
    args = parser.parse_args()

    if args.amplify < 1:
        raise SystemExit("--amplify must be at least 1")

    metrics = compare(args.expected, args.actual, args)
    print_summary(metrics)
    failures = validate_thresholds(metrics)
    if failures:
        print("Screenshot comparison failed: " + "; ".join(failures), file=sys.stderr)
        raise SystemExit(1)
    print("Screenshot comparison passed.")


if __name__ == "__main__":
    main()
