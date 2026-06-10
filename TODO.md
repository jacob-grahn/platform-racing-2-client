# Platform Racing 2 Haxe/OpenFL Port TODO

This plan ports Platform Racing 2 from Flash/Adobe Animate AS3 to Haxe/OpenFL.

Current assumptions:

- Primary implementation: Haxe + OpenFL.
- Primary target: browser/HTML5.
- Secondary targets: Android and iOS after browser parity.
- Asset strategy: use the unzipped FLA/XFL as a one-time migration source and authoring-structure reference, then generate initial Haxe/OpenFL source/assets from extracted XFL/XML with open tooling. After migration, leave the FLA/XFL behind and do future development directly in Haxe/OpenFL. SWFs are runtime behavior references only, not port build inputs.
- Build constraint: normal development and CI must not require Adobe Animate or an Adobe subscription.
- Networking strategy: test against the real PR2 server early.
- Initial visual goal: close enough to feel like PR2, not strict pixel-perfect parity.
- Testing strategy: replay the same scripted inputs against Flash and the OpenFL port, then compare screenshots and state where possible.

## 0. Baseline And Scope

- [x] Define the port asset source of truth.
  - Use extracted XFL/XML files under `flash/platform-racing-2-xfl/` as the primary migration reference for assets, timelines, symbol names, frame labels, linkage, and authoring structure.
  - Generate normalized Haxe classes and supporting assets once, then commit and maintain those outputs as normal source/assets.
  - The generator should not be part of the normal build pipeline after the migration output is produced.
  - JSON metadata is useful for inspection/debugging, but the runtime port should not depend on importing JSON asset graphs.
  - Ensure the normal port build does not depend on Adobe Animate.
  - Ensure normal development does not require rerunning the XFL generator.
- [x] Confirm initial stage and timing constants.
  - Flash `Main.as` defines a 550x400 client and sets `stage.frameRate = 27`.
  - The extracted FLA reports 27 FPS.
  - `tools/pr2driver.py` uses seconds-based timing and does not own game framerate.
  - Use 27 FPS for the Haxe/OpenFL port unless runtime comparison proves otherwise.
- [x] Capture baseline Flash screenshots.
  - Login screen.
  - Server select.
  - Lobby.
  - Level browser.
  - Character customization.
  - Empty/test course.
  - Running, jumping, crouching, swimming, item usage.
  - Initial Flash baseline subset captured under `test/baselines/flash/` from `flash/platform-racing-2.app`.
  - Captured: intro, login, guest server-select dialog, lobby popup, unobstructed lobby/level browser/customization, campaign level entry, gameplay start, running, jump/down-held movement attempts, swimming, level-editor item/setup reference, and held-item HUD references for Laser, Jet Pack, Lightning, Teleport, Ice Wave, Speed Burst, Super Jump, Sword, and Mine.
  - Clean crouch and active item-effect captures are intentionally out of scope for this baseline pass.
- [x] Store baseline captures in a stable directory.
  - Suggested: `test/baselines/flash/`.
- [ ] Define initial playable scope.
  - Real server connectivity should be tested early.
  - First full gameplay milestone can still be a simple real or fixture level.

Acceptance:

- Extracted FLA/XFL is treated as the primary source for asset structure.
- Flash runtime reference can be launched repeatably when behavior comparison is needed.
- Scripted inputs can be replayed.
- Screenshots can be captured at known stage coordinates.
- Framerate assumptions are documented.

## 1. OpenFL Project Skeleton

- [x] Install local Haxe/OpenFL toolchain.
  - Haxe 4.3.7 installed via Homebrew.
  - haxelib 4.1.1 configured to repo-local `.haxelib/`.
  - Lime 8.3.2 and OpenFL 9.5.2 installed.
  - Use `haxelib run openfl ...` because the optional `openfl` command shim is not on PATH.
- [x] Add Haxe/OpenFL project files.
  - `project.xml`.
  - `haxe/src/Main.hx`.
  - `haxe/src/pr2/Constants.hx`.
  - `assets/`.
  - Build instructions.
- [x] Create a minimal OpenFL app.
  - 550x400 logical stage.
  - Initial background color.
  - Deterministic frame counter.
  - Keyboard input logging.
  - Mouse input logging.
- [x] Verify browser build compiles.
  - `haxelib run openfl build html5`.
  - Generated output: `export/html5/bin/index.html`.
