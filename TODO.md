# Platform Racing 2 Haxe/OpenFL Port TODO

This is the working roadmap for getting the Flash client ported to a playable
Haxe/OpenFL browser build. Keep this file focused on what moves the port
forward; detailed command references belong in `README.md`, and asset-pipeline
details belong in `docs/vector-art-export-plan.md`.

## Direction

- Primary target: browser/HTML5 with Haxe + OpenFL.
- Secondary targets: Android and iOS after browser parity.
- First playable goal: launch into a local fixture level, render a simple
  course, and move one local character with PR2-like timing.
- Normal development and CI should not require Adobe Animate. Animate is only a
  migration tool for regenerating source assets.
- Visual goal for the first playable milestone is close enough to recognize and
  debug PR2, not pixel-perfect parity.
- Testing direction: deterministic fixture runs first, then Flash/OpenFL
  screenshot and debug-state comparisons, then real-server checks.

## Done Foundation

- [x] Baseline and scope documented.
  - Stage baseline: 550x400 at 27 FPS.
  - Initial playable scope: `docs/initial-playable-scope.md`.
  - Flash and OpenFL harness helpers exist under `tools/`.
- [x] OpenFL project skeleton exists.
  - Root `project.xml`.
  - Haxe source under `haxe/src/`.
  - Browser build path is `haxelib run openfl test html5`.
  - Runtime test command is documented in `README.md`.
- [x] XFL metadata and generated Haxe asset catalog exist.
  - `tools/xfl_metadata.py`.
  - `tools/generate_haxe_assets.py`.
  - Generated `pr2.generated.assets` package compile-checks.
- [x] Generated MovieClip runtime exists.
  - `AssetLibrary` and `PR2MovieClip` support nested timelines, labels,
    playback, frame scripts, transforms, visibility, and named children.
  - Runtime tests cover core timeline and character-composition behavior.
- [x] Basic XFL vector rendering exists.
  - Solid fill/stroke path rendering works for many leaf symbols.
  - Gradient/bitmap style parity is still incomplete, which is why the raster
    asset path remains important.
- [x] Character SVG exports and raster assets exist.
  - Character SVGs are under `vector-art/svg/character/`.
  - Character PNGs are under `vector-art/png/character/`.
  - Character atlases are under `vector-art/atlases/character/`.
  - Last verified character output: 632 individual PNGs, 19 atlas PNG pages,
    and 19 atlas JSON files.
- [x] Adobe Animate JSFL invocation is verified.
  - Direct command works:
    ```sh
    "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-character-svg-smoke.jsfl
    ```
  - It executes the JSFL and writes to tracked `vector-art/...` paths.
  - Caveat: the process stays attached while Animate remains open.
- [x] Browser networking risks are documented.
  - Browser client needs WebSocket support from the server/proxy side.
  - Raw TCP PR2 sockets cannot be opened directly from browser OpenFL.

## Current Priority: Get A Local Playable Harness

This is the shortest path to a working port. Keep it local and deterministic
until movement, rendering, and fixture loading are debuggable.

- [ ] Add a gameplay harness mode reachable from `Main`.
  - It can launch directly for development.
  - It should not require login, lobby, server data, or real level loading.
  - It should keep the logical 550x400 stage.
- [ ] Define a tiny fixture level format.
  - Blocks with tile coordinates and block type.
  - Player start position.
  - Finish position.
  - Gravity/stat defaults.
  - One committed flat-level fixture.
- [ ] Render the fixture level.
  - Draw basic solid blocks, start, and finish.
  - Use generated/raster block assets if ready; otherwise use clear temporary
    colored blocks and keep the renderer replaceable.
  - Preserve PR2 scale and coordinates.
- [ ] Port minimum local character movement.
  - Fixed 27 FPS update step.
  - Left/right acceleration.
  - Gravity.
  - Jump.
  - Down/crouch.
  - Grounded state.
  - Collision against basic solid tiles.
- [ ] Add deterministic debug state export.
  - Position.
  - Velocity.
  - Grounded/crouching state.
  - Current animation/state name.
  - Touched block type.
- [ ] Add one scripted movement verification.
  - Run right on the flat fixture for a fixed duration.
  - Jump and land on the flat fixture.
  - Assert stable final debug state.

Acceptance for this section:

- `haxelib run openfl build html5` succeeds.
- Browser build can enter the fixture level without network access.
- Local player can run, jump, crouch, land, and reach a finish block.
- Debug state is deterministic for a scripted input sequence.

## Character Rendering

Character rendering is important, but it should serve the playable harness
rather than becoming an open-ended art project.

- [ ] Decide how the character atlas metadata enters Haxe.
  - Option A: load atlas JSON directly at runtime.
  - Option B: convert atlas JSON into generated Haxe metadata.
  - Prefer the simpler path unless runtime loading creates target issues.
- [ ] Add character atlas PNGs to OpenFL assets.
  - Include `vector-art/atlases/character/**/*.png`.
  - Include atlas JSON if loading directly.
- [ ] Implement a small atlas frame loader.
  - Read `frame` rectangles.
  - Read `sourceTrim`.
  - Preserve part id, kind, channel, page, and scale.
- [ ] Render one known part from the atlas.
  - Start with `hat/002_exp`; it previously exposed negative-coordinate SVG
    behavior.
  - Confirm placement matches the existing generated MovieClip composition well
    enough to continue.
- [ ] Render one full customizable character.
  - Static, primary, and secondary layers remain separate.
  - Primary and secondary layers can be tinted independently.
  - Composite layer remains available for preview/debug/fallback.
- [ ] Compare representative character screenshots against Flash.
  - Default outfit.
  - Outfit with primary and secondary color changes.
  - Hat/head/body/feet mix.
  - Known tricky parts such as cheese hat and Fred/body-specific placement.

Acceptance for this section:

- Character customization works in the OpenFL harness.
- Common outfits look close enough to Flash for gameplay work.
- Character animation state switching remains compatible with the MovieClip
  runtime.

## Remaining Asset Migration

These assets matter for visual completeness, but most can happen after the
local playable harness has placeholder rendering.

- [ ] Export and rasterize non-character vector art.
  - Generate JSFL:
    ```sh
    python3 tools/generate_other_assets_jsfl.py
    ```
  - Run in Animate:
    ```sh
    "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-other-assets-svg.jsfl
    ```
  - Rasterize categories after SVGs are committed:
    ```sh
    python3 tools/rasterize_vector_art.py --sheets --category backgrounds --manifest vector-art/raster-manifest-backgrounds.json
    python3 tools/rasterize_vector_art.py --sheets --category stamps --manifest vector-art/raster-manifest-stamps.json
    python3 tools/rasterize_vector_art.py --sheets --category effects --manifest vector-art/raster-manifest-effects.json
    python3 tools/rasterize_vector_art.py --sheets --category items --manifest vector-art/raster-manifest-items.json
    ```
- [ ] Export block bitmap tiles.
  - Generate JSFL:
    ```sh
    python3 tools/generate_block_bitmap_jsfl.py
    ```
  - Run in Animate:
    ```sh
    "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-block-bitmaps.jsfl
    ```
  - Output target: `vector-art/png/blocks/`.
- [ ] Decide which asset families become runtime atlases.
  - Blocks/items/effects likely benefit from atlases.
  - Large backgrounds should probably stay as standalone images.
  - UI assets can be grouped later by screen or feature.

Acceptance for this section:

- Needed gameplay assets are available from committed files.
- The browser build can load them without Adobe Animate.
- Asset regeneration commands are documented and reproducible.

## AS3 To Haxe Porting Track

Port only what the playable milestones need first. Avoid broad mechanical ports
that do not compile into a useful screen.

- [ ] Establish minimal compatibility shims.
  - Timing helpers.
  - Keyboard/mouse input wrappers.
  - Basic event dispatch differences.
  - Asset lookup helpers.
- [ ] Port gameplay-facing data classes.
  - Constants/stat defaults.
  - Level fixture models.
  - Block type definitions.
  - Character state model.
- [ ] Port display classes as needed by the harness.
  - Character display wrapper.
  - Block display wrapper.
  - Minimal game page/container.
- [ ] Defer full UI shell until gameplay harness works.
  - Login.
  - Lobby.
  - Level browser.
  - Editor.
  - Full customization UI.

Acceptance for this section:

- New ported classes compile.
- Each ported class is exercised by the harness, tests, or asset pipeline.
- Flash/OpenFL differences stay isolated behind wrappers.

## Level Loading And Rendering

