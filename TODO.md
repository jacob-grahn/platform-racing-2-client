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
  - Browser client must use the gameserver WebSocket endpoint instead of raw
    TCP.
  - Raw TCP PR2 sockets cannot be opened directly from browser OpenFL.

## Current Priority: Get A Local Playable Harness

This is the shortest path to a working port. Keep it local and deterministic
until movement, rendering, and fixture loading are debuggable.

- [x] Add a gameplay harness mode reachable from `Main`.
  - It can launch directly for development.
  - It should not require login, lobby, server data, or real level loading.
  - It should keep the logical 550x400 stage.
- [x] Define a tiny fixture level format.
  - Blocks with tile coordinates and block type.
  - Player start position.
  - Finish position.
  - Gravity/stat defaults.
  - One committed flat-level fixture.
- [x] Render the fixture level.
  - Draw basic solid blocks, start, and finish.
  - Use generated/raster block assets if ready; otherwise use clear temporary
    colored blocks and keep the renderer replaceable.
  - Preserve PR2 scale and coordinates.
- [x] Port minimum local character movement.
  - Current implementation uses Flash-derived `LocalCharacter` land physics for
    basic solid blocks: foot-center coordinates, target velocity/friction,
    jump hold, crouch charge, grounded checks, wall hits, and ceiling bumps.
  - Fixed 27 FPS update step.
  - Left/right acceleration.
  - Gravity.
  - Jump.
  - Down/crouch.
  - Grounded state.
  - Collision against basic solid tiles.
- [x] Add deterministic debug state export.
  - Position.
  - Velocity.
  - Grounded/crouching state.
  - Current animation/state name.
  - Touched block type.
- [x] Add one scripted movement verification.
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

- [x] Decide how the character atlas metadata enters Haxe.
  - Option A: load atlas JSON directly at runtime.
  - Option B: convert atlas JSON into generated Haxe metadata.
  - Chosen path: load atlas JSON directly at runtime through
    `pr2.character.CharacterAtlas`.
- [x] Add character atlas PNGs to OpenFL assets.
  - Include `vector-art/atlases/character/**/*.png`.
  - Include atlas JSON if loading directly.
- [x] Implement a small atlas frame loader.
  - Read `frame` rectangles.
  - Read `sourceTrim`.
  - Preserve part id, kind, channel, page, and scale.
- [x] Render one known part from the atlas.
  - Start with `hat/002_exp`; it previously exposed negative-coordinate SVG
    behavior.
  - Confirm placement matches the existing generated MovieClip composition well
    enough to continue.
  - Implemented `CharacterAtlasFrameSprite`, which crops the frame from the
    atlas PNG and applies `sourceTrim` at atlas scale so negative source
    coordinates are preserved; the gameplay harness renders `hat/002_exp` over
    the local player placeholder.
- [ ] Render one full customizable character.
  - Static, primary, and secondary layers remain separate.
  - Primary and secondary layers can be tinted independently.
  - Composite layer remains available for preview/debug/fallback.
  - In progress: `CharacterDisplay` uses the generated `CharacterGraphic`
    timelines as the animation skeleton for run, stand, jump, super jump,
    bumped, crouch, crouch-walk, swim, and frozen states, then renders
    atlas-backed hat/head/body/feet static, primary, and secondary layers into
    the named part slots. It also has an explicit composite render mode for
    fallback/debug preview, and the gameplay harness can toggle it with `C`.
    Representative outfits can also be selected from the browser query string
    for screenshot capture, for example
    `hat=16&head=37&body=29&feet=40&primary=aa00ff&secondary=00cc11&render=composite`.
  - Remaining: add Flash screenshot comparisons for representative outfits.
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

- [x] Export and rasterize non-character vector art.
  - Generate JSFL:
    ```sh
    python3 tools/generate_other_assets_jsfl.py
    ```
  - Run in Animate:
    ```sh
    "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-other-assets-svg.jsfl
    ```
  - Rasterize exported categories:
    ```sh
    python3 tools/rasterize_vector_art.py --sheets --category backgrounds --category stamps --category effects --category items --manifest vector-art/raster-manifest-other.json
    ```
  - Exported: 7 backgrounds, 8 stamps, 10 effect symbols, and 10 item icons.
  - Effect animations are not baked as per-frame SVG sequences; the Haxe
    timeline runtime should drive animation from symbol/timeline metadata.
