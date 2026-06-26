# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, 27 FPS timing, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

## Parity Rules

- Treat `flash/**/*.as` and `flash/platform-racing-2-xfl/` as the behavioral and
  visual specification. Do not silently simplify a workflow because the happy
  path works.
- Keep browser transport adaptations behind narrow wrappers. WebSocket and
  same-origin HTTP proxy requirements may differ from Flash; commands,
  responses, state transitions, and visible behavior should not.
- Every ported feature needs deterministic state/protocol coverage and, when it
  is visible, a representative Flash/OpenFL screenshot comparison.
- Temporary drawings, record-only actions, harness redirects, hard-coded data,
  and unsupported buttons are parity gaps and must remain listed here.
- A task is complete only when the real user flow works. Rendering the art or
  recording the requested action is not completion.

## Current Priority: Real Login-to-Race Flow

The next milestone is one uninterrupted real-server session: login, lobby,
select/join a level, race with remote players, finish, and return to the lobby.
The persistent `LobbySocket` must survive every page transition as Flash's
`Main.socket` did. Login and session establishment are complete (see README);
level entry, race sync, and the in-game shell remain.

- [ ] Replace the campaign-harness redirect with the real level-entry protocol.
  - Port slot selection, `CourseMenu`, access checks, password/private flows,
    spectating, room commands, loading/cancel/error states, and game-page
    transition from `flash/level_browser`, `flash/page/GamePage.as`, and
    `flash/gameplay/Game.as`. In-place level loading via `confirm_slot`/
    `startGame` already works (see README); the remaining work is the full
    `CourseMenu`/access/spectate protocol around it.
- [ ] Port multiplayer race synchronization.
  - Implement local update emission, remote character creation/interpolation,
    player join/leave, positions, rotations, stats, hats, items/effects, block
    changes, countdown/start, timer, finish order, spectating, and disconnect.
  - Verify command names, field order, delimiters, update cadence, and rounding
    against the AS3 client and captured server traffic.
- [ ] Port the complete in-game shell and race lifecycle.
  - Implement `Course`, `GamePage`, countdown, race chat, minimap, stats, item
    display, hearts, drawing info, music selection, quit flow, finish page,
    experience gain, prizes, artifact/special-event behavior, and return to
    lobby.
  - Export or wire the authored `FinishedPageGraphic`, `ExpGainGraphic`,
    `DrawingInfoGraphic`, `StatsDisplayGraphic`, `RaceChatGraphic`,
    `MiniMapGraphic`, `MiniMapDot`, `PrizePopupGraphic`, `QuitButtonGraphic`, and
    `MusicSelectionGraphic`; no generic HUD substitutes in parity captures.

Acceptance: an account and a guest can each enter a real race over WebSocket,
see synchronized remote players, finish or quit, and return to the lobby without
a page reload. A deterministic transcript test verifies the full command/state
sequence and screenshots cover level entry, countdown, racing, and finish.

## Gameplay Fidelity

Character-part registration, the `LocalCharacter` and block-physics audits, and
real level decoding/rendering are complete (see README). Remaining physics work
is scoped to item behavior below.

- [ ] Port gameplay behavior not represented by the local harness: hats and hat
  powers, eggs/hearts, cowboy mode, artifact/special events, prizes, experience,
  rank progression, race modes, captcha, and server-authoritative interactions.
- [x] Port character "hold down to charge super jump" behavior. Crouch is now
  forced only by a low ceiling (block above the head, body tile clear) as in
  `LocalCharacter.processBlocks`; holding down on open ground charges
  `crouchCharge` and releases a `-crouchCharge*0.24` super jump per
  `LocalCharacter.landGo`, instead of incorrectly crouching.