- [x] Manually verify browser runtime.
  - `haxelib run openfl test html5`.
  - Confirmed app loads in browser at `http://127.0.0.1:3000`.
  - Confirmed 550x400 stage dimensions.
  - Confirmed deterministic frame counter advances.
  - Confirmed keyboard and mouse inputs update the HUD/log.
- [x] Add optional native desktop target.
  - Useful for debugging and screenshot comparison.
  - OpenFL mac target resolves with `haxelib run openfl display mac`.
  - Native output uses `export/macos/` and keeps normal browser builds unchanged.
  - Verified local native compile with `MACOSX_VER=26.5 haxelib run openfl build mac`.
  - Xcode 26.5 exposes `macosx26.5`; passing `MACOSX_VER=26.5` avoids hxcpp's failed
    `macosx26` lookup.
  - Keep this target optional; do not require Xcode for normal development or CI.

Acceptance:

- OpenFL app opens in browser.
- Stage size matches Flash.
- Keyboard and mouse events are received.
- A deterministic frame counter is visible or loggable.

## 2. Adobe-Free XFL Asset Pipeline Spike

- [x] Create an asset conversion tool.
  - Input: extracted XFL/XML library data.
  - Output: generated Haxe/OpenFL-friendly asset classes and any supporting bitmap/sound/vector assets.
  - Generated Haxe should be included by `project.xml` as native source, not loaded through a runtime JSON import step.
  - Treat this as a migration tool, not as a required normal build step.
  - The tool must run with open tooling only.
  - The tool must not require Adobe Animate, SWF export, or an Adobe subscription.
  - Added `tools/generate_haxe_assets.py`, which consumes `tools/xfl_metadata.py` and writes deterministic Haxe source under `haxe/src/pr2/generated/assets/`.
  - The first generated catalog includes schema typedefs, constants, media records, linkage classes, symbols, timelines, layers, frames, labels, display instances, transforms, color transforms, and shape summary bounds/counts.
  - Raw vector fill/stroke/edge streams remain in the metadata exporter and are deferred to the leaf vector rendering task.
- [x] Parse XFL document metadata.
  - Added `tools/xfl_metadata.py` to emit deterministic JSON from the extracted XFL.
  - `DOMDocument.xml`.
  - Stage size.
  - Frame rate.
  - Library item list.
  - Linkage class names.
  - Bitmap and sound metadata.
- [x] Parse symbol timelines.
  - `tools/xfl_metadata.py` now emits each symbol's `DOMTimeline`, ordered `DOMLayer` records, and `DOMFrame` records.
  - Captures frame indices, durations, frame labels, label types, layer ordering, layer visibility/locking/type metadata, frame element counts, and frame element type summaries.
  - `python3 tools/xfl_metadata.py --summary` verifies 988 symbol timelines, 2,587 layers, 11,511 timeline frames, 116 labels, and a max timeline length of 1,508 frames.
- [x] Parse display instances.
  - `DOMSymbolInstance`.
  - `DOMBitmapInstance`.
  - `DOMShape`.
  - Instance names.
  - Library item references.
  - Symbol type.
  - Loop mode.
  - Transformation points.
  - Matrices.
  - Visibility.
  - Color transforms.
  - Added lightweight frame `elements` trees in `tools/xfl_metadata.py`, including nested `DOMGroup` members.
- [x] Parse vector drawing data.
  - Solid fills.
  - Linear gradients.
  - Radial gradients.
  - Bitmap fills.
  - Strokes.
  - Raw edge/cubic command streams for later path decoding.
  - Approximate numeric shape bounds from parsed edge streams.
- [x] Generate native Haxe asset graph source.
  - Generate under a dedicated package such as `pr2.generated.assets`.
  - Emit typed Haxe structures/classes for library symbols, timelines, layers, frames, child instances, transforms, color transforms, labels, and referenced media.
  - Keep the generated source deterministic and diffable.
  - Commit the generated Haxe/source assets after review, then treat them as the editable Haxe/OpenFL baseline.
  - Do not wire this generation into `haxelib run openfl build ...` or normal CI builds.
  - Keep JSON output as an optional diagnostic/export mode only.
  - Stable symbol ids.
  - Symbol names.
  - Linkage class names.
  - Child instance definitions.
  - Timeline frames.
  - Labels.
  - Referenced bitmaps/sounds.
  - Generated package: `pr2.generated.assets`.
  - Verification: `haxe -cp haxe/src --macro 'include("pr2.generated.assets")' --no-output`.
