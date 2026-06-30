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


## bugs (see how it works in the source flash game before implementing fixes)
- [ ] character can move before the 321 countdown is done
- [ ] character should appear below water blocks, they should fade out some when near
- [ ] arrow blocks loose their arrow after they have been touched. The push animation plays, then the arrow is gone
- [ ] sword doesn't work
- [ ] super jump sound doesn't play
- [ ] jump sound doesn't play
- [ ] block bump sound doesn't play
- [ ] item block sound doesn't play
- [ ] probably some other sound effects don't play, they seem to have been missed so far
- [ ] poof visual effect and sound effect missing when touching a safety net
- [ ] art layers don't show up until they are done drawing


## Current Priority: Real Login-to-Race Flow

The level-entry decomposition, the multiplayer `Character`/`LocalCharacter`/
`RemoteCharacter` system and its emission/interpolation/lifecycle, the in-game
`Course`/`GamePage` shell, the HUD widgets, the 3-2-1 countdown, prize and
special-event behavior, and incremental level drawing are all ported and
unit-covered (see README). What remains is the end-to-end acceptance and the
still-unported popup/visual side effects.

--------
- [x] Run one uninterrupted real-server session: an account and a guest each log
  in, select/join a level, race with synchronized remote players, finish or
  quit, and return to the lobby without a page reload. Add a deterministic
  transcript test covering the full command/state sequence and screenshots for
  level entry, countdown, racing, and finish. This is the acceptance that flips
  the level-entry and race-sync milestones to done.
  Done: the live two-instance run is `tools/race_session.py` (drives two headless
  Chrome clients against pr2hub.com — account + guest co-join a campaign level,
  race with `remote-count >= 1`, quit, and return to the lobby; captures the
  level-entry/countdown/racing/finished screenshots per role). The CI-runnable
  counterpart is `RaceSessionTranscriptTest` (in the deterministic suite), which
  drives the production `LevelItem`/`GamePage`/`Course` objects through the whole
  join -> race -> quit -> return lifecycle and asserts the ordered wire-command
  transcript plus the level-entry/race-phase state at each transition.
- [ ] Port the deferred in-race popup side effects behind `GameCommandDelegate`:
  - [x] `LuxPopup`.
  - [ ] `Egg` popup.
    - [x] Mount authored `EggGraphic` instances for `addEggs` and remove them
      on collect, remote removal, reseed, and course teardown.
    - [x] Port the egg collection sound with Flash game-sound attenuation.
    - [x] Port the Flash `PhysicsEffect` egg movement step: gravity, active-block
      landing, grounded wall reversal, egg-mode wrapping, facing, fade-in, and
      local-player touch collection.
    - [x] Port the animated egg attack side effects.
      - [x] Port the Flash egg attack probe, add_effect payloads, and 120-frame
        cooldown.
      - [x] Mount and animate the local Slash/Laser/IceWave effect visuals from
        egg attacks.
    - [x] Port the animated egg squash/remove side effect.
  - [ ] `Hat` popup.
- [ ] Port the remaining character visual-effect hooks that are currently
  stubbed behind injectable hooks: particle emitters, jet-pack flame,
  `DjinnEffects`, and per-state sound playback. The held-weapon display frame is
  now wired to the authored `weapon` clip across character animation states.
- [ ] Port the full `CourseMenu` access/spectate UI around in-place level
  loading (slot selection, password/private flows, loading/cancel/error states)
  from `flash/level_browser`, `flash/page/GamePage.as`, and
  `flash/gameplay/Game.as`. In-place load via `confirm_slot`/`startGame`, the
  `SpectatePicker` boundary, and the `LevelEntry` machine already work.

Acceptance: an account and a guest can each enter a real race over WebSocket,
see synchronized remote players, finish or quit, and return to the lobby without
a page reload. A deterministic transcript test verifies the full command/state
sequence and screenshots cover level entry, countdown, racing, and finish.

## Gameplay Fidelity

