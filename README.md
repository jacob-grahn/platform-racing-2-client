# Platform Racing 2 Client

This repository is the Haxe/OpenFL port of the Platform Racing 2 Flash client.
The current migration source is the extracted Adobe Animate XFL under
`flash/platform-racing-2-xfl/`. Normal development should build from committed
Haxe/OpenFL source and committed generated assets, without requiring Adobe
Animate.

## Quick Start

Run the browser build from the repository root:

```sh
haxelib run openfl test html5
```

The client boots into the intro screens by default. A `?screen=` flag selects
the boot screen so development and automated tests can jump straight to one:

- `?screen=intro` (default): Jiggmin and Kongregate intro flow, then login.
  - `?intro=jiggmin` or `?intro=kongregate` plays just that one intro (testing).
- `?screen=login`: the (stub) login page.
- `?screen=harness`: the local gameplay harness; accepts the character query
  options (`hat`, `head`, `body`, `feet`, `primary`, `secondary`, `render`).
- `?screen=campaign`: loads a real campaign level through the configured API
  host/proxy, renders the decoded block layer, and places the character at the
  first start block. Accepts `page` and `levelId` (or `level`) to choose a
  listed campaign level.
- `?screen=symbol&symbol=<name>&scale=4&bg=FFFFFF`: renders one generated
  library symbol through the vector renderer for visual comparison work.

`IntroPage` publishes its progress to the `data-pr2-intro-state` body attribute
(`intro-jiggmin`, `intro-kongregate`, `login`) for harness observation.

Build without launching:

```sh
haxelib run openfl build html5
```

Run the lightweight runtime tests:

```sh
haxe test/deterministic.hxml
haxe test/real-server.hxml
```

Run the complete local verification gate (deterministic and protocol tests,
HTML5 build, and required character parity sequences):

```sh
tools/test_all.sh
```

Per-stage logs are written to `test/output/test-all/`; parity screenshots are
written to `test/output/`.

Capture the representative character parity cases (default, recolored, mixed
parts, and cheese-hat/Fred-body placement) after an HTML5 build:

```sh
for case in default colors mixed-parts tricky-parts; do python3 tools/openfl_driver.py sequence test/sequences/openfl/character-$case.json; done
```

Local server/API overrides can live in ignored shell env files. On sys targets,
set `PR2_API_HOST` to point API calls at a proxy or local endpoint:

```sh
PR2_API_HOST=/api haxe test/real-server.hxml
```

## Project Layout

- `project.xml`: OpenFL project file.
- `haxe/src/`: Haxe/OpenFL source.
- `haxe/test/`: Haxe test entry points.
- `assets/`: OpenFL app assets.
- `flash/platform-racing-2-xfl/`: extracted Animate/XFL migration source.
- `tools/`: asset extraction, generation, rasterization, and harness helpers.
- `vector-art/svg/`: SVG exports from Animate.
- `vector-art/png/`: generated 4x PNGs from SVG vector art.
- `vector-art/atlases/`: generated sprite sheets and frame JSON.
- `docs/`: migration notes and inventories.
- `TODO.md`: current porting plan and next steps.

## Porting Status

The port targets a faithful Haxe/OpenFL browser build of the original Flash
client: 550x400 stage, 27 FPS timing, Flash-compatible gameplay behavior, and
visual parity measured by deterministic state and screenshot comparisons. Normal
development and CI should use committed Haxe/OpenFL source and generated assets;
Adobe Animate is only a migration tool for regenerating source assets.

Current foundation:

- Generated asset metadata is available under `pr2.generated.assets` from the
  extracted XFL source.
- `AssetLibrary` and `PR2MovieClip` run generated timelines with nested clips,
  labels, frame scripts, transforms, visibility, and named children.
- The local harness can run fixture levels without login/lobby/server flow and
  exposes deterministic debug state for movement checks.
- `LocalCharacter` has Flash-derived land movement/collision, with additional
  tested behavior for water, crumble, vanish, mine, teleport, item/stat supply,
  push, timed move, ice, arrow, and safety blocks.
- `CharacterDisplay` uses the generated `CharacterGraphic` timeline skeleton and
  atlas-backed hat/head/body/feet parts, including primary/secondary layer
  rendering and a composite debug/fallback mode.
- Intro pages run through the MovieClip timeline runtime, with Jiggmin and
  Kongregate intro coverage and a stub login page.

Server level support:

- `CampaignListClient` fetches and validates campaign lists; `LevelDataClient`
  fetches and validates level data.
- `ServerLevelDecoder` decodes block strings in modes `m1`-`m4` into original
  pixel coordinates, and `ServerLevelRenderer` renders the decoded block layer at
  the original 30 px block scale.
- `ServerLevelFixtureAdapter` converts decoded server geometry into fixture
  collision data so local movement can run in real level layouts.
- Browser builds need a same-origin API proxy for pr2hub.com requests. The dev
  proxy is `tools/dev_proxy.py`; use `?apiHost=/api` with that proxy.

