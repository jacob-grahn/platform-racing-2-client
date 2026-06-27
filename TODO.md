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
`Main.socket` did. Login and session establishment are complete (see README),
and the level-entry decomposition (A1–A5 below) is now done; multiplayer race
sync (Section B) and the live in-game shell / cutover (Section C) remain.

- [ ] Replace the campaign-harness redirect with the real level-entry protocol.
  - Port slot selection, `CourseMenu`, access checks, password/private flows,
    spectating, room commands, loading/cancel/error states, and game-page
    transition from `flash/level_browser`, `flash/page/GamePage.as`, and
    `flash/gameplay/Game.as`. In-place level loading via `confirm_slot`/
    `startGame` already works (see README); the remaining work is the full
    `CourseMenu`/access/spectate protocol around it.
  - Decomposed A1–A5 (each ships a named `*Test.hx` in `DeterministicTestSuite`).
    **All five done and verified** — condensed below; see git history for detail.
    `GamePage` now mounts the real `Course` shell, resolves the load through the
    two-error `LevelEntry` machine, and registers the full `Game` command table
    via `GameCommandShell`. Remaining for this box (deferred to B/C, why it stays
    `[ ]`): the `SpectatePicker` UI (only `spectatePossible` is modeled) and the
    live race — character creation, `beginRace`/countdown/finish hooks, and the
    popup side-effects behind `GameCommandDelegate` (LuxPopup/CowboyMode/HappyHour/
    Egg/Hat unported). Flips to `[x]` when the real login→race→lobby flow runs.
  - [x] A1 — Faithful config-setter semantics → `pr2.gameplay.LevelConfig` (+
    `pr2.gameplay.Items`); decode/fetch were already in `ServerLevelDecoder`/
    `LevelDataClient`. Test: `LevelConfigTest`.
  - [x] A2 — Fetch + `MD5(version+id+levelData+LEVEL_SALT_2)` validation already in
    `LevelDataClient`; parsed→config handoff is `LevelConfig.fromServerData`. Test:
    `LevelDataClientTest`.
  - [x] A3 — Extracted the in-game `Course` shell (level render, camera, character
    layer, HUD at verified offsets) from `CampaignTestScreen`; `GamePage` mounts it
    instead of the harness. Test: `GameShellMountTest`.
  - [x] A4 — In-game load lifecycle as the pure `pr2.gameplay.LevelEntry`
    (`Idle→Selected→Loading→Ready|Failed`, matching-`startGame` gate, the two
    distinct `loadHandler` error strings, spectate-on-`Ready`); access cover
    (`LevelAccess`/`LevelItem`) and launch handoff (`LevelLaunch`) were already
    ported. Test: `LevelEntryStateTest`.
  - [x] A5 — `pr2.gameplay.GameCommandShell`: 1:1 parse/register of the
    `Game.initialize`/`remove` command table behind a typed `GameCommandDelegate`;
    character commands parse into reusable `LocalCharacterInit`/`RemoteCharacterInit`
    (consumed by B). Test: `GameCommandShellTest`.
