#!/usr/bin/env python3
"""Extract XFL sound payloads and generate the authoritative audio inventory."""

import argparse
import hashlib
import json
import re
import wave
from io import BytesIO
from pathlib import Path
import xml.etree.ElementTree as ET


DEFAULT_XFL = Path("flash/platform-racing-2-xfl")
DEFAULT_AS = Path("flash")
DEFAULT_OUTPUT = Path("assets/audio/sfx")
DEFAULT_MANIFEST = Path("docs/audio-inventory.json")

# Keep the XFL's opaque library names in generated metadata while giving the
# extracted runtime files names that describe their actual role.
RUNTIME_SOUND_STEMS = {
    "sound57": "intro_timeline_sound_01",
    "sound58": "intro_timeline_sound_02",
    "sound62": "intro_timeline_sound_03",
    "sound63": "intro_timeline_sound_04",
    "sound64": "intro_timeline_sound_05",
    "sound67": "intro_timeline_sound_06",
    "sound68": "intro_timeline_sound_07",
    "sound81": "logo_theme",
    "sound103": "menu_noodle_town_3",
    "sound104": "menu_noodle_town_2",
    "sound431": "countdown_go",
    "sound432": "countdown_ready",
    "sound442": "victory",
    "sound448": "block_thump",
    "sound452": "star",
    "sound453": "tick_tock",
    "sound460": "bump_sad",
    "sound473": "bump_happy",
    "sound549": "jet_engine",
    "sound550": "speed_up",
    "sound551": "slow_down",
    "sound552": "jump",
    "sound898": "egg_collect",
    "sound912": "squash",
    "sound913": "super_jump",
    "sound914": "ice_wave",
    "sound971": "mine_explosion",
    "sound1002": "slash_swish",
    "sound1003": "laser_hit",
    "sound1014": "laser_fire",
    "sound1019": "zap",
    "sound1021": "mine_appear",
    "sound1110": "teleport",
    "stingSound": "sting",
    "yeah": "artifact_yeah",
}


def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def sound_items(xfl_dir):
    root = ET.parse(xfl_dir / "DOMDocument.xml").getroot()
    return [dict(node.attrib) for node in root.iter() if local_name(node.tag) == "DOMSoundItem"]


def pcm_format(description):
    rate_match = re.search(r"(\d+)kHz", description)
    bits_match = re.search(r"(\d+)bit", description)
    if not rate_match or not bits_match:
        raise ValueError(f"unsupported PCM format: {description}")
    rates = {5: 5512, 11: 11025, 22: 22050, 44: 44100}
    rate_label = int(rate_match.group(1))
    if rate_label not in rates:
        raise ValueError(f"unsupported PCM sample rate: {description}")
    return rates[rate_label], int(bits_match.group(1)), 2 if "Stereo" in description else 1


