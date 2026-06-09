# Platform Racing 2 Haxe/OpenFL Port TODO

This plan ports Platform Racing 2 from Flash/Adobe Animate AS3 to Haxe/OpenFL.

Current assumptions:

- Primary implementation: Haxe + OpenFL.
- Primary target: browser/HTML5.
- Secondary targets: Android and iOS after browser parity.
- Asset strategy: try OpenFL SWF import first; fall back to an XFL-derived asset pipeline only if needed.
- Networking strategy: test against the real PR2 server early.
- Initial visual goal: close enough to feel like PR2, not strict pixel-perfect parity.
- Testing strategy: replay the same scripted inputs against Flash and the OpenFL port, then compare screenshots and state where possible.

## 0. Baseline And Scope

- [ ] Choose the canonical Flash reference build.
  - Use `flash/platform-racing-2.swf` or a Flash projector app.
  - Record Flash Player/projector version.
  - Confirm whether `flash/build.swf` or `flash/platform-racing-2.swf` is the better behavior reference.
- [ ] Confirm stage and timing constants.
  - `tools/pr2driver.py` assumes a 550x400 stage.
  - The extracted FLA reports 27 FPS.
  - `tools/pr2driver.py` currently assumes 24 FPS.
  - Decide which timing source matches the running game.
- [ ] Capture baseline Flash screenshots.
  - Login screen.
  - Server select.
  - Lobby.
  - Level browser.
  - Character customization.
  - Empty/test course.
  - Running, jumping, crouching, swimming, item usage.
- [ ] Store baseline captures in a stable directory.
  - Suggested: `test/baselines/flash/`.
- [ ] Define initial playable scope.
  - Real server connectivity should be tested early.
  - First full gameplay milestone can still be a simple real or fixture level.

Acceptance:

- Flash reference can be launched repeatably.
- Scripted inputs can be replayed.
- Screenshots can be captured at known stage coordinates.
- Framerate assumptions are documented.

## 1. OpenFL Project Skeleton

- [ ] Add Haxe/OpenFL project files.
  - `project.xml`.
  - `src/Main.hx`.
  - `assets/`.
  - Build instructions.
- [ ] Create a minimal OpenFL app.
  - 550x400 logical stage.
  - Matching background color.
  - Fixed logical update loop.
  - Keyboard input logging.
  - Mouse input logging.
- [ ] Verify browser build.
  - `openfl test html5`.
  - Confirm stage dimensions in browser.
  - Confirm inputs work.
- [ ] Add optional native desktop target.
  - Useful for debugging and screenshot comparison.

Acceptance:

- OpenFL app opens in browser.
- Stage size matches Flash.
- Keyboard and mouse events are received.
- A deterministic frame counter is visible or loggable.

## 2. OpenFL SWF Asset Feasibility Spike

- [ ] Add PR2 SWF as an OpenFL asset.
  - Start with `flash/platform-racing-2.swf`.
  - If needed, generate a reduced SWF containing only character assets.
- [ ] Load simple exported symbols through OpenFL.
  - Verify `Assets.getMovieClip(...)`.
  - Verify root timeline loading if useful.
- [ ] Test critical timeline APIs.
  - `play()`.
  - `stop()`.
  - `gotoAndPlay(frame)`.
  - `gotoAndStop(frame)`.
  - `gotoAndStop(label)`.
  - `currentFrame`.
  - `totalFrames`.
  - `currentLabels`.
  - `addFrameScript(...)` or equivalent generated behavior.
- [ ] Test critical PR2 symbols.
  - `CharacterGraphic`.
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
- [ ] Test named child access.
  - `head`.
  - `body`.
  - `foot1`.
  - `foot2`.
  - `weapon`.
  - `colorMC`.
  - `colorMC2`.
  - Hat children on head/body.
- [ ] Test color transforms.
  - Primary color layer.
  - Secondary color layer.
  - Visibility toggles.
  - Alpha/transparency cases.
- [ ] Test timeline composition.
  - Switch animation state.
  - Switch part id with `gotoAndStop(partId)`.
  - Advance frames.
  - Compare representative screenshots against Flash.
- [ ] Document failures.
  - Missing symbols.
  - Missing named children.
  - Incorrect vector rendering.
  - Incorrect gradients.
  - Incorrect filters/blends.
  - Incorrect frame labels.
  - Performance problems.

Acceptance:

- One OpenFL screen can render a customizable PR2 character.
- Part ids can be changed.
- Colors can be changed.
- Several animation states play or stop correctly.
- Visual output is close enough for an initial browser port.

## 3. Early Real Server Connectivity

- [ ] Inventory networking code.
  - `flash/com/jiggmin/data/PR2Socket.as`.
  - `flash/com/jiggmin/data/CommandHandler.as`.
  - `flash/SuperLoader.as`.
  - `flash/com/jiggmin/data/Encryptor.as`.
  - `flash/com/jiggmin/data/SecureData.as`.
  - Login and server selection classes.
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
  - FLA/XFL sounds.
  - SWF embedded sounds.
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
- [ ] Fix or parameterize test framerate.
  - Do not leave Flash and OpenFL tests using mismatched frame assumptions.
  - Allow per-target FPS if needed.
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
  - Hold right for fixed frames.
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