- [ ] Port multiplayer race synchronization.
  - Implement local update emission, remote character creation/interpolation,
    player join/leave, positions, rotations, stats, hats, items/effects, block
    changes, countdown/start, timer, finish order, spectating, and disconnect.
  - Verify command names, field order, delimiters, update cadence, and rounding
    against the AS3 client and captured server traffic.
  - Architecture decision: port the full Flash `Character`/`LocalCharacter`/
    `RemoteCharacter` hierarchy (truer 1:1), integrating with / replacing the
    `LocalPlayerController` harness rather than bolting sync onto it. Verification:
    AS3-spec deterministic transcript tests (emitted/consumed frame strings match
    byte-for-byte; interpolation tests step `go()` deterministically, no live
    server). Sequenced sub-tasks:
  - [x] **B1 — Port `Character` base.** `pr2/character/Character.hx` ports
    `flash/character/Character.as`: the appearance model (head/body/feet ids +
    per-part primary/epic colours and the four-slot hat stack with special-hat
    flags — `resetHats`/`setHats`/`getHighestHat`, `SecureStore` replaced by a flag
    map), driving the existing `CharacterDisplay` for parts/colours/state; the
    `changeState` state machine (clip = `state + "Anim"`, jump-sound via injectable
    hook); `getPos`/`setPos`/`rotate`/`updateSegs` (via `RotationMath`); the pure
    `blockTouchProbes` classifier B4 consumes; and the recovery-flash + fade-out
    removal lifecycle. No networking. Deferred behind hooks (need unported
    subsystems): particle emitters, jet-pack flame, `DjinnEffects`, held-weapon
    display frame, sound playback. Test: `CharacterBaseTest` (state transitions +
    jump-sound hook, hat stack/`getHighestHat`/flags, block-touch probes, recovery/
    removal).
  - [x] **B2 — Port `LocalCharacter` physics integration.** Migrate the audited
    `LocalPlayerController` physics into `pr2/character/LocalCharacter.hx extends
    Character` (or delegate to the existing controller) so behavior is preserved.
    Test: reuse/retarget `LocalPlayerControllerTest` against `LocalCharacter`.
    - [x] Add the `LocalCharacter` controller-delegation bridge. The new
      `pr2.character.LocalCharacter` extends `Character`, owns the audited
      `LocalPlayerController`, mirrors position/velocity/item/animation/facing
      state after each step, exposes the existing debug/block helpers, and is
      guarded by `LocalCharacterTest`.
    - [x] Retarget the full `LocalPlayerControllerTest` matrix through
      `LocalCharacter`. The controller parity matrix now instantiates
      `LocalCharacter` for the audited physics/block/item/rotation coverage,
      with controller-only debug hooks forwarded through the bridge.
    - [x] Cut over `Course`/live gameplay construction to `LocalCharacter`.
      `Course` now mounts the `LocalCharacter` bridge directly in the character
      layer and keeps the existing debug-state/HUD sync surface. Guarded by
      `GameShellMountTest`.
  - [x] **B3 — Port `LocalCharacter` emission.** Emit `p\`dX\`dY`,
    `exact_pos\`x\`y`, and `set_var\`<field>\`<value>` for each tracked field
    (scaleX, state, parent, item, rotMod, rot, sparkle, jet, beginRemove), gated by
    `updateInterval`/`framesSinceUpdate` (fallback 16). Emit event messages
    (`squash`, `sting`, `heart`, `loose_hat`, `hat_to_start`, `grab_egg`,
    `objective_reached`, `finish_race`, `quit_race`, `finish_drawing`,
    `check_hat_countdown`) via `LobbySocket.write`. Test: `LocalCharacterEmitTest`
    — drive scripted frames, assert exact emitted frame strings and cadence.
  - [ ] **B4 — Port `RemoteCharacter` consume + interpolation.** New
    `pr2/character/RemoteCharacter.hx` from `flash/character/RemoteCharacter.as`:
    register per-tempID commands (`p<id>`, `var<id>`, `exactPos<id>`,
    `setHats<id>`, `heart<id>`, `sting<id>`), `updateQueue` push, ENTER_FRAME
    `go()` with the `catchupRate` model (init `updateInterval+1`, −0.01 per
    consumed update, +0.08 when empty, clamp 10), `setVar`/`setExactPos`/`pos`
    queue ops, `processBlockTouches` remote activation, and command teardown on
    remove. Test: `RemoteCharacterConsumeTest` — feed recorded command frames, step
    `go()` deterministically, assert interpolated convergence and teardown.
    - [x] Port the command consume/interpolation core. `RemoteCharacter` now
      registers tempID-scoped position/var/exact-position/hat/heart/sting
      commands, applies Flash's queued catch-up stepping and exact-position latch,
      updates its minimap dot, exposes remote block-touch probes through a shell
      hook, and unregisters commands plus removes the dot on teardown. Guarded by
      `RemoteCharacterConsumeTest`.
    - [x] Add the real-map remote block activation adapter. `RemoteBlockActivation`
      resolves touched fixture blocks and dispatches Flash's remote-visible
      `ArrowBlock` animation, `VanishBlock` activation, and `WaterBlock` ripple
      effects through `ServerLevelRenderer`. Guarded by
      `RemoteCharacterConsumeTest` and `ServerLevelRendererTest`.
    - [x] Attach the remote block activation adapter when B5 mounts remotes in the
      live `Course`.
  - [x] **B5 — Wire create/destroy into the Game shell.**
    `createLocalCharacter`/`createRemoteCharacter` now route from
    `GameCommandShell` into the live `Course`, apply local stats/appearance,
    instantiate remotes into the character layer with minimap dots and real-map
    remote block activation, replace duplicate temp IDs, and tear remotes plus
    temp command handlers down on explicit/course removal. `forceQuit` routes
    through the game page quit flow. Guarded by `CharacterLifecycleTest`.
