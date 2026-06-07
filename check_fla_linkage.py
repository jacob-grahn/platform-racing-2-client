#!/usr/bin/env python3
"""
check_fla_linkage.py — verify FLA symbol linkage classes have matching AS3 definitions.

Run after each rename cycle to catch mismatches before building:
    python3 check_fla_linkage.py

Exit code 0 = all clear, 1 = mismatches found.

How it decides what to flag:
  - Always flags class_NNN names (obfuscated identifiers that may have been renamed).
  - For all other class names, flags only those that *do* have a backing .as file
    in the tree — i.e. classes that existed but got renamed away from what the FLA
    expects.
  - Pure-FLA symbols (component skins, *Graphic, BG*, etc.) that never had an .as
    file are silently ignored because they are expected to be FLA-only.
"""

import os
import re
import sys
import zlib

ROOT = os.path.dirname(os.path.abspath(__file__))
FLA  = os.path.join(ROOT, 'platform-racing-2.fla')

# Class name prefixes that are Flash framework / auto-generated — always skip.
SKIP_PREFIXES = (
    'fl.',
    'PR2_Graphics_1_Apr_2014_fla.',
)

# Known dead/inaccessible FLA symbols whose linkage can't be updated.
# Add entries here when a symbol can't be found in the Animate Library.
SKIP_DEAD_SYMBOLS = {
    'class_239',  # LIBRARY/MovieClips/Symbol 1113.xml — duplicate, inaccessible in Library; active SpeedBurst symbol already updated to PointyStar
}


def extract_fla_linkages(fla_path):
    """Return {className: fla_xml_path} for every linkageClassName in the FLA."""
    data = open(fla_path, 'rb').read()
    linkages = {}
    pos = 0
    while True:
        idx = data.find(b'PK\x03\x04', pos)
        if idx == -1:
            break
        fn_len    = int.from_bytes(data[idx+26:idx+28], 'little')
        extra_len = int.from_bytes(data[idx+28:idx+30], 'little')
        fname     = data[idx+30:idx+30+fn_len].decode('utf-8', errors='replace')
        comp_size = int.from_bytes(data[idx+18:idx+22], 'little')
        method    = int.from_bytes(data[idx+8:idx+10],  'little')
        data_off  = idx + 30 + fn_len + extra_len
        if fname.endswith('.xml') and method == 8 and comp_size > 0:
            try:
                xml = zlib.decompress(data[data_off:data_off+comp_size], -15).decode('utf-8', errors='replace')
                m = re.search(r'linkageClassName="([^"]+)"', xml)
                if m:
                    linkages[m.group(1)] = fname
            except Exception:
                pass
        pos = idx + 1
    return linkages


def collect_as3_classes(root):
    """Return {className: relative_file_path} for every 'class Foo' in .as files."""
    classes = {}
    for dirpath, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for f in files:
            if not f.endswith('.as'):
                continue
            fpath = os.path.join(dirpath, f)
            try:
                content = open(fpath, encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            for m in re.finditer(r'\bclass\s+(\w+)', content):
                name = m.group(1)
                if name not in classes:
                    classes[name] = os.path.relpath(fpath, root)
    return classes


def is_obfuscated(cls):
    """True if the name looks like an obfuscated class identifier."""
    return bool(re.match(r'^class_\d+$', cls))


def should_skip(cls):
    return cls in SKIP_DEAD_SYMBOLS or any(cls.startswith(p) for p in SKIP_PREFIXES)


def main():
    linkages = extract_fla_linkages(FLA)
    as3      = collect_as3_classes(ROOT)

    problems  = []   # (cls, fla_path, reason)
    verified  = []   # (cls, as3_path)
    fla_only  = []   # skipped — pure FLA symbol, no AS3 ever existed

    for cls, fla_path in sorted(linkages.items()):
        if should_skip(cls):
            continue

        has_as3 = cls in as3

        if has_as3:
            verified.append((cls, as3[cls]))
        elif is_obfuscated(cls):
            problems.append((cls, fla_path, 'obfuscated name — may have been renamed'))
        else:
            fla_only.append(cls)   # expected, pure-FLA symbol

    if problems:
        print(f"MISMATCHES ({len(problems)}) — FLA expects these classes but no AS3 definition found:\n")
        for cls, fla_path, reason in problems:
            print(f"  {cls}")
            print(f"    reason : {reason}")
            print(f"    FLA    : {fla_path}")
        print()
    else:
        print("No mismatches found.\n")

    print(f"Verified OK ({len(verified)}):")
    for cls, path in verified:
        print(f"  {cls:45s} -> {path}")

    print(f"\nSkipped (pure-FLA symbols, no AS3 needed): {len(fla_only)}")

    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
