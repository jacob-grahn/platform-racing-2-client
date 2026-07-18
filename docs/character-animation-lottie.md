# Character animation Lottie workflow

All nine native character states use editable standard-Lottie transform
documents as their motion source:

- `stand`, `run`, `jump`, `superJump`, `bumped`, `crouch`, `crouchWalk`,
  `swim`, and `frozen` live under
  `art/intermediate/character-lottie/*.lottie.json`. This intermediate source
  directory is outside the published runtime asset trees.

The documents contain null layers rather than character artwork. The required
layers are `characterRoot`, `heldItem`, `head`, `body`, `frontFoot`, and
`backFoot`. Each slot is parented to `characterRoot`; the runtime attaches the
player's selected and colored SVG artwork after the Lottie transforms have
been compiled into `art/rigs/character-rig.json`.
The frozen state additionally exposes its authored `frozenOverlay` layer.

Each document also carries a versioned `metadata.customProps.pr2` record. It
keeps the state name, end behavior and completion signal, plus each slot's
parent, part kind, optional authored asset, and draw order. These values are
not standard Lottie transform channels, but they are required to round-trip
the Flash timeline without falling back to hidden XFL-only configuration. The
compiler rejects missing, reordered, or malformed metadata rather than
silently guessing it.

Motion uses the standard Lottie `ks` transform properties: anchor (`a`),
position (`p`), scale (`s`), rotation (`r`), opacity (`o`), skew (`sk`), and
skew axis (`sa`). The current compiler profile requires a zero anchor and zero
skew axis. That subset represents all 278 existing character-animation frames
without loss.

After editing a document, regenerate the runtime rig:

```sh
python3 tools/generate_character_rig.py
```

Then run the focused character tests:

```sh
./test.sh --character
```

The normal test gate compares every migrated pose with the archival XFL. If an
intentional redesign should differ from Flash, change that parity policy as an
explicit follow-up rather than silently accepting drift.

To reseed documents from the archival XFL, run the destructive import
explicitly with one or more state names:

```sh
python3 tools/export_character_lottie.py stand run jump superJump bumped crouch crouchWalk swim frozen
```

The exporter is not part of the normal build. Lottie remains the editable
source after the initial import; the native character rig is its generated
runtime representation.
