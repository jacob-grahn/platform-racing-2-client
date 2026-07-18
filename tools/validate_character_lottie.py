#!/usr/bin/env python3
"""Validate editable character Lottie files and optionally compare archival poses."""

from __future__ import annotations

import argparse

from character_lottie_motion import load_lottie_motion
from generate_character_rig import ROOT, STATE_SOURCES, animation_record, root_matrices


STATES = tuple(state[0] for state in STATE_SOURCES)
TOLERANCE = 1e-9


def difference(left: dict[str, float], right: dict[str, float]) -> float:
    return max(abs(left[key] - right[key]) for key in ("a", "b", "c", "d", "tx", "ty", "alpha"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xfl-parity", action="store_true", help="compare every compiled pose with the archival XFL")
    args = parser.parse_args()
    roots = root_matrices()
    maximum = 0.0
    frame_total = 0
    for name in STATES:
        path = ROOT / "art/intermediate/character-lottie" / f"{name}.lottie.json"
        motion = load_lottie_motion(path)
        frame_total += motion["frameCount"]
        if not args.xfl_parity:
            continue
        state = next(state for state in STATE_SOURCES if state[0] == name)
        archival = animation_record(*state, roots, use_lottie=False)
        maximum = max(maximum, difference(motion["root"], archival["root"]))
        if motion["name"] != archival["name"]:
            raise SystemExit(f"{name} Lottie state metadata differs from the archival animation")
        if motion["endBehavior"] != archival["endBehavior"] or motion["endSignal"] != archival["endSignal"]:
            raise SystemExit(f"{name} Lottie completion metadata differs from the archival animation")
        if motion["frameRate"] != archival["frameRate"] or motion["frameCount"] != archival["frameCount"]:
            raise SystemExit(f"{name} Lottie timing differs from the archival animation")
        archival_definitions = [
            {key: slot[key] for key in ("name", "parent", "partKind", "asset", "drawOrder")}
            for slot in archival["slots"]
        ]
        if motion["slotDefinitions"] != archival_definitions:
            raise SystemExit(f"{name} Lottie slot metadata differs from the archival animation")
        for slot in archival["slots"]:
            compiled = motion["slots"][slot["name"]]
            for frame, expected in zip(compiled, slot["frames"]):
                maximum = max(maximum, difference(frame, expected))
    if args.xfl_parity and maximum > TOLERANCE:
        raise SystemExit(f"character Lottie XFL parity exceeded {TOLERANCE}: {maximum}")
    suffix = f", maximum XFL matrix delta {maximum:.3g}" if args.xfl_parity else ""
    print(f"Character Lottie passed: {len(STATES)} states/{frame_total} frames{suffix}")


if __name__ == "__main__":
    main()