- [x] Camera centers on the player on entry. Two bugs stacked here:
  1. Root cause: in the real login->lobby->race flow the game mounted inside a
     nested lobby panel, not the stage. Every `PageHolder` claimed the `startGame`
     launch in its constructor (`LevelLaunch.install`), so the lobby's nested
     holders (`PlayersTab` inner list holder, `LobbySide`) became the launch
     target. The `GamePage` then loaded into an offset lobby panel, leaving the
     lobby chrome (Vault/Editor/Logout/Options) on screen and shifting the game
     right/down. Flash uses a single root `Main.pageHolder`; now only the
     stage-root holder installs (`PageHolder(..., root = true)` from `Main`).
     Guarded by `LobbyServicesTest.testLevelLaunchTargetsRootHolder`.
  2. The follow easing matched Flash (`Course.cameraFollowPlayer` target `-c.x`,
     `-c.y + 45`), but `CampaignTestScreen` (wrapped by `GamePage`) seeded
     `CameraFollow` from the renderer's off-center focus and eased in over ~10
     frames. Flash hides that ease-in behind the 3-2-1 countdown
     (`Course.beginRace`/`toggleKeyScroll`); this screen has no countdown, so it
     now snaps to the settled spawn target via `CameraFollow.snapTo`.
- [x] Port in-game minimap. `gameplay/MiniMap` and `gameplay/MiniMapDot` port
  `MiniMap.as`/`MiniMapDot.as`: the block silhouette is rasterized to a bitmap
  fitted to the authored 400x44 strip (`rasterizeScale`/`fitScale`/`numLimit`),
  finish boxes (`MiniMapFinishGraphic`) and constant-4px player dots layer over
  it, and the dot drives the authored five colour frames via `setTempID`.
  `CampaignTestScreen` builds it from the decoded level (excluding start blocks
  and minion eggs as `Map.attachObject` does), places the local yellow dot at
  stage (80,2) per Course's holder offset, and tracks the player each frame.
  Guarded by `MiniMapTest`. The `MiniMapDot` hover popup (player name) and
  remote-player dots are deferred until the full `Game`/`Course` shell and
  multiplayer sync land.
- [x] Port in-game item display. `gameplay/ItemDisplay` drives the authored
  `ItemDisplayGraphic` item frames, dual item-name fields, and three ammo dots
  from `LocalPlayerController` state in `CampaignTestScreen`, at Flash's stage
  position (2,2). Guarded by `ItemDisplayTest`.
- [x] Port in-game menu buttons.
  - [x] Port the authored quit button, including immediate mouse quit, the
    focused Space-key confirmation while racing, glow controls, `quit_race`,
    the finish popup, and `set_game_room`none` return-to-lobby flow.
  - [x] Port the authored music-selection dropdown and runtime song switching.
    `gameplay/MusicSelection` renders `MusicSelectionGraphic` around the shared
    authored `FlComboBox`, filters the catalog through the saved song blacklist,
    selects the level's requested/random fallback track, switches looping
    `GameMusic` playback on user changes, and supports the artifact song.
    `CampaignTestScreen` positions it at Course's stage-space coordinates and
    tears it down with the level. Guarded by `MusicSelectionTest`.
- [x] Port finish popup, level rating, experience gain. `gameplay/FinishedPage`,
  `gameplay/ExpGain`, and `ui/RatingSelect` port `FinishedPage.as`/`ExpGain.as`/
  `RatingSelect.as` over the authored `FinishedPageGraphic`, `ExpGainGraphic`,
  `HighlightStar`, and `RatingSelectGraphic` symbols: award/exp lines (capped at
  five), the `+ delta` total, the 45-frame exp-bar ease with the AS3 end-clamping
  (`m.bar.bar.width`/`textBox`), and the 1-5 star control that confirms via
  `ConfirmPopup` and POSTs to `submit_rating.php` through `UploadingPopup`
  (`ServerConfig.submitRatingUrl`). Guarded by `FinishedPageTest`. Since the real
  in-game `Game`/`Course` shell and multiplayer finish protocol are not ported
  yet, `FinishedPage` takes the level id directly and exposes the same
  `award`/`setExpGain` entry points `Game` called, with an injected `onReturn` for
  the "Return to Lobby" button (Flash's `set_game_room`none` + page change). Wiring
  it to the live race-finish/award/exp commands is deferred to the multiplayer
  race-sync and in-game-shell tasks above.
