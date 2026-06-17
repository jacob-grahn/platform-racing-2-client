# Platform Racing 2 Haxe/OpenFL Port TODO

Working roadmap for porting the original Flash Platform Racing 2 client to a
Haxe/OpenFL browser build. The end goal is a faithful reproduction of the
original game — matching gameplay/physics timing, level and character behavior,
and visuals — not a loose remake. Keep this file focused on what moves the port
forward; command references belong in `README.md`, and asset-pipeline details in
`docs/vector-art-export-plan.md`.

## Direction

- End goal: a faithful port of the original Flash game. Same physics/timing,
  same level and character behavior, visuals that match the original. Pixel-level
  parity is pursued through the Flash-vs-OpenFL comparison harnesses (screenshots
  + debug state), not judged by eye.
- Primary target: browser/HTML5 with Haxe + OpenFL. Secondary: Android and iOS
  after browser parity.
- Strategy: build the smallest playable, deterministic harness first, then grow
  fidelity outward (more blocks, items, real levels, real server). Approximate
  visuals are acceptable as intermediate milestones, but every approximation is
  a tracked gap to close, not the destination.
- Normal development and CI must not require Adobe Animate; it is only a
  migration tool for regenerating source assets.
- Testing order: deterministic fixture runs, then Flash/OpenFL screenshot and
  debug-state comparisons, then real-server checks.

## Current Focus

The local playable harness is done. The faithful-port path from here:

1. Verify character rendering against Flash — finish the full customizable
   character and add the screenshot comparisons (Character Rendering section).
2. Continue real server-level support — render coverage now includes the decoded
   block layer with the character placed at the first start block, and decoded
   blocks now feed local movement/collision with first-pass ice/arrow behavior;
   next is remaining special block behavior and dynamic level choice.
3. Automate the renderer-vs-PNG diff to lock in vector fidelity (Vector
   Renderer section).

## Completed So Far

Foundation:
- Project/scope baseline: 550x400 stage at 27 FPS; OpenFL skeleton
  (`project.xml`, `haxe/src/`, `haxelib run openfl test html5`); scope in
  `docs/initial-playable-scope.md`.
- XFL asset pipeline: `tools/xfl_metadata.py` + `tools/generate_haxe_assets.py`
  produce the generated `pr2.generated.assets` catalog (988 symbols, 67 media
  items, 11511 timeline frames).
- MovieClip runtime: `AssetLibrary` + `PR2MovieClip` drive nested timelines,
  labels, playback, frame scripts, transforms, visibility, and named children,
  with runtime tests.
- Adobe Animate JSFL invocation verified for regenerating source assets.
- Browser networking constraint documented: must use the gameserver WebSocket
  endpoint; raw TCP sockets are not openable from browser OpenFL.

Local playable harness:
- Gameplay harness reachable from `Main`, no login/lobby/server needed, logical
  550x400 stage.
- Tiny fixture level format (block tile coords + type, start, finish,
  gravity/stat defaults) with one committed flat fixture, rendered with basic
  blocks/start/finish at PR2 scale.
- Flash-derived `LocalCharacter` land physics at a fixed 27 FPS step: run,
  gravity, jump (hold), crouch/charge, grounded checks, wall/ceiling hits, and
  solid-tile collision.
- Deterministic debug-state export (position, velocity, grounded/crouch, state
  name, touched block) plus scripted run/jump/land verification.

Character rendering (foundation; remaining work below):
- Character atlas metadata loads at runtime via `pr2.character.CharacterAtlas`;
  atlas PNGs/JSON bundled; frame loader reads frame rects + `sourceTrim`
  preserving part id/kind/channel/page/scale.
- `CharacterAtlasFrameSprite` renders atlas parts (negative source coords
  preserved).
- `CharacterDisplay` uses generated `CharacterGraphic` timelines as the
  animation skeleton (run, stand, jump, super jump, bumped, crouch, crouch-walk,
  swim, frozen) and renders atlas-backed hat/head/body/feet static/primary/
  secondary layers into named slots, with a composite fallback/debug mode (`C`
  to toggle) and query-string outfit selection.

Vector renderer (remaining work below):
- Translates XFL `DOMShape` edges/styles to OpenFL `Graphics`. Done: hex
  fixed-point coords (`#13.FB`); fill-edge stitching into closed contours
  (reversing `fillStyle1`); linear/radial gradient fills with correct
  XFL->OpenFL gradient-matrix conversion; `DOMRectangleObject`/`DOMOvalObject`
  primitives; and the `cubics`/`/`/`]` resolution — cubics proven redundant and
  dropped at extraction (catalog shrank ~12.8MB->10.0MB), `/` and `]` handled as
  line/quad.

Asset migration:
- Exported + rasterized non-character vector art (7 backgrounds, 8 stamps, 10
  effect symbols, 10 item icons) and block bitmap tiles into `vector-art/png/`.
