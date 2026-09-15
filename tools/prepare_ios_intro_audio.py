#!/usr/bin/env python3
"""Generate the iOS intro PCM asset from the committed Flash MP3 (macOS)."""

from pathlib import Path
import subprocess
import tempfile
import wave


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/audio/sfx/logo_theme.mp3"
OUTPUT = ROOT / "art/audio-ios/logo_theme.wav"


def main():
    with tempfile.TemporaryDirectory() as directory:
        converted = Path(directory) / "logo_theme.wav"
        subprocess.run(
            ["afconvert", "-f", "WAVE", "-d", "LEI16", str(SOURCE), str(converted)],
            check=True,
        )
        with wave.open(str(converted), "rb") as audio:
            assert audio.getnchannels() == 2
            assert audio.getsampwidth() == 2
            assert audio.getframerate() == 22050
            assert audio.getnframes() > 0
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_bytes(converted.read_bytes())
    print(f"Generated {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
