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
- [x] character dissapears during rotation animation after hitting a rotate block. After the rotation the character reappears, but the camera is far away and takes a few frames to snap back to the character
- [x] blocks should play a bump animation when bumped from below or shot from the side
  - [x] animate the block when bumped from below
  - [x] animate the block when shot from the side
- [x] arrow blocks don't work right afer rotating a level with a rotate block
- [x] character dissapears when in water (perhaps the character is rendering behind the background?)
- [x] happy and sad blocks should deactivate/grey out after one use
- [x] happy and sad blocks should play sound effects when bumped
 

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
  - [x] Jiggmin hat (id 13, `JIGG`): while falling (`velY > 0`), squash remote
    players below you (bounce + `squash` command via `maybeSquash`).
  - [x] Artifact hat (id 14, `ARTIFACT`):
    - [x] Gameplay power: 30 s `speedBurst`, clamp the course timer to 30 s,
      reversed controls, `YeahSound`/music feedback, and removal cleanup
      (clear speed burst, restore controls).
    - [x] Render the silent blue `Zap` flash visual on activation.
  - [x] Jellyfish hat (id 15, `JELLYFISH`): periodically sting nearby players
    (`stingCooldown` + `maybeSting`) and be immune to the sting `hurt` reaction.
  - [x] Cheese hat (id 16, `CHEESE`): cosmetic only (secondary-color
    transparency workaround) — no gameplay power.
  - [x] Port the hat-attack game-mode loose-hat lifecycle. `effects.Hat`
    display/pickup is partially ported in `gameplay/HatEffect.hx`.
    - [x] Drop the highest equipped hat on a hat-mode hit and emit Flash's
      `loose_hat` drop command.
    - [x] Complete `get_hat` pickup parity.
    - [x] Complete `returnHatToStart`/`hat_to_start` bounds parity.
- [x] Port the full `effects.Egg` PhysicsEffect movement/attack/squash visuals.
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

- [x] Port Jet pack fuel/thrust,
  [x] Port multi-use reload timing (Laser Gun/Sword/Ice Wave)
  [x] Port teleport/mine effect
  [x] Port speed-burst expiry
  [x] Port lightning
  [x] Port mine item
  [x] Port block item

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
