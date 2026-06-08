#!/usr/bin/env python3
"""Rename a symbol (method, variable, constant) across all .as files.

Usage:
    python3 rename_symbol.py method_86 disableCaching
    python3 rename_symbol.py --dry-run method_86 disableCaching
    python3 rename_symbol.py --ext .as,.fla method_86 disableCaching
"""

import os
import re
import sys
import argparse


def main():
    parser = argparse.ArgumentParser(description="Rename a symbol across all .as files")
    parser.add_argument("old_name", help="Symbol to find (exact identifier)")
    parser.add_argument("new_name", help="Replacement name")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show changes without modifying files")
    parser.add_argument("--root", default=".",
                        help="Root directory to search (default: current dir)")
    parser.add_argument("--ext", default=".as",
                        help="Comma-separated file extensions to scan (default: .as)")
    args = parser.parse_args()

    extensions = tuple(e.strip() for e in args.ext.split(","))
    pattern = re.compile(r'\b' + re.escape(args.old_name) + r'\b')

    changed: list[tuple[str, int]] = []
    for dirpath, dirnames, filenames in os.walk(args.root):
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        for filename in filenames:
            if not filename.endswith(extensions):
                continue
            filepath = os.path.join(dirpath, filename)
            try:
                with open(filepath, encoding='utf-8', errors='replace') as f:
                    content = f.read()
            except OSError:
                continue
            new_content, count = pattern.subn(args.new_name, content)
            if count:
                changed.append((filepath, count))
                if not args.dry_run:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)

    if not changed:
        print(f"No occurrences of '{args.old_name}' found.")
        return

    total = sum(c for _, c in changed)
    for filepath, count in sorted(changed):
        rel = os.path.relpath(filepath, args.root)
        hits = f"{count} hit{'s' if count != 1 else ''}"
        print(f"  {rel}: {hits}")

    action = "Would rename" if args.dry_run else "Renamed"
    print(f"\n{action} {total} occurrence(s) across {len(changed)} file(s).")
    if args.dry_run:
        print("(dry run — no files modified; remove --dry-run to apply)")


if __name__ == "__main__":
    main()