- Runtime atlas grouping decided: stamps + item icons atlased; large
  backgrounds and timeline-driven effects standalone; block bitmaps as direct
  PNG tiles.
- Intro/logo approach decided: intros run on the `PR2MovieClip` timeline
  runtime. Flash page system ported under `pr2.page` (`Page`, `PageHolder`,
  `IntroPage`, stub `LoginPage`); `IntroPage` reproduces the original site-mode
  intro queue, final-frame `COMPLETE` script, click-to-skip, and login
  transition. `JiggminIntroGraphic` renders (Kongregate/Armor/BubbleBox remain).

Server level harness:
- `LevelDataClient` fetches + verifies a level
  (`MD5(version+id+levelData+salt)`, `validateSaveString`) into
  `ServerLevelData`; verified on level 50815.
- `ServerLevelDecoder` decodes the block string (modes m1-m4) into absolute
  pixel-coord `DecodedBlock`s + `ServerLevel`; `ObjectCodes` ports block codes
  100-132. Verified byte-identical to a Python reference (516 blocks).
- `ServerLevelRenderer` renders a decoded server level's block layer at original
  PR2 30 px scale using the committed Flash-derived block bitmap tiles, cameras
  around the first start block, and places a layered `CharacterDisplay` there.
- `ServerLevelFixtureAdapter` normalizes decoded server coordinates into a
  `FixtureLevel` so `LocalPlayerController` can move through real level
  geometry; the campaign screen accepts keyboard input against this converted
  collision state.
- `LocalPlayerController` now preserves server block identities for ice and
  directional arrows and applies their AS3 stand/bump/side-hit movement effects
  in deterministic tests.
- Dev CORS proxy `tools/dev_proxy.py` serves the build and proxies
  `/api/* -> pr2hub.com` same-origin (`?apiHost=/api`).

Networking + tooling:
- Server repo accepts WebSocket connections alongside raw TCP into the same PR2
  command buffer (production stays `wss://`).
- `tools/openfl_driver.py` drives the browser build (keyDown/keyUp/tap/hold/
  debug-state/shot, normalized to 550x400); `tools/compare_screenshots.py`
  scores PNG/JPEG diffs; debug-state `--expect` checks. Passing suites:
  `harness-boot`, `character-customization`, `run-right`, `jump`, `crouch`.

## Character Rendering — Remaining

Keep character rendering in service of the playable harness and faithful
appearance, not an open-ended art project.

- [ ] Finish one full customizable character.
  - Separate static/primary/secondary layers; independent primary/secondary
    tinting; composite layer kept for preview/debug/fallback.
  - Remaining: verify against Flash for representative outfits.
- [ ] Compare representative character screenshots against Flash.
  - Default outfit; primary + secondary color change; hat/head/body/feet mix;
    known tricky parts (cheese hat, Fred/body-specific placement).

Acceptance: customization works in the harness; common outfits match Flash
closely; animation-state switching stays compatible with the MovieClip runtime.

## Vector Renderer — Remaining

`pr2.runtime.VectorShapeRenderer` translates XFL `DOMShape` edges/styles into
OpenFL `Graphics` calls (OpenFL rasterizes). Reference: edge coords are raw XFL
twips / 20 = px (DPI-independent); commands `!` moveTo, `|`/`/` lineTo, `[`/`]`
quadTo, coords decimal or hex fixed-point (`#13.FB`). Ruffle/`xfl2svg` are
algorithm references only. The raster asset path remains the fallback for any
symbol the renderer cannot yet reproduce faithfully.

Comparison harness (done): `?screen=symbol&symbol=<name>&scale=4&bg=FFFFFF`
renders one symbol through the vector path (`pr2.page.SymbolPreview`); capture
with `tools/openfl_driver.py` and compare to the Adobe `@4x.png` under
`vector-art/png/`. Good test symbol: `UI/Global/MuteButton`.

