#!/usr/bin/env python3
"""Minify the generated HTML5 JavaScript bundle with Lime's bundled Terser."""

import platform
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "export/html5/bin/PlatformRacing2.js"


def lime_templates() -> Path:
    """Ask haxelib where Lime is, since it may be installed outside .haxelib/."""
    haxelib = shutil.which("haxelib")
    if haxelib is not None:
        try:
            result = subprocess.run([haxelib, "libpath", "lime"], check=True, cwd=ROOT, capture_output=True, text=True)
            for line in result.stdout.splitlines():
                if line.strip() and (Path(line.strip()) / "templates").is_dir():
                    return Path(line.strip()) / "templates"
        except (OSError, subprocess.CalledProcessError):
            pass
    return ROOT / ".haxelib/lime/8,3,2/templates"


LIME_TEMPLATES = lime_templates()
TERSER = LIME_TEMPLATES / "bin/node/terser/bin/terser"


def bundled_node() -> Path:
    system = platform.system()
    machine = platform.machine().lower()
    if system == "Darwin":
        return LIME_TEMPLATES / "bin/node/node-mac"
    if system == "Linux":
        return LIME_TEMPLATES / ("bin/node/node-linux32" if machine in {"x86", "i386", "i686"} else "bin/node/node-linux64")
    if system == "Windows":
        return LIME_TEMPLATES / "bin/node/node-windows.exe"
    raise SystemExit(f"Unsupported platform for bundled Terser: {system}")


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing HTML5 bundle: {SOURCE}")

    node = bundled_node()
    if not node.exists():
        system_node = shutil.which("node")
        if system_node is None:
            raise SystemExit(f"Missing bundled Node executable: {node}")
        print(f"Bundled Node not found at {node}; using {system_node}.")
        node = Path(system_node)
    if not TERSER.exists():
        raise SystemExit(f"Missing bundled Terser executable: {TERSER}")

    original_size = SOURCE.stat().st_size
    with tempfile.NamedTemporaryFile(suffix=".js", delete=False) as temp:
        temp_path = Path(temp.name)

    try:
        subprocess.run(
            [str(node), str(TERSER), str(SOURCE), "-c", "-m", "-o", str(temp_path)],
            check=True,
            cwd=ROOT,
        )
        SOURCE.write_bytes(temp_path.read_bytes())
    finally:
        temp_path.unlink(missing_ok=True)

    print(f"Minified HTML5 JS: {original_size} -> {SOURCE.stat().st_size} bytes.")


if __name__ == "__main__":
    main()