Campaign payload reference:

- Campaign lists are fetched from `pr2hub.com/files/lists/campaign/{page}` and
  validated with `MD5(ret.substr(10, len - 53) + "984cn98c54$")`.
- Level data is fetched from `pr2hub.com/levels/{id}.txt?version={v}` and
  validated with `MD5(version + id + levelData + "0kg4%dsw")`.
- The decoded `levelData` is `&`-joined URL-encoded vars passed through
  `validateSaveString`; `data` is backtick-delimited with read mode in
  `data[0]` and the relative-coordinate block string in `data[1]`.

Networking status:

- Browser OpenFL cannot open the original raw TCP gameserver socket directly, so
  browser deployment must use the gameserver WebSocket path.
- The minimal networking spike opens the selected server WebSocket, sends
  `request_login_id` with the Flash `chr(0x04)` delimiter, and parses
  `setLoginID`.
- Local config and credentials should stay in ignored env/local files. Sys-target
  API calls can use `PR2_API_HOST` for a proxy or local endpoint.

## Haxe/OpenFL Commands

Browser development path:

```sh
haxelib run openfl test html5
haxelib run openfl build html5
```

Optional macOS target for local debugging:

```sh
haxelib run openfl display mac
MACOSX_VER=26.5 haxelib run openfl test mac
MACOSX_VER=26.5 haxelib run openfl build mac
```

If your installed macOS SDK suffix differs, check it with:

```sh
xcodebuild -showsdks
```

## Generated Haxe Assets

Extract XFL metadata summary:

```sh
python3 tools/xfl_metadata.py --summary
```

Regenerate the Haxe asset catalog:

```sh
python3 tools/generate_haxe_assets.py
```

Compile-check the generated package:

```sh
haxe -cp haxe/src --macro 'include("pr2.generated.assets")' --no-output
```

## Vector Art Inventory

Regenerate the vector-art inventory:

```sh
python3 tools/vector_art_inventory.py
python3 tools/verify_deferred_linkages.py
```

Recover bitmap files retained only as XFL `bin/*.dat` payloads:

```sh
python3 tools/extract_xfl_bitmaps.py
python3 tools/extract_xfl_bitmaps.py --check
```

Extract embedded sound effects and regenerate the audio inventory (including
streamed music metadata and authored playback parameters):

```sh
python3 tools/extract_xfl_audio.py
python3 tools/extract_xfl_audio.py --check
```

Verify the Adobe-exported Kongregate intro art and its committed runtime atlas:

```sh
python3 tools/verify_kongregate_intro.py
```

The default inventory output is `docs/vector-art-inventory.json`.

## Adobe Animate SVG Export

Adobe Animate is only needed when regenerating SVGs from the original XFL/FLA
source. Normal OpenFL builds should not require it.

Regenerate the character SVG export JSFL:

```sh
python3 tools/generate_animate_svg_export_jsfl.py
```

Generate a small smoke-test JSFL:

```sh
python3 tools/generate_animate_svg_export_jsfl.py --limit 8 --out vector-art/export-character-svg-smoke.jsfl
```

Run a JSFL file through Adobe Animate on macOS:

```sh
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" vector-art/export-character-svg.jsfl
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" vector-art/export-character-svg-smoke.jsfl
```

The direct Animate executable also runs JSFL scripts:

```sh
"/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-character-svg-smoke.jsfl
```

This was verified with the smoke export. The command stays attached while
Animate remains open, so unattended automation still needs a quit/wrapper
decision.

Other generated JSFL entry points:

```sh
python3 tools/generate_other_assets_jsfl.py
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" vector-art/export-other-assets-svg.jsfl

python3 tools/generate_block_bitmap_jsfl.py
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" vector-art/export-block-bitmaps.jsfl
```

Animated effects are intentionally not exported as per-frame SVG sequences.
The Haxe/OpenFL timeline runtime should own labels, frame scripts, nested
symbols, transforms, visibility, and customization. The exported effect SVGs
are reusable symbol images for runtime composition and fallback rendering.
This includes the countdown, egg, heart, ice-wave, Djinn-ice, and character
item/state animation symbols; their generated XFL metadata drives playback.

## SVG To PNG Rasterization

Rasterize committed SVGs to 4x PNGs and sprite sheets:

```sh
python3 tools/rasterize_vector_art.py --sheets --manifest vector-art/raster-manifest.json
```

Rasterize only character art:

```sh
python3 tools/rasterize_vector_art.py --sheets --category character --manifest vector-art/raster-manifest.json
```

Rasterize the exported non-character SVGs. Backgrounds, block overlays, effect
symbols, and login page components remain standalone PNGs; stamps and item icons
are packed into separate atlases:

```sh
python3 tools/rasterize_vector_art.py --sheets --category backgrounds --category blocks --category stamps --category effects --category items --category login --manifest vector-art/raster-manifest-other.json
```

Rasterize the baked intro symbols. The Kongregate intro keeps its original
timeline transforms in Haxe, while the difficult nested vector symbols are
loaded from this atlas:

```sh
python3 tools/rasterize_vector_art.py --sheets --category intro --manifest vector-art/raster-manifest-intro.json
```

The rasterizer uses Inkscape when available and falls back to Lime's bundled
Batik renderer. The default Inkscape path is:

```text
/Applications/Inkscape.app/Contents/MacOS/inkscape
```

Check Inkscape availability:

```sh
/Applications/Inkscape.app/Contents/MacOS/inkscape --version
```

## Raster Asset Verification

Verify the current character raster output:

```sh
python3 - <<'PY'
import json
from pathlib import Path
from PIL import Image

with open('vector-art/raster-manifest.json') as f:
    manifest = json.load(f)

pngs = sorted(Path('vector-art/png').rglob('*.png'))
atlas_pngs = sorted(Path('vector-art/atlases').rglob('*.png'))
atlas_jsons = sorted(Path('vector-art/atlases').rglob('*.json'))
assert len(manifest['pngs']) == 632
assert len(pngs) == 632
assert len(manifest['atlases']) == len(atlas_pngs)
assert len(atlas_pngs) == len(atlas_jsons)
for path in atlas_pngs:
    image = Image.open(path)
    assert image.width <= 4096 and image.height <= 4096, (path, image.size)
    assert image.getbbox() is not None, path
print('verified', len(pngs), 'pngs,', len(atlas_pngs), 'atlas pages')
PY
```

## Harness Helpers

Capture an OpenFL screenshot after launching the app:

```sh
python3 tools/openfl_driver.py --delay 2.0 shot test/baselines/openfl/run_harness.png
```

Capture popup parity fixtures without requiring a live lobby session:

```sh
python3 tools/openfl_driver.py --delay 8 --query 'screen=popup&popup=loadouts' shot test/output/openfl-popup-loadouts.png
```

Supported popup fixtures are `message`, `confirm`, `send-message`, `codes`,
`loadouts`, and `credits`.

Capture a representative character outfit for comparison work:

```sh
python3 tools/openfl_driver.py --delay 2.0 --query 'hat=16&head=37&body=29&feet=40&primary=aa00ff&secondary=00cc11&render=composite' shot test/output/openfl-character-outfit.png
```

Read and validate the OpenFL harness debug state:

```sh
python3 tools/openfl_driver.py --delay 1.0 \
  --expect fixture=flat-level \
  --expect x=75 \
  --expect y=270 \
  --expect grounded=true \
  debug-state
```

Compare two stage screenshots and write diff artifacts:

```sh
python3 tools/compare_screenshots.py expected.png actual.png --diff test/output/diff.png --metrics test/output/metrics.json --threshold-percent 1 --threshold-rms 8
```

Score the vector renderer against the Adobe `@4x` rasters. Each case renders one
library symbol through the `?screen=symbol` vector path, trims it to its content
box, resizes to the reference raster, and reports `rmsDelta` / `differingPercent`
(`rmsDelta` is the gate; see `tools/symbol_render_cases.json` for the cases and
per-case thresholds):

```sh
python3 tools/compare_symbol_render.py --diff-dir test/output/symbol-diffs --metrics test/output/symbol-metrics.json
python3 tools/compare_symbol_render.py --symbol UI/Global/MuteButton --reference vector-art/png/login/mute_button@4x.png
```

Check approximate OpenFL frame rate:

```sh
python3 tools/openfl_driver.py --fps-duration 30 --fps-target 27 --fps-tolerance 5 fps
```

Run a scripted OpenFL harness sequence:

```sh
python3 tools/openfl_driver.py sequence test/sequences/openfl/harness-boot.json
python3 tools/openfl_driver.py sequence test/sequences/openfl/run-right.json
python3 tools/openfl_driver.py sequence test/sequences/openfl/lobby-flow.json
python3 tools/openfl_driver.py sequence test/sequences/openfl/lobby-parity.json
python3 tools/compare_screenshots.py test/baselines/flash/04_lobby_unobstructed.jpg test/output/openfl-lobby-shell.png --diff test/output/openfl-vs-flash-lobby-diff.png --metrics test/output/openfl-vs-flash-lobby-metrics.json --threshold-percent 100 --threshold-rms 255
```

To exercise campaign and search responses through the real same-origin proxy,
start `tools/dev_proxy.py` and run the parity sequence against it:

```sh
python3 tools/openfl_driver.py --base-url http://127.0.0.1:8000 sequence test/sequences/openfl/lobby-parity.json
```

Sequence files keep one browser session open and can combine `keyDown`,
`keyUp`, `tap`, `hold`, `mouseMove`, `debug-state`, and `shot` actions. Screenshots and
diff output should go under ignored `test/output/`.

## Useful References

- `TODO.md`: active migration plan and resume notes.
- `docs/vector-art-export-plan.md`: vector export and rasterization details.
- `docs/initial-playable-scope.md`: initial playable target.
- `docs/networking-inventory.md`: Flash networking inventory.