- [x] Export block bitmap tiles.
  - Generate JSFL:
    ```sh
    python3 tools/generate_block_bitmap_jsfl.py
    ```
  - Run in Animate:
    ```sh
    "/Applications/Adobe Animate 2024/Adobe Animate 2024.app/Contents/MacOS/Adobe Animate 2024" vector-art/export-block-bitmaps.jsfl
    ```
  - Output target: `vector-art/png/blocks/`.
- [x] Decide initial runtime atlas grouping.
  - Stamps and item display icons are atlased.
  - Large backgrounds and timeline-driven effect symbols stay standalone.
  - Block bitmaps stay as direct PNG tiles for now.
  - UI assets can be grouped later by screen or feature.

Acceptance for this section:

- Needed gameplay assets are available from committed files.
- The browser build can load them without Adobe Animate.
- Asset regeneration commands are documented and reproducible.

Follow-up asset coverage audit:

- [ ] Export gameplay block overlays and block-piece graphics not covered by
  block bitmap tiles.
  - `ArrowBlockGraphic`
  - `EggBlockGraphic`
  - `Arrow2Graphic`
  - `BrickPieceGraphic`
  - `CrumblePieceGraphic`
  - `StartBlockText`
- [ ] Export remaining gameplay/item effect symbols as reusable timeline-driven
  assets, not per-frame SVG sequences.
  - `CountdownGraphic`
  - `EggGraphic`
  - `HeartGraphic`
  - `IceWaveGraphic`
  - `DjinnIceGraphic`
  - `PR2_Graphics_1_Apr_2014_fla.jetPackStates_47`
  - `PR2_Graphics_1_Apr_2014_fla.swordAnim_53`
  - `PR2_Graphics_1_Apr_2014_fla.gunFireAnim_40`
  - `PR2_Graphics_1_Apr_2014_fla.iceWaveFireAnim_55`
  - `PR2_Graphics_1_Apr_2014_fla.superJumpAnim_60`
  - `PR2_Graphics_1_Apr_2014_fla.jumpAnim_61`
  - `PR2_Graphics_1_Apr_2014_fla.bumpedAnim_59`
  - `PR2_Graphics_1_Apr_2014_fla.frozenSolidAnim_65`
- [ ] Export in-game HUD/page graphics once the playable harness needs them.
  - `FinishedPageGraphic`
  - `ExpGainGraphic`
  - `DrawingInfoGraphic`
  - `StatsDisplayGraphic`
  - `RaceChatGraphic`
  - `MiniMapGraphic`
  - `MiniMapDot`
  - `PrizePopupGraphic`
  - `QuitButtonGraphic`
  - `MusicSelectionGraphic`
- [ ] Export editor/lobby/menu graphics by screen as those screens are ported.
  - Initial candidates: `LevelEditorMenuGraphic`, `DrawingPopupGraphic`,
    `HatPickerGraphic`, `LobbyGraphic`, `LobbyBottomButtonsGraphic`,
    `PlayersTabListGraphic`, `GetLevelsPopupGraphic`, and `StorePopupGraphic`.
- [x] Decide how to handle intro/logo animations.
  - Intro/logo MovieClips are driven by the `PR2MovieClip` timeline runtime,
    not baked per-frame sequences. The Flash page system is ported under
    `pr2.page` (`Page`, `PageHolder`, `IntroPage`, stub `LoginPage`), and
    `IntroPage` reproduces the original `menu.IntroPage` flow: queue intros by
    site mode, play each one, reproduce its final-frame `COMPLETE` frame
    script with `setFrameScript`, click-to-skip, then transition to login.
  - `JiggminIntroGraphic` renders well; its wordmark is the bundled
    `assets/blocks/jiggmin_logo.png` bitmap injected into `logo.logo_mc` (the
    original `PixelEffect1` pixel dissolve is not ported yet).
  - `KongregateIntroGraphic` is wired and plays/transitions correctly but
    renders blank: its logo is the unexported `bitmap379.jpg` plus nested
    vector pieces the renderer does not handle yet. See the bitmap audit below.
  - `ArmorIntroGraphic` / `BubbleBoxIntroGraphic` are reachable by site mode
    but unverified.
  - Remaining: port `com.jiggmin.pixelEffects.PixelEffect1` for the Jiggmin
    dissolve; export/render the Kongregate intro art.
