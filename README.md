# Platform Racing 2 Client

This repository is the Haxe/OpenFL port of the Platform Racing 2 Flash client.
The current migration source is the extracted Adobe Animate XFL under
`flash/platform-racing-2-xfl/`. Normal development should build from committed
Haxe/OpenFL source and committed generated assets, without requiring Adobe
Animate.

## License
Art: Rights belong to credited artits, otherwise https://creativecommons.org/licenses/by-nc/4.0/
Music: Rights belong to credited artists
Code: MIT

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
- `?screen=campaign&debug=campaign`: debug-only campaign harness. Loads a real
  campaign level through the configured API host/proxy, renders the decoded block
  layer, and places the character at the first start block. Accepts `page` and
  `levelId` (or `level`) to choose a listed campaign level.
  - `&localLevel=<name>` instead builds a synthetic level entirely client-side
    (no server fetch) and mounts it in the same `Course`/`ServerLevelRenderer`
    path — the offline gameplay sandbox. Layouts: `rotate` (a boxed-in room with
    a rotate block over the spawn) and `flat` (a wide open floor).
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
./test.sh
./test.sh real-server
```

The deterministic suite runs one representative test from every test class by
default. Run `./test.sh --full` to execute every deterministic test.

Run complete tests for one or more related domains by passing flags; multiple
flags select their union:

```sh
./test.sh --physics --blocks
./test.sh --level-rendering
./test.sh --lobby --items
./test.sh --level-editor
```

Use `./test.sh --help` to list every domain flag.

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
- `art/svg/`: SVG exports from Animate.
- `art/png/timeline/`: generated PNG fallbacks for timeline artwork whose SVG
  features OpenFL cannot render directly.
- `docs/`: migration notes and inventories.
- `docs/browser-platform-differences.md`: audited, platform-required HTML5
  differences and their parity boundaries.
- `docs/deflash-symbol-inventory.md`: generated inventory of the production
  `PR2MovieClip` root symbols, grouped by feature owner and native replacement
  shape; regenerate it with `tools/generate_deflash_symbol_inventory.py`.
- `docs/deflash-coupling-inventory.md`: generated deletion ledger of handwritten
  timeline navigation, name lookup, `Fl*` control, reflection, and legacy
  dependency sites, grouped by migration owner.
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
- The `?screen=campaign&localLevel=<name>` sandbox can run synthetic levels
  without login/lobby/server flow and exposes deterministic debug state for
  movement checks.

### De-Flash Architecture Goal

The presentation layer will move incrementally from reflective Flash timeline
access to concrete, typed Haxe views. For example, current code commonly loads
an authored symbol and discovers its controls by string name:

```haxe
art = PR2MovieClip.fromLinkage("SomePopupGraphic");
nameBox = LobbyArt.text(art, "nameBox");
button = DisplayUtil.findByName(art, "ok_bt");
```

The target is an ordinary Haxe view whose structure is explicit and checked by
the compiler:

```haxe
class ConfirmDialogView extends Sprite {
	public final message:TextField;
	public final confirmButton:GameButton;
	public final cancelButton:GameButton;

	public function new() {
		super();
		// Explicit construction and layout.
	}
}
```

This is a code-structure and asset-pipeline migration only. Layout, artwork,
animation, sound, timing, behavior, and user flows must remain unchanged, with
the deterministic and screenshot/parity tests acting as regression gates. See
`TODO.md` for the incremental migration plan and
`docs/deflash-symbol-inventory.md` for the generated production boundary.
`tools/deflash-boundary-allowlist.json` records the maximum legacy dependencies
of the current migration adapters. `./test.sh` checks both generated inventories
and rejects a new `PR2MovieClip`, `Fl*`, or generated-timeline dependency; the
allowlist may shrink as views are migrated, but should not grow.

Campaign payload reference:

- Campaign lists are fetched from `pr2hub.com/files/lists/campaign/{page}` and
  validated with `MD5(ret.substr(10, len - 53) + "984cn98c54$")`.
- Level data is fetched from `pr2hub.com/levels/{id}.txt?version={v}` and
  validated with `MD5(version + id + levelData + "0kg4%dsw")`.
- The decoded `levelData` is `&`-joined URL-encoded vars passed through
  `validateSaveString`; `data` is backtick-delimited with read mode in
  `data[0]` and the relative-coordinate block string in `data[1]`.

## Haxe/OpenFL Commands

### Pinned Native Toolchain

The repository currently uses Haxe 4.3.7, OpenFL 9.5.2, Lime 8.3.2, and the
official hxcpp `v4.3.146` GitHub release. Do not use hxcpp 4.3.2 from Haxelib
for Android builds: it can produce an application that packages successfully
but fails at startup because `__atomic_compare_exchange_4` cannot be resolved.

The `.haxelib/` directory is repository-local and ignored by Git. Install the
pinned hxcpp tag and compile its command-line tool from the repository root:

```sh
tools/setup_hxcpp.sh
```

Confirm that the local Git checkout is on the expected release before making a
native build:

```sh
git -C .haxelib/hxcpp/git describe --tags --exact-match
```

This should print `v4.3.146`. The Git checkout's `haxelib.json` reports the
API-series version `4.3.0`; the Git tag is the authoritative pinned release.

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
python3 tools/generate_animate_svg_export_jsfl.py --limit 8 --out art/export-character-svg-smoke.jsfl
```