- [ ] Inventory real PR2 level payload format.
  - Course data fields.
  - Block grid data.
  - Background/stamp/draw/text object data.
  - Settings and game modes.
- [ ] Build local fixture loader first.
  - Flat level.
  - Blocks-only showcase.
  - Special block showcase when interactions are ready.
- [ ] Add real level parser after fixture renderer works.
  - Parse saved/server payloads.
  - Handle malformed data.
  - Load at least one known real level into the renderer.
- [ ] Expand rendering coverage.
  - Backgrounds.
  - Stamps/draw objects.
  - Text objects.
  - Minimap if required for gameplay.

Acceptance for this section:

- Fixture levels render correctly.
- At least one real level can be loaded and displayed without gameplay parity.

## Gameplay Expansion

After the flat fixture is playable, add mechanics in small testable batches.

- [ ] Special block interactions.
  - Ice.
  - Water.
  - Crumble.
  - Vanish.
  - Mine.
  - Teleport.
  - Item blocks.
  - Move/rotate blocks.
  - Custom stats.
- [ ] Items.
  - Sword.
  - Laser gun.
  - Mine.
  - Jet pack.
  - Super jump.
  - Speed burst.
  - Ice wave.
  - Teleport.
  - Lightning.
- [ ] Movement edge cases.
  - Swimming.
  - Bumping/recovery.
  - Frozen state.
  - Moving/rotating block collisions.
  - Corner cases.

Acceptance for this section:

- Each mechanic has a fixture level.
- Debug state exposes enough information to compare behavior.
- Common movement feels close to Flash.

## Networking And Real Server Flow

Do not block local gameplay on this, but keep it moving because browser
deployment depends on server/proxy compatibility.

- [ ] Add server-side WebSocket support in the server repo.
  - Same-origin paths such as `/servers/<server_name>`.
  - Preserve existing PR2 command payload semantics.
  - Production endpoint should be `wss://...`.
- [ ] Build a minimal OpenFL networking spike.
  - Request server list or a harmless endpoint.
  - Connect to a configured WebSocket URL.
  - Parse at least one real response.
- [ ] Add safe local configuration.
  - No credentials committed.
  - Ignored local config or environment variables if needed.
- [ ] Port real flow after local harness is useful.
  - Login.
  - Server selection.
  - Lobby.
  - Level browser.
  - Load one real level.

Acceptance for this section:

- Browser build can reach a real server path through WebSocket.
- At least one real response is parsed.
- Login feasibility is known before full UI porting.

## Testing

- [ ] Generalize `tools/pr2driver.py`.
  - Keep Flash backend.
  - Add browser/OpenFL backend.
  - Common sequence format for launch, click, tap, hold, wait, screenshot.
  - Normalize captures to 550x400.
- [ ] Add screenshot comparison.
  - Pixel/perceptual diff.
  - Ignored regions for live data and blinking UI.
  - Store expected, actual, and diff images.
- [ ] Add debug-state comparison for OpenFL.
  - Movement state.
  - Current level/fixture state.
  - Current character appearance state.
- [ ] Keep deterministic and real-server tests separate.
  - Fixture tests verify parity.
  - Real-server tests verify connectivity and broad behavior only.

Initial suites:

- [ ] `harness-boot`
- [ ] `character-customization`
- [ ] `level-load-flat`
- [ ] `run-right`
- [ ] `jump`
- [ ] `crouch`
- [ ] `finish-race`
- [ ] `real-server-connect`

Acceptance for this section:

- One command can run a useful scripted sequence against OpenFL.
- Failures produce screenshots and debug output that are easy to inspect.

## Later Work

- [ ] Sound and music.
  - Extract/import sound assets.
  - Port `SoundEffects`.
  - Handle browser autoplay restrictions.
- [ ] Full UI polish.
  - Login shell.
  - Lobby.
  - Level browser.
  - Customization UI.
  - Editor shell if needed.
- [ ] Performance and compatibility.
  - Profile browser rendering.
  - Optimize after behavior works.
  - Test Chrome, Firefox, Safari, mobile Safari, and Android Chrome.
  - Watch memory across repeated level loads.
- [ ] Mobile targets.
  - Responsive browser wrapper.
  - Touch controls.
  - Android build.
  - iOS build.
- [ ] Release readiness.
  - Production build command.
  - Asset cache/versioning.
  - Loading/error screens.
  - Server/proxy docs.
  - Public test build.