- [ ] Audit the five unexported bitmap media entries.
  - 31 bitmap items exist in the XFL; 26 block tile bitmaps are exported.
  - `Images/bitmap379.jpg` exists as a normal XFL image file and appears to be
    the Kongregate logo.
  - `Images/bitmap1249.png`, `Images/bitmap371.png`,
    `Images/bitmap386.png`, and `Images/bitmap97.jpg` are referenced as
    embedded bitmap payloads but do not exist as normal files under
    `LIBRARY/Images/`.
- [ ] Keep broad Flash component skins and low-priority UI linkage symbols out
  of early gameplay batches unless a ported screen depends on them.
  - The latest audit found 258 non-character linkage-exported symbols not
    exported as standalone assets yet: 3 `backgrounds`, 8 `blocks`,
    41 `components`, 10 `items_effects`, 144 `ui`, and 52 `uncategorized`.

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

### Server Campaign Level Test Harness

A second, more complex test (beyond the hardcoded flat fixture): fetch a real
campaign level list from the PR2 server, load the first level, render it, and
drop our character in. Built incrementally — reachable via `?screen=campaign`.

Server pipeline confirmed from the Flash source:

- Campaign list: `GET https://pr2hub.com/files/lists/campaign/{page}` returns
  JSON `{levels:[{level_id, version, title, ...}], hash}`. The Flash client
  validates `hash == MD5(ret.substr(10, len-53) + LEVEL_LIST_SALT)`
  (`LEVEL_LIST_SALT = "984cn98c54$"`). `page = ((server_id + day) % 6) + 1` in
  Flash; we can just pick a fixed page for the test.
- Level data: `GET https://pr2hub.com/levels/{id}.txt?version={v}` returns
  `levelData + 32charMD5`. Validate
  `MD5(version + id + levelData + LEVEL_SALT_2)` (`LEVEL_SALT_2 = "0kg4%dsw"`).
- `levelData` is `&`-joined URL-encoded vars (`data`, `title`, `gravity`,
  `max_time`, `items`, `song`, `gameMode`, ...). Pass through
  `validateSaveString` (whitelist of allowed params) first.
- The `data` field is backtick-delimited. `data[0]` = read mode (`m1`..`m4`),
  `data[1]` = encoded block string. Block string is relative-coordinate; decode
  per `decodeLevelData`/`decodeObjectString`/`decodeObjectString2`/
  `decodeBlockString` in `flash/page/GamePage.as` into
  `o{blockCode};{x};{y};{opts}` tokens at pixel coords (segSize 30). Block codes
  100-132 map to block types (`flash/com/jiggmin/data/Objects.as`).

Bits (take one at a time):

- [ ] Bit 1 — Networking + campaign list fetch.
  - Async text loader over `openfl.net.URLLoader` (maps to XHR on html5).
  - Server config: base/levels URLs and salts.
  - `CampaignListClient`: fetch page, validate list hash, parse into
    `CampaignLevelInfo` entries.
  - `?screen=campaign` shows fetch status + first level title/id/version.
- [x] Bit 2 — Fetch + verify raw level data for the first level.
  - `LevelDataClient`: split trailing 32-char hash, validate
    `MD5(version+id+levelData+LEVEL_SALT_2)`, run `validateSaveString`, parse
    the `&`-joined vars into `ServerLevelData` (exposes title/gravity/max_time/
    items/gameMode + the raw `data` blob and read mode).
  - Verified on real data (level 50815 "Newbieland 2"): hashValid=true, mode m3,
    dataLen 22234, 8 items. Unit test covers the `validateSaveString` "and"
    round-trip + hash mismatch (`LevelDataClientTest`, 13 assertions).
