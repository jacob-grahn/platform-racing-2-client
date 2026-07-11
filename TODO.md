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

## Follow-up Port Gaps

### Shared Infrastructure

#### Build Size And HTML5 Payload

- Further reduce HTML5 payload size by splitting, lazy-loading, or lowering the
  default scale of character atlases. After the first payload pass,
  `export/html5/bin` is about `33.86 MB` raw and `23.71 MB` with gzip; character
  atlas PNGs remain the largest binary bucket and gzip does not reduce them
  meaningfully.
- Investigate removing unused generated asset metadata from the final JS.
  `AssetCatalog.media()` and `AssetCatalog.linkageClasses()` do not appear to
  have runtime callers, but their bitmap/sound/linkage literals still survive
  into `PlatformRacing2.js`.
- Investigate excluding test-only fixtures from the HTML5 export. The broad
  `assets/` include currently ships `assets/fixtures/flat-level.json`, even
  though local campaign test levels are built in code.
- Investigate dropping `assets/fonts/DejaVuSans-BoldOblique.ttf`. Current
  generated text faces include Verdana, Verdana-Bold, and Verdana-Italic, but no
  Verdana-BoldItalic; the file is about 632 KB raw / 329 KB gzipped.
- Investigate making audio assets non-preloaded. The audio files are needed at
  runtime, but the broad `assets/` include appears to preload about 1.5 MB raw /
  1.28 MB gzipped of sounds up front.

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

### Lobby Dialogs And Account Workflows

### Login, Lobby, And Social Lists

### Level Browser And Listings

### Level Editor


### Gameplay, Effects, And Items

- Finish "Don't Move JV" race parity. The shared e2e now captures one gameplay
  screenshot per second for both clients under `test/output/dmjv-{target}/gameplay/`,
  and the old Flash baseline screenshots show the race completing. Current Haxe
  parity fixes include Flash-centered race start positioning, immediate collision
  probe refresh after `onStand()`, Flash-style hurt-frame decrement timing,
  runtime omission of start markers, and last-loaded block lookup for overlapping
  tiles. The Haxe route still diverges in the first mine/arrow stack: after
  `bump:mine@12,27`, the port side-collides with `basic@11,30`, snaps to
  `x=370`, lands on `basic@12,31`, and never reaches Race Complete. The current
  published Flash app launches headless in the harness, so a fresh frame trace
  past this point still needs a working projector publish or another tracing path.

### Player Profile, Store, And UI Polish