- [x] Automate the renderer-vs-PNG diff.
  - `tools/compare_symbol_render.py` renders each case symbol through the
    `?screen=symbol` vector path (real-time DevTools capture — the symbol screen
    loads its catalog asynchronously, so the virtual-time `shot` path only ever
    grabs the preloader), trims it to its content box, resizes to the reference
    raster, and scores `rmsDelta` / `differingPercent`. Render scale auto-fits
    the stage from the reference `@4x` size so large symbols are not clipped, so
    the score is scale-independent and deterministic. Cases + per-case thresholds
    live in `tools/symbol_render_cases.json` (MuteButton, tree1, rock1).
  - `rmsDelta` is the gate; `differingPercent` is report-only (gradient/anti-alias
    diffs keep it near 100% even for faithful renders). MuteButton's gradient
    panel matches well (rms ~13); the stamps still expose real fill/contour gaps
    (rock1 misses a highlight, tree1's right silhouette differs) with looser
    baseline thresholds to tighten as the renderer improves.

Remaining gap: close the stamp fill/contour differences so their thresholds can
tighten toward the leaf-symbol level.

Acceptance (met for scoring; renderer fidelity still improving): simple line+fill
leaf symbols render close enough to their Adobe PNGs to use without the raster
fallback; linear/radial gradients render recognizably; the harness can score a
symbol against its PNG.

## Asset Migration — Remaining

These widen visual coverage toward parity; most can follow the playable harness.
Regeneration commands live in `README.md` / `docs/vector-art-export-plan.md`.

- [ ] Export block overlays / block-piece graphics not covered by tile bitmaps:
  `ArrowBlockGraphic`, `EggBlockGraphic`, `Arrow2Graphic`, `BrickPieceGraphic`,
  `CrumblePieceGraphic`, `StartBlockText`.
- [ ] Export remaining gameplay/item effect symbols as timeline-driven assets
  (not per-frame SVG): `CountdownGraphic`, `EggGraphic`, `HeartGraphic`,
  `IceWaveGraphic`, `DjinnIceGraphic`, and the `PR2_Graphics_..._fla`
  jetpack/sword/gunfire/iceWave/superJump/jump/bumped/frozenSolid anims.
- [ ] Export in-game HUD/page graphics when the harness needs them:
  `FinishedPageGraphic`, `ExpGainGraphic`, `DrawingInfoGraphic`,
  `StatsDisplayGraphic`, `RaceChatGraphic`, `MiniMapGraphic`, `MiniMapDot`,
  `PrizePopupGraphic`, `QuitButtonGraphic`, `MusicSelectionGraphic`.
- [ ] Export editor/lobby/menu graphics per screen as those screens are ported:
  `LevelEditorMenuGraphic`, `DrawingPopupGraphic`, `HatPickerGraphic`,
  `LobbyGraphic`, `LobbyBottomButtonsGraphic`, `PlayersTabListGraphic`,
  `GetLevelsPopupGraphic`, `StorePopupGraphic`.
- [ ] Finish the intro animations: render the Kongregate intro art (its logo is
  `bitmap379.jpg` plus nested vector pieces), and verify Armor/BubbleBox intros.
  `com.jiggmin.pixelEffects.PixelEffect1` (the Jiggmin pixel dissolve) is ported,
  wired into `IntroPage`, and covered by `pr2.effects.PixelEffect1Test`.
- [ ] Resolve the five unexported bitmap media entries.
  - `Images/bitmap379.jpg` is a normal XFL image (likely the Kongregate logo).
  - `bitmap1249.png`, `bitmap371.png`, `bitmap386.png`, `bitmap97.jpg` are
    referenced as embedded payloads but absent under `LIBRARY/Images/`.
- [ ] Leave broad Flash component skins / low-priority UI linkage symbols (258
  audited: 3 backgrounds, 8 blocks, 41 components, 10 items_effects, 144 ui, 52
  uncategorized) until a ported screen needs them.

Acceptance: needed assets ship from committed files; the browser build loads
them without Animate; regeneration is documented and reproducible.

## AS3 -> Haxe Porting Track

Port only what milestones need; avoid mechanical ports that don't compile into a
useful screen. Keep Flash/OpenFL differences behind wrappers so behavior stays
faithful to the original AS3.

- [ ] Minimal compatibility shims: timing, keyboard/mouse input, event-dispatch
  differences, asset lookup.
- [ ] Gameplay-facing data classes: constants/stat defaults, level fixture
  models, block-type definitions, character state model.
- [ ] Display wrappers as the harness needs them: character, block, minimal
  game page/container.
- [ ] Defer the full UI shell (login, lobby, level browser, editor, full
  customization UI) until the gameplay harness is useful.

Acceptance: ported classes compile, are exercised by harness/tests/pipeline, and
keep Flash/OpenFL differences isolated.

## Level Loading And Rendering

- [ ] Inventory the real PR2 level payload format: course fields, block grid,
  background/stamp/draw/text objects, settings and game modes.
- [ ] Build the local fixture loader first (flat, blocks-only showcase, special
  blocks once interactions exist).
- [ ] Add the real level parser after the fixture renderer works: parse
  saved/server payloads, handle malformed data, load one known real level.
- [ ] Expand rendering coverage: backgrounds, stamps/draw objects, text objects,
  minimap if needed.

Acceptance: fixture levels render correctly; at least one real level loads and
displays (without gameplay parity yet).

### Server Campaign Level Test Harness

Fetch a real campaign level from pr2hub.com, render it, and drop the character
in. Reachable via `?screen=campaign`; built in bits. Bits 2 and 3 and the CORS
dev proxy are done (see Completed).

Server pipeline (confirmed from Flash source; salts/URLs the open bits need):
- Campaign list: `GET pr2hub.com/files/lists/campaign/{page}` -> JSON
  `{levels:[...], hash}`, `hash == MD5(ret.substr(10,len-53) + "984cn98c54$")`;
  `page = ((server_id + day) % 6) + 1` (a fixed page is fine for the test).
- Level data: `GET pr2hub.com/levels/{id}.txt?version={v}` -> `levelData +
  32char MD5`, validate `MD5(version+id+levelData+"0kg4%dsw")`; `levelData` is
  `&`-joined URL-encoded vars run through `validateSaveString`. `data` is
  backtick-delimited: `data[0]` read mode `m1`-`m4`, `data[1]` block string
  (relative coords, segSize 30; codes 100-132 from `Objects.as`).

- [ ] Bit 1 — Networking + campaign list fetch.
  - Async text loader over `openfl.net.URLLoader` (XHR on html5); server config
    (URLs + salts); `CampaignListClient` fetch/validate/parse into
    `CampaignLevelInfo`; `?screen=campaign` shows first level title/id/version.
- [ ] Bit 4 — Render the decoded server level.
  - Pixel coords + background color; map block codes to block art; camera/scale
    so the level fits or scrolls.
- [ ] Bit 5 — Place the character in the loaded level.
  - Spawn `CharacterDisplay` at the start block (code 111); reuse harness
    wiring; collide against decoded blocks if practical.
- [ ] Production CORS: a real deploy needs a server-side proxy or CORS on the
  level host (not needed for the local harness).

## Gameplay Expansion

Add mechanics in small, testable batches after the flat fixture is playable.
Each should match original PR2 behavior, verified via debug state / comparison.

- [ ] Special block interactions: ice, water, crumble, vanish, mine, teleport, and item blocks done (water enters/exits the
  `LocalCharacter.waterGo` swim mode with the AS3 paddle/damping/exit-boost
  constants; crumble uses AS3-style force/life removal in the local harness;
  vanish fades out after contact, becomes inactive, and reappears after its
  Flash delay once unoccupied; mine applies AS3 radial knockback and removes
  itself on contact; teleport groups blocks by color, moves to the next same-color
  block, and applies the Flash 3000 ms color cooldown; item blocks use the
  Flash `SupplyBlock` bump hook, support single-use/infinite supply types, and
  expose the granted item id in debug state); remaining: move/rotate blocks,
  custom stats.
- [ ] Items: sword, laser gun, mine, jet pack, super jump, speed burst, ice
  wave, teleport, lightning.
- [ ] Movement edge cases: swimming done (water `mode` switch in
  `LocalPlayerController`, swim animation + `mode` in debug state, deterministic
  tests); remaining: bumping/recovery, frozen state, moving/rotating block
  collisions, corner cases.

Acceptance: each mechanic has a fixture level; debug state exposes enough to
compare behavior; common movement feels like Flash.

## Networking And Real Server Flow

Don't block local gameplay on this, but keep it moving — browser deployment
depends on the real gameserver flow. (Server-side WebSocket support is done.)

- [ ] Minimal OpenFL networking spike: connect to a configured WebSocket URL,
  send `request_login_id` with the `chr(0x04)` delimiter, parse `setLoginID`.
- [ ] Safe local config: no committed credentials; ignored local config / env
  vars if needed.
- [ ] Port the real flow after the local harness is useful: login, server
  selection, lobby, level browser, load one real level.

Acceptance: the browser build reaches a real server path over WebSocket; at
least one real response is parsed; login feasibility is known before full UI.

## Testing

- [ ] Generalize `tools/pr2driver.py` into a common sequence format for Flash
  and OpenFL (launch/click/tap/hold/wait/screenshot). OpenFL sequence support
  and 550x400 normalization already exist.
- [ ] Keep deterministic fixture tests (parity) separate from real-server tests
  (connectivity / broad behavior only).
- [ ] Remaining suites: `intro-flow` (Jiggmin renders; verify
  `data-pr2-intro-state` + click-to-skip; Kongregate pending art),
  `level-load-flat`, `finish-race`, `real-server-connect`.

Acceptance: one command runs a useful scripted OpenFL sequence; failures produce
screenshots + debug output that are easy to inspect.

## Later Work

- [ ] Sound and music: extract/import assets, port `SoundEffects`, handle
  browser autoplay restrictions.
- [ ] Full UI polish: login shell, lobby, level browser, customization UI,
  editor shell if needed.
- [ ] Performance/compatibility: profile browser rendering, optimize after
  behavior is right, test Chrome/Firefox/Safari/mobile, watch memory across
  level loads.
- [ ] Mobile targets: responsive wrapper, touch controls, Android, iOS.
- [ ] Release readiness: production build, asset cache/versioning, loading/error
  screens, gameserver WebSocket deploy docs, public test build.