- [x] Bit 3 — Decode the block string (modes m1-m4) into a block list.
  - `ServerLevelDecoder` ports `decodeLevelData` + `decodeObjectString`/
    `decodeObjectString2`/`decodeBlockString`; emits `DecodedBlock{code, x, y,
    opts}` at absolute pixel coords into a `ServerLevel` (bg color + bounds +
    start/finish helpers). `ObjectCodes` ports the 100-132 block codes and the
    `<100 -> +100` resolution.
  - Verified on real data (level 50815): 516 blocks, bg 0xE0C8B8, 4 starts +
    1 finish, bounds 10530x1650px — byte-identical to an independent Python
    reference port. Unit test covers m1/m2/m3/m4 + bad mode
    (`ServerLevelDecoderTest`, 31 assertions).
  - Art/draw/text layers (the other backtick sections) still deferred to Bit 4.
- [ ] Bit 4 — Render the decoded server level.
  - Pixel coords, background color, map block codes to block art assets.
  - Camera/scale so the level fits or scrolls.
- [ ] Bit 5 — Place the character into the loaded level.
  - Spawn `CharacterDisplay` at the start block (code 111); reuse harness
    wiring; collision against decoded blocks if practical.
- [x] Cross-cutting — CORS / cross-origin access to pr2hub.com.
  - Confirmed: pr2hub.com sends no `Access-Control-Allow-Origin`, so a browser
    cannot read its responses cross-origin.
  - Resolved for dev: `tools/dev_proxy.py` serves the build and proxies
    `/api/* -> https://pr2hub.com/*` same-origin; `ServerConfig` host is
    configurable via `?apiHost=/api`. Verified the proxy returns the list and a
    level txt (id 50815 "Newbieland 2") with HTTP 200.
  - Still open for production: a real deploy needs either a server-side proxy
    or CORS on the level host. Not needed for the local test harness.

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
deployment depends on the real gameserver flow.

- [x] Add server-side WebSocket support in the server repo.
  - The multiplayer server now sniffs raw vs WebSocket connections on the
    transport and feeds both into the same PR2 command buffer.
  - The browser port can reuse the PR2 socket protocol code closely; only the
    browser transport changes from raw TCP to WebSocket frames.
  - Production endpoint should still be `wss://...`.
- [ ] Build a minimal OpenFL networking spike.
  - Request server list or a harmless endpoint.
  - Connect to a configured WebSocket URL.
  - Send the normal `request_login_id` command with the existing PR2
    `chr(0x04)` message delimiter.
  - Parse `setLoginID` from a real response.
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
  - [x] Add browser/OpenFL sequence support for `keyDown`, `keyUp`, `tap`,
    `hold`, `debug-state`, and `shot` actions in one browser session.
  - [ ] Common sequence format for Flash and OpenFL launch/click/tap/hold/wait/screenshot actions.
  - [x] Normalize OpenFL sequence captures to 550x400.
- [x] Add screenshot comparison.
  - `tools/compare_screenshots.py` compares PNG/JPEG screenshots with RGB
    pixel metrics, repeated ignored rectangles, threshold failures, amplified
    diff PNG output, and JSON metrics output.
- [x] Add debug-state comparison for OpenFL.
  - `tools/openfl_driver.py debug-state` reads `data-pr2-debug-state`
    through Chrome DevTools after a configurable delay.
  - Repeated `--expect key=value` checks validate movement state, current
    level/fixture state, and current character appearance/render state.
- [ ] Keep deterministic and real-server tests separate.
  - Fixture tests verify parity.
  - Real-server tests verify connectivity and broad behavior only.

Initial suites:

- [x] `harness-boot`
- [x] `character-customization`
- [ ] `intro-flow` (Jiggmin renders; verify via `data-pr2-intro-state` and
  click-to-skip; Kongregate render pending its art)
- [ ] `level-load-flat`
- [x] `run-right`
- [x] `jump`
- [x] `crouch`
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
  - Gameserver WebSocket deployment docs.
  - Public test build.
