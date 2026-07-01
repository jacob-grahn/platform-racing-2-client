# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

## Parity Rules

- Treat `flash/**/*.as` and `flash/platform-racing-2-xfl/` as the behavioral and
  visual specification. Do not silently simplify a workflow because the happy
  path works.
- Temporary drawings, record-only actions, harness redirects, hard-coded data,
  and unsupported buttons are parity gaps and must remain listed here.
- A task is complete only when the real user flow works. Rendering the art or
  recording the requested action is not completion.
- Run only the related test cases for your change, the full suite is a bit slow

## Bugs
- [ ] after rotating once with a rotate block, player can walk to the left and go through walls
- [ ] art backgrounds line art is drawn too thick
- [ ] the arrows on arrow blocks dissapaer a few seconds after touching them
- [ ] move blocks don't move
- [ ] move blocks don't display their direction arrow before moving

## Current Priority: Real Login-to-Race Flow

The level-entry decomposition, the multiplayer `Character`/`LocalCharacter`/
`RemoteCharacter` system and its emission/interpolation/lifecycle, the in-game
`Course`/`GamePage` shell, the HUD widgets, the 3-2-1 countdown, prize and
special-event behavior, and incremental level drawing are all ported and
unit-covered (see README). What remains is the end-to-end acceptance and the
still-unported popup/visual side effects.

--------
- [ ] Port the deferred in-race popup side effects behind `GameCommandDelegate`:
- [ ] Port the full `CourseMenu` access/spectate UI around in-place level
  loading
  - [ ] slot selection
  - [ ] password/private flows
  - [x] Port encrypted level-password verification: hash with
    `LEVEL_PASS_SALT`, decrypt the Flash `result` payload with
    `LEVEL_PASS_KEY`/`LEVEL_PASS_IV`, and gate access on matching
    `level_id`/`access == 1`.
  - [ ] Port private/full slot selection behavior.
  - [ ] Port CourseMenu loading/cancel/error state visuals.
  - [ ] Port spectate UI wiring around in-place loading.

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

- [ ] Port hats and hat powers. The appearance/hat-stack model
  (`resetHats`/`setHats`/`getHighestHat` and the hat-id → power-flag map) is
  already ported in `Character`; remaining work is the per-power gameplay
  behavior in `LocalCharacter` plus the hat-attack loose-hat lifecycle. Port one
  power at a time (AS3 refs are `character/Character.as` and
  `character/LocalCharacter.as`):
  - [x] Propeller hat (id 4, `PROP`): holding Up while falling (`velY > 0`)
    multiplies `velY` by 0.85 to slow the descent.
  - [x] Cowboy hat (id 5, `COWBOY`): while airborne, force swim/`water` mode
    (`waterTicks`); apply stat boost (`maxVelX >= 12`, `accel >= 1.86`,
    `SuperJump = 4.5`) via `ensureCowboyStats`, and `resetStats` when removed.
  - [x] Crown (id 6, `CROWN`): invincibility — immune to death except in `dm`
    and `hat` game modes.
  - [x] Santa hat (id 7, `SANTA`): stand on water/safety blocks (`onStand` while
    over a `WaterBlock`/`SafetyBlock`); +1 `maxVelX` via `ensureSantaStats`, and
    `resetStats` when removed.
  - [x] Party hat (id 8, `PARTY`): immune to the `hurt` mode reaction from
    sting and zap.
  - [x] Top hat (id 9, `TOP`): pass through `VanishBlock`s.
  - [x] Jump-start hat (id 10, `JUMP_START`): on equip, grant a 2000 ms
    `speedBurst` item.
  - [x] Moon hat (id 11, `MOON`): low gravity (course gravity × 0.85);
    `resetGravity` when removed.
  - [ ] Jiggmin hat (id 13, `JIGG`): while falling (`velY > 0`), squash remote
    players below you (bounce + `squash` command via `maybeSquash`).
  - [ ] Artifact hat (id 14, `ARTIFACT`): 30 s `speedBurst`, clamp the course
    timer to 30 s, reversed controls, plus `Zap`/`YeahSound`/music feedback;
    clean up (clear speed burst, restore controls) when removed.
  - [ ] Jellyfish hat (id 15, `JELLYFISH`): periodically sting nearby players
    (`stingCooldown` + `maybeSting`) and be immune to the sting `hurt` reaction.
  - [x] Cheese hat (id 16, `CHEESE`): cosmetic only (secondary-color
    transparency workaround) — no gameplay power.
  - [ ] Port the hat-attack game-mode loose-hat lifecycle: drop your highest hat
    on bump (`getHighestHat` → `loose_hat`), `get_hat` pickup, and
    `returnHatToStart`/`hat_to_start` when a hat leaves the map bounds.
    `effects.Hat` display/pickup is partially ported in
    `gameplay/HatEffect.hx`.
- [ ] Port the full `effects.Egg` PhysicsEffect movement/attack/squash visuals.
  The egg round command boundary is already wired.
- [ ] Port captcha.
- [ ] Port rank progression.
  - [x] Wire in-race `award` and `setExpGain` commands into the authored
    `FinishedPage` overlay: awards queue before the popup exists, later awards
    update it live, and exp gain marks the player done without emitting a quit.
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
  - [x] Port level-info moderation/unpublish actions.
    Done: moderators see the authored `unpublish_bt`, open
    `ChooseLevelModModePopup`, confirm Unpublish/Restrict, POST
    `level_moderate.php` with `level_id`/`action`, and successful responses fade
    the level-info and moderation popups.
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