- [x] Generate or implement a PR2 MovieClip runtime layer.
  - Consume generated Haxe asset definitions directly.
  - May wrap OpenFL `MovieClip`, or may use custom `Sprite`/`Timeline` classes.
  - Must support named child lookup.
  - Must support timeline-controlled child placement.
  - Must support nested timelines.
  - Added `pr2.runtime.AssetLibrary` and `pr2.runtime.PR2MovieClip`.
  - Runtime consumes committed generated `SymbolAssetDef` records directly.
  - Supports symbol/linkage lookup, frame expansion from layer durations, nested symbol instances, labels, playback controls, current frame/total frame APIs, transforms/color transforms, and named timeline children.
  - Leaf vector art is represented by bounds placeholders until the vector rendering milestone.
- [x] Test critical timeline APIs in the generated runtime.
  - `play()`.
  - `stop()`.
  - `gotoAndPlay(frame)`.
  - `gotoAndStop(frame)`.
  - `gotoAndStop(label)`.
  - `currentFrame`.
  - `totalFrames`.
  - `currentLabels`.
  - Frame-script hooks mapped from generated/decompiled AS3 classes.
  - Added `haxe/test/pr2/runtime/PR2MovieClipRuntimeTest.hx`, covering timeline playback, stop behavior, numeric and label seeks, frame wrapping, labels, frame-script hooks, named child lookup, transforms, color transforms, visibility, and invalid frame errors.
  - Verification: `haxe --library lime --library openfl -cp haxe/src -cp haxe/test --main pr2.runtime.PR2MovieClipRuntimeTest --interp`.
- [ ] Render leaf vector symbols.
  - First target: direct OpenFL vector drawing if practical.
  - Fallback target: rasterize leaf symbols to generated PNG/texture assets.
  - Keep timelines dynamic even if leaf art is rasterized.
- [ ] Test critical PR2 character symbols.
  - `runAnim`.
  - `standAnim`.
  - `jumpAnim`.
  - `superJumpAnim`.
  - `bumpedAnim`.
  - `crouchAnim`.
  - `crouchWalkAnim`.
  - `swimAnim`.
  - `frozenSolidAnim`.
  - `headsMC`.
  - `bodyMC`.
  - `footMC`.
  - `hatsMC`.
  - Weapon clips.
- [x] Test named child access.
  - `head`.
  - `body`.
  - `foot1`.
  - `foot2`.
  - `weapon`.
  - `colorMC`.
  - `colorMC2`.
  - Hat children on head/body.
- [x] Test color transforms.
  - Primary color layer.
  - Secondary color layer.
  - Visibility toggles.
  - Alpha/transparency cases.
  - Added runtime assertions for complete OpenFL `ColorTransform` multiplier/offset mapping, alpha-zero transparency, hidden tinted children, identity defaults, and generated PR2 primary/secondary `colorMC`/`colorMC2` children.
  - Verification: `haxe --library lime --library openfl -cp haxe/src -cp haxe/test --main pr2.runtime.PR2MovieClipRuntimeTest --interp`.
- [ ] Test timeline composition.
  - Switch animation state.
  - Switch part id with `gotoAndStop(partId)`.
  - Advance frames.
  - Compare representative screenshots against Flash.

Acceptance:

- The port can build character assets without Adobe Animate.
- Generated assets/classes are deterministic.
- One OpenFL screen can render a customizable PR2 character from XFL-derived data.
- Part ids can be changed.
- Colors can be changed.
- Several animation states play or stop correctly.
- Visual output is close enough for an initial browser port.

## 3. Early Real Server Connectivity

- [x] Inventory networking code.
  - `flash/com/jiggmin/data/PR2Socket.as`.
  - `flash/com/jiggmin/data/CommandHandler.as`.
  - `flash/SuperLoader.as`.
  - `flash/com/jiggmin/data/Encryptor.as`.
  - `flash/com/jiggmin/data/SecureData.as`.
  - Login and server selection classes.
  - Documented in `docs/networking-inventory.md`.
  - Covered `PR2Socket`, `CommandHandler`, `SuperLoader`, `Encryptor`, `SecureData`, `SecureStore`, `CommAuth`, `Main`, `CheckServers`, `ServerSelectPopup`, `ConnectingPopup`, and `LoggingInPopup`.