Run a JSFL file through Adobe Animate on macOS:

```sh
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" art/export-character-svg.jsfl
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" art/export-character-svg-smoke.jsfl
```

The direct Animate executable also runs JSFL scripts:

```sh
"/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" art/export-character-svg-smoke.jsfl
```

This was verified with the smoke export. The command stays attached while
Animate remains open, so unattended automation still needs a quit/wrapper
decision.

Other generated JSFL entry points:

```sh
python3 tools/generate_other_assets_jsfl.py
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" art/export-other-assets-svg.jsfl

python3 tools/generate_block_bitmap_jsfl.py
open -a "/Applications/Adobe Animate 2024/Adobe Animate 2024.app" art/export-block-bitmaps.jsfl
```

## Timeline Bitmap Fallbacks

Most exported artwork is rendered directly from SVG. Regenerate the small PNG
fallback set for timeline SVGs containing unsupported bitmap fills or filters
with:

```sh
python3 tools/rasterize_timeline_bitmap_fills.py
```

The generated files live in `art/png/timeline/` and are packaged as
`assets/timeline-bitmap/` by `project.xml`.

Check Inkscape availability:

```sh
/Applications/Inkscape.app/Contents/MacOS/inkscape --version
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

Read and validate the OpenFL debug state. The offline gameplay sandbox
(`?screen=campaign&debug=1&localLevel=<name>`) publishes the local player's
state to `data-pr2-debug-state`:

```sh
python3 tools/openfl_driver.py --delay 2.0 --query 'screen=campaign&debug=1&localLevel=flat' \
  --expect phase=playable \
  debug-state
```

Measure real-level art drawing performance through the campaign harness. Build
first, then serve the HTML5 export through the local API proxy so browser fetches
for `pr2hub.com` stay same-origin:

```sh
haxelib run openfl build html5
python3 tools/dev_proxy.py --port 8000 --dir export/html5/bin
```

Run the metric harness from another terminal. It records drawing/playable timing,
per-sample FPS, art/block progress, heap usage, and Chrome performance metrics:

```sh
python3 tools/measure_art_render.py \
  --base-url http://127.0.0.1:8000 \
  --label current-candyland \
  --level-id 3460484 --version 13 \
  --out test/output/art-render-candyland.json \
  --timeout 180 --print-every 16
```

Useful art-render stress cases:

```text
3460484 v13  Candyland          Fast-ish, visible parity check, lots of strokes
4866546 v15  Volcanic Inferno   Medium-heavy art and block mix
5877893 v18  Apocalypse         Extreme art case; old builds may not finish
5821108 v92  Smog               Earlier baseline candidate
```

To compare an older revision against the current build, keep each export in a
separate directory and run two proxy ports:

```sh
git worktree add /private/tmp/pr2-baseline add6470
haxelib run openfl build html5
cd /private/tmp/pr2-baseline
haxelib run openfl build html5

python3 tools/dev_proxy.py --port 8001 --dir /private/tmp/pr2-baseline/export/html5/bin
python3 tools/dev_proxy.py --port 8002 --dir /path/to/current/export/html5/bin

python3 tools/measure_art_render.py --base-url http://127.0.0.1:8001 \
  --label baseline-apocalypse --level-id 5877893 --version 18 \
  --out test/output/art-render-baseline-apocalypse.json --timeout 300

python3 tools/measure_art_render.py --base-url http://127.0.0.1:8002 \
  --label current-apocalypse --level-id 5877893 --version 18 \
  --out test/output/art-render-current-apocalypse.json --timeout 180
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
python3 tools/compare_symbol_render.py --symbol UI/Global/MuteButton --reference test/baselines/vector-art/mute_button@4x.png
```

Check approximate OpenFL frame rate:

```sh
python3 tools/openfl_driver.py --fps-duration 30 --fps-target 27 --fps-tolerance 5 fps
```

Run a scripted OpenFL driver sequence:

```sh
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
`keyUp`, `tap`, `hold`, `mouseMove`, `navigate`, `metrics`, `debug-state`, and
`shot` actions. Screenshots, metrics, and diff output should go under ignored
`test/output/`.

Run the broad browser navigation smoke suite, including route reloads, member
and guest lobby tabs, and per-checkpoint Chrome metrics:

```sh
tools/test_browser_navigation.sh
```

The metrics JSON is written to `test/output/browser-navigation-metrics.json`.

Sequences wait for the app to boot past the OpenFL preloader before the clock
starts: step `time` offsets are measured from when `Main` sets the
`data-pr2-app-ready` body attribute, not from browser launch. This keeps input
from being dispatched into the preloader (where it is silently dropped), so
`time` values only need to cover in-app settling, not a guessed preload
duration.