- [x] Mine, brick, and crumble blocks disappear visually when removed. The
  shared `LocalPlayerController.blockAlphaAt` removal state now drives every
  campaign block display rather than only vanish blocks, and the fixture
  renderer uses the authored mine and crumble bitmap assets. Guarded by
  `FixtureLevelRendererTest` and `ServerLevelRendererTest`.
- [x] Show the authored mine explosion and mine/brick/crumble piece effects
  when those blocks are hit or removed.
  - [x] Show the authored 14-frame mine explosion and spatial explosion sound
    when a mine is triggered.
  - [x] Show the authored mine, brick, and crumble piece physics. Authored
    `BrickPieceGraphic`, `CrumblePieceGraphic`, and `MinePieceGraphic` fragments
    now use Flash's exact counts, randomized spawn/velocity/rotation spreads,
    gravity, friction, fade rate, and 20-frame removal lifecycle.
- [x] Vanish blocks now reproduce `VanishBlock.as` visually as well as
  physically: contact fades the block by 0.1 per frame, the inactive block is
  hidden during its 2-second delay, and an unoccupied block reappears at 0.2
  alpha before fading back in. The shared `LocalPlayerController` state drives
  both fixture and server-level renderers. Guarded by
  `LocalPlayerControllerTest`, `FixtureLevelRendererTest`, and
  `ServerLevelRendererTest`.
- [x] Arrow blocks render their arrows. `ServerLevelRenderer` now draws arrow
  blocks as a `basic2` base tile plus the generated `ArrowBlockGraphic`,
  centered on the tile (15,15) and rotated per direction (up 0, down 180, left
  -90, right 90) exactly as `ArrowBlock`/`ArrowUp/Down/Left/RightBlock` and
  `Blocks.getBlock` do in AS3. Guarded by `ServerLevelRendererTest`.
  - [x] Port the "press" brighten animation. Local arrow collisions now emit a
    visual activation that drives the authored eight-frame `ArrowBlockGraphic`
    timeline, including its frame-1 stop script and `ArrowBlock.animateArrow`
    retrigger rules. Guarded by `LocalPlayerControllerTest` and
    `ServerLevelRendererTest`.
- [x] Fix click-to-skip in the intro. Flash's `menu.IntroPage` listened for
  `MouseEvent.CLICK` on the stage so a click anywhere skipped to login, but
  OpenFL's HTML5 backend does not dispatch a stage-level CLICK for clicks on
  plain (non-button) art or the empty backdrop, so only interactive symbols
  (the global mute button, the center logo) skipped. `IntroPage` now keeps the
  stage listener (so those symbols still skip) and adds a transparent,
  full-stage skip hit area on top of the intro art with its own CLICK listener,
  matching `LoginPage.createHitArea`. An `ended` guard makes the now-doubled
  skip path idempotent so a click never stacks two `LoginPage` transitions.
  Verified end-to-end with `tools/openfl_driver.py sequence`: a plain-area
  click advances `data-pr2-intro-state` from `intro-jiggmin` to `login`.
- [ ] Fix the position of the in-game quit button, match it to the source game
- [ ] Port in-game chat
- [ ] Play in-game music, streaming from a server endpoint. Dropdown can select different songs
- [ ] Character shrinks too short when crouching under a block
- [ ] Pressing up while under a block should bump it
- [ ] Bumping an item block should give your character an item
- [ ] Bumping a regular item block should grey it out, bumping it again does not give an item
- [ ] Port the scale-shake effect when charging a super jump
- [ ] Background art layers are not showing
- [ ] Port the live level drawing from the source game, x blocks and x lines are drawn every frame until everything is ready and the game begins
- [ ] Hide the in-game debug text by default. Type /debug into the chat to show/hide it

### Physics 1:1 (preserve original quirks/bugs)

The physics port must map 1:1 to the original engine, preserving its quirks and
bugs. Do not "fix" or idealize behavior — replicate the AS3 exactly, including
rounding, ordering, and edge cases.

