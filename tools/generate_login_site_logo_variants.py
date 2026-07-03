#!/usr/bin/env python3
"""Generate login page SVG variants with site-specific logo visibility."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "vector-art/svg/login/login_page.svg"

LOGO_TAGS = {
    "kong": '<g id="kongLogo" transform="matrix( 1, 0, 0, 1, 5.45,364.45) ">',
    "bubble_box": '<g display="none" id="bubbleBoxLogo" transform="matrix( 1, 0, 0, 1, 98.4,374.95) ">',
    "armor_games": '<g display="none" id="armorGamesLogo" transform="matrix( 0.883941650390625, 0, 0, 0.883941650390625, 4.75,351.3) ">',
}

VISIBLE_TAGS = {
    "kong": '<g id="kongLogo" transform="matrix( 1, 0, 0, 1, 5.45,364.45) ">',
    "bubble_box": '<g id="bubbleBoxLogo" transform="matrix( 1, 0, 0, 1, 98.4,374.95) ">',
    "armor_games": '<g id="armorGamesLogo" transform="matrix( 0.883941650390625, 0, 0, 0.883941650390625, 4.75,351.3) ">',
}

HIDDEN_TAGS = {
    "kong": '<g display="none" id="kongLogo" transform="matrix( 1, 0, 0, 1, 5.45,364.45) ">',
    "bubble_box": '<g display="none" id="bubbleBoxLogo" transform="matrix( 1, 0, 0, 1, 98.4,374.95) ">',
    "armor_games": '<g display="none" id="armorGamesLogo" transform="matrix( 0.883941650390625, 0, 0, 0.883941650390625, 4.75,351.3) ">',
}

VARIANTS = {
    "login_page_bubble_box.svg": "bubble_box",
    "login_page_armor_games.svg": "armor_games",
    "login_page_no_logo.svg": None,
}


def build_variant(source: str, visible_logo: str | None) -> str:
    result = source
    for key, source_tag in LOGO_TAGS.items():
        replacement = VISIBLE_TAGS[key] if key == visible_logo else HIDDEN_TAGS[key]
        if source_tag not in result:
            raise RuntimeError(f"Missing login logo tag for {key}")
        result = result.replace(source_tag, replacement, 1)
    return result


def main() -> int:
    source = SOURCE.read_text(encoding="utf-8")
    for file_name, visible_logo in VARIANTS.items():
        (SOURCE.parent / file_name).write_text(build_variant(source, visible_logo), encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