- [ ] Identify browser blockers.
  - Raw TCP sockets versus WebSocket/HTTP.
  - CORS.
  - TLS/mixed-content issues.
  - Crossdomain policy replacement needs.
- [ ] Build minimal OpenFL networking spike.
  - Request server list or a harmless endpoint.
  - Attempt login flow if credentials are available.
  - Attempt lobby/list data fetch.
- [ ] Decide whether a proxy is required.
  - If browser cannot talk directly to the real server, define a small proxy/shim.
  - Keep proxy protocol minimal and documented.
- [ ] Add safe test credentials/config handling.
  - No credentials committed.
  - Local `.env` or ignored config file if needed.

Acceptance:

- OpenFL browser build can reach the real server directly, or the need for a proxy is proven.
- At least one real server response is parsed.
- Login feasibility is known early.

## 4. AS3 To Haxe Port Foundation

- [ ] Establish package mapping.
  - Keep package names close to AS3 where practical.
  - Preserve class names during the mechanical port.
- [ ] Set up porting conventions.
  - AS3 `Number` -> Haxe `Float`.
  - AS3 `int`/`uint` -> Haxe `Int` where safe.
  - AS3 `Array` -> Haxe `Array<T>` or `Array<Dynamic>` initially.
  - Dynamic MovieClip fields may need `Reflect.field` or typed wrappers.
- [ ] Create compatibility shims.
  - `SecureStore`.
  - `Data`.
  - `SuperLoader`.
  - `PR2Socket`.
  - `CommandHandler`.
  - `SoundEffects`.
  - `Settings`.
  - `EpicFlash`.
  - `Objects`.
  - `Random`.
  - `Time`.
- [ ] Port leaf/data classes first.
  - Constants.
  - Utility functions.
  - Simple model classes.
- [ ] Port rendering classes next.
  - Graphic wrapper classes.
  - UI controls.
  - Character display classes.
- [ ] Port gameplay classes after the display foundation works.
  - Blocks.
  - Backgrounds.
  - Items.
  - Character physics.
  - Course/game state.

Acceptance:

- A useful subset of classes compiles in Haxe.
- Compatibility shims isolate Flash/OpenFL differences.
- No broad rewrites before behavior is understood.

## 5. Character Rendering Milestone

- [ ] Port `Character`.
  - Constructor.
  - `resetHats`.
  - `setColors`.
  - `setHatColors`.
  - `setHeadColors`.
  - `setBodyColors`.
  - `setFeetColors`.
  - `applyAppearance`.
  - `updatePartMC`.
  - `applyPartColor`.
  - `changeState`.
  - Weapon display updates.
- [ ] Build character test harness.
  - Display one character centered on the stage.
  - Controls to cycle animation states.
  - Controls to cycle hat/head/body/feet ids.
  - Controls to cycle primary/secondary colors.
  - Deterministic frame stepping.
- [ ] Compare against Flash.
  - Same part ids.
  - Same colors.
  - Same animation frame.
  - Same position and scale.
- [ ] Create representative character cases.
  - Default outfit.
  - Multi-hat outfit.
  - Secondary color outfit.
  - Cheese hat transparency workaround.
  - Fred/body-specific hat placement.
  - Epic parts if available.

Acceptance:

- Character customization works in the port.
- Common outfits look close enough to Flash.
- Animation state switching behaves like Flash.

## 6. Core Runtime Loop

- [ ] Port frame/update behavior.
  - Enter-frame events.
  - Timer behavior.
  - `setTimeout`.
  - `clearTimeout`.
  - `setInterval`.
  - `clearInterval`.
- [ ] Port keyboard state handling.
  - Left/right/up/down/space.
  - Any alternate keys used by PR2.
  - Prevent browser-default key behavior where needed.
- [ ] Port mouse handling.
  - Stage coordinates.
  - Button rollover/out/down/up/click.
  - Text field focus.
- [ ] Port main display hierarchy.
  - `Main`.
  - `Page`.
  - `PageHolder`.
  - `GamePage`.
  - Minimal page transition flow.

Acceptance:

- Main app can switch between a minimal menu/page and gameplay harness.
- Frame-dependent logic advances deterministically.
- Input state matches expected Flash behavior.