- [ ] Audit and port item physics/interaction 1:1 (item effects on the
  character and world, timing, and edge cases).
  - [x] Enforce the authored multi-use item reload timing: Laser Gun and Sword
    wait 800ms (22 frames at 27 FPS), Ice Wave waits 1000ms (27 frames), and a
    held item key fires again only when the reload completes.
  - [ ] Complete the remaining item effect, world interaction, and edge-case
    audit against the AS3 item/effect classes and server protocol.
Acceptance: scripted input and server transcripts produce matching Flash debug
state at agreed checkpoints, and representative race screenshots stay within
documented image-diff thresholds.

## Lobby and Account Completion

The lobby shell and tabs exist, but a number of interactions are currently
record-only or fixture-driven. Audit every reachable control against the AS3;
do not infer completion from the presence of a tab or exported symbol. The
external-link, Options, and Credits popups are already functional (see README).

- [ ] Replace `LobbyPopups.lastRequest` stand-ins with functional player,
  guest-player, guild, level-info/report, admin/moderation, and social-action
  popups, including their network requests and refresh behavior.
- [ ] Implement the remaining bottom-strip destinations: store/vault and
  quantity/purchase flows, and the level editor. Preserve guest/member
  visibility and logout side effects.
- [ ] Verify every Chat, PMs, Players, Account, Campaign, listing, Favorites, and
  Search operation against real HTTP/socket responses. Cover paging, stale and
  out-of-order responses, loading/error/empty states, permissions, unread
  updates, room changes, link handling, and state restoration after a race.
- [ ] Complete account/profile workflows: password/email changes, outfit and
  loadout persistence, part information, guild actions, friend/follow/ignore,
  moderation controls, rank tokens, hotkeys, and server-driven refreshes.
- [ ] Replace any remaining synthetic lobby visuals/data with authored symbols
  and exact Flash typography, masks, scroll behavior, hover/focus states, and
  stacking. Add focused baselines for every popup and non-empty/error state,
  not only the current shell/tab fixtures.

Acceptance: every lobby control performs its original operation against the
real services, all role/guest variants are covered, and no reachable action is
implemented only as a test marker.

## Level Editor and Level Management

- [ ] Port `LevelEditor`, `LevelEditorMenu`, sidebars, tools, drawing/text/stamp
  placement, block options, selection/deletion, undo-equivalent behavior,
  camera/zoom, settings, hats/items/music menus, and test-course transition.
- [ ] Port load/save/upload/delete/report-management flows and their validation,
  access rules, popups, server formats, loading/errors, and return navigation.
- [ ] Round-trip representative original level payloads without semantic drift;
  compare editor and test-course screenshots with Flash at the same camera and
  selected-tool state.

Acceptance: a user can load, edit, test, save, and reopen a real level with the
same serialized meaning and visible result as Flash.

## Runtime and Visual Coverage

Static-text fidelity, authored-symbol fallback removal, and the `FlattenPolicy`
`cacheAsBitmap` optimization are complete (see README).

