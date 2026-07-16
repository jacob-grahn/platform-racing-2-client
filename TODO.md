# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

#### De-Flash The Haxe/OpenFL Architecture

The application, networking, data, and gameplay layers are already largely
ordinary Haxe/OpenFL code, but the presentation layer still interprets the
Animate/XFL object model at runtime. `PR2MovieClip`, the generated asset catalog,
the `Fl*` controls, linkage-class strings, frame labels, and recursive
instance-name lookup collectively act as a small Flash compatibility runtime.
Replace that runtime incrementally with typed Haxe views, PR2-specific controls,
explicit animation state, and neutral art data. Keep OpenFL as the renderer and
keep the AS3/XFL client as the parity specification throughout the migration.
This is strictly a code-structure and asset-pipeline change: the finished client
must be visually and functionally indistinguishable from the current port. Do
not redesign screens, controls, animations, timing, sound, or user flows as part
of this work. Use the existing deterministic domain tests and screenshot/parity
sequences as regression gates, extending them where a migrated feature does not
yet have enough coverage to prove that its observable behavior is unchanged.

This must be a strangler migration, not a second port running in parallel: each
item should replace a production flow behind the existing deterministic and
screenshot coverage, and the compatibility path should remain available for
unmigrated symbols until it has no production callers.

The presentation layer will move incrementally from reflective Flash timeline
access to concrete, typed Haxe views. For example, current code commonly loads
an authored symbol and discovers its controls by string name:

```haxe
art = PR2MovieClip.fromLinkage("SomePopupGraphic");
nameBox = LobbyArt.text(art, "nameBox");
button = DisplayUtil.findByName(art, "ok_bt");
```

The target is an ordinary Haxe view whose structure is explicit and checked by
the compiler:

```haxe
class ConfirmDialogView extends Sprite {
	public final message:TextField;
	public final confirmButton:GameButton;
	public final cancelButton:GameButton;

	public function new() {
		super();
		// Explicit construction and layout.
	}
}
```

This is a code-structure and asset-pipeline migration only. Layout, artwork,
animation, sound, timing, behavior, and user flows must remain unchanged, with
the deterministic and screenshot/parity tests acting as regression gates. See
`TODO.md` for the incremental migration plan and
`docs/deflash-symbol-inventory.md` for the generated production boundary.
`tools/deflash-boundary-allowlist.json` records the maximum legacy dependencies
of the current migration adapters. `./test.sh` checks both generated inventories
and rejects a new `PR2MovieClip`, `Fl*`, or generated-timeline dependency; the
allowlist may shrink as views are migrated, but should not grow.

Campaign payload reference:

- Campaign lists are fetched from `pr2hub.com/files/lists/campaign/{page}` and
  validated with `MD5(ret.substr(10, len - 53) + "984cn98c54$")`.
- Level data is fetched from `pr2hub.com/levels/{id}.txt?version={v}` and
  validated with `MD5(version + id + levelData + "0kg4%dsw")`.
- The decoded `levelData` is `&`-joined URL-encoded vars passed through
  `validateSaveString`; `data` is backtick-delimited with read mode in
  `data[0]` and the relative-coordinate block string in `data[1]`.

##### Prove The Migration Path

- Port one representative, modest dialog end to end. It should include static
  art, text, at least two buttons, one editable/selectable control, focus and
  keyboard handling, open/close animation, and listener cleanup. Remove that
  dialog's catalog/runtime dependencies and verify its real user flow plus
  screenshot parity before choosing the broader UI migration pattern.
- Port one simple gameplay effect end to end. Replace its linkage lookup,
  timeline playback, frame script, and completion detection with the native
  animation API, then add deterministic lifetime and visual parity coverage.
- Document the resulting view, control, asset, animation, ownership, and
  teardown conventions. Update the generator/tooling only after these two
  vertical slices demonstrate which data a native implementation actually
  needs.

##### Migrate Production Features

- Replace static timeline symbols with direct SVG/bitmap assets or explicit
  OpenFL display compositions. Start with modal overlays, HUD decorations,
  block overlays, and other leaf visuals that have no named interactive
  children or authored animation.
- Replace button-like and state-only timelines with typed enums and native
  controls. Migrate shared UI helpers such as tabs, rating stars, navigation,
  arrows, progress bars, and scroll bars before converting the screens that use
  them.
