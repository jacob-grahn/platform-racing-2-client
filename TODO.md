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

- [x] Baseline and scope defined.
  - XFL/XML under `flash/platform-racing-2-xfl/` is the migration source; committed Haxe/OpenFL output becomes normal maintained source.
  - Normal development/builds must not require Adobe Animate, SWF export, or rerunning the generator.
  - Stage/timing baseline is 550x400 at 27 FPS.
  - Flash reference captures live under `test/baselines/flash/`; clean crouch and active item-effect captures remain out of scope for the initial baseline pass.
  - Initial playable scope is documented in `docs/initial-playable-scope.md`: a browser gameplay harness with one local player, fixed 27 FPS movement, basic blocks, start/finish, restart, and debug state export.

Acceptance:

- Extracted FLA/XFL is treated as the primary source for asset structure.
- Flash runtime reference can be launched repeatably when behavior comparison is needed.
- Scripted inputs can be replayed.
- Screenshots can be captured at known stage coordinates.
- Framerate assumptions are documented.

## 1. OpenFL Project Skeleton

- [x] OpenFL skeleton complete.
  - Toolchain: Haxe 4.3.7, haxelib 4.1.1, Lime 8.3.2, OpenFL 9.5.2; use `haxelib run openfl ...`.
  - Added `project.xml`, `haxe/src/Main.hx`, `haxe/src/pr2/Constants.hx`, `assets/`, and build instructions.
  - Minimal app verifies 550x400 stage, deterministic frame counter, and keyboard/mouse logging.
  - Browser build verified with `haxelib run openfl build html5`; runtime verified with `haxelib run openfl test html5`.
  - Optional mac target is available for debugging; local compile uses `MACOSX_VER=26.5 haxelib run openfl build mac`.

Acceptance:

- OpenFL app opens in browser.
- Stage size matches Flash.
- Keyboard and mouse events are received.
- A deterministic frame counter is visible or loggable.

## 2. Adobe-Free XFL Asset Pipeline Spike

- [x] XFL metadata and Haxe asset generation complete.
  - `tools/xfl_metadata.py` parses document metadata, library items, symbol timelines, display instances, transforms/color transforms, and raw vector fill/stroke/edge data.
  - `tools/generate_haxe_assets.py` emits deterministic Haxe under `haxe/src/pr2/generated/assets/`; JSON remains diagnostic only.
  - Generated package `pr2.generated.assets` verifies with `haxe -cp haxe/src --macro 'include("pr2.generated.assets")' --no-output`.
- [x] Generated MovieClip runtime complete.
  - Added `pr2.runtime.AssetLibrary` and `pr2.runtime.PR2MovieClip`.
  - Runtime supports symbol/linkage lookup, nested timelines, named child lookup, labels, playback controls, current frame APIs, transforms/color transforms, visibility, and frame-script hooks.
  - Leaf vector art is still represented by bounds placeholders until the vector rendering task.
- [x] Generated runtime tests cover timeline APIs and PR2 character composition basics.
  - Coverage lives in `haxe/test/pr2/runtime/PR2MovieClipRuntimeTest.hx`.
  - Verifies playback/stop/seek behavior, labels, frame wrapping, named children, transforms/color transforms, visibility, frame-script hooks, invalid frame errors, character animation children, part selector frame ranges, color layers, weapon/jetpack labels, and selected part persistence.
  - Verification: `haxe --library lime --library openfl -cp haxe/src -cp haxe/test --main pr2.runtime.PR2MovieClipRuntimeTest --interp`.
- [ ] Render leaf vector symbols.
  - First target: direct OpenFL vector drawing if practical.
  - Fallback target: rasterize leaf symbols to generated PNG/texture assets.
  - Keep timelines dynamic even if leaf art is rasterized.
- [ ] Compare representative character composition screenshots against Flash.

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
  - Documented in `docs/networking-inventory.md`.
  - Covers socket protocol, command handling, HTTP loader flow, auth/crypto helpers, server selection, connection, and login classes.
- [ ] Identify browser blockers.
  - Browser OpenFL/Haxe must use WebSockets for live socket traffic; browsers
    cannot connect to the existing raw TCP PR2 socket directly.
  - CORS.
  - TLS/mixed-content issues.
  - Crossdomain policy replacement needs.
  - Production WebSocket pathing should use same-origin HTTPS/TLS endpoints
    such as `wss://platformracing.com/servers/derron` to avoid cross-domain,
    mixed-content, and exposed-port concerns.
- [ ] Prerequisite: add server-side WebSocket support in the server repo.
  - External repo work; track here only as a dependency for browser client
    networking tasks.
  - Route same-origin paths like `/servers/<server_name>` to the appropriate
    PR2 game server.
  - Preserve the existing PR2 command protocol payload semantics over the
    WebSocket connection so the Haxe client can share protocol handling with
    the Flash socket inventory.
  - Serve endpoints over `wss://platformracing.com/...` in production.
  - Confirm browser-visible CORS/origin, TLS, and proxy headers are compatible
    with the deployed site.
- [ ] Build minimal OpenFL networking spike.
  - Request server list or a harmless endpoint.
  - Connect to a configured WebSocket URL, initially matching the planned
    production shape such as `wss://platformracing.com/servers/derron`.
  - Attempt login flow if credentials are available.
  - Attempt lobby/list data fetch.
- [ ] Document browser WebSocket client contract.
  - Server-list entries must resolve to WebSocket paths/URLs the browser can
    open without mixed content or cross-origin failures.
  - Keep any path-to-server mapping outside this repo unless client selection
    metadata is needed.
  - Keep the browser protocol minimal and documented.
- [ ] Add safe test credentials/config handling.
  - No credentials committed.
  - Local `.env` or ignored config file if needed.

Acceptance:

- OpenFL browser build can reach the real server through the server-provided
  WebSocket path.
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
  - `tools/pr2driver.py` replays inputs using wall-clock seconds and does not own game framerate.
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