- [ ] Audit generated timelines against Flash for masks, filters, blend modes,
  color transforms, nested frame scripts, sound frames, dynamic text/font
  embedding, buttons, nine-slice scaling, and unload/disposal behavior. Add a
  reduced fixture for every runtime fix.
  - [x] Apply authored element blend modes in `PR2MovieClip`, including
    Animate's `layer` mode, with a reduced runtime fixture covering multiply,
    screen, layer, and the normal default.
  - [x] Apply authored Blur, Glow, and DropShadow filters in source order, with
    Flash-compatible omitted-attribute defaults and keyframe removal. A reduced
    runtime fixture covers every generated-catalog filter type and parameter.
  - [x] Apply authored symbol nine-slice scaling grids. XFL `scaleGridLeft`,
    `scaleGridRight`, `scaleGridTop`, and `scaleGridBottom` now generate into
    `SymbolAssetDef` and initialize OpenFL `scale9Grid`; reduced and generated
    `SquareBG` fixtures cover coordinate and size conversion.
  - [x] Preserve authored timeline sound-frame metadata in the generated asset
    catalog, including sound names/effects, in/out points, and envelope points.
  - [x] Play authored timeline sound frames with Flash-compatible sync,
    envelope, seeking, looping, and stop/disposal behavior.
    - [x] Play default/event sounds once when the playhead enters their exact
      keyframe, without retriggering across the keyframe's held duration.
    - [x] Apply authored in/out-point seeking and volume envelopes. Timeline
      event sounds now convert Animate's 44.1 kHz sample markers to playback
      milliseconds, start at `inPoint44`, stop at `outPoint44`, and linearly
      interpolate authored left/right envelope levels while playing. Guarded by
      `AudioRuntimeTest`.
    - [x] Implement stop-sync frames. Generated frame metadata now retains
      `soundSync`, and entering a `stop` keyframe terminates every active
      instance of that named library sound without affecting other sounds.
      Guarded by `AudioRuntimeTest`.
    - [x] Implement start-sync frames. Entering a `start` keyframe plays like an
      event sound only when that named library sound has no active instance;
      existing playback continues without restarting. Guarded by
      `AudioRuntimeTest`.
    - [x] Stop timeline-owned sounds when their `PR2MovieClip` is disposed,
      without interrupting another timeline's instance of the same library
      sound. Guarded by `AudioRuntimeTest`.
    - [x] Preserve authored `soundLoopMode`/`soundLoop` metadata and play event/
      start sounds with Flash repeat-count and continuous-loop semantics.
      Guarded by `AudioRuntimeTest`.
    - [x] Implement stream sync mode. Stream frames now remain active across
      their authored keyframe duration, seek from the playhead's 27 FPS frame
      offset and authored in-point, continue without restarting across
      sequential frames, and stop on timeline stop or disposal. Guarded by
      `AudioRuntimeTest`.
- [ ] Establish per-screen screenshot thresholds and compare at exact 550x400
  stage size for default, hover, pressed, focused, disabled, loading, populated,
  empty, and error states. Keep visual metrics alongside baselines so “looks
  close” is not the acceptance criterion.
- [ ] Audit cleanup across repeated login/lobby/race/editor transitions: event
  listeners, timers, sockets, bitmap data, audio, and display-list references
  must not leak or duplicate behavior.
  - [x] Recursively dispose animated `PR2MovieClip` descendants inside
    `DOMGroup`, component, and mask-holder containers so nested `ENTER_FRAME`
    listeners cannot survive their owning timeline.
  - [x] Stop timeline-sound envelope/out-point monitor timers when playback is
    explicitly stopped by a sync frame or owning `PR2MovieClip` disposal.
    Guarded by `AudioRuntimeTest`.

## Test and Release Matrix

- [ ] Verify Chrome, Firefox, and Safari keyboard/focus, rendering, WebSocket,
  audio, storage, and lifecycle behavior. Profile long sessions only after
  behavior is correct, then optimize without changing parity.
- [ ] Prepare the browser release path: production proxy/WebSocket configuration,
  HTTPS, cache/version strategy, preload/error handling, diagnostics, and a
  public test build.
- [ ] After browser parity, port touch controls and package Android/iOS. Mobile
  layout adaptations must not alter the canonical 550x400 game coordinates or
  browser behavior.

## Final 1:1 Audit

- [ ] Build a source-class coverage inventory mapping every first-party AS3
  class and linkage to its Haxe implementation, deliberate platform adapter, or
  verified unreachable/dead status. An exported asset alone does not count as a
  class port.
- [ ] Walk every original user flow and role: guest, member, moderator/admin
  where testable, login failures, lobby/social/account/store, level browsing,
  racing/spectating, editor/management, disconnect/reconnect, and logout.
- [x] Document only unavoidable browser differences, with evidence that each is
  platform-required rather than an implementation shortcut.

The port is complete when no reachable behavior is a placeholder or harness
redirect, the coverage inventory has no unexplained gaps, and deterministic,
protocol, audio, and visual comparisons demonstrate parity with the Flash
client.
</content>
</invoke>