- Migrate routine dialogs and forms to concrete typed views, grouped by shared
  behavior rather than by catalog order. Each migrated dialog must retain its
  loading, error, disabled, focus, keyboard, and teardown paths—not only its
  successful click path.
- Migrate lobby pages, listings, account/customization views, and level-browser
  UI after their shared controls and row/list primitives are native. Remove
  `LobbyArt`/`DisplayUtil.findByName` access as each view becomes typed.
- Migrate level-editor menus, option popups, cursors, stamps, and block-setting
  controls. Preserve live editing, save/load, report/moderation, and test-course
  flows, and run the focused level-editor and UI parity coverage for each batch.
- Replace gameplay effects and animated HUD elements with explicit native
  clips. Move every linkage-specific frame script currently installed inside
  `PR2MovieClip` into the owning typed effect/view and characterize its exact
  looping, stopping, sound, and completion behavior in tests.
- Rebuild the intro as an explicit composed animation with native sound cues
  after the common animation primitives are stable. Preserve site-mode branches,
  skip/play interactions, timing, labels that affect behavior, and final page
  transition parity.

##### Native Character Rig

- Specify a PR2 character-rig format with typed animation states, a stable
  attachment hierarchy, interchangeable head/body/feet/hat parts, primary and
  secondary tint channels, held-item/weapon sockets, and explicit frame timing.
  Initially generate this neutral format from XFL so artwork is not manually
  re-authored during the runtime migration.
- Implement a native `CharacterView` that consumes the rig without
  `PR2MovieClip`, numeric part timelines, or recursive named-child discovery.
  Keep gameplay state and physics outside the renderer and make animation
  advancement deterministic from the gameplay clock.
- Port character states and part/color combinations in parity-tested batches,
  including standing, running, jumping, super-jumping, crouching, swimming,
  frozen/bumped states, multiple hats, Fred-body placement, epic colors, held
  items, weapon actions, and particle/effect attachment points.
- Switch gameplay, lobby previews, editor previews, and player listings to the
  same native character implementation. Delete the old character timeline path
  only after all consumers and the existing character screenshot matrix pass.

##### Remove The Compatibility Runtime

- Change asset generation to emit only assets and neutral data still consumed
  by native views. Stop packaging unreachable XFL symbol metadata and remove
  catalog partitions as their final production consumers disappear.
- Remove the `Fl*` controls, `FlComponentFactory`, recursive timeline-name
  access, linkage factories, runtime frame scripts, timeline sound dispatch,
  flattening analyzers, and `PR2MovieClip` in dependency order. Keep preview or
  archival XFL tooling outside the production build if it remains useful for
  parity investigation.
- Add a final build-time check that production source and output contain no
  `PR2MovieClip`, `Fl*`, linkage-class, frame-script, or generated XFL timeline
  dependencies. Run the related domain suites and representative screenshot
  sequences, audit HTML5 payload/performance, and update `README.md` to describe
  the native architecture and one-way legacy asset migration workflow.


#### Build Size And HTML5 Payload

- Investigate removing unused generated asset metadata from the final JS.
  `AssetCatalog.media()` and `AssetCatalog.linkageClasses()` do not appear to
  have runtime callers, but their bitmap/sound/linkage literals still survive
  into `PlatformRacing2.js`.
- Investigate dropping `assets/fonts/DejaVuSans-BoldOblique.ttf`. Current
  generated text faces include Verdana, Verdana-Bold, and Verdana-Italic, but no
  Verdana-BoldItalic; the file is about 632 KB raw / 329 KB gzipped.
- Investigate making audio assets non-preloaded. The audio files are needed at
  runtime, but the broad `assets/` include appears to preload about 1.5 MB raw /
  1.28 MB gzipped of sounds up front.
- Revisit lossless SVG minification if the asset payload grows. A conservative
  SVGO 4.0.1 trial across all 2,130 files reduced the SVG tree from 5,512,063 to
  5,061,915 bytes: about 450 KB raw (8.17%), but only 33 KB gzipped (1.76%). The
  ten largest SVGs produced byte-identical 1100-pixel Inkscape renders. Before
  adopting the pass, add OpenFL render coverage and fix the XML-invalid `--`
  inside the comment in `art/svg/login/login_page_no_logo.svg`.

#### HTML5 Multiplayer Transport

- Replace the temporary hard-coded `wss://pr2hub.com/gameservers/{server_id}`
  browser routing hack with a configured, server-advertised WebSocket endpoint.
  `ServerInfo.websocketUrl()` currently discards the advertised address and port
  so the HTML5 client can connect through the PR2Hub relay.

