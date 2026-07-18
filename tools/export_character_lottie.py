#!/usr/bin/env python3
"""Seed editable standard-Lottie character motion from the archival XFL."""

from __future__ import annotations

import argparse

from character_lottie_motion import write_lottie
from generate_character_rig import ROOT, STATE_SOURCES, animation_record, root_matrices


EXPORT_STATES = {state[0] for state in STATE_SOURCES}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("states", nargs="*", choices=sorted(EXPORT_STATES))
    args = parser.parse_args()
    states = args.states or sorted(EXPORT_STATES)
    roots = root_matrices()
    records = {state[0]: animation_record(*state, roots, use_lottie=False) for state in STATE_SOURCES if state[0] in states}
    for name in states:
        path = ROOT / "art/intermediate/character-lottie" / f"{name}.lottie.json"
        write_lottie(path, records[name])
        print(f"Exported editable character motion: {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