def wav_bytes(payload, description):
    rate, bits, channels = pcm_format(description)
    output = BytesIO()
    with wave.open(output, "wb") as wav:
        wav.setnchannels(channels)
        wav.setsampwidth(bits // 8)
        wav.setframerate(rate)
        wav.writeframes(payload)
    return output.getvalue(), rate, bits, channels


def extracted_sound(xfl_dir, item):
    library_payload = xfl_dir / "LIBRARY" / item["name"]
    if library_payload.suffix.lower() == ".mp3" and library_payload.exists():
        return library_payload.read_bytes(), "mp3", None

    payload = (xfl_dir / "bin" / item["soundDataHRef"]).read_bytes()
    if len(payload) >= 2 and payload[0] == 0xFF and payload[1] & 0xE0 == 0xE0:
        return payload, "mp3", None
    encoded, rate, bits, channels = wav_bytes(payload, item["format"])
    return encoded, "wav", {"sampleRate": rate, "bitsPerSample": bits, "channels": channels}


def source_usages(as_dir, item):
    needles = [value for value in (item.get("linkageClassName"), item.get("linkageIdentifier")) if value]
    usages = []
    if not needles:
        return usages
    pattern = re.compile(r"\b(?:" + "|".join(map(re.escape, needles)) + r")\b")
    for path in sorted(as_dir.rglob("*.as")):
        for number, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
            if pattern.search(line) and not re.match(r"\s*(?:public |private |protected )?class\s", line):
                usages.append({"source": path.as_posix(), "line": number, "expression": line.strip()})
    return usages


def timeline_usages(xfl_dir, sound_name):
    usages = []
    for path in sorted((xfl_dir / "LIBRARY").rglob("*.xml")):
        root = ET.parse(path).getroot()
        for frame in root.iter():
            if local_name(frame.tag) != "DOMFrame" or frame.get("soundName") != sound_name:
                continue
            attrs = {key: value for key, value in sorted(frame.attrib.items()) if key != "soundName"}
            usages.append({"source": path.relative_to(xfl_dir).as_posix(), "frame": attrs})
    return usages


def music_catalog(as_dir):
    path = as_dir / "ui" / "GameSound.as"
    text = path.read_text(encoding="utf-8-sig")
    songs = []
    pattern = re.compile(r'addSong\(\{"id":"([^"]+)", "label":"([^"]+)", "file":"([^"]*)"\}\)')
    for song_id, label, filename in pattern.findall(text):
        if filename:
            songs.append({
                "id": song_id,
                "label": label,
                "file": filename,
                "url": "/music/new/" + filename,
                "volume": "Settings.musicLevel / 100",
                "playLoops": 9999,
            })
    return songs


def build(xfl_dir, as_dir, output_dir):
    files = {}
    sounds = []
    for item in sound_items(xfl_dir):
        encoded, extension, pcm = extracted_sound(xfl_dir, item)
        source_stem = Path(item["name"]).stem
        stem = RUNTIME_SOUND_STEMS.get(source_stem, source_stem)
        target = output_dir / f"{stem}.{extension}"
        files[target] = encoded
        entry = {
            "libraryName": item["name"],
            "output": target.as_posix(),
            "sha256": hashlib.sha256(encoded).hexdigest(),
            "format": item["format"],
            "sampleCount": int(item["sampleCount"]),
            "durationSeconds": round(int(item["sampleCount"]) / pcm_format(item["format"])[0], 6),
            "linkageClass": item.get("linkageClassName"),
            "linkageIdentifier": item.get("linkageIdentifier"),
            "sourceUsages": source_usages(as_dir, item),
            "timelineUsages": timeline_usages(xfl_dir, item["name"]),
        }
        if pcm:
            entry["decodedPcm"] = pcm
        sounds.append(entry)
    manifest = {
        "source": (xfl_dir / "DOMDocument.xml").as_posix(),
        "soundEffects": sounds,
        "streamedMusic": music_catalog(as_dir),
        "behavior": {
            "musicBasePath": "/music/new",
            "musicLooping": "GameSound restarts on SOUND_COMPLETE; play() also requests 9999 loops",
            "spatialSound": "SoundEffects.playGameSound attenuates over 700 pixels and pans by horizontal offset",
        },
    }
    return files, (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xfl", type=Path, default=DEFAULT_XFL)
    parser.add_argument("--as-dir", type=Path, default=DEFAULT_AS)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--check", action="store_true", help="fail when generated files are missing or stale")
    args = parser.parse_args()

    files, manifest = build(args.xfl, args.as_dir, args.output)
    files[args.manifest] = manifest
    stale = [path for path, data in files.items() if not path.exists() or path.read_bytes() != data]
    expected = set(files)
    extras = set(args.output.glob("*")) - expected if args.output.exists() else set()
    if args.check and (stale or extras):
        paths = sorted(str(path) for path in set(stale) | extras)
        raise SystemExit("Missing, stale, or unexpected generated audio files:\n" + "\n".join(paths))
    if not args.check:
        for path in extras:
            path.unlink()
        for path, data in files.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            if not path.exists() or path.read_bytes() != data:
                path.write_bytes(data)
    print(f"Verified {len(files) - 1} sound effects and {len(json.loads(manifest)['streamedMusic'])} music tracks.")


if __name__ == "__main__":
    main()
