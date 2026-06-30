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
- Run only the related test cases for your change, the full suite is a bit slow

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
  - [x] `Hat` popup.
    - [x] Port `maybeReturnHatToStart`: out-of-bounds loose hats are removed,
      respawned at the matching start block when one exists, and their remote
      remove command/display lifecycle is deterministic.
    - [x] Port loose-hat `PhysicsEffect` stepping and local-player pickup:
      gravity, active-block landing/wall clamp, display rotation, `get_hat`
      emission, and done-playing suppression are deterministic.
- [ ] Port the remaining character visual-effect hooks that are currently
  stubbed behind injectable hooks:
  [x] particle emitters
  [ ] jet-pack flame,
  [ ] `DjinnEffects`
  [ ] per-state sound playback.
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

### Physics 1:1 (preserve original quirks/bugs)

The physics port must map 1:1 to the original engine, preserving its quirks and
bugs. Do not "fix" or idealize behavior — replicate the AS3 exactly, including
rounding, ordering, and edge cases.

- [ ] Port Jet pack fuel/thrust,
  [ ] Port multi-use reload timing (Laser Gun/Sword/Ice Wave)
  [ ] Port teleport/mine effect
  [ ] Port speed-burst expiry
  [ ] Port lightning
  [ ] Port mine item
  [ ] Port block item

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
  - [x] Apply returned `level_data.php` fields to the authored popup display.
- [ ] Port the level-info report/rating/moderation actions.
  - [x] Port member level-report popup flow: authored report dialog, blank-reason
    error, confirmation, and `level_report.php` upload fields.
  - [x] Port level-info rating action.
    - [x] Port the Flash rating hover cover and numeric `HoverPopup`.
  - [ ] Port level-info moderation/unpublish actions.
- [ ] Port the admin/moderation popups.


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

Acceptance: a user can load, edit, test, save, and reopen a real level with the
same serialized meaning and visible result as Flash.