## 7. Level Data And Rendering

- [ ] Inventory level format.
  - Course data fields.
  - Block data.
  - Background data.
  - Draw objects.
  - Text objects.
  - Stamps.
  - Settings and game modes.
- [ ] Port level parsing.
  - Real server level payloads.
  - Local fixture payloads.
  - Error handling for malformed data.
- [ ] Port block rendering.
  - Basic blocks.
  - Start/finish.
  - Water/ice.
  - Crumble/vanish.
  - Mine.
  - Item/supply.
  - Teleport.
  - Arrow/rotate/move.
  - Custom stats.
- [ ] Port background rendering.
  - Block background.
  - Object background.
  - Drawable background.
  - Effect background.
  - Minimap data if tied to rendering.
- [ ] Create fixture levels.
  - Empty flat level.
  - Blocks-only level.
  - Special block showcase.
  - Item showcase.
  - Moving/rotating block showcase.

Acceptance:

- Fixture levels render at the correct scale and coordinates.
- At least one real server level can be loaded and displayed.

## 8. Physics And Gameplay

- [ ] Port character movement.
  - Gravity.
  - Acceleration.
  - Friction.
  - Jumping.
  - Crouching.
  - Swimming.
  - Bumping.
  - Recovery frames.
  - Frozen state.
- [ ] Port collision detection.
  - Solid blocks.
  - Slopes or special geometry if present.
  - Moving blocks.
  - Rotating blocks.
  - Edge cases around corners.
- [ ] Port block interactions.
  - Start/finish.
  - Crumble.
  - Vanish.
  - Mine.
  - Ice.
  - Water.
  - Move.
  - Rotate.
  - Arrows.
  - Teleport.
  - Item blocks.
  - Custom stats blocks.
- [ ] Port items.
  - Sword.
  - Laser gun.
  - Mine.
  - Jet pack.
  - Super jump.
  - Speed burst.
  - Ice wave.
  - Teleport.
  - Lightning.
- [ ] Add debug state export.
  - Character position.
  - Velocity.
  - Animation state.
  - Current animation frame.
  - Current item.
  - Collision/block state.

Acceptance:

- Running and jumping on a flat fixture level feels close to Flash.
- Special block interactions work on fixture levels.
- Debug state can be compared across deterministic test runs.

## 9. UI, Menus, And Real Server Flow

- [ ] Port intro/login shell.
  - Intro animation or acceptable equivalent.
  - Login form.
  - Server selection.
  - Error popups.
- [ ] Wire real server login.
  - Login success.
  - Login failure.
  - Guest flow if supported.
  - Session persistence if needed.
- [ ] Port lobby.
  - Lobby left/right/bottom regions.
  - Chat display.
  - Player list.
  - Server/lobby commands.
- [ ] Port level browser.
  - Campaign.
  - Newest.
  - Best.
  - Best week.
  - Search.
  - Favorites.
  - Level listing UI.
- [ ] Port player profile/customization UI.
  - Part selector.
  - Color picker.
  - Presets.
  - Loadouts.
- [ ] Port editor shell later unless needed earlier.

Acceptance:

- User can connect to the real server.
- User can reach lobby or equivalent real-server screen.
- User can browse/load at least one real level.

## 10. Sound And Music

- [ ] Extract/import sound assets.
  - XFL sound library entries.
  - Referenced files under the extracted XFL `bin/` directory.
  - SWF may be used as a reference to identify missing sounds, but not as a normal build input.
- [ ] Port `SoundEffects`.
  - One-shot effects.
  - Looping effects.
  - Sound transforms.
- [ ] Port music playback.
  - Course music.
  - Menu music if present.
  - Mute behavior.
  - Volume behavior.
- [ ] Handle browser autoplay restrictions.
  - Start audio only after user gesture.
  - Fail gracefully if audio is blocked.

Acceptance:

- Gameplay sound effects trigger at expected events.
- Music and mute behavior work in browser.

## 11. E2E Test Framework

- [ ] Generalize `tools/pr2driver.py`.
  - Keep current Flash backend.
  - Add browser/OpenFL backend.
  - Keep common sequence JSON format.
  - Support `launch`, `click`, `tap`, `hold`, and `shot`.
  - Normalize captures to 550x400.
