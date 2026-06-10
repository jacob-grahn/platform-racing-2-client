# Initial Playable Scope

The first playable milestone should prove the Haxe/OpenFL port can enter a
course, render enough of it to orient the player, and move one local character
with Flash-like timing. It should stay small enough to debug against the Flash
baseline captures and the decompiled AS3.

## Milestone Target

- Launch directly into a local gameplay harness from the OpenFL app.
- Load a committed fixture level, not a live server level.
- Render a simple blocks-only course with:
  - one player start block
  - a flat run of basic solid blocks
  - one finish block
  - a small water or ice section if the first collision pass supports it cleanly
- Display one local character centered on the stage with selectable placeholder
  or generated timeline art.
- Support left, right, jump, and down/crouch input.
- Advance movement on the 27 FPS fixed frame cadence.
- Restart the fixture level without reloading the page.
- Expose a compact debug readout for position, velocity, grounded state,
  animation state, current frame, and touched block type.

## Out Of Scope

- Login, lobby, chat, multiplayer, and real server socket protocol.
- Full level browser or editor flow.
- Items, hats, prizes, campaign progression, and experience gain.
- Moving, rotating, crumble, vanish, teleport, mine, item, and custom-stat block
  behavior.
- Pixel-perfect art parity. Placeholder block or character art is acceptable
  while the vector rendering milestone is still open.
- Mobile packaging. Browser remains the required target.

## Implementation Order

1. Add a gameplay harness state reachable from `Main`.
2. Define a tiny typed fixture format for blocks, start position, finish
   position, gravity, and stat defaults.
3. Render fixture blocks at PR2 tile scale with obvious colors or generated
   asset clips.
4. Port the minimum local character state needed for horizontal movement,
   jumping, crouching, gravity, and collision against solid tiles.
5. Wire the existing keyboard state into the harness.
6. Add deterministic debug state export so scripted comparison can inspect
   behavior without relying only on screenshots.
7. Add one runtime test or headless simulation test for fixed-frame movement on
   the flat fixture.

## Acceptance

- `haxelib run openfl build html5` succeeds.
- The browser build can start the fixture level without network access.
- The local player can run, jump, crouch, land on the flat course, and reach the
  finish block.
- The debug state is deterministic for a scripted input sequence.
- At least one screenshot from the harness can be compared with the existing
  Flash gameplay-start baseline to validate stage framing and scale.
