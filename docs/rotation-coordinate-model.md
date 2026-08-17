# Rotation coordinate model

The port preserves Flash PR2's rotation-local physics model. It does not keep a
character's raw `x` and `y` stable when gravity rotates.

## Coordinate spaces

- **Canonical map space** owns blocks, block segments, runtime level changes,
  Snake tiles, and minimap positions. It is shared by every participant.
- **Gravity-local space** owns character, loose-hat, egg, laser, and ice-wave
  physics. A rotation commit rewrites these coordinates so gravity remains the
  positive local Y direction.
- **Effect-packet space** is the coordinate representation used by a particular
  Flash `add_effect` payload. Most projectiles send gravity-local coordinates;
  mines use their own historical encoding.
- **Display space** is the observing client's unrotated character/effect plane.
  A sender-local projectile must be reprojected into this frame.

Use `CoordinateFrames` for conversions. Do not reproduce rotation signs at call
sites.

```text
canonical = canonicalFromGravity(local, courseRotation)
local = gravityFromCanonical(canonical, courseRotation)
receiverLocal = gravityBetween(senderLocal, senderRotation, receiverRotation)
```

`RotationMath.rotatePoint` intentionally preserves ActionScript integer
coercion and single-wrap angle normalization.

## Flash packet compatibility

The wire layouts remain unchanged.

| Effect | Position representation | Rotation metadata |
|---|---|---|
| Laser | Sender gravity frame | Included |
| Ice Wave | Sender gravity frame | Included |
| Mine | Mine-specific rotated map centre | Included |
| Hat | Sender gravity frame | Included |
| Slash | Sender gravity frame | Not included |
| Teleport | Sender gravity frame | Not included |
| Block activation | Canonical segment | Push direction only |
| Snake | Canonical segment | Direction is canonical |

`EffectPackets` decodes the rotation-aware item layouts into typed values before
gameplay or rendering consumes them.

## Legacy limitations

Slash, Teleport, and Push activation do not carry enough sender-frame metadata
to reconstruct every cross-rotation presentation from the packet alone. This is
part of the Flash protocol. Do not append fields, infer from potentially stale
remote-player state, or silently redefine payload directions without an
explicitly versioned compatibility design.

## Implementation rules

1. Gameplay authority converts to canonical map space before changing blocks.
2. Rotation-local physics stays in its originating gravity frame and is
   reprojected for the observing client.
3. Rendering APIs receive display-ready coordinates; renderers do not decode
   network packets.
4. Use `LevelRenderer.courseRotationDegrees` for committed Flash
   `blockBackground.rotation`. The inherited `Sprite.rotation` is unrelated.
5. Preserve all ActionScript truncation and right-angle sign conventions.
6. Test every rotation-aware packet across the 4 × 4 sender/receiver matrix:
   `0`, `90`, `180`, and `-90` degrees.
