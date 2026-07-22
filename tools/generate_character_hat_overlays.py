#!/usr/bin/env python3
"""Generate static hat bases and animated overlay SVG frames from the XFL."""

from __future__ import annotations

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path

from compose_static_xfl_symbol_svg import (
    Composer,
    DEFAULT_LEAF_ROOT,
    DEFAULT_MANIFEST,
    DEFAULT_XFL_ROOT,
    SVG_NS,
    load_leaf_jobs,
    load_symbols,
    svg_bytes,
)


ROOT = Path(__file__).resolve().parents[1]

HATS = (
    {
        "directory": "004_prop",
        "containerFrame": 3,
        "overlaySymbol": "Parts/Hats/Propeller/Symbol 692",
        "overlayFrames": 4,
        "overlayMatrix": (1, 0, 0, 1, -84.15, -116.65),
    },
    {
        "directory": "013_jigg",
        "containerFrame": 12,
        "overlaySymbol": "Parts/Hats/Jigg/bubbleSpin",
        "overlayFrames": 9,
        "overlayMatrix": (1, 0, 0, 1, 14.1, -42.75),
    },
)


def matrix_text(values):
    return "matrix(" + " ".join(str(value) for value in values) + ")"


def generated_assets(xfl_root, manifest, leaf_root):
    symbols = load_symbols(xfl_root)
    jobs = load_leaf_jobs(manifest)
    assets = {}
    for hat in HATS:
        directory = ROOT / "art" / "svg" / "character" / "hat" / hat["directory"]
        base_composer = Composer(
            symbols,
            jobs,
            leaf_root,
            xfl_root,
            excluded_instance_names=("colorMC", "colorMC2"),
            excluded_layers_by_symbol={"Parts/Hats/hatsMC": ("Layer 3",)},
        )
        base = base_composer.compose_symbol("Parts/Hats/hatsMC", hat["containerFrame"])
        assets[directory / "static_base.svg"] = svg_bytes(base, "Parts/Hats/hatsMC")

        for frame in range(hat["overlayFrames"]):
            overlay_composer = Composer(symbols, jobs, leaf_root, xfl_root)
            content = overlay_composer.compose_symbol(hat["overlaySymbol"], frame)
            wrapper = ET.Element(
                f"{{{SVG_NS}}}g",
                {"transform": matrix_text(hat["overlayMatrix"])},
            )
            wrapper.append(content)
            path = directory / "overlay_frames" / f"frame_{frame + 1:03d}.svg"
            assets[path] = svg_bytes(wrapper, hat["overlaySymbol"])
    return assets


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xfl-root", default=DEFAULT_XFL_ROOT)
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--leaf-root", default=DEFAULT_LEAF_ROOT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    assets = generated_assets(args.xfl_root, args.manifest, args.leaf_root)
    stale = []
    for path, content in assets.items():
        if args.check:
            if not path.is_file() or path.read_bytes() != content:
                stale.append(str(path.relative_to(ROOT)))
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
    if stale:
        raise SystemExit("Animated hat SVG assets are stale: " + ", ".join(stale))
    print(f"Generated {len(assets)} animated hat SVG assets")


if __name__ == "__main__":
    main()