- [x] Remove test-driver framerate assumptions.
  - Do not make `tools/pr2driver.py` own or parameterize game framerate.
  - Replay inputs using wall-clock seconds.
- [ ] Add screenshot comparison.
  - Pixel diff.
  - Perceptual threshold.
  - Ignored regions for blinking cursors, timestamps, chat, live server data.
  - Save actual, expected, and diff images.
- [ ] Add state comparison where possible.
  - Port can expose debug state.
  - Flash may only be screenshot-based unless instrumentation is added.
- [ ] Add deterministic controls.
  - Fixed random seed in port.
  - Disable optional particle randomness in test mode if needed.
  - Test fixture levels.
  - Mock server fixtures for deterministic tests.
- [ ] Keep real-server tests separate.
  - Real server tests verify connectivity and broad behavior.
  - Mock/fixture tests verify deterministic parity.

Acceptance:

- One command can run a sequence against Flash.
- One command can run the same sequence against OpenFL.
- Screenshots are compared with useful diff artifacts.

## 12. E2E Test Suites

- [ ] `boot-login-screen`.
  - Launch.
  - Wait.
  - Screenshot login screen.
- [ ] `real-server-connect`.
  - Launch port.
  - Request server/login data.
  - Verify non-empty response or expected login result.
- [ ] `character-customization`.
  - Open customization harness or UI.
  - Change parts/colors.
  - Screenshot representative states.
- [ ] `level-load-flat`.
  - Load fixture or known simple level.
  - Screenshot initial spawn.
- [ ] `run-right`.
  - Hold right for a fixed number of seconds.
  - Capture final position.
- [ ] `jump`.
  - Tap/hold jump.
  - Capture apex and landing.
- [ ] `crouch`.
  - Hold down.
  - Capture animation/state.
- [ ] `ice-slide`.
  - Run onto ice.
  - Capture slide behavior.
- [ ] `water-swim`.
  - Enter water.
  - Capture swim movement.
- [ ] `mine-hit`.
  - Trigger mine.
  - Capture explosion/bump/recovery.
- [ ] `teleport`.
  - Enter teleport.
  - Capture destination.
- [ ] `item-use`.
  - Pick up item.
  - Use item.
  - Capture effect.
- [ ] `finish-race`.
  - Reach finish.
  - Capture finish UI/state.

Acceptance:

- Core suites pass with close-enough visual thresholds.
- Failures produce screenshots and diffs that are easy to inspect.

## 13. Mobile Targets

- [ ] Preserve 550x400 logical game coordinates.
- [ ] Add responsive browser wrapper.
  - Scale to fit.
  - Fullscreen option.
  - No clipping.
- [ ] Add touch controls.
  - Left.
  - Right.
  - Jump.
  - Down/crouch.
  - Item.
  - Chat/menu controls.
- [ ] Build Android target.
  - OpenFL Android setup.
  - Input latency test.
  - Asset memory test.
- [ ] Build iOS target.
  - OpenFL iOS setup.
  - Touch controls.
  - Audio behavior.
  - App lifecycle pause/resume.

Acceptance:

- A simple level is playable on Android and iOS.
- Browser parity remains the priority until stable.

## 14. Performance And Compatibility

- [ ] Profile browser rendering.
  - Character timelines.
  - Vector-heavy UI.
  - Large levels.
  - Many particles/effects.
  - Multiple remote players.
- [ ] Optimize only after behavior works.
  - Cache static vectors.
  - Rasterize expensive leaf symbols if needed.
  - Reduce unnecessary display-list churn.
  - Pool effects/particles.
- [ ] Test browsers.
  - Chrome.
  - Firefox.
  - Safari.
  - Mobile Safari.
  - Android Chrome.
- [ ] Test memory stability.
  - Repeated level loads.
  - Repeated race starts.
  - Lobby to game to lobby cycles.

Acceptance:

- Browser build runs smoothly enough for normal play.
- No major memory growth across repeated sessions.

## 15. Release Readiness

- [ ] Add production build command.
- [ ] Add asset cache/versioning.
- [ ] Add loading/error screens.
- [ ] Add basic telemetry or error logging if desired.
- [ ] Document server/proxy requirements.
- [ ] Document browser/mobile support.
- [ ] Publish a test build.
- [ ] Run core E2E suites before release.

Acceptance:

- Public browser build can connect, load, and play.
- Core parity tests pass.
- Known limitations are documented.