#### Native Mobile Targets

- Add an explicit mobile build configuration for the native `ios` and `android`
  targets. Define `pr2_mobile_ui` when Lime's `mobile` condition is active, use
  the device's full resolution, force landscape orientation, and keep the
  existing desktop/HTML5 presentation unchanged.
- Replace the current fixed `550 x 400`, `NO_SCALE` behavior on mobile with a
  root viewport that:
  - lays out inside the iOS/Android safe area;
  - preserves a centered `550 x 400` logical game area without cropping;
  - uses the extra landscape width as control gutters where possible; and
  - falls back to translucent controls over the course on narrower displays.
- Add resize/orientation/lifecycle handling. Recompute the viewport when the
  usable bounds change and clear all held input when the app is deactivated,
  interrupted, backgrounded, or covered by a modal screen.
- Build an offline native mobile smoke-test route first. It must load a course,
  render all assets and HUD elements, play audio, and complete a race on real
  iOS and Android devices before native login/lobby work is considered stable.
- Validate the pinned hxcpp `v4.3.146` upgrade on physical Android devices,
  including an affected older device/architecture that would expose the hxcpp
  4.3.2 `__atomic_compare_exchange_4` startup failure. Pin and document the
  remaining known-working JDK, Android SDK, and NDK versions.
- Add target-specific app metadata and packaging: icons, launch screens, bundle
  identifiers, supported orientations, permissions, Android signing, iOS
  provisioning, and release build instructions.
- Audit native behavior for HTTP GET/POST requests, cookies and sessions,
  `SharedObject` persistence, saved accounts, dynamic audio loading, embedded
  fonts, soft-keyboard text entry, external links, and fatal-error reporting.

##### Native Multiplayer Transport

- Extract `LobbySocket`'s JS WebSocket implementation behind a shared transport
  interface so login, frame buffering, pinging, command dispatch, disconnects,
  and reconnection policy do not depend on a specific socket implementation.
- Implement the native transport with a direct TCP socket unless device testing
  reveals a material platform or TLS disadvantage. The multiplayer server
  supports direct socket connections as well as WebSockets, so prefer the direct
  connection to avoid adding a native WebSocket dependency.
- Run socket I/O away from the render thread, marshal received frames back to
  the OpenFL thread, preserve the protocol's `\x04` frame delimiter across
  partial reads, and make writes safe when lifecycle callbacks race a close.
- Verify native login, lobby reuse of the login connection, ping timing,
  clean/unclean disconnects, background/resume behavior, and reconnect failure
  states against a live server on both iOS and Android.
- Decide and document whether native release connections require encryption or
  another transport security layer. Do not silently send credentials over an
  untrusted plaintext TCP connection merely because direct sockets are easier.

##### Mobile Gameplay Controls

- Introduce a shared player-input aggregator instead of synthesizing keyboard
  events. Keyboard and touch sources should independently contribute to the
  existing `LocalPlayerInput` actions without changing character physics,
  item behavior, or network emission.
- Add a mobile-only six-button race overlay:
  - left side: move left, jump, and item;
  - right side: move right, jump, and item; and
  - duplicate jump/item buttons should support either hand and simultaneous
    presses without one button's release cancelling the other button's hold.
- Handle touch input explicitly with `TOUCH_BEGIN`, `TOUCH_MOVE`, `TOUCH_END`,
  and stable `touchPointID` ownership. Support sliding between controls and
  release touches that end outside their original button.
- Give controls large adjustable hit areas, clear pressed feedback, safe-area
  padding, and configurable size, opacity, handedness, and position. Ensure the
  overlay sits above the course/HUD but below modal and finished-race screens.
- Add deterministic tests for multi-finger input aggregation, duplicated
  jump/item holds, touch cancellation, focus loss, reversed controls, item
  press/release semantics, and course rotation.
- Add device tests for common play combinations, including run+jump, run+item,
  changing direction while jumping, and holding jetpack/item input.

##### Proper Mobile Lobby

- Run the completed mobile lobby through native login, soft-keyboard, safe-area,
  popup, race-return, and rotation tests on representative physical iOS and
  Android phones/tablets before release. Browser coverage is available with
  `?screen=lobby&mobile=1` (and `offlineLists=1` for deterministic level data).