- [ ] Port the complete in-game shell and race lifecycle.
  - Implement `Course`, `GamePage`, countdown, race chat, minimap, stats, item
    display, hearts, drawing info, music selection, quit flow, finish page,
    experience gain, prizes, artifact/special-event behavior, and return to
    lobby.
  - Export or wire the authored `FinishedPageGraphic`, `ExpGainGraphic`,
    `DrawingInfoGraphic`, `StatsDisplayGraphic`, `RaceChatGraphic`,
    `MiniMapGraphic`, `MiniMapDot`, `PrizePopupGraphic`, `QuitButtonGraphic`, and
    `MusicSelectionGraphic`; no generic HUD substitutes in parity captures.
  - [x] Port the authored drawing-readiness display. `gameplay/DrawingInfo`
    wraps `DrawingInfoGraphic`, mirrors Flash's four player rows, starts each
    player's `drawing...` animation from `addPlayer`, handles the `finishDrawing`
    command by hiding the matching spinner, unregisters on remove, and is mounted
    in the current campaign/game path at Course's stage-space position while
    incremental block drawing runs. Guarded by `DrawingInfoTest`.
  - [x] Port the authored stats display. `gameplay/StatsDisplay` wraps
    `StatsDisplayGraphic`, shows the character's speed/acceleration/jump from
    `LocalCharacter.setStats`, and opens the `Current Stats` `HoverPopup` after a
    250ms hover (torn down on mouse-out/remove). Mounted at Course's stage-space
    (490, 34) and fed from the controller's stats each frame. Guarded by
    `StatsDisplayTest`.
  - [x] Port the authored deathmatch hearts. `gameplay/Hearts` stacks
    `HeartGraphic` icons (0.2 scale, 20px step) and grows/shrinks toward the
    requested count clamped to 0..15 like `Data.numLimit`. Mounted at Course's
    stage-space (515, 59), hidden until a deathmatch level reports lives per
    `Course.setLife`. Guarded by `HeartsTest`.
  - [x] Port the 3-2-1 race countdown. `gameplay/Countdown` drives the authored
    `CountdownGraphic` timeline, attaching its frame scripts (count at 9/24/39,
    finish at 54, self-remove at 62), playing `ReadySound`/`GoSound` scaled by
    the saved sound level, and invoking an injected `onFinish` for the
    gameplay-start hook `Course.beginRace`/`onCountdownFinish` ran. Wiring it to
    the live `beginRace` command is deferred to the multiplayer race-sync task.
    Guarded by `CountdownTest`.
  - [x] Port the prize announcement. `gameplay/PrizePopup` (with the
    `com.jiggmin.data.EpicFlash` port) renders `PrizePopupGraphic`: target clip
    selection by type (`hat`/`head`/`body`/`feet`/`exp`/`cancel`), the
    "You won" / "Anyone who finishes" / "The winner" body lines with `a`/`an`/`a
    pair of`, the title decoration, flavor description, exp/cancel detail lines,
    and the epic-upgrade shimmer. Wiring it to the live prize/special-event
    commands is deferred to the multiplayer race-sync task. Guarded by
    `PrizePopupTest`.
  - The remaining list items are confirmed already ported (and recorded below or
    in the README): race chat (`RaceChat`), minimap (`MiniMap`), item display
    (`ItemDisplay`), drawing info (`DrawingInfo`), music selection
    (`MusicSelection`), quit flow (`QuitButton`), finish page (`FinishedPage`),
    experience gain (`ExpGain`), and return-to-lobby (`GamePage`). The `Course`
    and `GamePage` full shells and artifact/special-event behavior remain blocked
    on the level-entry and multiplayer race-sync tasks above.
  - Cutover sub-tasks (do after Sections A and B land):
  - [ ] **C1 — Flip `GamePage` default to the real shell.** Gate
    `CampaignTestScreen` behind a debug flag and update these notes to record that
    the full `Course`/`GamePage` shells are unblocked.
  - [ ] **C2 — Port artifact / special-event behavior** onto the real shell from
    `flash/.../PlaceArtifact.as` and `SpecialEvent.as`, wiring the deferred
    `Countdown.beginRace` and `PrizePopup` live-command hooks. Tests:
    `SpecialEventTest` / `PlaceArtifactTest`.

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
- [ ] Port the live level drawing from the source game, x blocks and x lines are
  drawn every frame until everything is ready and the game begins.
  - [x] Draw server-level blocks incrementally before gameplay starts. The
    campaign/game renderer now attaches blocks in frame batches and holds player
    stepping in a `phase=drawing` state until every block is present, instead of
    synchronously drawing the full map. Guarded by `ServerLevelRendererTest`.
  - [ ] Port incremental drawing for authored art lines/objects/text and wire the
    real `finish_drawing` readiness flow around all background layers.

