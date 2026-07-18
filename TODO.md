# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

#### De-Flash The Haxe/OpenFL Architecture

The production presentation layer has been migrated away from the Animate/XFL
compatibility runtime, but removal of the runtime did not prove visual or
behavioral parity. The current phase is a systematic audit of every migrated
production root against `flash/**/*.as` and
`flash/platform-racing-2-xfl/`. Treat the legacy client as the specification,
not merely as an implementation reference.

Do not mark an audit complete because a native view exists, a linkage is absent,
or the happy path works. Completion requires evidence for the observable parts
that apply: exact layout and registration points, artwork and colors, masks and
filters, layer order, text/font metrics, mouse and keyboard interaction, focus,
disabled/loading/error states, animation frames and timing, sound cues, modal
stacking and fades, teardown, and the resulting navigation or network action.
Add focused deterministic tests plus an HTML5 screenshot or replay sequence that
compares the migrated flow with the AS3/XFL reference.

The migration replaced reflective Flash timeline access with concrete, typed
Haxe views. The historical pattern loaded an authored symbol and discovered its
controls by string name:

```haxe
art = PR2MovieClip.fromLinkage("SomePopupGraphic");
nameBox = LobbyArt.text(art, "nameBox");
button = DisplayUtil.findByName(art, "ok_bt");
```

The current pattern is an ordinary Haxe view whose structure is explicit and
checked by the compiler:

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

The original change was intended to affect only code structure and the asset
pipeline. Layout, artwork, animation, sound, timing, behavior, and user flows
must still match. `docs/deflash-symbol-inventory.md` records the generated
production boundary, while `tools/deflash-boundary-allowlist.json` preserves the
historical maximum legacy dependencies for regression detection. `./test.sh`
must continue rejecting new production `PR2MovieClip`, `Fl*`, or generated-XFL
timeline dependencies while the audit uses archival tooling outside production.

Campaign payload reference:

- Campaign lists are fetched from `pr2hub.com/files/lists/campaign/{page}` and
  validated with `MD5(ret.substr(10, len - 53) + "984cn98c54$")`.
- Level data is fetched from `pr2hub.com/levels/{id}.txt?version={v}` and
  validated with `MD5(version + id + levelData + "0kg4%dsw")`.
- The decoded `levelData` is `&`-joined URL-encoded vars passed through
  `validateSaveString`; `data` is backtick-delimited with read mode in
  `data[0]` and the relative-coordinate block string in `data[1]`.

##### Audit Migrated Production Features

Audit the shared primitives first because a single mismatch can affect many
roots. Each item needs comparison evidence, not only a unit test of the native
API.

###### Production root parity audits

This is the former migration boundary from
`docs/deflash-symbol-inventory.md`. Each unchecked item is a new audit of one
unique migrated root, including every production call site. Complete an item
only after its native replacement has been compared with the AS3 owner and XFL
symbol and the applicable visual, behavioral, timing, sound, failure, and
teardown paths are covered by focused tests and screenshot/replay evidence.

##### Compatibility-Runtime Removal Audits

- [ ] Re-run representative end-to-end flows against both archival Flash and the
  native client before declaring the de-flash goal complete; dependency removal
  alone is not an acceptance criterion.
  - Audit note: Focused deterministic tests cover native behavior only; there is no current
    dual-client evidence bundle for intros, login, lobby, gameplay/effects, editor, and
    character flows, so retain this final acceptance audit. The machine-checked matrix in
    `docs/deflash-dual-client-acceptance.json` records the missing shared replays/evidence and
    the current macOS Flash synthetic-click blocker without treating native-only proof as parity.


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
