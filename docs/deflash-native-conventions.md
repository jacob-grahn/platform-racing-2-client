# Native presentation conventions

The first two production de-Flash slices are `QuantityPopup` and `MineAppear`.
They establish the conventions below. The AS3/XFL sources remain the visual and
behavioral specification; these conventions change construction and ownership,
not the player-visible result.

## Views and controls

- Give every migrated screen or dialog a concrete `*View` class with `final`
  typed fields for all text and interactive children. The owner invokes those
  fields directly; it never discovers them through linkage strings or instance
  names.
- Use `NativeView.ownControl`, `ownAnimation`, and `listen` for resources owned
  by a view. The owner calls `dispose()` exactly once from its existing removal
  path. Callback fields must be cleared during disposal.
- Use `GameButton`, `GameSlider`, and later native controls for actual input.
  Preserve mouse, focus, tab order, keyboard, disabled, and cancellation paths.
  Do not substitute a visual-only click target for a real control.
- Keep existing popup behavior where it is already part of the public flow.
  `Popup` now draws its modal overlay directly with OpenFL, while its fade
  events, centering, open-popup tracking, and teardown contract stay unchanged.

## Assets and layout

- Add a typed identifier to `tools/native-assets.json`, regenerate
  `NativeAssetIds.hx`, and add an explicit `Project.xml` asset mapping for each
  leaf asset a native view owns. A native view may use an exported SVG leaf or
  recovered original bitmap, but must not construct a generated catalog symbol.
- Reuse the original source artwork. `QuantityPopupView` uses the exported
  `ShadowBG` SVG leaf at its authored transform; `MineAppearAnimation` uses the
  recovered original `assets/bitmaps/mine.jpg` payload. This keeps visual decisions in the
  parity source instead of hand-redrawing them.
- Copy authored positions, dimensions, colors, and transforms into named native
  layout code. Keep the source symbol/frame reference in the class doc comment
  or test so a future correction has an unambiguous source of truth.

## Animation and effects

- Model authored playback with `AnimationClip` and an owner-driven
  `AnimationClock`. The display owner advances its clock once per
  `ENTER_FRAME`; the clip owns completion and never depends on an implicit
  timeline frame script.
- Put completion behavior (world mutation, removal, callbacks, sound timing)
  in the typed effect/view owner. Completion must be idempotent and disposal
  must stop both clock and listeners.
- Characterize key authored frames, total lifetime, final-frame behavior, and
  completion in deterministic tests. For bitmap effects, also assert that the
  native asset is the original XFL payload rather than replacement artwork.

## Required parity proof for later slices

For every migrated production slice, retain a focused real-flow test covering
success, cancellation, disabled/error, focus/keyboard, and teardown as
applicable. Add representative visual checks: authored layout/transform values,
original asset provenance, and pixel/screenshot comparison whenever the flow
has a stage harness. Keep the legacy catalog renderer only in test code when it
is useful as an oracle; it must not remain on the production path.