### Physics 1:1 (preserve original quirks/bugs)

The physics port must map 1:1 to the original engine, preserving its quirks and
bugs. Do not "fix" or idealize behavior — replicate the AS3 exactly, including
rounding, ordering, and edge cases.

- [ ] Audit and port item physics/interaction 1:1 (item effects on the
  character and world, timing, and edge cases).
  - [x] Enforce the authored multi-use item reload timing: Laser Gun and Sword
    wait 800ms (22 frames at 27 FPS), Ice Wave waits 1000ms (27 frames), and a
    held item key fires again only when the reload completes.
  - [x] Port Jet Pack fuel depletion and thrust timing. The local harness now
    mirrors `items.JetPack`: 200 fuel ticks, three ammo pips derived from
    remaining fuel, per-frame thrust of `-1.25` above `-5` vertical speed and
    `-0.5` afterward, no fuel use while crouching, and item removal only when
    fuel reaches zero. Guarded by `LocalPlayerControllerTest`.
  - [ ] Complete the remaining item effect, world interaction, and edge-case
    audit against the AS3 item/effect classes and server protocol.
    - [x] Emit teleport-item start/end pop effect coordinates from the local
      controller, matching `items.Teleport` (`x`, `y - 25` before and after the
      120 px move) and suppressing effects when the destination is blocked.
      Guarded by `LocalPlayerControllerTest`.
    - [x] Emit mine-item effect coordinates from the centered placed mine tile,
      rotated with `Data.rotatePoint`, matching `items.Mine`'s `add_effect`
      payload shape. Guarded by `LocalPlayerControllerTest`.
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
  - [x] Remove `lastRequest` marker behavior from the ported player,
    guest-player, and guild routes. `LobbyPopups.showPlayer`,
    `showGuestPlayer`, `showGuild`, and `showGuildByName` now only open their
    authored popup classes, leaving `lastRequest` reserved for still-unported
    routes. Guarded by `PlayerPopupTest` and `GuildPopupTest`.
  - [x] Replace guild link stand-ins with the authored `GuildPopupGraphic`
    flow. `LobbyPopups.showGuild`/`showGuildByName` now open `GuildPopup`,
    load `guild_info.php` with member rows, fill GP/member/prose fields, expose
    PM Everyone for current guild members, and preserve the Shift guild-id
    title toggle. Guarded by `GuildPopupTest`.
- [ ] Implement the remaining bottom-strip destinations: level editor. Preserve
  guest/member visibility and logout side effects.
  - [x] Remove the record-only `lastRequest` marker from the bottom-strip
    store/vault route. The button now opens the authored Vault of Magics popup
    directly, with deterministic coverage that the route no longer mutates the
    placeholder request marker. The catalog, quantity, purchase, FAQ, sale, coin,
    and booster flows are covered by the existing StorePopup implementation.
  - [x] Replace the record-only level-editor click marker with the Flash-shaped
    editor handoff. The lobby computes the permanent-moderator flag before
    leaving, changes pages through the level-editor factory, and closes the
    persistent lobby socket; the full editor implementation remains in the
    level-editor section below. Guarded by `LobbyServicesTest`.
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
  - [x] Dispose active server-level renderer animations on teardown. Removing
    `ServerLevelRenderer` now clears the incremental block-draw listener and
    recursively disposes arrow timelines plus active mine explosion/block-piece
    effects, so race-screen teardown cannot leave their frame listeners alive.
    Guarded by `ServerLevelRendererTest`.

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

The port is complete when no reachable behavior is a placeholder or harness
redirect, the coverage inventory has no unexplained gaps, and deterministic,
protocol, audio, and visual comparisons demonstrate parity with the Flash
client.