Character-part registration, the `LocalCharacter` and block-physics audits, and
real level decoding/rendering are complete (see README). Remaining work is the
item-physics audit below plus unported gameplay subsystems.

Port gameplay behavior not represented by the local harness, one subsystem at a
time:

- [ ] Port hats and hat powers.
- [ ] Port the full `effects.Egg` PhysicsEffect movement/attack/squash visuals.
  The egg round command boundary is already wired.
- [ ] Port the deathmatch hearts gameplay behavior (the `Hearts` HUD widget is
  already ported).
- [ ] Port captcha.
- [ ] Port rank progression.
- [ ] Port race modes.
- [ ] Port the remaining server-authoritative interactions.

### Physics 1:1 (preserve original quirks/bugs)

The physics port must map 1:1 to the original engine, preserving its quirks and
bugs. Do not "fix" or idealize behavior — replicate the AS3 exactly, including
rounding, ordering, and edge cases.

- [ ] Complete the remaining item effect, world-interaction, and edge-case audit
  against the AS3 item/effect classes and server protocol. Jet pack fuel/thrust,
  multi-use reload timing (Laser Gun/Sword/Ice Wave), teleport/mine effect
  emission, super-jump crouch, speed-burst expiry, lightning, mine
  blocked-placement, and the base item availability/release gates are done (see
  README).

Acceptance: scripted input and server transcripts produce matching Flash debug
state at agreed checkpoints, and representative race screenshots stay within
documented image-diff thresholds.

## Lobby and Account Completion

The lobby shell and tabs exist, but a number of interactions are still
record-only or fixture-driven. Audit every reachable control against the AS3; do
not infer completion from the presence of a tab or exported symbol. The
player, guest-player, guild, send-message, external-link, level-info shell,
Options, Credits, store/Vault, and level-editor-handoff routes are functional
(see README).

Finish the still-unported lobby popup routes, one at a time:

- [ ] Port the level-info popup data population.
- [ ] Port the level-info report/rating/moderation actions.
- [ ] Port the admin/moderation popups.

Verify each lobby data surface against real HTTP/socket responses, one at a
time. Each must cover paging, stale and out-of-order responses,
loading/error/empty states, permissions, unread updates, room changes, link
handling, and state restoration after a race:

- [ ] Verify Chat.
- [ ] Verify PMs.
- [ ] Verify Players.
- [ ] Verify Account.
- [ ] Verify Campaign.
- [ ] Verify the level listing.
- [ ] Verify Favorites.
- [ ] Verify Search.
Complete account/profile workflows, one at a time:

- [ ] Port password and email changes.
- [ ] Port outfit and loadout persistence.
- [ ] Port part information.
- [ ] Port guild actions.
- [ ] Port friend/follow/ignore.
- [ ] Port moderation controls.
- [ ] Port rank tokens.
- [ ] Port hotkeys.
- [ ] Port server-driven profile refreshes.
- [ ] Replace any remaining synthetic lobby visuals/data with authored symbols
  and exact Flash typography, masks, scroll behavior, hover/focus states, and
  stacking. Add focused baselines for every popup and non-empty/error state,
  not only the current shell/tab fixtures.

Acceptance: every lobby control performs its original operation against the
real services, all role/guest variants are covered, and no reachable action is
implemented only as a test marker.

## Level Editor and Level Management

The lobby-to-editor handoff (permanent-moderator flag, page change, lobby socket
close) is wired; the editor itself is unported.

Port the editor itself, one piece at a time:

- [ ] Port the `LevelEditor`/`LevelEditorMenu` shell and layout.
- [ ] Port the editor sidebars.
- [ ] Port the editor tools.
- [ ] Port drawing/text/stamp placement.
- [ ] Port block options.
- [ ] Port selection/deletion.
- [ ] Port undo-equivalent behavior.
- [ ] Port camera/zoom.
- [ ] Port editor settings.
- [ ] Port the hats/items/music menus.
- [ ] Port the test-course transition.

Then the level-management flows, one at a time:

- [ ] Port the load flow with its validation, access rules, popups, server
  format, loading/errors, and return navigation.
- [ ] Port the save flow with the same coverage.
- [ ] Port the upload flow with the same coverage.
- [ ] Port the delete flow with the same coverage.
- [ ] Port the report-management flow with the same coverage.
- [ ] Round-trip representative original level payloads without semantic drift;
  compare editor and test-course screenshots with Flash at the same camera and
  selected-tool state.

Acceptance: a user can load, edit, test, save, and reopen a real level with the
same serialized meaning and visible result as Flash.

## Runtime and Visual Coverage

Static-text fidelity, authored-symbol fallback removal, the `FlattenPolicy`
`cacheAsBitmap` optimization, blend modes, Blur/Glow/DropShadow filters,
nine-slice scaling, and the full timeline sound-frame runtime are complete (see
README).

Audit remaining generated-timeline behavior against Flash, one aspect at a time.
Add a reduced fixture for every runtime fix.

- [ ] Audit masks.
- [ ] Audit color transforms.
- [ ] Audit nested frame scripts.
- [ ] Audit dynamic text/font embedding.
- [ ] Audit buttons.
- [ ] Audit unload/disposal.
- [ ] Establish per-screen screenshot thresholds and compare at exact 550x400
  stage size for default, hover, pressed, focused, disabled, loading, populated,
  empty, and error states. Keep visual metrics alongside baselines so "looks
  close" is not the acceptance criterion.
- [ ] Audit cleanup across repeated login/lobby/race/editor transitions: event
  listeners, timers, sockets, bitmap data, audio, and display-list references
  must not leak or duplicate behavior. Nested-clip, audio-monitor-timer, and
  server-level-renderer animation disposal are done (see README).

## Test and Release Matrix

Verify keyboard/focus, rendering, WebSocket, audio, storage, and lifecycle
behavior per browser. Profile long sessions only after behavior is correct, then
optimize without changing parity:

- [ ] Verify Chrome.
- [ ] Verify Firefox.
- [ ] Verify Safari.

Prepare the browser release path, one piece at a time:

- [ ] Port the production proxy/WebSocket configuration.
- [ ] Set up HTTPS.
- [ ] Define the cache/version strategy.
- [ ] Port preload/error handling.
- [ ] Add diagnostics.
- [ ] Ship a public test build.

Then mobile, after browser parity:

- [ ] Port touch controls.
- [ ] Package Android/iOS. Mobile layout adaptations must not alter the canonical
  550x400 game coordinates or browser behavior.

## Final 1:1 Audit

- [ ] Build a source-class coverage inventory mapping every first-party AS3
  class and linkage to its Haxe implementation, deliberate platform adapter, or
  verified unreachable/dead status. An exported asset alone does not count as a
  class port. The `background`, `items`, `blocks` (+`blocks/options`),
  `character`, `chat`, `dialogs`, `social`, `effects`, `gameplay`,
  `level_browser`, `page`, and `sounds` packages are inventoried in
  `docs/source-class-coverage.md` (guarded by
  `SourceClassCoverageInventoryTest`). Remaining: inventory the rest of the
  first-party AS3 packages and reconcile every class. The `com.*`, `lobby`,
  `menu`, `player_profile`, `shop`, `ui`, `levelEditor`, and `level_management`
  packages are now inventoried.
Walk every original user flow and role, one at a time:

- [ ] Walk the guest role end to end.
- [ ] Walk the member role end to end.
- [ ] Walk the moderator/admin role end to end where testable.
- [ ] Walk the login-failure paths.
- [ ] Walk lobby/social/account/store.
- [ ] Walk level browsing.
- [ ] Walk racing/spectating.
- [ ] Walk editor/management.
- [ ] Walk disconnect/reconnect.
- [ ] Walk logout.

The port is complete when no reachable behavior is a placeholder or harness
redirect, the coverage inventory has no unexplained gaps, and deterministic,
protocol, audio, and visual comparisons demonstrate parity with the Flash
client.
