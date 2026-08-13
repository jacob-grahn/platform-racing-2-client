# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

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

#### HTML PR2 Forum Bug Reports

These unresolved reports were reviewed from pages 1-4 of the Jiggmin's Village
HTML PR2 bug-report prefix on 2 August 2026. Locked threads and threads whose
original reporter confirmed the bug was fixed are intentionally omitted.
Supporting images are stored in `docs/bug-reports/html-pr2/`; videos remain
available from their source threads.

##### Bug reports

- [!] [Super jump animation can blur body parts](https://jiggmin2.com/forums/showthread.php?tid=5423):
  a super jump can randomly blur or lower the resolution of body parts until a
  later super jump happens to restore them.
- [!] [Heart Block Doesn't Work](https://jiggmin2.com/forums/showthread.php?tid=5439):
  touching a Heart Block does not grant invincibility.
- [!] [Santa Hat does not give +10 Speed boost unless picked up](https://jiggmin2.com/forums/showthread.php?tid=5432):
  starting a race with the hat gives no boost, while repeated pickup/drop cycles
  stack +10 Speed without removing the boost on drop.
- [!] [Colour pallete color picker not working](https://jiggmin2.com/forums/showthread.php?tid=5438):
  the eyedropper appears but does not sample a colour.
- [x] [LE lags when drawing](https://jiggmin2.com/forums/showthread.php?tid=5437):
  drawing in an art-heavy level produces noticeable freezes.
- [!] [Super Jumping layers Player in front of Hat](https://jiggmin2.com/forums/showthread.php?tid=5436):
  charging a super jump draws the player in front of the equipped hat until a
  hat is dropped or picked up.
  [Evidence](docs/bug-reports/html-pr2/tid-5436-01.png)
- [x] [Sword hitbox still not identical](https://jiggmin2.com/forums/showthread.php?tid=5435):
  sword reach is too short in one standing setup and remains standing-height
  while crawling instead of matching the Flash hitbox.
  Evidence: [standing range](docs/bug-reports/html-pr2/tid-5435-01.png),
  [HTML crawl hitbox](docs/bug-reports/html-pr2/tid-5435-02.png), and
  [Flash crawl hitbox](docs/bug-reports/html-pr2/tid-5435-03.png).
- [x] [Colour Swatch Displays incorrect colours](https://jiggmin2.com/forums/showthread.php?tid=5434):
  saved swatches display colours roughly `#808080` brighter per channel than the
  popup and character part.
  Evidence: [example 1](docs/bug-reports/html-pr2/tid-5434-01.png) and
  [example 2](docs/bug-reports/html-pr2/tid-5434-02.png).
- [x] [Hat Effect Bugs](https://jiggmin2.com/forums/showthread.php?tid=5417):
  audit Moon, Jellyfish, Jumpstart, Artifact, and Santa effects: start-of-race
  effects are missing, several pickup/drop effects persist incorrectly, the
  Jellyfish lightning graphic and Speed Burst stars are absent, Artifact timing
  and facing are wrong, and Santa does not freeze Arrow or Vanish Blocks.
- [x] [Changing Hats changes stats](https://jiggmin2.com/forums/showthread.php?tid=5433):
  switching Santa/Cowboy hats while testing in Level Editor mutates displayed
  stats to 50 or 100, including during Super Flying Cowboy Mode.
  [Evidence](docs/bug-reports/html-pr2/tid-5433-01.png)
- [x] [Minimum Rank Requirement only updates on Account tab](https://jiggmin2.com/forums/showthread.php?tid=5431):
  logging into a lower-ranked account while another lobby tab is selected can
  retain the prior account's rank and bypass level rank restrictions.
  Evidence: [step 1](docs/bug-reports/html-pr2/tid-5431-01.png),
  [step 2](docs/bug-reports/html-pr2/tid-5431-02.png), and
  [result](docs/bug-reports/html-pr2/tid-5431-03.png).
- [!] [Player gets forfeited at start of race](https://jiggmin2.com/forums/showthread.php?tid=5429):
  with Flash and HTML players on Lightspeed 2 (3711604), the second entrant can
  be marked forfeited during countdown, continue playing, and receive no EXP.
  [Evidence](docs/bug-reports/html-pr2/tid-5429-01.png)
- [!] [Mine rotate glitch not working as expected](https://jiggmin2.com/forums/showthread.php?tid=5428):
  super-jumping into a Rotate Block while quickly placing a Mine does not match
  Flash's mine disappearance and wall-pass behavior.
- [!] [Mine doesn't delete itself on explosion](https://jiggmin2.com/forums/showthread.php?tid=5427):
  a Mine remains present if a player is inside it when it explodes.
- [!] [No mine placement animation while rotated](https://jiggmin2.com/forums/showthread.php?tid=5392):
  placed Mines omit their placement animation while the player is rotated.
  [Evidence](docs/bug-reports/html-pr2/tid-5392-01.gif)
- [!] [Block stacking doesn't work the same way](https://jiggmin2.com/forums/showthread.php?tid=5395):
  layered/stacked Block behavior differs from Flash and remains reproducible on
  the extra-glitches build.
- [!] [Attacks from alien eggs don't do anything](https://jiggmin2.com/forums/showthread.php?tid=5393):
  Alien Egg attacks only apply the freeze effect instead of their full behavior.
  [Evidence](docs/bug-reports/html-pr2/tid-5393-01.gif)
- [!] [Mines can't be placed in the same column that you're standing](https://jiggmin2.com/forums/showthread.php?tid=5390):
  Mine placement is offset one block forward and cannot target the player's
  current column.
  [Evidence](docs/bug-reports/html-pr2/tid-5390-01.png)
- [x] [Teleport blocks teleport rotated players to random position](https://jiggmin2.com/forums/showthread.php?tid=5424):
  Teleport Blocks send rotated players to apparently random positions while
  unrotated players work normally.
- [x] [Hitting a finish block while testing in LE crashes](https://jiggmin2.com/forums/showthread.php?tid=5422):
  touching a Finish Block during a Level Editor test plays the finish sound and
  then crashes the client.
- [x] [Alternate Movement Controls don't work in Level Editor](https://jiggmin2.com/forums/showthread.php?tid=5421):
  edit mode accepts only arrow keys; configured alternate movement keys such as
  WASD do nothing.
- [x] [Campaign Tab Bug](https://jiggmin2.com/forums/showthread.php?tid=5420):
  reloading the in-game Campaign tab resets it to the server's daily campaign
  instead of preserving the user's most recent campaign selection.
- [x] [Item Uses Display Bug](https://jiggmin2.com/forums/showthread.php?tid=5419):
  switching between unused multi-charge items can display one charge until the
  item is used, even though all three charges remain.
- [x] [Infinite Jetpack Sound Bug](https://jiggmin2.com/forums/showthread.php?tid=5418):
  collecting another item while using a Jetpack can leave its sound looping for
  every player until all charges of a later item are consumed.
- [!] [Super Flying Cowboy Hat Mode doesn't exist?](https://jiggmin2.com/forums/showthread.php?tid=5387):
  the Fred-with-hat animation appears, but the mode text is absent and the mode
  does not activate.
- [?] [Up Arrow physics not identical](https://jiggmin2.com/forums/showthread.php?tid=5360):
  Up Arrow, player, and/or Safety Net collision differs from Flash on Pixel
  Perfect (6511621), leaving the player stuck after the Crumble Blocks.
  Evidence: [initial comparison](docs/bug-reports/html-pr2/tid-5360-01.png) and
  [remaining failure](docs/bug-reports/html-pr2/tid-5360-02.gif).
- [!] [Scale issue with canvas of game](https://jiggmin2.com/forums/showthread.php?tid=5415):
  the game canvas chooses the wrong scale at common 1080p/1440p viewport sizes;
  opening developer tools before loading produces the expected scale.
  Evidence: [normal load](docs/bug-reports/html-pr2/tid-5415-01.png) and
  [developer-tools load](docs/bug-reports/html-pr2/tid-5415-02.png).
- [!] [Other players can destroy blocks by touching them](https://jiggmin2.com/forums/showthread.php?tid=5375):
  remote contact with Bricks, Crumble Blocks, or Mines hides the local graphic
  and repeatedly plays destruction art even though local collision remains.
  Evidence: [brick contact](docs/bug-reports/html-pr2/tid-5375-01.png),
  [invisible brick](docs/bug-reports/html-pr2/tid-5375-02.png), and
  [removed Mine position](docs/bug-reports/html-pr2/tid-5375-03.png).
- [!] [Stamps not aligned properly](https://jiggmin2.com/forums/showthread.php?tid=5413):
  stamps and art layers 00, 2, and 3 are offset relative to Blocks and lines.
  Evidence: [stamp](docs/bug-reports/html-pr2/tid-5413-01.png),
  [layer example 1](docs/bug-reports/html-pr2/tid-5413-02.png), and
  [layer example 2](docs/bug-reports/html-pr2/tid-5413-03.png).
- [!] [A couple of Level Editor problems](https://jiggmin2.com/forums/showthread.php?tid=5412):
  fix the reported editor parity gaps: initial camera/Block positions and Start
  numbers, hover icons, option-popup positions, Custom Stats/sliders, Text
  bounding-box resizing, cross-layer selection, dragging placement, and hard-to-
  click selection controls.
  Evidence: [1](docs/bug-reports/html-pr2/tid-5412-01.png),
  [2](docs/bug-reports/html-pr2/tid-5412-02.png),
  [3](docs/bug-reports/html-pr2/tid-5412-03.png),
  [4](docs/bug-reports/html-pr2/tid-5412-04.png),
  [5](docs/bug-reports/html-pr2/tid-5412-05.png), and
  [6](docs/bug-reports/html-pr2/tid-5412-06.png).
